import os
import random
import logging
from datetime import datetime, timedelta

import psycopg2
from dotenv import load_dotenv
from faker import Faker


# ----------------------------
# Configuration & logging
# ----------------------------

load_dotenv()  # Load values from .env if present

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)


DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME", "ecommerce_db")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")

BRAND_COUNT = int(os.getenv("BRAND_COUNT", "20"))
CATEGORY_COUNT = int(os.getenv("CATEGORY_COUNT", "10"))
SELLER_COUNT = int(os.getenv("SELLER_COUNT", "25"))
PRODUCT_COUNT = int(os.getenv("PRODUCT_COUNT", "2000"))
PROMOTION_COUNT = int(os.getenv("PROMOTION_COUNT", "10"))
PROMOTION_PRODUCT_COUNT = int(os.getenv("PROMOTION_PRODUCT_COUNT", "100"))


fake = Faker()
Faker.seed(42)
random.seed(42)


def get_connection():
    logger.info(
        "Connecting to PostgreSQL at %s:%s, db=%s, user=%s",
        DB_HOST,
        DB_PORT,
        DB_NAME,
        DB_USER,
    )
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
    )


def generate_brands(cur, n: int) -> list[int]:
    logger.info("Generating %s brands...", n)
    sql = """
        INSERT INTO brand (brand_name, country, created_at)
        VALUES (%s, %s, %s)
        RETURNING brand_id
    """
    brand_ids = []
    for _ in range(n):
        brand_name = fake.unique.company()
        country = fake.country()
        created_at = fake.date_time_this_decade()
        cur.execute(sql, (brand_name, country, created_at))
        brand_id = cur.fetchone()[0]
        brand_ids.append(brand_id)
    return brand_ids


def generate_categories(cur, total_categories: int) -> list[int]:
    """
    Generate category hierarchy.
    total_categories includes both level 1 and level 2. We keep 5 main + (total - 5) sub.
    """
    logger.info("Generating %s categories (with hierarchy)...", total_categories)

    categories = []
    insert_sql = """
        INSERT INTO category (category_name, parent_category_id, level, created_at)
        VALUES (%s, %s, %s, %s)
        RETURNING category_id
    """

    # Level 1 main categories (no parent)
    main_categories = [
        "Electronics",
        "Fashion",
        "Home & Living",
        "Beauty & Health",
        "Sports & Outdoors",
    ]

    main_ids = []
    for name in main_categories:
        created_at = fake.date_time_this_year()
        cur.execute(insert_sql, (name, None, 1, created_at))
        cid = cur.fetchone()[0]
        main_ids.append(cid)
        categories.append(cid)

    # Level 2 subcategories referencing a random main category
    default_sub_categories = [
        "Mobile Phones",
        "Laptops",
        "Men Clothing",
        "Women Clothing",
        "Kitchen Appliances",
    ]

    remaining = max(total_categories - len(main_categories), 0)
    sub_categories: list[str] = []
    while len(sub_categories) < remaining:
        sub_categories.extend(default_sub_categories)
    sub_categories = sub_categories[:remaining]

    for name in sub_categories:
        parent_id = random.choice(main_ids)
        created_at = fake.date_time_this_year()
        cur.execute(insert_sql, (name, parent_id, 2, created_at))
        cid = cur.fetchone()[0]
        categories.append(cid)

    return categories


def generate_sellers(cur, n: int) -> list[int]:
    logger.info("Generating %s sellers...", n)
    sql = """
        INSERT INTO seller (seller_name, join_date, seller_type, rating, country)
        VALUES (%s, %s, %s, %s, %s)
        RETURNING seller_id
    """

    seller_types = ["Official", "Marketplace"]
    seller_ids = []

    for _ in range(n):
        seller_name = fake.company()
        join_date = fake.date_between(start_date="-5y", end_date="today")
        seller_type = random.choice(seller_types)
        rating = round(random.uniform(3.0, 5.0), 1)
        country = "Vietnam"

        cur.execute(sql, (seller_name, join_date, seller_type, rating, country))
        seller_id = cur.fetchone()[0]
        seller_ids.append(seller_id)

    return seller_ids


