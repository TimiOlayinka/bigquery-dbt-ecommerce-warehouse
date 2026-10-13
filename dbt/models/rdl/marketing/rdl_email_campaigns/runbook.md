# Runbook: rdl_email_campaigns

## What this model supports
Feeds downstream ODL marketing fact and campaign dimension models.

## Expected refresh
Daily at 01:30 UTC following Cloud Run marketing ingestion jobs.

## Recovery steps
1. Verify GCS staging payload landed in `gs://omnistyle-rdl-staging/raw/*/marketing/`
2. Re-run `dbt run --select rdl_email_campaigns+`
