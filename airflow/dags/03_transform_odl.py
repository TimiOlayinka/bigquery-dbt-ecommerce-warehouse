"""
DAG 3: ODL (Operational Data Layer)
Triggers Dataform workflow to build conforming dimensions and facts (odl schema).
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.google.cloud.operators.dataform import (
    DataformCreateCompilationResultOperator,
    DataformCreateWorkflowInvocationOperator,
)
from airflow.sensors.external_task import ExternalTaskSensor

default_args = {
    "owner": "timi.olayinka",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=3),
}

PROJECT_ID = "bellosdata"
REGION = "europe-west2"
REPOSITORY_ID = "boohoo-dataform"

with DAG(
    dag_id="03_transform_odl",
    default_args=default_args,
    description="Operational Data Layer: Conformed dimensions and facts via Dataform",
    schedule="@daily",
    start_date=datetime(2026, 5, 20),
    catchup=False,
    tags=["transform", "dataform", "odl"],
) as dag:

    wait_for_rdl = ExternalTaskSensor(
        task_id="wait_for_rdl",
        external_dag_id="02_transform_rdl",
        external_task_id=None,
        timeout=600,
        poke_interval=30,
    )

    compile_odl = DataformCreateCompilationResultOperator(
        task_id="compile_odl",
        project_id=PROJECT_ID,
        region=REGION,
        repository_id=REPOSITORY_ID,
        compilation_result={
            "git_commitish": "main",
        },
    )

    run_odl = DataformCreateWorkflowInvocationOperator(
        task_id="run_odl",
        project_id=PROJECT_ID,
        region=REGION,
        repository_id=REPOSITORY_ID,
        workflow_invocation={
            "compilation_result": "{{ task_instance.xcom_pull('compile_odl')['name'] }}",
            "invocation_config": {
                "included_tags": ["odl"],
                "transitive_dependencies_included": True,
            },
        },
    )

    wait_for_rdl >> compile_odl >> run_odl
