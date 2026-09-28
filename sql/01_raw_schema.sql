-- Raw layer: mirrors the CSV, no constraints.
-- All data lands here first via COPY; downstream layers clean and reshape it.

CREATE SCHEMA IF NOT EXISTS raw;

DROP TABLE IF EXISTS raw.transactions_raw;
CREATE TABLE raw.transactions_raw (
    transaction_id    BIGINT,
    transaction_date  DATE,
    store_id          INT,
    store_name        TEXT,
    city              TEXT,
    customer_id       INT,
    customer_email    TEXT,
    region            TEXT,
    product_id        INT,
    sku               TEXT,
    category          TEXT,
    quantity          INT,
    unit_price        NUMERIC(12, 2),
    discount_pct      NUMERIC(5, 2),
    loaded_at         TIMESTAMP DEFAULT NOW()
);
