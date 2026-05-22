"""
DAG 3: ODL (Operational Data Layer)
Runs dbt models tagged with 'odl' to build conforming dimensions and facts.
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
    dag_id="03_transform_odl",
    default_args=default_args,
    description="Operational Data Layer: Conformed dimensions and facts",
    schedule_interval="@daily",
    start_date=datetime(2026, 5, 20),
    catchup=False,
    tags=["transform", "dbt", "odl"],
) as dag:

    wait_for_rdl = ExternalTaskSensor(
        task_id="wait_for_rdl",
        external_dag_id="02_transform_rdl",
        external_task_id=None,
        timeout=600,
        poke_interval=30,
    )

    dbt_run_odl = BashOperator(
        task_id="dbt_run_odl",
        bash_command=f"cd {DBT_DIR} && dbt deps && dbt run --select tag:odl --profiles-dir .",
    )

    wait_for_rdl >> dbt_run_odl
