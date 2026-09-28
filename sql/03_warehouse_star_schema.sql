-- Warehouse layer: classic star schema with 1 fact + 4 dimensions.

CREATE SCHEMA IF NOT EXISTS warehouse;

DROP TABLE IF EXISTS warehouse.fact_sales;
DROP TABLE IF EXISTS warehouse.dim_date;
DROP TABLE IF EXISTS warehouse.dim_customer;
DROP TABLE IF EXISTS warehouse.dim_product;
DROP TABLE IF EXISTS warehouse.dim_store;

CREATE TABLE warehouse.dim_date (
    date_key   INT PRIMARY KEY,        -- YYYYMMDD
    full_date  DATE UNIQUE NOT NULL,
    year       INT NOT NULL,
    quarter    INT NOT NULL,
    month      INT NOT NULL,
    month_name TEXT NOT NULL,
    day        INT NOT NULL,
    weekday    INT NOT NULL,
    weekday_name TEXT NOT NULL,
    is_weekend BOOLEAN NOT NULL
);

CREATE TABLE warehouse.dim_customer (
    customer_key   SERIAL PRIMARY KEY,
    customer_id    INT UNIQUE NOT NULL,
    customer_email TEXT,
    region         TEXT,
    first_seen     DATE
);

CREATE TABLE warehouse.dim_product (
    product_key SERIAL PRIMARY KEY,
    product_id  INT UNIQUE NOT NULL,
    sku         TEXT,
    category    TEXT
);

CREATE TABLE warehouse.dim_store (
    store_key  SERIAL PRIMARY KEY,
    store_id   INT UNIQUE NOT NULL,
    store_name TEXT,
    city       TEXT
);

CREATE TABLE warehouse.fact_sales (
    sales_key      BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT UNIQUE NOT NULL,
    date_key       INT NOT NULL REFERENCES warehouse.dim_date(date_key),
    customer_key   INT NOT NULL REFERENCES warehouse.dim_customer(customer_key),
    product_key    INT NOT NULL REFERENCES warehouse.dim_product(product_key),
    store_key      INT NOT NULL REFERENCES warehouse.dim_store(store_key),
    quantity       INT NOT NULL,
    unit_price     NUMERIC(12, 2) NOT NULL,
    discount_pct   NUMERIC(5, 2)  DEFAULT 0,
    gross_amount   NUMERIC(14, 2) NOT NULL,
    net_amount     NUMERIC(14, 2) NOT NULL
);

CREATE INDEX idx_fact_date     ON warehouse.fact_sales(date_key);
CREATE INDEX idx_fact_customer ON warehouse.fact_sales(customer_key);
CREATE INDEX idx_fact_product  ON warehouse.fact_sales(product_key);
CREATE INDEX idx_fact_store    ON warehouse.fact_sales(store_key);
