# Databricks notebook source
# MAGIC %pip install snowflake-connector-python pandas pyarrow

# COMMAND ----------

dbutils.library.restartPython()

# COMMAND ----------

# ============================================================
# Notebook : 01_raw_ingest_and_load
# Project  : Snowflake Supply Chain Analytics
# Author   : Sameer Nayak
# Layer    : Bronze (raw as-landed)
# ============================================================

import pandas as pd
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas
from pyspark.sql import functions as F
from datetime import datetime

print(f"Run timestamp: {datetime.now()}")
print("All imports successful.")

# COMMAND ----------

SNOWFLAKE_CONFIG = {
    "account"  : "Your Account",
    "user"     : "Your UserName",
    "password" : "Your Password",
    "database" : "SUPPLY_CHAIN_DB",
    "schema"   : "BRONZE",
    "warehouse": "TRANSFORM_WH",
    "role"     : "ACCOUNTADMIN",
}

print(f"Target: {SNOWFLAKE_CONFIG['database']}.{SNOWFLAKE_CONFIG['schema']}")

# COMMAND ----------

BASE_PATH = "/Volumes/snowflake-supply-chain-analytics/raw_source/raw_source_volume/"

source_map = {
    "RAW_ORDERS"          : f"{BASE_PATH}olist_orders_dataset.csv",
    "RAW_CUSTOMERS"       : f"{BASE_PATH}olist_customers_dataset.csv",
    "RAW_ORDER_ITEMS"     : f"{BASE_PATH}olist_order_items_dataset.csv",
    "RAW_PRODUCTS"        : f"{BASE_PATH}olist_products_dataset.csv",
    "RAW_SELLERS"         : f"{BASE_PATH}olist_sellers_dataset.csv",
    "RAW_PAYMENTS"        : f"{BASE_PATH}olist_order_payments_dataset.csv",
    "RAW_REVIEWS"         : f"{BASE_PATH}olist_order_reviews_dataset.csv",
    "RAW_GEOLOCATION"     : f"{BASE_PATH}olist_geolocation_dataset.csv",
    "RAW_CATEGORY_TRANSLATION" : f"{BASE_PATH}product_category_name_translation.csv",
}

print("Base path:", BASE_PATH)
print(f"Sources defined ({len(source_map)}):", list(source_map.keys()))

# COMMAND ----------

spark_dataframes = {}
validation_report = []

for table_name, path in source_map.items():
    print(f"\nReading: {table_name}")

    # Read CSV directly from Databricks Volume using Spark
    df = spark.read.format("csv") \
        .option("header", "true") \
        .option("inferSchema", "true") \
        .option("mode", "PERMISSIVE") \
        .load(path)

    # Add metadata columns — standard Bronze layer practice
    df = df \
        .withColumn("_ingested_at",   F.lit(datetime.now().isoformat())) \
        .withColumn("_source_file",   F.lit(path)) \
        .withColumn("_pipeline_name", F.lit("databricks_serverless_olist_v1"))

    row_count = df.count()
    spark_dataframes[table_name] = df

    validation_report.append({
        "table"  : table_name,
        "rows"   : row_count,
        "columns": len(df.columns),
    })
    print(f"  Rows: {row_count:,}  |  Columns: {len(df.columns)}")

# COMMAND ----------

print("\n" + "="*55)
print("  VALIDATION SUMMARY")
print("="*55)
print(f"  {'Table':<30} {'Rows':>10}   Cols")
print("-"*55)

for r in validation_report:
    print(f"  {r['table']:<30} {r['rows']:>10,}   {r['columns']}")

print("="*55)
print(f"\n  Total tables : {len(validation_report)}")
total_rows = sum(r['rows'] for r in validation_report)
print(f"  Total rows   : {total_rows:,}")
print("\n  All files read successfully. Ready to load to Snowflake Bronze.")

# COMMAND ----------

load_results = []

conn = snowflake.connector.connect(**SNOWFLAKE_CONFIG)
print(f"Connected to Snowflake ✓")
print(f"Target: {SNOWFLAKE_CONFIG['database']}.{SNOWFLAKE_CONFIG['schema']}\n")

for table_name, spark_df in spark_dataframes.items():
    print(f"Loading → BRONZE.{table_name} ...")

    try:
        # Spark → pandas
        pdf = spark_df.toPandas()

        # ✅ FIX: Strip Spark's internal PlanMetrics metadata that causes
        # JSON serialization errors in snowflake-connector-python >= 3.6.0
        pdf = pd.DataFrame(pdf.to_dict(orient="records"))

        # Uppercase columns (Snowflake convention)
        pdf.columns = [c.upper() for c in pdf.columns]

        success, n_chunks, n_rows, _ = write_pandas(
            conn              = conn,
            df                = pdf,
            table_name        = table_name,
            database          = SNOWFLAKE_CONFIG["database"],
            schema            = SNOWFLAKE_CONFIG["schema"],
            auto_create_table = True,
            overwrite         = True,
        )

        load_results.append({"table": table_name, "rows": n_rows, "status": "SUCCESS"})
        print(f"  ✓ {n_rows:,} rows loaded")

    except Exception as e:
        load_results.append({"table": table_name, "rows": 0, "status": f"FAILED: {e}"})
        print(f"  ✗ FAILED: {e}")

conn.close()
print("\nConnection closed.")