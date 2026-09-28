-- Staging layer: deduped and typed. One row per transaction.

CREATE SCHEMA IF NOT EXISTS staging;

DROP TABLE IF EXISTS staging.transactions_stg;
CREATE TABLE staging.transactions_stg (
    transaction_id    BIGINT PRIMARY KEY,
    transaction_date  DATE   NOT NULL,
    store_id          INT    NOT NULL,
    store_name        TEXT   NOT NULL,
    city              TEXT,
    customer_id       INT    NOT NULL,
    customer_email    TEXT,
    region            TEXT,
    product_id        INT    NOT NULL,
    sku               TEXT,
    category          TEXT,
    quantity          INT    NOT NULL,
    unit_price        NUMERIC(12, 2) NOT NULL,
    discount_pct      NUMERIC(5, 2)  DEFAULT 0,
    net_amount        NUMERIC(14, 2) NOT NULL,
    processed_at      TIMESTAMP DEFAULT NOW()
);
