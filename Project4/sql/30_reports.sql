-- Project 04: parameterized reports (functions). Uses orders + order_item + product + brand + seller.
-- Join on (order_id, order_date) to align with partitioned layout and denormalized line items.

-- Monthly revenue: month, total_orders, total_quantity, total_revenue
CREATE OR REPLACE FUNCTION public.report_monthly_revenue(
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    month DATE,
    total_orders BIGINT,
    total_quantity NUMERIC,
    total_revenue NUMERIC
)
LANGUAGE SQL
STABLE
AS $$
    SELECT
        date_trunc('month', o.order_date)::DATE AS month,
        COUNT(DISTINCT (o.order_id, o.order_date))::BIGINT AS total_orders,
        COALESCE(SUM(oi.quantity), 0)::NUMERIC AS total_quantity,
        COALESCE(SUM(oi.subtotal), 0)::NUMERIC AS total_revenue
    FROM orders o
    JOIN order_item oi
        ON oi.order_id = o.order_id
       AND oi.order_date = o.order_date
    WHERE o.order_date >= p_start_date::TIMESTAMP
      AND o.order_date < (p_end_date + 1)::TIMESTAMP
    GROUP BY 1
    ORDER BY 1;
$$;

-- Daily revenue: date, total_orders, total_quantity, total_revenue; filter by product list
CREATE OR REPLACE FUNCTION public.report_daily_revenue(
    p_start_date DATE,
    p_end_date DATE,
    p_product_ids INT[]
)
RETURNS TABLE (
    day DATE,
    total_orders BIGINT,
    total_quantity NUMERIC,
    total_revenue NUMERIC
)
LANGUAGE SQL
STABLE
AS $$
    SELECT
        o.order_date::DATE AS day,
        COUNT(DISTINCT (o.order_id, o.order_date))::BIGINT AS total_orders,
        COALESCE(SUM(oi.quantity), 0)::NUMERIC AS total_quantity,
        COALESCE(SUM(oi.subtotal), 0)::NUMERIC AS total_revenue
    FROM orders o
    JOIN order_item oi
        ON oi.order_id = o.order_id
       AND oi.order_date = o.order_date
    WHERE o.order_date >= p_start_date::TIMESTAMP
      AND o.order_date < (p_end_date + 1)::TIMESTAMP
      AND oi.product_id = ANY(p_product_ids)
    GROUP BY 1
    ORDER BY 1;
$$;

-- Seller performance
CREATE OR REPLACE FUNCTION public.report_seller_performance(
    p_start_date DATE,
    p_end_date DATE,
    p_category_id INT DEFAULT NULL,
    p_brand_id INT DEFAULT NULL
)
RETURNS TABLE (
    seller_id INT,
    seller_name VARCHAR,
    total_orders BIGINT,
    total_quantity NUMERIC,
    total_revenue NUMERIC
)
LANGUAGE SQL
STABLE
AS $$
    SELECT
        s.seller_id,
        s.seller_name,
        COUNT(DISTINCT (o.order_id, o.order_date))::BIGINT AS total_orders,
        COALESCE(SUM(oi.quantity), 0)::NUMERIC AS total_quantity,
        COALESCE(SUM(oi.subtotal), 0)::NUMERIC AS total_revenue
    FROM orders o
    JOIN order_item oi
        ON oi.order_id = o.order_id
       AND oi.order_date = o.order_date
    JOIN product p ON p.product_id = oi.product_id
    JOIN seller s ON s.seller_id = o.seller_id
    WHERE o.order_date >= p_start_date::TIMESTAMP
      AND o.order_date < (p_end_date + 1)::TIMESTAMP
      AND (p_category_id IS NULL OR p.category_id = p_category_id)
      AND (p_brand_id IS NULL OR p.brand_id = p_brand_id)
    GROUP BY s.seller_id, s.seller_name
    ORDER BY total_revenue DESC NULLS LAST;
$$;

-- Top products per brand (ranked within brand)
CREATE OR REPLACE FUNCTION public.report_top_products_per_brand(
    p_start_date DATE,
    p_end_date DATE,
    p_top_n INT DEFAULT 5,
    p_seller_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
    brand_id INT,
    brand_name VARCHAR,
    product_id INT,
    product_name VARCHAR,
    total_quantity BIGINT,
    total_revenue NUMERIC
)
LANGUAGE SQL
STABLE
AS $$
    WITH agg AS (
        SELECT
            b.brand_id,
            b.brand_name,
            p.product_id,
            p.product_name,
            SUM(oi.quantity)::BIGINT AS q,
            SUM(oi.subtotal)::NUMERIC AS rev
        FROM orders o
        JOIN order_item oi
            ON oi.order_id = o.order_id
           AND oi.order_date = o.order_date
        JOIN product p ON p.product_id = oi.product_id
        JOIN brand b ON b.brand_id = p.brand_id
        WHERE o.order_date >= p_start_date::TIMESTAMP
          AND o.order_date < (p_end_date + 1)::TIMESTAMP
          AND (p_seller_ids IS NULL OR p.seller_id = ANY(p_seller_ids))
        GROUP BY b.brand_id, b.brand_name, p.product_id, p.product_name
    ),
    ranked AS (
        SELECT
            a.*,
            RANK() OVER (
                PARTITION BY a.brand_id
                ORDER BY a.q DESC, a.rev DESC
            ) AS rk
        FROM agg a
    )
    SELECT brand_id, brand_name, product_id, product_name, q AS total_quantity, rev AS total_revenue
    FROM ranked
    WHERE rk <= p_top_n
    ORDER BY brand_id, total_quantity DESC;
$$;

-- Orders status summary (raw status values)
CREATE OR REPLACE FUNCTION public.report_orders_status_summary(
    p_start_date DATE,
    p_end_date DATE,
    p_seller_ids INT[] DEFAULT NULL,
    p_category_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
    status VARCHAR,
    total_orders BIGINT,
    total_revenue NUMERIC
)
LANGUAGE SQL
STABLE
AS $$
    SELECT
        o.status,
        COUNT(DISTINCT (o.order_id, o.order_date))::BIGINT AS total_orders,
        COALESCE(SUM(oi.subtotal), 0)::NUMERIC AS total_revenue
    FROM orders o
    JOIN order_item oi
        ON oi.order_id = o.order_id
       AND oi.order_date = o.order_date
    JOIN product p ON p.product_id = oi.product_id
    WHERE o.order_date >= p_start_date::TIMESTAMP
      AND o.order_date < (p_end_date + 1)::TIMESTAMP
      AND (p_seller_ids IS NULL OR o.seller_id = ANY(p_seller_ids))
      AND (p_category_ids IS NULL OR p.category_id = ANY(p_category_ids))
    GROUP BY o.status
    ORDER BY total_orders DESC;
$$;
