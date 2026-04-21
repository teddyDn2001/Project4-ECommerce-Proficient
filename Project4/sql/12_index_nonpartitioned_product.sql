-- Optional: index on product_id before migration (for baseline benchmarks)
CREATE INDEX IF NOT EXISTS order_item_product_id_idx ON order_item (product_id);
