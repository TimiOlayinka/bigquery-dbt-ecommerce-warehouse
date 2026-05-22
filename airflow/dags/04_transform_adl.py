"""
DAG 4: ADL (Analytical Data Layer)
Runs dbt models tagged with 'adl' to build reporting marts.
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.sensors.external_task import ExternalTaskSensor

default_args = {
    "owner": "timi.olayinka",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=3),
}

DBT_DIR = "/opt/boohoo-repo/dbt"

with DAG(
    dag_id="04_transform_adl",
    default_args=default_args,
    description="Analytical Data Layer: Reporting marts and aggregations",
    schedule="@daily",
    start_date=datetime(2026, 5, 20),
    catchup=False,
    tags=["transform", "dbt", "adl"],
) as dag:

    wait_for_odl = ExternalTaskSensor(
        task_id="wait_for_odl",
        external_dag_id="03_transform_odl",
        external_task_id=None,
        timeout=600,
        poke_interval=30,
    )

    dbt_run_adl = BashOperator(
        task_id="dbt_run_adl",
        bash_command=f"cd {DBT_DIR} && dbt deps && dbt run --select tag:adl --profiles-dir .",
    )

    wait_for_odl >> dbt_run_adl
