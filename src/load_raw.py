"""COPY the raw CSV into the raw.transactions_raw table."""

from __future__ import annotations

from pathlib import Path

from sqlalchemy import text

from .db import BASE_DIR, make_engine

CSV = BASE_DIR / "data" / "raw_transactions.csv"


def main() -> None:
    if not CSV.exists():
        raise FileNotFoundError(
            f"{CSV} not found. Run: python -m src.generate_sample_data"
        )

    engine = make_engine()
    with engine.begin() as conn:
        conn.execute(text("TRUNCATE raw.transactions_raw"))
        raw_conn = conn.connection
        cur = raw_conn.cursor()
        with CSV.open("r", encoding="utf-8") as f:
            cur.copy_expert(
                "COPY raw.transactions_raw FROM STDIN WITH (FORMAT CSV, HEADER TRUE)",
                f,
            )
        n = cur.rowcount
    print(f"COPY-loaded {n:,} rows into raw.transactions_raw")


if __name__ == "__main__":
    main()
