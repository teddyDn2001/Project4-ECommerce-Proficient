-- Project 04: analytical queries for benchmarking (run with EXPLAIN ANALYZE and save plans)
-- Example: EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) <query>;

-- 1) Total revenue per month
SELECT
    date_trunc('month', o.order_date)::DATE AS month,
    SUM(oi.subtotal) AS total_revenue
FROM orders o
JOIN order_item oi ON oi.order_id = o.order_id
    AND oi.order_date = o.order_date
WHERE o.order_date >= TIMESTAMP '2025-08-01'
  AND o.order_date < TIMESTAMP '2025-11-01'
GROUP BY 1
ORDER BY 1;

-- 2) Orders filtered by seller and date
SELECT o.order_id, o.order_date, o.seller_id, o.status, o.total_amount
FROM orders o
WHERE o.seller_id = 1
  AND o.order_date >= TIMESTAMP '2025-09-01'
  AND o.order_date < TIMESTAMP '2025-10-01'
ORDER BY o.order_date
LIMIT 500;

-- 3) Filter order_item by product_id
SELECT oi.order_item_id, oi.order_id, oi.product_id, oi.quantity, oi.subtotal
FROM order_item oi
WHERE oi.product_id = 1
ORDER BY oi.order_date
LIMIT 500;

-- 4) Order with highest total_amount
SELECT order_id, order_date, seller_id, status, total_amount
FROM orders
ORDER BY total_amount DESC
LIMIT 1;

-- 5) Products with highest quantity sold
SELECT
    oi.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_quantity,
    SUM(oi.subtotal) AS total_revenue
FROM order_item oi
JOIN product p ON p.product_id = oi.product_id
GROUP BY oi.product_id, p.product_name
ORDER BY total_quantity DESC
LIMIT 20;

-- 6) Orders by seller in October 2025
SELECT o.seller_id, COUNT(*) AS order_count, SUM(o.total_amount) AS revenue
FROM orders o
WHERE o.order_date >= TIMESTAMP '2025-10-01'
  AND o.order_date < TIMESTAMP '2025-11-01'
GROUP BY o.seller_id
ORDER BY order_count DESC;

-- 7) Revenue per product per month
SELECT
    date_trunc('month', o.order_date)::DATE AS month,
    oi.product_id,
    p.product_name,
    SUM(oi.subtotal) AS revenue,
    SUM(oi.quantity) AS qty
FROM orders o
JOIN order_item oi ON oi.order_id = o.order_id AND oi.order_date = o.order_date
JOIN product p ON p.product_id = oi.product_id
WHERE o.order_date >= TIMESTAMP '2025-08-01'
  AND o.order_date < TIMESTAMP '2025-11-01'
GROUP BY 1, 2, 3
ORDER BY month, revenue DESC;

-- 8) Products sold per seller
SELECT
    p.seller_id,
    oi.product_id,
    SUM(oi.quantity) AS total_quantity,
    SUM(oi.subtotal) AS total_revenue
FROM order_item oi
JOIN product p ON p.product_id = oi.product_id
GROUP BY p.seller_id, oi.product_id
ORDER BY p.seller_id, total_quantity DESC;
