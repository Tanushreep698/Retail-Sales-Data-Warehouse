"""Generate ~1M synthetic retail transactions as a CSV.

The number of rows is configurable; default is 100K for git-friendliness.
For a full 1M run: python -m src.generate_sample_data --rows 1000000
"""

from __future__ import annotations

import argparse
import csv
import random
from datetime import date, timedelta
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
DATA_DIR.mkdir(parents=True, exist_ok=True)

random.seed(2026)

STORES = [(i, f"Store-{i:03d}", random.choice(["Bengaluru", "Mumbai", "Delhi", "Chennai", "Hyderabad"]))
          for i in range(1, 51)]
PRODUCTS = [
    (i, f"SKU-{i:05d}",
     random.choice(["Electronics", "Grocery", "Apparel", "Home", "Beauty", "Sports"]),
     round(random.uniform(50, 5000), 2))
    for i in range(1, 501)
]
CUSTOMERS = [
    (i,
     f"cust_{i}@example.com",
     random.choice(["North", "South", "East", "West"]),
     (date(2022, 1, 1) + timedelta(days=random.randint(0, 1000))).isoformat())
    for i in range(1, 20_001)
]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rows", type=int, default=100_000)
    parser.add_argument("--out", default=str(DATA_DIR / "raw_transactions.csv"))
    args = parser.parse_args()

    start = date(2024, 1, 1)
    days = 640

    dup_every = 200  # ~0.5% duplicates
    with open(args.out, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow([
            "transaction_id", "transaction_date",
            "store_id", "store_name", "city",
            "customer_id", "customer_email", "region",
            "product_id", "sku", "category",
            "quantity", "unit_price", "discount_pct",
        ])
        for i in range(args.rows):
            store = random.choice(STORES)
            prod = random.choice(PRODUCTS)
            cust = random.choice(CUSTOMERS)
            row = [
                100_000_000 + i,
                (start + timedelta(days=random.randint(0, days))).isoformat(),
                store[0], store[1], store[2],
                cust[0], cust[1], cust[2],
                prod[0], prod[1], prod[2],
                random.randint(1, 5),
                prod[3],
                random.choice([0, 0, 0, 5, 10, 15, 20]),
            ]
            w.writerow(row)
            if i % dup_every == 0 and i > 0:
                w.writerow(row)

    print(f"Wrote {args.out} ({args.rows:,} rows + duplicates)")


if __name__ == "__main__":
    main()
