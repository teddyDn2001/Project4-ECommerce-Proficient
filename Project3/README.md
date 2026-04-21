## Project 03 – Python in Data (E‑commerce OLTP)

This project uses **Python + Faker** to generate synthetic data for an **E‑commerce OLTP** schema and loads it into **PostgreSQL**.

### Tables covered

Generated with Faker:
- **brand** (20 rows)
- **category** (10 rows, with parent/child hierarchy)
- **seller** (25 rows, Vietnam-based)
- **product** (2000 rows, linked to brand/category/seller)
- **promotion** (10 rows)
- **promotion_product** (100 rows)

Schema only (no large-volume data yet; for next project):
- **orders**
- **order_item**

### 1. Install dependencies

From the project directory:

```bash
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Configure environment like a real project

Copy the sample `.env` file and adjust:

```bash
cp .env.example .env
```

Mở file `.env` và chỉnh:
- Thông tin kết nối DB: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
- Số lượng record muốn sinh: `BRAND_COUNT`, `CATEGORY_COUNT`, `SELLER_COUNT`, `PRODUCT_COUNT`, `PROMOTION_COUNT`, `PROMOTION_PRODUCT_COUNT`

Script sẽ tự đọc `.env` thông qua `python-dotenv`.

### 3. Prepare PostgreSQL database

Create a PostgreSQL database (example: `ecommerce_db`), then run the schema:

```bash
psql -h localhost -U postgres -d ecommerce_db -f schema_postgres.sql
```

Adjust host, user, and database name as needed.

### 4. Generate data

Run:

```bash
python generate_data.py
```

This will insert data into all tables listed in the **Generated with Faker** section, keeping all foreign keys consistent.

