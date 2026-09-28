-- Staging -> Warehouse: incremental UPSERT into dims + INSERT new facts only.

-- 1. dim_date: any dates in staging that aren't in dim_date yet
INSERT INTO warehouse.dim_date (
    date_key, full_date, year, quarter, month, month_name,
    day, weekday, weekday_name, is_weekend
)
SELECT DISTINCT
    TO_CHAR(transaction_date, 'YYYYMMDD')::INT AS date_key,
    transaction_date,
    EXTRACT(YEAR    FROM transaction_date)::INT,
    EXTRACT(QUARTER FROM transaction_date)::INT,
    EXTRACT(MONTH   FROM transaction_date)::INT,
    TRIM(TO_CHAR(transaction_date, 'Month')),
    EXTRACT(DAY     FROM transaction_date)::INT,
    EXTRACT(ISODOW  FROM transaction_date)::INT,
    TRIM(TO_CHAR(transaction_date, 'Day')),
    EXTRACT(ISODOW  FROM transaction_date) IN (6, 7)
FROM staging.transactions_stg
ON CONFLICT (date_key) DO NOTHING;

-- 2. dim_customer
INSERT INTO warehouse.dim_customer (customer_id, customer_email, region, first_seen)
SELECT DISTINCT ON (customer_id)
    customer_id, customer_email, region, MIN(transaction_date) OVER (PARTITION BY customer_id)
FROM staging.transactions_stg
ON CONFLICT (customer_id) DO UPDATE
    SET customer_email = EXCLUDED.customer_email,
        region         = EXCLUDED.region;

-- 3. dim_product
INSERT INTO warehouse.dim_product (product_id, sku, category)
SELECT DISTINCT product_id, sku, category
FROM staging.transactions_stg
ON CONFLICT (product_id) DO UPDATE
    SET sku      = EXCLUDED.sku,
        category = EXCLUDED.category;

-- 4. dim_store
INSERT INTO warehouse.dim_store (store_id, store_name, city)
SELECT DISTINCT store_id, store_name, city
FROM staging.transactions_stg
ON CONFLICT (store_id) DO UPDATE
    SET store_name = EXCLUDED.store_name,
        city       = EXCLUDED.city;

-- 5. fact_sales incremental: only new transactions
INSERT INTO warehouse.fact_sales (
    transaction_id, date_key, customer_key, product_key, store_key,
    quantity, unit_price, discount_pct, gross_amount, net_amount
)
SELECT
    s.transaction_id,
    TO_CHAR(s.transaction_date, 'YYYYMMDD')::INT,
    dc.customer_key,
    dp.product_key,
    ds.store_key,
    s.quantity, s.unit_price, s.discount_pct,
    ROUND(s.quantity * s.unit_price, 2)  AS gross_amount,
    s.net_amount
FROM staging.transactions_stg s
JOIN warehouse.dim_customer dc ON dc.customer_id = s.customer_id
JOIN warehouse.dim_product  dp ON dp.product_id  = s.product_id
JOIN warehouse.dim_store    ds ON ds.store_id    = s.store_id
LEFT JOIN warehouse.fact_sales f ON f.transaction_id = s.transaction_id
WHERE f.transaction_id IS NULL;
