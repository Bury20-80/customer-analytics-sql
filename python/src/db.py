from getpass import getpass
import os
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.engine import URL

PROJECT_ROOT = Path(__file__).resolve().parents[2]
load_dotenv(PROJECT_ROOT / ".env")


def get_engine():
    """Create a PostgreSQL SQLAlchemy engine without storing credentials in the repo."""
    password = os.getenv("DB_PASSWORD") or getpass("PostgreSQL password: ")
    url = URL.create(
        "postgresql+psycopg2",
        username=os.getenv("DB_USER", "postgres"),
        password=password,
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "5432")),
        database=os.getenv("DB_NAME", "contoso_100k"),
    )
    return create_engine(url)
