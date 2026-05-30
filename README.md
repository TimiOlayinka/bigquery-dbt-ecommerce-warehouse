<p align="center">
  <h1 align="center">Boohoo Group Data Pipeline</h1>
  <p align="center">
    <strong>Multi-brand e-commerce data warehouse on GCP — 9 Cloud Run Jobs across 7 brands, BigQuery star schema, Dataform medallion architecture (RDL → ODL → ADL), Airflow on a cost-optimised Compute Engine VM managed by Instance Schedules.</strong>
  </p>
  <p align="center">
    <img src="https://img.shields.io/badge/BigQuery-669DF6?style=for-the-badge&logo=googlebigquery&logoColor=white" alt="BigQuery">
    <img src="https://img.shields.io/badge/Cloud_Run-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white" alt="Cloud Run">
    <img src="https://img.shields.io/badge/Cloud_Scheduler-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white" alt="Cloud Scheduler">
    <img src="https://img.shields.io/badge/Cloud_Storage-AECBFA?style=for-the-badge&logo=googlecloudstorage&logoColor=black" alt="GCS">
    <img src="https://img.shields.io/badge/Apache_Airflow-017CEE?style=for-the-badge&logo=apacheairflow&logoColor=white" alt="Airflow">
    <img src="https://img.shields.io/badge/Dataform-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white" alt="Dataform">
    <img src="https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform">
    <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
    <img src="https://img.shields.io/badge/Python_3.11-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python">
  </p>
</p>

---

## Architecture Overview

A **production-grade, cost-optimised data warehouse** for the Boohoo Group's multi-brand e-commerce ecosystem. **9 Cloud Run Jobs** generate data for **7 brands** across **5 e-commerce platforms**, landing as JSONL.GZ in Cloud Storage. **BigQuery** warehouses the data through a **Dataform-driven medallion architecture** (RDL → ODL → ADL) spanning **48+ models**. **Apache Airflow** runs on a **Compute Engine VM** that is automatically started and stopped by **Instance Schedules** — running just **2 hours, 3 days a week** to minimise costs.

### Brands & Platforms

| Brand | Platform | RDL Dataset |
|-------|----------|-------------|
| **Boohoo** | Boohoo Commerce | `rdl_boohoo` |
| **BoohooMAN** | Boohoo Commerce | `rdl_boohoo_man` |
| **PrettyLittleThing** | Salesforce Commerce Cloud | `rdl_prettylittlething` |
| **NastyGal** | Shopify | `rdl_nastygal` |
| **Karen Millen** | Magento | `rdl_karen_millen` |
| **Coast** | Magento | `rdl_coast` |
| **Debenhams** | Oracle Commerce | `rdl_debenhams` |

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

    subgraph BQ["🏢 BigQuery (7 per-brand RDL datasets)"]
        RDL_BQ["RDL Layer\n7 brand datasets\n21 _stg → _history tables"]
        ODL_BQ["ODL Layer\n5 dims · 7 facts · 3 maps"]
        ADL_BQ["ADL / BI Layer\n12 analytical tables"]
    end

    subgraph DF["🔄 Dataform (48+ models)"]
        DF_RUN["Dataform\nRDL → ODL → ADL"]
    end

    L1 & L2 & L3 & L4 & L5 & L6 & L7 & L8 & L9 -->|"JSONL.GZ"| RDL_GCS
    RDL_GCS -->|"LOAD"| RDL_BQ
    RDL_BQ --> DF_RUN --> ODL_BQ --> ADL_BQ
    IS1 & IS2 -->|"start/stop"| GCE
    AF -->|"Orchestrates"| DF_RUN

    style JOBS fill:#4285F4,color:#fff
    style GCS fill:#AECBFA,color:#000
    style SCHEDULER fill:#34A853,color:#fff
    style GCE fill:#232F3E,color:#fff
    style BQ fill:#669DF6,color:#fff
    style DF fill:#4285F4,color:#fff
