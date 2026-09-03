from pathlib import Path

import pandas as pd
from sqlalchemy import text

PROJECT_ROOT = Path(__file__).resolve().parents[2]
SQL_ROOT = PROJECT_ROOT / "sql"


def load_sql(relative_path: str) -> str:
    """Read a SQL file from the project's sql/ directory."""
    path = SQL_ROOT / relative_path
    if not path.exists():
        raise FileNotFoundError(f"SQL file not found: {path}")
    return path.read_text(encoding="utf-8")


def read_sql_file(engine, relative_path: str) -> pd.DataFrame:
    """Execute a SELECT query stored in a project SQL file and return a DataFrame."""
    return pd.read_sql_query(text(load_sql(relative_path)), engine)
