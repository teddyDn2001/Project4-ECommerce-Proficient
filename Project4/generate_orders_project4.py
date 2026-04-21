#!/usr/bin/env python3
"""
Project 04: bulk-generate orders + order_items (2.5M–3M orders, 2–4 line items each).
Prerequisites: Project3 base data loaded; run sql/00_prep_alter_tables.sql first.

Env:
  ORDERS_COUNT   default 2700000
  BATCH_ORDERS   default 800 (rows per INSERT multi-values batch)
  RANDOM_SEED    default 42
  DB_*           same as Project3 (.env)
"""

from __future__ import annotations

import logging
import os
import random
from datetime import datetime, timedelta
from decimal import Decimal

import psycopg2
from dotenv import load_dotenv
from psycopg2.extras import execute_values

load_dotenv()

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

STATUSES = ("PLACED", "PAID", "DELIVERED", "SHIPPED", "CANCELLED", "RETURNED")
STATUS_WEIGHTS = (5, 4, 70, 11, 7, 3)

START = datetime(2025, 8, 1, 0, 0, 0)
END = datetime(2025, 10, 31, 23, 59, 59)


def random_order_date(rng: random.Random) -> datetime:
    span = int((END - START).total_seconds())
    return START + timedelta(seconds=rng.randint(0, span))


def pick_status(rng: random.Random) -> str:
    return rng.choices(STATUSES, weights=STATUS_WEIGHTS, k=1)[0]


def load_seller_products(cur) -> dict[int, list[tuple[int, Decimal]]]:
    cur.execute(
        """
        SELECT product_id, seller_id, discount_price, price
        FROM product
        WHERE is_active = TRUE
        """
    )
    rows = cur.fetchall()
    if not rows:
        cur.execute(
            "SELECT product_id, seller_id, discount_price, price FROM product"
        )
        rows = cur.fetchall()
    by_seller: dict[int, list[tuple[int, Decimal]]] = {}
    for pid, sid, disc, price in rows:
        unit = disc if disc is not None else price
        by_seller.setdefault(sid, []).append((pid, Decimal(str(unit))))
    return by_seller


def insert_orders_batch(cur, batch: list[tuple]) -> list[int]:
    """batch tuples: (order_date, seller_id, status, total_amount, created_at)"""
    n = len(batch)
    placeholders = ",".join(["(%s,%s,%s,%s,%s)"] * n)
    flat = [x for row in batch for x in row]
    cur.execute(
        f"""
        INSERT INTO orders (order_date, seller_id, status, total_amount, created_at)
        VALUES {placeholders}
        RETURNING order_id
        """,
        flat,
    )
    return [r[0] for r in cur.fetchall()]


def main() -> None:
    orders_target = int(os.getenv("ORDERS_COUNT", "2700000"))
    batch_orders = int(os.getenv("BATCH_ORDERS", "800"))
    seed = int(os.getenv("RANDOM_SEED", "42"))
    rng = random.Random(seed)

    conn = psycopg2.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "5432")),
        dbname=os.getenv("DB_NAME", "ecommerce_db"),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASSWORD", "postgres"),
    )
    conn.autocommit = False

    with conn.cursor() as cur:
        by_seller = load_seller_products(cur)
    seller_ids = [s for s, p in by_seller.items() if len(p) >= 2]
    if not seller_ids:
        raise RuntimeError(
            "Need at least one seller with 2+ products (assignment requires 2–4 items per order)."
        )

    inserted = 0
    zero = Decimal("0.00")

    while inserted < orders_target:
        chunk = min(batch_orders, orders_target - inserted)
        batch: list[tuple] = []
        meta: list[tuple[int, datetime, datetime, str]] = []

        for _ in range(chunk):
            sid = rng.choice(seller_ids)
            od = random_order_date(rng)
            st = pick_status(rng)
            ca = od + timedelta(seconds=rng.randint(0, 300))
            batch.append((od, sid, st, zero, ca))
            meta.append((sid, od, ca, st))

        with conn.cursor() as cur:
            new_ids = insert_orders_batch(cur, batch)
            if len(new_ids) != chunk:
                raise RuntimeError("RETURNING order_id count mismatch")

            item_rows: list[tuple] = []
            for order_id, (sid, od, ca, _) in zip(new_ids, meta):
                prods = by_seller[sid]
                n_items = rng.randint(2, min(4, len(prods)))
                chosen = rng.sample(prods, k=n_items)
                for pid, unit in chosen:
                    qty = rng.randint(1, 5)
                    unit_q = unit.quantize(Decimal("0.01"))
                    sub = (unit_q * qty).quantize(Decimal("0.01"))
                    item_rows.append(
                        (order_id, od, pid, qty, unit_q, sub, ca)
                    )

            execute_values(
                cur,
                """
                INSERT INTO order_item (
                    order_id, order_date, product_id, quantity, unit_price, subtotal, created_at
                ) VALUES %s
                """,
                item_rows,
                page_size=8000,
            )

            cur.execute(
                """
                UPDATE orders o
                SET total_amount = s.sum_sub
                FROM (
                    SELECT order_id, SUM(subtotal) AS sum_sub
                    FROM order_item
                    WHERE order_id = ANY(%s)
                    GROUP BY order_id
                ) s
                WHERE o.order_id = s.order_id
                """,
                (new_ids,),
            )

        conn.commit()
        inserted += chunk
        if inserted % 50_000 == 0 or inserted >= orders_target:
            logger.info("Orders inserted: %s / %s", inserted, orders_target)

    logger.info("Completed %s orders.", inserted)


if __name__ == "__main__":
    main()
