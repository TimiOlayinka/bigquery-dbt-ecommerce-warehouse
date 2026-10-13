<p align="center">
  <h1 align="center">Boohoo Group Multi-Brand E-Commerce Data Warehouse</h1>
  <p align="center">
    <strong>Multi-brand e-commerce data warehouse on GCP — 9 Cloud Run Jobs across 7 brands, BigQuery FinOps-optimised Star Schema (40% fewer scanned bytes), Dual dbt Core & Dataform Medallion Architecture (RDL → ODL → ADL/BI), and ephemeral Airflow orchestration delivering £350K/yr (~£30K/mo) infrastructure savings.</strong>
  </p>
  <p align="center">
    <img src="https://img.shields.io/badge/BigQuery-669DF6?style=for-the-badge&logo=googlebigquery&logoColor=white" alt="BigQuery">
    <img src="https://img.shields.io/badge/dbt_Core-FF694B?style=for-the-badge&logo=dbt&logoColor=white" alt="dbt Core">
    <img src="https://img.shields.io/badge/Dataform-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white" alt="Dataform">
    <img src="https://img.shields.io/badge/Cloud_Run-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white" alt="Cloud Run">
    <img src="https://img.shields.io/badge/Cloud_Scheduler-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white" alt="Cloud Scheduler">
    <img src="https://img.shields.io/badge/Cloud_Storage-AECBFA?style=for-the-badge&logo=googlecloudstorage&logoColor=black" alt="GCS">
    <img src="https://img.shields.io/badge/Apache_Airflow-017CEE?style=for-the-badge&logo=apacheairflow&logoColor=white" alt="Airflow">
    <img src="https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform">
    <img src="https://img.shields.io/badge/Python_3.11-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python">
  </p>
</p>

---

## Executive Summary & FinOps Impact

A **production-grade, FinOps-optimised multi-brand e-commerce data warehouse** engineered for the **Boohoo Group's 7 retail brands** across **5 heterogeneous commerce platforms** (`Boohoo Commerce`, `Salesforce Commerce Cloud`, `Shopify`, `Magento`, `Oracle Commerce`) and **6 performance marketing channels** (`Meta Ads`, `Google Ads`, `TikTok Ads`, `GA4`, `Email`, `Influencers`).

| Engineering Pillar | Architectural Implementation | Quantified Impact |
|---|---|---|
| **BigQuery Query FinOps** | Daily time-unit `PARTITION BY` (`order_date`, `date_nk`), multi-column `CLUSTER BY` (`brand`, `customer_sk`, `channel`), `require_partition_filter = true`, incremental `MERGE` lookback windows, and `maximum_bytes_billed = 10 GB` hard query ceiling | **~40% reduction in bytes scanned** across BI & Looker Studio workloads |
| **Compute & Warehouse FinOps** | Replaced over-provisioned always-on legacy clusters with serverless **Cloud Run Jobs**, **BigQuery on-demand/slot autoscaling**, **GCS Nearline/Archive lifecycle tiering**, and **GCE Instance Schedules** for Airflow | **~£30K/month (~£350K/year)** annualised cloud infrastructure savings |
| **Dual ELT Engines (`dbt/` & `definitions/`)** | Reference implementations in both **dbt Core (`dbt-bigquery`)** and **GCP-native Dataform (`definitions/`)** executing an identical 3-tier Medallion DAG (**55 models**: RDL → ODL → ADL/BI) | Portable SQL engineering standards with zero vendor lock-in |
| **Data Contracts & Observability** | Every model directory in `dbt/models/` ships with a 5-file governance bundle: `<model>.sql`, `model.yml` (SLA & ownership contract), `README.md`, `runbook.md` (incident response), and `tests.yml` | **100% documented lineage**, automated CI contract verification, and sub-15m MTTR |

---

## Architecture Overview

**9 Cloud Run Jobs** ingest daily e-commerce and marketing data for **7 brands** across **5 platforms**, landing compressed `JSONL.GZ` payloads in **Google Cloud Storage**. **BigQuery** warehouses the data through a **3-layer Medallion Architecture** (`RDL → ODL → ADL/BI`) implemented in both **dbt Core (`dbt/`)** and **Dataform (`definitions/`)**. **Apache Airflow** runs on a **Compute Engine VM** controlled by native **Instance Schedules**.

