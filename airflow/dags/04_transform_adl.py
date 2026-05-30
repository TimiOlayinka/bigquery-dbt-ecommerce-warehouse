"""
DAG 4: ADL (Analytical Data Layer)
Triggers Dataform workflow to build reporting marts (bi schema).
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
    dag_id="04_transform_adl",
    default_args=default_args,
    description="Analytical Data Layer: Reporting marts and aggregations via Dataform",
    schedule="@daily",
    start_date=datetime(2026, 5, 20),
    catchup=False,
    tags=["transform", "dataform", "adl"],
) as dag:

    wait_for_odl = ExternalTaskSensor(
        task_id="wait_for_odl",
        external_dag_id="03_transform_odl",
        external_task_id=None,
        timeout=600,
        poke_interval=30,
    )

    compile_adl = DataformCreateCompilationResultOperator(
        task_id="compile_adl",
        project_id=PROJECT_ID,
        region=REGION,
        repository_id=REPOSITORY_ID,
        compilation_result={
            "git_commitish": "main",
        },
    )

    run_adl = DataformCreateWorkflowInvocationOperator(
        task_id="run_adl",
        project_id=PROJECT_ID,
        region=REGION,
        repository_id=REPOSITORY_ID,
        workflow_invocation={
            "compilation_result": "{{ task_instance.xcom_pull('compile_adl')['name'] }}",
            "invocation_config": {
                "included_tags": ["adl"],
                "transitive_dependencies_included": True,
            },
        },
    )

    wait_for_odl >> compile_adl >> run_adl
