"""
load_to_sql.py
Loads the cleaned dataset into a SQL database (Postgres, MySQL, or SQL Server).
Credentials are read from environment variables — never hardcode passwords in scripts
you plan to put on GitHub.

Usage:
    python load_to_sql.py --db postgres
    python load_to_sql.py --db mysql
    python load_to_sql.py --db mssql

Set your credentials first (see .env.example), e.g. on macOS/Linux:
    export DB_USER=postgres
    export DB_PASSWORD=your_password
"""

import argparse
import os

import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.engine import URL

CLEANED_DATA_PATH = "customer_shopping_behavior_cleaned.csv"
TABLE_NAME = "customer"


def get_engine(db_type: str):
    """Build a SQLAlchemy engine for the requested database type."""
    host = os.getenv("DB_HOST", "localhost")
    database = os.getenv("DB_NAME", "customer_behavior")
    username = os.getenv("DB_USER")
    password = os.getenv("DB_PASSWORD")

    if not username or not password:
        raise ValueError(
            "Set DB_USER and DB_PASSWORD environment variables before running this script."
        )

    if db_type == "postgres":
        port = os.getenv("DB_PORT", "5432")
        return create_engine(URL.create(
            "postgresql+psycopg2", username=username, password=password,
            host=host, port=int(port), database=database,
        ))

    if db_type == "mysql":
        port = os.getenv("DB_PORT", "3306")
        return create_engine(URL.create(
            "mysql+pymysql", username=username, password=password,
            host=host, port=int(port), database=database,
        ))

    if db_type == "mssql":
        port = os.getenv("DB_PORT", "1433")
        driver = os.getenv("DB_DRIVER", "ODBC Driver 17 for SQL Server")
        return create_engine(URL.create(
            "mssql+pyodbc", username=username, password=password,
            host=host, port=int(port), database=database,
            query={"driver": driver},
        ))

    raise ValueError(f"Unsupported db type: {db_type}")


def load_to_sql(db_type: str, csv_path: str = CLEANED_DATA_PATH, table_name: str = TABLE_NAME):
    """Load a CSV into the specified database and print a sample back."""
    df = pd.read_csv(csv_path)
    engine = get_engine(db_type)

    df.to_sql(table_name, engine, if_exists="replace", index=False)
    print(f"Loaded {len(df)} rows into '{table_name}' table on {db_type}.")

    sample = pd.read_sql(f"SELECT * FROM {table_name} LIMIT 5;", engine)
    print(sample)
    return sample


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Load cleaned data into a SQL database.")
    parser.add_argument(
        "--db",
        choices=["postgres", "mysql", "mssql"],
        required=True,
        help="Which database to load into.",
    )
    args = parser.parse_args()
    load_to_sql(args.db)