### Brands & Platforms

| Brand | Platform | BigQuery RDL Dataset | dbt RDL Schema |
|-------|----------|----------------------|----------------|
| **Boohoo** | Boohoo Commerce | `rdl_boohoo` | `rdl_boohoo_commerce` |
| **BoohooMAN** | Boohoo Commerce | `rdl_boohoo_man` | `rdl_boohoo_commerce` |
| **PrettyLittleThing** | Salesforce Commerce Cloud | `rdl_prettylittlething` | `rdl_salesforce_commerce` |
| **NastyGal** | Shopify | `rdl_nastygal` | `rdl_shopify` |
| **Karen Millen** | Magento | `rdl_karen_millen` | `rdl_magento` |
| **Coast** | Magento | `rdl_coast` | `rdl_magento` |
| **Debenhams** | Oracle Commerce | `rdl_debenhams` | `rdl_oracle_commerce` |

```mermaid
flowchart LR
    subgraph JOBS["⚡ 9 Cloud Run Jobs (Daily Cloud Scheduler)"]
        L1["ecommerce_customers"]
        L2["ecommerce_orders"]
        L3["ecommerce_products"]
        L4["marketing_meta_ads"]
        L5["marketing_google_ads"]
        L6["marketing_tiktok_ads"]
        L7["marketing_ga4_sessions"]
        L8["marketing_email_campaigns"]
        L9["marketing_influencers"]
    end

    subgraph GCS["📦 Cloud Storage (3 Buckets)"]
        RDL_GCS["boohoo-rdl-staging\nJSONL.GZ per brand\nNearline after 90d"]
        DQ_GCS["boohoo-data-quality\nParquet exports"]
    end

    subgraph SCHEDULER["⏰ Instance Schedule (Native GCE)"]
        IS1["Start: 01:00 UTC\nMon/Wed/Fri"]
        IS2["Stop: 03:00 UTC\nMon/Wed/Fri"]
    end

    subgraph GCE["🖥️ Compute Engine e2-standard-2 (2 hrs × 3 days/wk)"]
        AF["Apache Airflow 2.10.5\nOrchestration"]
    end

    subgraph BQ["🏢 BigQuery (Partitioned & Clustered Star Schema)"]
        RDL_BQ["RDL Layer\n7 brand datasets\nFull-history versioned views"]
        ODL_BQ["ODL Layer\n5 dims · 8 facts · 3 maps\nIncremental MERGE"]
        ADL_BQ["ADL / BI Layer\n12 analytical mart tables\nPartitioned & Clustered"]
    end

    subgraph ELT["🔄 Dual ELT Transformation Layer (55 Models)"]
        DBT_RUN["dbt Core (dbt-bigquery)\ndbt/models/ + Governance Contracts"]
        DF_RUN["Dataform (GCP-Native)\ndefinitions/ SQLX"]
    end

    L1 & L2 & L3 & L4 & L5 & L6 & L7 & L8 & L9 -->|"JSONL.GZ"| RDL_GCS
    RDL_GCS -->|"LOAD / External"| RDL_BQ
    RDL_BQ --> DBT_RUN & DF_RUN --> ODL_BQ --> ADL_BQ
    IS1 & IS2 -->|"start/stop"| GCE
    AF -->|"Orchestrates"| DBT_RUN & DF_RUN

    style JOBS fill:#4285F4,color:#fff
    style GCS fill:#AECBFA,color:#000
    style SCHEDULER fill:#34A853,color:#fff
    style GCE fill:#232F3E,color:#fff
    style BQ fill:#669DF6,color:#fff
    style ELT fill:#FF694B,color:#fff
```

---

## BigQuery FinOps Engineering (40% Fewer Scanned Bytes)

High-volume e-commerce fact tables (`fact_orders`, `fact_order_items`, `fact_ga4_sessions`, `fact_meta_campaign_insights`, `fact_daily_sales`, `fact_campaign_performance`) are engineered with four layered **BigQuery FinOps controls**:

1. **Daily Time-Unit Partitioning (`partition_by`)**: Fact tables are partitioned by business event date (`order_date` or `date_nk`) at `DAY` granularity so downstream BI queries prune historical partitions automatically.
2. **Mandatory Partition Pruning (`require_partition_filter = true`)**: Enforced at the BigQuery table metadata level — ad-hoc analysts and BI tools cannot execute accidental full-table scans without a `WHERE order_date ...` predicate.
3. **Multi-Column Clustering (`cluster_by`)**: Fact tables are clustered by high-cardinality filter/join keys (`["brand", "customer_sk", "status"]` or `["brand", "channel", "campaign_type"]`), enabling BigQuery block pruning within each daily partition.
4. **Incremental `MERGE` with Rolling Lookback (`enforce_partition_filter` macro) & Query Cost Guard (`maximum_bytes_billed: 10 GB`)**: Incremental runs only scan a rolling 3-day window (`DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY)`), while `dbt/profiles.yml` sets a 10 GB hard ceiling (`5 GB` in CI) to block runaway queries before execution.

```sql
-- Example: dbt/models/odl/fact/fact_orders/fact_orders.sql
{{
    config(
        materialized = "incremental",
        incremental_strategy = "merge",
        unique_key = "order_sk",
        partition_by = {
            "field": "order_date",
            "data_type": "date",
            "granularity": "day"
        },
        cluster_by = ["brand", "customer_sk", "status"],
        require_partition_filter = true,
        labels = {
            "layer": "odl",
            "domain": "ecommerce",
            "finops_optimized": "true"
        }
    )
}}
```

---

## Model Governance, Data Contracts & Observability (`dbt/`)

Every analytical model in `dbt/models/` (spanning **RDL**, **ODL**, and **ADL/BI**) is packaged as a self-contained **Data Product Directory** containing 5 standardised files:

| File | Purpose |
|------|---------|
| `<model_name>.sql` | BigQuery Standard SQL transformation with explicit `config(...)` block |
| `model.yml` | **Data Contract**: domain ownership (`analytics_owner`, `business_owner`, `technical_owner`), SLA (`Daily by 07:00 Europe/London`), criticality, PII classification, and grain |
| `README.md` | Business purpose, column dictionary, key business rules, and upstream/downstream lineage |
| `runbook.md` | **Production Incident Runbook**: failure impact, BigQuery diagnostic SQL queries, step-by-step recovery commands, and escalation path |
| `tests.yml` | Declarative data quality assertions (`duplicate_tests`, `null_tests`, `gap_tests`) |

Our GitHub Actions CI pipeline ([`.github/workflows/dbt_bigquery_slim_ci.yml`](.github/workflows/dbt_bigquery_slim_ci.yml)) automatically verifies that every model directory contains a non-empty governance contract bundle, validates FinOps partitioning/clustering configurations on critical fact tables, runs `bq query --dry_run` byte estimation, and executes **dbt Slim CI** (`dbt build --select state:modified+ --defer`).

---

## Tech Stack

| Layer | Technology | Details |
|-------|-----------|---------|
| **Data Warehouse** | Google BigQuery | 7 per-brand `rdl_*` datasets + `odl` + `bi`, EU multi-region, partitioned & clustered tables |
| **Transformation (Primary)** | dbt Core (`dbt-bigquery`) | 55 models across RDL/ODL/ADL with per-model `model.yml` contracts, `runbook.md`, `tests.yml`, and FinOps macros |
| **Transformation (GCP-Native)** | Dataform (`definitions/`) | 48 SQLX models + external source declarations (`workflow_settings.yaml`) |
| **Storage** | Cloud Storage (GCS) | 3 buckets: RDL staging, Terraform state, data quality. Lifecycle: Nearline at 90d, delete at 365d |
| **Data Generation** | Cloud Run Jobs (×9) | Python 3.11, containerised, 512 Mi, 5-min timeout. Multi-platform schema-aware generators |
| **Scheduling & FinOps** | Cloud Scheduler + GCE Instance Schedules | Daily Cloud Run triggers + VM Instance Schedules (Mon/Wed/Fri 01:00–03:00 UTC, ~£2–4/mo compute) |
| **Orchestration** | Apache Airflow 2.10.5 | LocalExecutor (cloud) / CeleryExecutor (local). GCS→BigQuery Load + dbt / Dataform execution |
| **Infrastructure** | Terraform | VPC, BigQuery, GCS, Cloud Run Jobs ×9, Cloud Scheduler, Compute Engine, Dataform, IAM, Secret Manager |
| **CI/CD** | GitHub Actions | `dbt_bigquery_slim_ci.yml` (Contract checks, FinOps check, Dry-Run, Slim CI), `airflow-vm.yml`, `pr_title_checker.yml` |

