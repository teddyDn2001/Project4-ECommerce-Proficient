-- E-commerce OLTP schema for PostgreSQL

-- Note: we use table name "orders" instead of reserved word "order"

CREATE TABLE IF NOT EXISTS brand (
    brand_id     SERIAL PRIMARY KEY,
    brand_name   VARCHAR(100) NOT NULL,
    country      VARCHAR(50)  NOT NULL,
    created_at   TIMESTAMP    NOT NULL
);

CREATE TABLE IF NOT EXISTS category (
    category_id         SERIAL PRIMARY KEY,
    category_name       VARCHAR(100) NOT NULL,
    parent_category_id  INT REFERENCES category(category_id),
    level               SMALLINT     NOT NULL,
    created_at          TIMESTAMP    NOT NULL
);

CREATE TABLE IF NOT EXISTS seller (
    seller_id    SERIAL PRIMARY KEY,
    seller_name  VARCHAR(150) NOT NULL,
    join_date    DATE         NOT NULL,
    seller_type  VARCHAR(50)  NOT NULL,
    rating       NUMERIC(2,1) NOT NULL,
    country      VARCHAR(50)  NOT NULL
);

CREATE TABLE IF NOT EXISTS product (
    product_id    SERIAL PRIMARY KEY,
    product_name  VARCHAR(200)   NOT NULL,
    category_id   INT            NOT NULL REFERENCES category(category_id),
    brand_id      INT            NOT NULL REFERENCES brand(brand_id),
    seller_id     INT            NOT NULL REFERENCES seller(seller_id),
    price         NUMERIC(12,2)  NOT NULL,
    discount_price NUMERIC(12,2) NOT NULL,
    stock_qty     INT            NOT NULL,
    rating        NUMERIC(2,1)   NOT NULL,
    created_at    TIMESTAMP      NOT NULL,
    is_active     BOOLEAN        NOT NULL
);

CREATE TABLE IF NOT EXISTS orders (
    order_id     SERIAL PRIMARY KEY,
    order_date   TIMESTAMP      NOT NULL,
    seller_id    INT            NOT NULL REFERENCES seller(seller_id),
    status       VARCHAR(20)    NOT NULL,
    total_amount NUMERIC(12,2)  NOT NULL,
    created_at   TIMESTAMP      NOT NULL
);

CREATE TABLE IF NOT EXISTS order_item (
    order_item_id SERIAL PRIMARY KEY,
    order_id      INT           NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id    INT           NOT NULL REFERENCES product(product_id),
    quantity      INT           NOT NULL,
    unit_price    NUMERIC(12,2) NOT NULL,
    subtotal      NUMERIC(12,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS promotion (
    promotion_id    SERIAL PRIMARY KEY,
    promotion_name  VARCHAR(100)  NOT NULL,
    promotion_type  VARCHAR(50)   NOT NULL,
    discount_type   VARCHAR(20)   NOT NULL,
    discount_value  NUMERIC(10,2) NOT NULL,
    start_date      DATE          NOT NULL,
    end_date        DATE          NOT NULL
);

CREATE TABLE IF NOT EXISTS promotion_product (
    promo_product_id SERIAL PRIMARY KEY,
    promotion_id     INT        NOT NULL REFERENCES promotion(promotion_id),
    product_id       INT        NOT NULL REFERENCES product(product_id),
    created_at       TIMESTAMP  NOT NULL
);

