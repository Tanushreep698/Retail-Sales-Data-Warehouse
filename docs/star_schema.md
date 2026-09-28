# Star Schema

```
                     +-------------------+
                     |   dim_date        |
                     |-------------------|
                     | date_key (PK)     |
                     | full_date         |
                     | year / quarter    |
                     | month / weekday   |
                     +---------+---------+
                               |
+-----------------+   +--------+--------+   +-----------------+
|  dim_customer   |   |   fact_sales    |   |  dim_product    |
|-----------------|   |-----------------|   |-----------------|
| customer_key(PK)|<--| customer_key    |   | product_key (PK)|
| customer_id     |   | product_key     |-->| product_id      |
| region          |   | store_key       |   | sku / category  |
+-----------------+   | date_key        |   +-----------------+
                      | quantity        |
                      | unit_price      |
                      | discount_pct    |   +-----------------+
                      | gross_amount    |   |  dim_store      |
                      | net_amount      |   |-----------------|
                      +--------+--------+-->| store_key (PK)  |
                               |            | store_id        |
                               |            | store_name/city |
                               +----------->+-----------------+
```

## Grain

One row in `fact_sales` = one line item on a customer transaction.

## Design Choices

- **Surrogate keys** (`*_key`) on every dimension so natural keys can change without breaking history.
- **Date dimension** is populated from staging so only months with data get generated (keeps the dim tight for smaller demos).
- **Incremental load** on `fact_sales`: a `LEFT JOIN` on `transaction_id` skips rows already in the warehouse, so re-running the ETL never double-counts.
- **Deduplication** happens in the raw &rarr; staging step via `ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY loaded_at DESC)`.
- **Currency & discount** normalized: `net_amount = quantity * unit_price * (1 - discount_pct/100)`.