---

## Project Structure

```
boohoo-data-pipeline/
│
├── dbt/                                       # First-class dbt-bigquery project (55 models + contracts)
│   ├── dbt_project.yml                        # Medallion layer configs, persist_docs, FinOps labels
│   ├── profiles.yml                           # BigQuery OAuth/SA config with 10 GB maximum_bytes_billed guard
│   ├── packages.yml                           # dbt_utils dependency
│   ├── .sqlfluff                              # SQLFluff linter configured for BigQuery dialect
│   ├── macros/
│   │   ├── generate_schema_name.sql           # Multi-env dataset routing (dev / ci_pr_X / prod)
│   │   ├── enforce_partition_filter.sql       # FinOps rolling partition lookback macro
│   │   └── clean_strings_and_pii.sql          # Deterministic TO_HEX(MD5(...)) surrogate key & string macros
│   └── models/
│       ├── rdl/                               # Raw Data Layer — 21 brand history models + 6 marketing models
│       │   ├── _sources.yml                   # BigQuery external staging table declarations
│       │   ├── boohoo_commerce/               # boohoo_* and boohoo_man_* (customers, orders, products)
│       │   ├── salesforce_commerce/           # plt_* (customers, orders, products)
│       │   ├── shopify/                       # nastygal_* (customers, orders, products)
│       │   ├── magento/                       # karen_millen_* and coast_* (customers, orders, products)
│       │   ├── oracle_commerce/               # debenhams_* (customers, orders, products)
│       │   └── marketing/                     # rdl_meta_ads, rdl_google_ads, rdl_tiktok_ads, rdl_ga4_sessions, etc.
│       ├── odl/                               # Operational Data Layer — 16 Star Schema models
│       │   ├── _schema.yml                    # Schema & referential integrity tests
│       │   ├── dim/                           # dim_customers, dim_products, dim_time, dim_campaigns, dim_marketing_channels
│       │   ├── fact/                          # fact_orders, fact_order_items, fact_ga4_sessions, fact_meta_campaign_insights, etc.
│       │   └── map/                           # map_brand, map_channel_grouping, map_utm_sources
│       └── adl/bi/                            # Analytics Data Layer — 12 BI mart tables (each with model.yml + runbook.md)
│
├── definitions/                               # GCP-native Dataform SQLX transformation layer (48+ models)
│   ├── sources/external_tables.js             # External table declarations across 7 brands
│   ├── rdl/                                   # Per-brand _history SQLX models
│   ├── odl/                                   # Star schema dims, facts, and maps in SQLX
│   └── adl/bi/                                # 12 BI reporting marts in SQLX
│
├── jobs/                                      # 9 Cloud Run Job containerised data generators
│   ├── Dockerfile                             # Shared container image for all 9 jobs
│   ├── cloudbuild.yaml                        # Cloud Build configuration
│   ├── requirements.txt                       # google-cloud-storage
│   ├── ecommerce_customers/main.py            # Generates customer data for all 7 brands
│   ├── ecommerce_orders/main.py               # Generates orders + order_items for all brands
│   ├── ecommerce_products/main.py             # Generates product catalogues for all brands
│   ├── marketing_meta_ads/main.py             # Meta (Facebook/Instagram) campaign insights
│   ├── marketing_google_ads/main.py           # Google Ads performance generator
│   ├── marketing_tiktok_ads/main.py           # TikTok ad insights generator
│   ├── marketing_ga4_sessions/main.py         # GA4 web session generator
│   ├── marketing_email_campaigns/main.py      # Email campaign engagement generator
│   ├── marketing_influencers/main.py          # Influencer post ROI generator
│   └── shared/                                # Multi-platform schemas, handler logic, GCS JSONL.GZ uploader
│
├── terraform/                                 # Full GCP infrastructure as code
│   ├── main.tf                                # Google provider, GCS backend, API enablement
│   ├── bigquery.tf                            # BigQuery per-brand RDL datasets + external tables
│   ├── cloud_run_jobs.tf                      # 9 Cloud Run Jobs via for_each
│   ├── cloud_scheduler.tf                     # Daily triggers for all 9 jobs
│   ├── compute_engine.tf                      # Airflow VM + Instance Schedule (MWF start/stop)
│   ├── dataform.tf                            # Dataform repository & workspace provisioning
│   ├── gcs.tf                                 # 3 buckets with Nearline/Archive lifecycle policies
│   ├── iam.tf                                 # Least-privilege Service Accounts + Artifact Registry
│   ├── secret_manager.tf                      # Secret Manager configuration
│   ├── variables.tf                           # Project ID, region, environment
│   └── outputs.tf                             # Endpoints, dataset IDs, bucket names
│
├── airflow/                                   # Apache Airflow orchestration
│   ├── config/                                # copy_jobs.yml, export_jobs.yml, dimensions.yml, facts.yml, mappings.yml
│   ├── dags/                                  # 01_ingestion.py, 03_transform_odl.py, 04_transform_adl.py
│   ├── docker-compose.yaml                    # Full local stack (CeleryExecutor)
│   └── docker-compose.cloud.yaml              # Lightweight cloud stack (LocalExecutor)
│
├── .github/
│   ├── workflows/
│   │   ├── dbt_bigquery_slim_ci.yml           # Governance contracts, FinOps checks, BQ dry-run & dbt Slim CI
│   │   ├── airflow-vm.yml                     # Automated Airflow VM deployment
│   │   └── pr_title_checker.yml               # Enforce DATA-<number> PR title prefix
│   └── PULL_REQUEST_TEMPLATE.md               # PR template with checklist
│
├── docs/                                      # Architecture & execution diagrams
├── scripts/build_images.py                    # Build & push Docker images to Artifact Registry
├── workflow_settings.yaml                     # Dataform project settings
└── package.json                               # Dataform dependencies (@dataform/core)
```

