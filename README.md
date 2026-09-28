# Retail Sales Data Warehouse

A three-layer **PostgreSQL data warehouse** for ~1M retail sales transactions. Follows the classic **raw &rarr; staging &rarr; warehouse** ETL pattern with a **star schema** (1 fact + 4 dimensions), deduplication, and idempotent incremental loads.

## Description

Raw transactions land in `raw.transactions_raw` via `COPY`. A staging step deduplicates them (`ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY loaded_at DESC)`), normalizes types, and computes `net_amount`. Warehouse loaders upsert dimensions, then insert only new fact rows so re-runs never double-count. Analytical queries produce monthly revenue with MoM growth, product rankings, store performance, and customer cohort retention.

## Features

- **Three-layer architecture**: `raw` &rarr; `staging` &rarr; `warehouse` schemas keep concerns separate
- **Star schema**: `fact_sales` + `dim_date`, `dim_customer`, `dim_product`, `dim_store`
- **Deduplication** via window functions in the raw &rarr; staging step
- **Incremental loads** on `fact_sales` &mdash; safe to re-run without duplicates
- **Idempotent dimension upserts** with `ON CONFLICT DO UPDATE`
- Synthetic data generator (default 100K rows, scale to 1M with `--rows 1000000`)
- Analytical SQL: MoM revenue growth, top products, store rankings, cohort retention

## Tech Stack

- **Database:** PostgreSQL 14+
- **Language:** Python 3.10+ (data generator + ETL runner)
- **Libraries:** SQLAlchemy, psycopg2-binary

## Installation

1. Clone:
   ```bash
   git clone https://github.com/Tanushreep698/Retail-Sales-Data-Warehouse.git
   cd Retail-Sales-Data-Warehouse
   ```

2. Virtual env + deps:
   ```bash
   python -m venv venv
   source venv/bin/activate           # Linux / macOS
   venv\Scripts\activate              # Windows
   pip install -r requirements.txt
   ```

3. Create the database:
   ```bash
   createdb retail_dw
   ```
   (or use `psql`: `CREATE DATABASE retail_dw;`)

4. DB credentials:
   ```bash
   cp .env.example .env
   ```

5. Create all three layers:
   ```bash
   psql retail_dw -f sql/01_raw_schema.sql
   psql retail_dw -f sql/02_staging_schema.sql
   psql retail_dw -f sql/03_warehouse_star_schema.sql
   ```

## How to Run

**1. Generate sample data** (100K default; use `--rows 1000000` for the full million):
```bash
python -m src.generate_sample_data --rows 100000
```

**2. Load into `raw`:**
```bash
python -m src.load_raw
```

**3. Run the ETL** (raw &rarr; staging &rarr; warehouse):
```bash
python -m src.run_etl
```

**4. Run the analytics:**
```bash
psql retail_dw -f sql/06_analytics.sql
```

## Star Schema

See [`docs/star_schema.md`](docs/star_schema.md) for the diagram and design notes.

- `fact_sales` &mdash; grain = one line item on a transaction, includes measures (`quantity`, `unit_price`, `discount_pct`, `gross_amount`, `net_amount`)
- `dim_date`, `dim_customer`, `dim_product`, `dim_store` &mdash; conformed dimensions with surrogate keys

## Screenshots

_Add screenshots after running:_
- `docs/schema-diagram.png` &mdash; ER diagram
- `docs/analytics-results.png` &mdash; sample query output

## Project Structure

```
retail-sales-warehouse/
├── src/
│   ├── db.py                     # SQLAlchemy engine factory
│   ├── generate_sample_data.py   # synthetic transactions
│   ├── load_raw.py               # CSV -> raw.transactions_raw
│   └── run_etl.py                # raw -> staging -> warehouse
├── sql/
│   ├── 01_raw_schema.sql
│   ├── 02_staging_schema.sql
│   ├── 03_warehouse_star_schema.sql
│   ├── 04_etl_raw_to_staging.sql
│   ├── 05_etl_staging_to_warehouse.sql
│   └── 06_analytics.sql
├── docs/star_schema.md
├── data/                         # generated (gitignored)
├── requirements.txt
└── .env.example
```

## License

MIT