```

### How It Works

1. **Cloud Scheduler** triggers **9 Cloud Run Jobs** daily at midnight UTC — each generates e-commerce and marketing data for all 7 brands, uploading JSONL.GZ to **Cloud Storage**
2. **Instance Schedule** starts the **Airflow VM** at **01:00 UTC** on Mon/Wed/Fri
3. **Airflow** orchestrates **GCS → BigQuery Load** jobs (defined in `copy_jobs.yml`) to load raw data into per-brand RDL datasets
4. **Dataform** transforms the data through a **3-layer medallion architecture**: RDL (`_stg` → `_history` tables) → ODL (dimensional model) → ADL (business analytics)
5. **Instance Schedule** stops the VM at **03:00 UTC**, keeping total compute to ~**6 hours/week** (~£2–4/month)
6. **BigQuery → GCS Export** jobs (defined in `export_jobs.yml`) export Parquet files for external consumption

---

## Tech Stack

| Layer | Technology | Details |
|-------|-----------|---------|
| **Data Warehouse** | BigQuery | 7 per-brand `rdl_*` datasets + `odl` + `bi`, EU location, on-demand pricing |
| **Storage** | Cloud Storage | 3 buckets: RDL staging, Terraform state, data quality. Lifecycle: Nearline at 90d, delete at 365d |
| **Data Generation** | Cloud Run Jobs (×9) | Python 3.11, containerised, 512 Mi, 5-min timeout. Multi-platform schema-aware generators |
| **Scheduling** | Cloud Scheduler | Daily job triggers + VM Instance Schedules (Mon/Wed/Fri) |
| **Cost Optimisation** | Instance Schedules | Native GCE feature — VM runs 2 hrs × 3 days/wk. ~£2–4/month compute |
| **Orchestration** | Apache Airflow 2.10.5 | LocalExecutor (cloud). GCS→BigQuery Load + Dataform |
| **Transformation** | Dataform (GCP-native) | 48+ models: 21 RDL tables + 15 ODL tables + 12 ADL tables |
| **Infrastructure** | Terraform | VPC, BigQuery, GCS, Cloud Run Jobs ×9, Cloud Scheduler, Compute Engine, IAM, Secret Manager |
| **Container Registry** | Artifact Registry | `boohoo-jobs` Docker repository |
| **Containerisation** | Docker Compose | Lightweight cloud stack (4 containers) |
| **CI/CD** | GitHub Actions | PR title enforcement (`DATA-<number>`) |
| **Language** | Python 3.11 | Cloud Run Jobs, Airflow DAGs, Dataform model generator, scripts |

---

## Project Structure

```
boohoo-data-pipeline/
│
├── jobs/                                      # Cloud Run Job data generators
│   ├── Dockerfile                             # Shared container image for all 9 jobs
│   ├── requirements.txt                       # google-cloud-storage
│   ├── ecommerce_customers/main.py            # Generates customer data for all 7 brands
│   ├── ecommerce_orders/main.py               # Generates orders + order_items for all brands
│   ├── ecommerce_products/main.py             # Generates product catalogues for all brands
│   └── shared/
│       ├── config/ecommerce.py                # Multi-platform schemas, BRAND_SOURCES, ref data
│       ├── handler_logic.py                   # gen_customers, gen_orders, gen_products
│       └── utils.py                           # GCS upload helper (JSONL.GZ)
│
├── terraform/                                 # Full GCP infrastructure as code
│   ├── main.tf                                # Google provider, GCS backend, API enablement
│   ├── bigquery.tf                            # BigQuery per-brand RDL datasets + external tables
│   ├── cloud_run_jobs.tf                      # 9 Cloud Run Jobs via for_each
│   ├── cloud_scheduler.tf                     # Daily triggers for all 9 jobs
│   ├── compute_engine.tf                      # Airflow VM + Instance Schedule (MWF start/stop)
│   ├── gcs.tf                                 # 3 buckets with lifecycle policies
│   ├── iam.tf                                 # Service accounts + Artifact Registry
│   ├── secret_manager.tf                      # Placeholder for future API keys
│   ├── variables.tf                           # Project ID, region, environment
│   └── outputs.tf                             # Endpoints, dataset IDs, bucket names
│
├── dataform/                                  # Dataform transformation layer (48+ models)
│   ├── workflow_settings.yaml                 # Project config
│   └── definitions/
│       ├── sources/                           # External table declarations
│       ├── rdl/                               # Raw Data Layer — 21 _history tables
│       │   ├── boohoo/                        # customers, orders, products
│       │   ├── boohoo_man/
│       │   ├── prettylittlething/
│       │   ├── nastygal/
│       │   ├── karen_millen/
│       │   ├── coast/
│       │   └── debenhams/
│       ├── odl/                               # Operational Data Layer — 15 tables
│       │   ├── dim/                           # dim_customers, dim_products, dim_time, etc.
│       │   ├── fact/                          # fact_orders, fact_meta_campaign_insights, etc.
│       │   └── map/                           # map_brand, map_channel_grouping, map_utm_sources
│       └── adl/bi/                            # Analytics Data Layer — 12 BI tables
│
├── airflow/                                   # Airflow orchestration
│   ├── config/
│   │   ├── copy_jobs.yml                      # GCS → BigQuery Load definitions
│   │   └── export_jobs.yml                    # BigQuery → GCS Parquet Export definitions
│   ├── dags/
│   │   └── gcp_session.py                     # GCP credentials helper (ADC + service account)
│   ├── docker-compose.yaml                    # Full local stack (CeleryExecutor)
│   └── docker-compose.cloud.yaml              # Lightweight cloud stack (LocalExecutor)
│
├── scripts/
│   ├── build_images.py                        # Build & push Docker images to Artifact Registry
│   └── generate_models.py                     # Scaffold all RDL/ODL/ADL SQL models
│
├── .github/
│   ├── workflows/pr_title_checker.yml         # Enforce DATA-<number> PR title prefix
│   └── PULL_REQUEST_TEMPLATE.md               # PR template with checklist
│
└── boohoo/                                    # Brand configuration and data models
```

---

## Key Components

### ⚡ Cloud Run Job Data Generators

**9 Cloud Run Jobs** generate e-commerce and marketing data for all 7 brands, triggered daily by Cloud Scheduler:

| Job | Output | Description |
|-----|--------|-------------|
| `ecommerce_customers` | `{brand}/customers/` | Customer profiles per brand/platform |
| `ecommerce_orders` | `{brand}/orders/` + `order_items/` | Orders and line items |
| `ecommerce_products` | `{brand}/products/` | Product catalogues |
| `marketing_meta_ads` | `{brand}/meta_ads/` | Meta (Facebook/Instagram) ad campaigns |
| `marketing_google_ads` | `{brand}/google_ads/` | Google Ads performance |
| `marketing_tiktok_ads` | `{brand}/tiktok_ads/` | TikTok ad insights |
| `marketing_ga4_sessions` | `{brand}/ga4_sessions/` | Google Analytics 4 sessions |
| `marketing_email_campaigns` | `{brand}/email_campaigns/` | Email engagement metrics |
| `marketing_influencers` | `{brand}/influencers/` | Influencer performance |

All jobs share a single Docker image pushed to **Artifact Registry** (`boohoo-jobs`). Each Cloud Run Job overrides the `CMD` at deploy time.

**GCS path pattern**: `raw/{brand}/{dataset}/ingest_date={yyyy-mm-dd}/{dataset}.jsonl.gz`

### ⏰ VM Cost Scheduler

The Airflow VM is managed by **native GCE Instance Schedules** — no extra functions needed:

| Component | Configuration |
|-----------|--------------|
| **Instance Schedule** | `boohoo-airflow-schedule` — Start Mon/Wed/Fri at **01:00 UTC**, Stop at **03:00 UTC** |
| **VM** | `e2-standard-2` — Debian 12, 20 GB pd-ssd, static external IP |
| **Runtime** | ~**6 hours/week** total (2 hrs × 3 days) |
| **Estimated cost** | ~**£2–4/month** |

### 🏢 BigQuery Data Warehouse

**Datasets**: 7 per-brand `rdl_*` + `odl` + `bi` | **Location**: EU | **Pricing**: On-demand

Each brand has its own BigQuery dataset with `_stg` (external) and `_history` (materialized) tables:

| Logical Layer | Purpose |
|---------------|---------|
| `rdl_{brand}` datasets | Per-brand raw data (21 _stg + 21 _history tables) |
| `odl_*` tables | Operational star schema (15 tables) |
| `bi_*` tables | Analytics / BI layer (12 tables) |


### 🔄 Dataform Medallion Architecture

The Dataform project uses **Dataform (GCP-native BigQuery integration)** to transform data through three layers:

```
RDL (21 _history tables)      ODL (15 tables)              ADL (12 tables)
────────────────────          ──────────────               ──────────────
Per-brand _stg → _history →   Star schema dims/facts   →   BI-ready analytics
• Dedup via ROW_NUMBER        • dim_customers (UNION ALL   • fact_revenue_by_brand
• Platform-specific fields      + dedup by email)          • fact_daily_sales
• _history table reads        • dim_products (margin calc) • fact_customer_segments
                              • dim_time (date spine via   • fact_marketing_roas
                                GENERATE_DATE_ARRAY)       • fact_channel_performance
                              • fact_orders (surrogate     • ... (7 more)
                                keys, revenue calcs)
                              • 7 marketing fact tables
                              • 3 mapping tables
