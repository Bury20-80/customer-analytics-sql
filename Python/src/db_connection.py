"""
Połączenie do bazy Postgres (Contoso 100K) przez SQLAlchemy.

Wymaga pliku .env w folderze python/ (obok requirements.txt) z zawartością:

    DB_HOST=localhost
    DB_PORT=5432
    DB_NAME=contoso_100k
    DB_USER=postgres
    DB_PASSWORD=twoje_haslo

.env NIE trafia do repo — musi być w .gitignore.
"""

import os
from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from dotenv import load_dotenv

load_dotenv()

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "contoso_100k")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD")


def get_engine() -> Engine:
    """Zwraca skonfigurowany SQLAlchemy engine do bazy contoso_100k."""
    if DB_PASSWORD is None:
        raise ValueError(
            "Brak DB_PASSWORD. Sprawdź, czy plik .env istnieje w folderze python/ "
            "i zawiera poprawne dane logowania."
        )

    connection_string = (
        f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}"
        f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )
    return create_engine(connection_string)


def test_connection() -> None:
    """Szybki sanity check — czy połączenie działa i widać tabele."""
    engine = get_engine()
    with engine.connect() as conn:
        from sqlalchemy import text
        result = conn.execute(
            text(
                "SELECT table_name FROM information_schema.tables "
                "WHERE table_schema = 'public' ORDER BY table_name"
            )
        )
        tables = [row[0] for row in result]
        print("Połączenie OK. Tabele w schemacie public:")
        for t in tables:
            print(f"  - {t}")


if __name__ == "__main__":
    test_connection()
