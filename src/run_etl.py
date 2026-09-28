"""Run the full ETL: raw -> staging -> warehouse."""

from __future__ import annotations

from pathlib import Path

from sqlalchemy import text

from .db import BASE_DIR, make_engine

SQL_DIR = BASE_DIR / "sql"
STEPS = [
    "04_etl_raw_to_staging.sql",
    "05_etl_staging_to_warehouse.sql",
]


def main() -> None:
    engine = make_engine()
    for step in STEPS:
        path = SQL_DIR / step
        sql = path.read_text(encoding="utf-8")
        print(f"\n>>> Running {step}")
        with engine.begin() as conn:
            conn.execute(text(sql))
        print(f"    Done: {step}")


if __name__ == "__main__":
    main()