```

---

## Infrastructure (Terraform)

All infrastructure is provisioned as code in `europe-west2` (London) with GCS backend state:

| Resource | Details |
|----------|---------|
| **BigQuery** | 7 per-brand `rdl_*` datasets + `odl` + `bi`, EU location, on-demand pricing |
| **Cloud Storage** | 3 buckets: `boohoo-rdl-staging`, `boohoo-terraform-state`, `boohoo-data-quality` |
| **Cloud Run Jobs (×9)** | Containerised Python 3.11 data generators, 512 Mi, Artifact Registry images |
| **Cloud Scheduler (×9)** | Daily midnight UTC triggers for each Cloud Run Job |
| **Compute Engine** | `e2-standard-2`, Debian 12, 20 GB pd-ssd, static IP, Docker bootstrap |
| **Instance Schedule** | Native GCE start/stop: Mon/Wed/Fri 01:00–03:00 UTC |
| **IAM** | `boohoo-data-generator` SA (GCS + BQ), `boohoo-airflow-vm` SA (BQ admin + GCS + Run invoker) |
| **Artifact Registry** | `boohoo-jobs` Docker repository |
| **Secret Manager** | Placeholder for future API keys |

---

## Getting Started

### Prerequisites

- Google Cloud SDK (`gcloud`) configured
- A GCP project with billing enabled
- Terraform ≥ 1.0
- Docker & Docker Compose
- Python 3.11
- Dataform CLI (optional, for local dev)

### 1. Provision Infrastructure

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

### 3. Run Dataform Models

```bash
cd dataform
dataform compile    # Validate SQL
dataform run        # Build all models
```

### 4. Start Airflow Locally

```bash
cd airflow
docker compose up -d

# Airflow UI → http://localhost:8081
```

---

## License

This project is for educational and portfolio purposes.