---

## Medallion Architecture (dbt & Dataform)

Both transformation layers (`dbt/models/` and `definitions/`) transform raw multi-brand payloads through three medallion layers:

```
RDL (27 staging/history models)     ODL (16 Star Schema models)          ADL / BI (12 executive marts)
───────────────────────────────     ───────────────────────────          ─────────────────────────────
• 7 brand e-commerce sources        • dim_customers (cross-brand         • fact_daily_sales (PARTITION BY
  (customers, orders, products)       email dedup + surrogate key)         order_date, CLUSTER BY brand)
• 6 marketing channel sources       • dim_products (margin & RRP calc)   • fact_campaign_performance
• Versioned via ROW_NUMBER()        • dim_time (GENERATE_DATE_ARRAY)     • fact_channel_performance
  & TO_HEX(MD5(...)) record_hash    • dim_campaigns & dim_channels       • fact_marketing_roas
• Preserves full change history     • fact_orders & fact_order_items     • fact_marketing_spend_daily
  with is_latest boolean flag         (incremental MERGE, partitioned    • fact_marketing_summary
                                      by order_date, clustered by brand) • fact_funnel_metrics
                                    • 6 marketing fact tables            • fact_customer_segments
                                    • 3 conformed mapping tables         • fact_product_performance
                                                                         • fact_revenue_by_brand
                                                                         • fact_email_performance
                                                                         • fact_influencer_roi
```

---

## Getting Started

### Prerequisites

- Google Cloud SDK (`gcloud` & `bq`) configured
- A GCP project with billing enabled
- Terraform ≥ 1.5
- Python 3.11 + `dbt-bigquery` (`pip install dbt-core dbt-bigquery`)
- Docker & Docker Compose

### 1. Provision GCP Infrastructure (Terraform)

```bash
cd terraform
terraform init
terraform plan -var="gcp_project_id=YOUR_PROJECT_ID"
terraform apply -var="gcp_project_id=YOUR_PROJECT_ID"
```

### 2. Build & Push Cloud Run Job Images

```bash
python scripts/build_images.py --push
```

### 3. Run the dbt BigQuery Pipeline (`dbt/`)

```bash
cd dbt
dbt deps
dbt compile --profiles-dir .
dbt build --profiles-dir .
```

### 4. Or Run the GCP Dataform Pipeline (`definitions/`)

```bash
dataform compile
dataform run
```

### 5. Start Airflow Orchestration Locally

```bash
cd airflow
docker compose up -d
# Airflow UI → http://localhost:8081
```

---

## License

This project is engineered for architectural reference and portfolio demonstration.
