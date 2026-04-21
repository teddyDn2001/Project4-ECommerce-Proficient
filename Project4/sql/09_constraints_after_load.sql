-- Run after successful bulk insert into orders / order_item
ALTER TABLE order_item
    ALTER COLUMN order_date SET NOT NULL;

ALTER TABLE order_item
    ALTER COLUMN created_at SET NOT NULL;
