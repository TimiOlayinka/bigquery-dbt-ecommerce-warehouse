"""
DAG 2: GCS to BigQuery RDL Load
Loads raw JSONL data from GCS staging into BigQuery history tables.
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
from airflow.sensors.external_task import ExternalTaskSensor
from airflow.utils.task_group import TaskGroup

default_args = {
    "owner": "timi.olayinka",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}

PROJECT_ID = "bellosdata"
GCS_BUCKET = "boohoo-rdl-staging-bellosdata"
BQ_DATASET = "boohoo_dwh"

# Define the sources, brands, and datasets
ECOMMERCE_MAPPING = [
    ("boohoo_commerce", "boohoo", ["customers", "orders", "products"]),
    ("boohoo_commerce", "boohoo_man", ["customers", "orders", "products"]),
    ("salesforce_commerce", "prettylittlething", ["customers", "orders", "products"]),
    ("shopify", "nastygal", ["customers", "orders", "products"]),
    ("magento", "karen_millen", ["customers", "orders", "products"]),
    ("magento", "coast", ["customers", "orders", "products"]),
    ("oracle_commerce", "debenhams", ["customers", "orders", "products"]),
]

MARKETING_MAPPING = [
    ("marketing", brand, ["meta_ads", "google_ads", "tiktok_ads", "ga4_sessions", "email_campaigns", "influencers"])
    for brand in ["boohoo", "boohoo_man", "prettylittlething", "nastygal", "karen_millen", "coast", "debenhams"]
]

with DAG(
    dag_id="02_transform_rdl",
    default_args=default_args,
    description="Raw Data Layer: Load GCS JSONL into BigQuery history tables",
    schedule="@daily",
    start_date=datetime(2026, 5, 20),
    catchup=False,
    tags=["load", "gcs", "bigquery", "rdl"],
) as dag:

    wait_for_ingestion = ExternalTaskSensor(
        task_id="wait_for_ingestion",
        external_dag_id="01_ingestion",
        external_task_id=None,
        timeout=600,
        poke_interval=30,
    )

    with TaskGroup("load_ecommerce") as load_ecommerce:
        for source, brand, datasets in ECOMMERCE_MAPPING:
            for dataset in datasets:
                # BigQuery table name mapping (e.g. boohoo_customers_history)
                # Map brand names to match the dbt model expectations
                bq_brand = brand
                if brand == "boohoo":
                    bq_brand = "boohoo"
                elif brand == "boohoo_man":
                    bq_brand = "boohoo_man"
                elif brand == "prettylittlething":
                    bq_brand = "plt"
                
                table_name = f"{bq_brand}_{dataset}_history"
                
                GCSToBigQueryOperator(
                    task_id=f"load_{bq_brand}_{dataset}",
                    bucket=GCS_BUCKET,
                    source_objects=[f"raw/{source}/{brand}/{dataset}/ingest_date={{{{ ds }}}}/{dataset}.jsonl.gz"],
                    destination_project_dataset_table=f"{PROJECT_ID}.{BQ_DATASET}.{table_name}",
                    source_format="NEWLINE_DELIMITED_JSON",
                    write_disposition="WRITE_APPEND",
                    create_disposition="CREATE_IF_NEEDED",
                    autodetect=True,
                    ignore_unknown_values=True,
                )

    with TaskGroup("load_marketing") as load_marketing:
        for source, brand, datasets in MARKETING_MAPPING:
            for dataset in datasets:
                bq_brand = brand
                if brand == "boohoo":
                    bq_brand = "boohoo"
                elif brand == "boohoo_man":
                    bq_brand = "boohoo_man"
                elif brand == "prettylittlething":
                    bq_brand = "plt"
                
                table_name = f"{bq_brand}_{dataset}_history"
                
                GCSToBigQueryOperator(
                    task_id=f"load_{bq_brand}_{dataset}",
                    bucket=GCS_BUCKET,
                    source_objects=[f"raw/{source}/{brand}/{dataset}/ingest_date={{{{ ds }}}}/{dataset}.jsonl.gz"],
                    destination_project_dataset_table=f"{PROJECT_ID}.{BQ_DATASET}.{table_name}",
                    source_format="NEWLINE_DELIMITED_JSON",
                    write_disposition="WRITE_APPEND",
                    create_disposition="CREATE_IF_NEEDED",
                    autodetect=True,
                    ignore_unknown_values=True,
                )

    from airflow.operators.bash import BashOperator
    DBT_DIR = "/opt/boohoo-repo/dbt"

    dbt_run_rdl = BashOperator(
        task_id="dbt_run_rdl",
        bash_command=f"cd {DBT_DIR} && dbt deps && dbt run --select tag:rdl --profiles-dir .",
    )

    wait_for_ingestion >> load_ecommerce >> load_marketing >> dbt_run_rdl