def generate_products(cur, n: int) -> list[int]:
    logger.info("Generating %s products...", n)

    # Fetch FK values
    cur.execute("SELECT brand_id FROM brand")
    brand_ids = [row[0] for row in cur.fetchall()]

    cur.execute("SELECT category_id FROM category")
    category_ids = [row[0] for row in cur.fetchall()]

    cur.execute("SELECT seller_id FROM seller")
    seller_ids = [row[0] for row in cur.fetchall()]

    if not (brand_ids and category_ids and seller_ids):
        raise RuntimeError("FK tables must be populated before generating products.")

    sql = """
        INSERT INTO product (
            product_name, category_id, brand_id, seller_id,
            price, discount_price, stock_qty, rating, created_at, is_active
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING product_id
    """

    product_ids = []
    for _ in range(n):
        product_name = fake.catch_phrase()
        category_id = random.choice(category_ids)
        brand_id = random.choice(brand_ids)
        seller_id = random.choice(seller_ids)

        price = round(random.uniform(100_000, 50_000_000), 2)
        discount_factor = random.uniform(0.7, 1.0)
        discount_price = round(price * discount_factor, 2)
        stock_qty = random.randint(0, 500)
        rating = round(random.uniform(3.0, 5.0), 1)
        created_at = fake.date_time_between(start_date="-3y", end_date="now")
        is_active = random.choice([True, False])

        cur.execute(
            sql,
            (
                product_name,
                category_id,
                brand_id,
                seller_id,
                price,
                discount_price,
                stock_qty,
                rating,
                created_at,
                is_active,
            ),
        )
        product_id = cur.fetchone()[0]
        product_ids.append(product_id)

    return product_ids


def generate_promotions(cur, n: int) -> list[int]:
    logger.info("Generating %s promotions...", n)
    sql = """
        INSERT INTO promotion (
            promotion_name, promotion_type, discount_type,
            discount_value, start_date, end_date
        )
        VALUES (%s, %s, %s, %s, %s, %s)
        RETURNING promotion_id
    """

    promotion_types = ["product", "category", "seller", "flash_sale"]
    discount_types = ["percentage", "fixed_amount"]

    promotion_ids = []
    for _ in range(n):
        promotion_name = f"{fake.random_int(1, 12)}.{fake.random_int(1, 12)} Mega Sale"
        promotion_type = random.choice(promotion_types)
        discount_type = random.choice(discount_types)

        if discount_type == "percentage":
            discount_value = random.choice([5, 10, 15, 20, 25, 30, 40, 50])
        else:
            discount_value = random.choice([50_000, 100_000, 150_000, 200_000, 300_000, 500_000])

        start_date = fake.date_between(start_date="-1y", end_date="today")
        extra_days = random.randint(30, 50)
        end_date_dt = datetime.combine(start_date, datetime.min.time()) + timedelta(days=extra_days)
        end_date = end_date_dt.date()

        cur.execute(
            sql,
            (
                promotion_name,
                promotion_type,
                discount_type,
                discount_value,
                start_date,
                end_date,
            ),
        )
        promotion_id = cur.fetchone()[0]
        promotion_ids.append(promotion_id)

    return promotion_ids


def generate_promotion_products(cur, n: int) -> None:
    logger.info("Generating %s promotion_product mappings...", n)

    cur.execute("SELECT promotion_id FROM promotion")
    promotion_ids = [row[0] for row in cur.fetchall()]

    cur.execute("SELECT product_id FROM product")
    product_ids = [row[0] for row in cur.fetchall()]

    if not (promotion_ids and product_ids):
        raise RuntimeError("Promotions and products must be generated first.")

    sql = """
        INSERT INTO promotion_product (promotion_id, product_id, created_at)
        VALUES (%s, %s, %s)
    """

    used_pairs = set()
    count = 0

    while count < n:
        promotion_id = random.choice(promotion_ids)
        product_id = random.choice(product_ids)
        pair = (promotion_id, product_id)

        if pair in used_pairs:
            continue

        created_at = fake.date_time_this_year()
        cur.execute(sql, (promotion_id, product_id, created_at))

        used_pairs.add(pair)
        count += 1


def main() -> None:
    conn = get_connection()
    conn.autocommit = False

    try:
        with conn.cursor() as cur:
            # The tables should already be created via schema_postgres.sql
            # Generate data in FK-safe order
            generate_brands(cur, n=BRAND_COUNT)
            generate_categories(cur, total_categories=CATEGORY_COUNT)
            generate_sellers(cur, n=SELLER_COUNT)
            generate_products(cur, n=PRODUCT_COUNT)
            generate_promotions(cur, n=PROMOTION_COUNT)
            generate_promotion_products(cur, n=PROMOTION_PRODUCT_COUNT)

        conn.commit()
        logger.info("Data generation completed and committed.")
    except Exception as e:
        conn.rollback()
        logger.exception("Error occurred, rolled back transaction: %s", e)
        raise
    finally:
        conn.close()
        logger.info("Connection closed.")


if __name__ == "__main__":
    main()

