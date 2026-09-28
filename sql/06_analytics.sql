-- Analytical queries on the warehouse.

-- Monthly revenue with month-over-month growth
WITH monthly AS (
    SELECT
        d.year,
        d.month,
        SUM(f.net_amount) AS revenue,
        COUNT(*)          AS orders
    FROM warehouse.fact_sales f
    JOIN warehouse.dim_date d ON d.date_key = f.date_key
    GROUP BY d.year, d.month
)
SELECT
    year, month, revenue, orders,
    LAG(revenue) OVER (ORDER BY year, month) AS prev_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY year, month))
        / NULLIF(LAG(revenue) OVER (ORDER BY year, month), 0) * 100, 2
    ) AS mom_growth_pct
FROM monthly
ORDER BY year, month;

-- Top 10 products by net revenue
SELECT
    p.sku, p.category,
    SUM(f.net_amount) AS revenue,
    SUM(f.quantity)   AS units_sold,
    RANK() OVER (ORDER BY SUM(f.net_amount) DESC) AS rev_rank
FROM warehouse.fact_sales f
JOIN warehouse.dim_product p ON p.product_key = f.product_key
GROUP BY p.sku, p.category
ORDER BY revenue DESC
LIMIT 10;

-- Store performance
SELECT
    s.store_name, s.city,
    COUNT(DISTINCT f.transaction_id) AS orders,
    ROUND(SUM(f.net_amount), 2) AS revenue,
    ROUND(SUM(f.net_amount) / COUNT(DISTINCT f.transaction_id), 2) AS aov
FROM warehouse.fact_sales f
JOIN warehouse.dim_store s ON s.store_key = f.store_key
GROUP BY s.store_name, s.city
ORDER BY revenue DESC;

-- Customer cohort retention (cohort = month of first purchase)
WITH first_purchase AS (
    SELECT
        f.customer_key,
        DATE_TRUNC('month', MIN(d.full_date)) AS cohort_month
    FROM warehouse.fact_sales f
    JOIN warehouse.dim_date d ON d.date_key = f.date_key
    GROUP BY f.customer_key
),
purchases AS (
    SELECT
        f.customer_key,
        DATE_TRUNC('month', d.full_date) AS purchase_month
    FROM warehouse.fact_sales f
    JOIN warehouse.dim_date d ON d.date_key = f.date_key
    GROUP BY f.customer_key, DATE_TRUNC('month', d.full_date)
)
SELECT
    fp.cohort_month,
    (EXTRACT(YEAR FROM p.purchase_month) - EXTRACT(YEAR FROM fp.cohort_month)) * 12
      + (EXTRACT(MONTH FROM p.purchase_month) - EXTRACT(MONTH FROM fp.cohort_month)) AS month_number,
    COUNT(DISTINCT p.customer_key) AS active_customers
FROM first_purchase fp
JOIN purchases p ON p.customer_key = fp.customer_key
GROUP BY fp.cohort_month, month_number
ORDER BY fp.cohort_month, month_number;
