-- Project 04: prepare existing Project3 tables for transactional load
-- Run after schema_postgres.sql + generate_data.py

ALTER TABLE order_item
    ALTER COLUMN order_item_id TYPE BIGINT;

ALTER TABLE order_item
    ADD COLUMN IF NOT EXISTS order_date TIMESTAMP;

ALTER TABLE order_item
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP;

UPDATE order_item oi
SET
    order_date = o.order_date,
    created_at = COALESCE(oi.created_at, o.created_at)
FROM orders o
WHERE oi.order_id = o.order_id
  AND (oi.order_date IS NULL OR oi.created_at IS NULL);

ALTER TABLE order_item
    ALTER COLUMN unit_price TYPE NUMERIC(10, 2);

-- After bulk load (generate_orders_project4.py), enforce NOT NULL:
-- ALTER TABLE order_item ALTER COLUMN order_date SET NOT NULL;
-- ALTER TABLE order_item ALTER COLUMN created_at SET NOT NULL;
