"""
DAG 1: Ingestion Layer
Triggers all 9 Cloud Run micro-services to generate synthetic data into GCS.
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.google.cloud.operators.cloud_run import CloudRunExecuteJobOperator
from airflow.utils.task_group import TaskGroup

default_args = {
    "owner": "timi.olayinka",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}

PROJECT_ID = "bellosdata"
REGION = "europe-west2"

ECOMMERCE_JOBS = [
    "omnistyle-ecommerce-customers",
    "omnistyle-ecommerce-orders",
    "omnistyle-ecommerce-products",
]

MARKETING_JOBS = [
    "omnistyle-marketing-meta-ads",
    "omnistyle-marketing-google-ads",
    "omnistyle-marketing-tiktok-ads",
    "omnistyle-marketing-ga4-sessions",
    "omnistyle-marketing-email-campaigns",
    "omnistyle-marketing-influencers",
]

with DAG(
    dag_id="01_ingestion",
    default_args=default_args,
    description="Generate synthetic data across 9 Cloud Run micro-services into GCS",
    schedule="@daily",
    start_date=datetime(2026, 5, 20),
    catchup=False,
    tags=["ingestion", "cloud-run", "gcs"],
) as dag:

    with TaskGroup("ecommerce_data") as ecommerce_group:
        for job_name in ECOMMERCE_JOBS:
            CloudRunExecuteJobOperator(
                task_id=f"generate_{job_name.replace('omnistyle-', '').replace('-', '_')}",
                project_id=PROJECT_ID,
                region=REGION,
                job_name=job_name,
                deferrable=False,
            )

    with TaskGroup("marketing_data") as marketing_group:
        for job_name in MARKETING_JOBS:
            CloudRunExecuteJobOperator(
                task_id=f"generate_{job_name.replace('omnistyle-', '').replace('-', '_')}",
                project_id=PROJECT_ID,
                region=REGION,
                job_name=job_name,
                deferrable=False,
            )

    # Ecommerce and Marketing run in parallel
    [ecommerce_group, marketing_group]
