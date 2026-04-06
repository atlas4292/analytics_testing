import dagster as dg
from dagster_duckdb import DuckDBResource
from pathlib import Path


@dg.asset
def customers() -> str:
    return "https://raw.githubusercontent.com/dbt-labs/jaffle-shop-classic/refs/heads/main/seeds/raw_customers.csv"


@dg.asset
def orders() -> str:
    return "https://raw.githubusercontent.com/dbt-labs/jaffle-shop-classic/refs/heads/main/seeds/raw_orders.csv"


@dg.asset
def payments() -> str:
    return "https://raw.githubusercontent.com/dbt-labs/jaffle-shop-classic/refs/heads/main/seeds/raw_payments.csv"


@dg.asset
def florida_real_estate(duckdb: DuckDBResource):
    path: str = str(Path(__file__).parent.parent / "data" / "florida_real_estate_sold_properties_ultimate.csv")
    table_name: str = "florida_real_estate"

    with duckdb.get_connection() as conn:
        conn.execute(
            f"""
            CREATE OR REPLACE TABLE {table_name} AS
            SELECT *
            FROM read_csv_auto('{path}')
            """
        )