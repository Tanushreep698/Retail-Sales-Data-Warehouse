-- Raw -> Staging: dedupe on transaction_id (keep newest by loaded_at),
-- drop bad rows, compute net_amount.

TRUNCATE staging.transactions_stg;

INSERT INTO staging.transactions_stg (
    transaction_id, transaction_date,
    store_id, store_name, city,
    customer_id, customer_email, region,
    product_id, sku, category,
    quantity, unit_price, discount_pct, net_amount
)
SELECT
    r.transaction_id,
    r.transaction_date,
    r.store_id, r.store_name, r.city,
    r.customer_id, r.customer_email, r.region,
    r.product_id, r.sku, r.category,
    r.quantity, r.unit_price, COALESCE(r.discount_pct, 0),
    ROUND(r.quantity * r.unit_price * (1 - COALESCE(r.discount_pct, 0) / 100.0), 2)
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY transaction_id
            ORDER BY loaded_at DESC
        ) AS rn
    FROM raw.transactions_raw
    WHERE transaction_id IS NOT NULL
      AND transaction_date IS NOT NULL
      AND quantity > 0
      AND unit_price >= 0
) r
WHERE r.rn = 1;
