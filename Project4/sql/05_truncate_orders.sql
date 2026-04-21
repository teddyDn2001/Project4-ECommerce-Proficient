-- Reset transactional tables before a fresh bulk load
TRUNCATE TABLE order_item, orders RESTART IDENTITY CASCADE;
