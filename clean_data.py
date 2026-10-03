"""
clean_data.py
Cleans and transforms the customer shopping behavior dataset.
Run this script to produce a cleaned CSV ready for SQL loading and analysis.
"""

import pandas as pd

INPUT_PATH = "customer_shopping_behavior.csv"
OUTPUT_PATH = "customer_shopping_behavior_cleaned.csv"


def load_data(path: str) -> pd.DataFrame:
    """Load the raw CSV into a DataFrame."""
    return pd.read_csv(path)


def clean_columns(df: pd.DataFrame) -> pd.DataFrame:
    """Standardize column names to snake_case."""
    df.columns = df.columns.str.lower().str.replace(" ", "_")
    df = df.rename(columns={"purchase_amount_(usd)": "purchase_amount"})
    return df


def fill_missing_ratings(df: pd.DataFrame) -> pd.DataFrame:
    """Fill missing review ratings with the median rating per category."""
    df["review_rating"] = df.groupby("category")["review_rating"].transform(
        lambda x: x.fillna(x.median())
    )
    return df


def add_age_group(df: pd.DataFrame) -> pd.DataFrame:
    """Bucket customers into age groups using quartiles."""
    labels = ["Young Adult", "Adult", "Middle-aged", "Senior"]
    df["age_group"] = pd.qcut(df["age"], q=4, labels=labels)
    return df


def add_purchase_frequency_days(df: pd.DataFrame) -> pd.DataFrame:
    """Convert purchase frequency labels into an approximate number of days."""
    frequency_mapping = {
        "Fortnightly": 14,
        "Weekly": 7,
        "Monthly": 30,
        "Quarterly": 90,
        "Bi-Weekly": 14,
        "Annually": 365,
        "Every 3 Months": 90,
    }
    df["purchase_frequency_days"] = df["frequency_of_purchases"].map(frequency_mapping)
    return df


def drop_redundant_columns(df: pd.DataFrame) -> pd.DataFrame:
    """Drop promo_code_used since it's identical to discount_applied."""
    if "promo_code_used" in df.columns and "discount_applied" in df.columns:
        if (df["discount_applied"] == df["promo_code_used"]).all():
            df = df.drop(columns=["promo_code_used"])
    return df


def clean_pipeline(input_path: str = INPUT_PATH, output_path: str = OUTPUT_PATH) -> pd.DataFrame:
    """Run the full cleaning pipeline and save the result."""
    df = load_data(input_path)
    df = clean_columns(df)
    df = fill_missing_ratings(df)
    df = add_age_group(df)
    df = add_purchase_frequency_days(df)
    df = drop_redundant_columns(df)

    df.to_csv(output_path, index=False)
    print(f"Cleaned data saved to {output_path}")
    print(f"Rows: {len(df)}, Columns: {len(df.columns)}")
    return df


if __name__ == "__main__":
    clean_pipeline()
