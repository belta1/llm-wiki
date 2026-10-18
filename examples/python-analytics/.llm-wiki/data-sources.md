---
updated: 2026-09-23
covers: [data, connections]
status: current
---

# Data sources

Where the raw sales data comes from and where processed output goes. *How* to connect to each named
source (driver, DSN, auth, credential env-var names) lives once in the user-global catalog
`~/.claude/llm-wiki/data-sources.md`, joined by **Name** — never in this repo, and never a secret.

## Sources this repo uses

| Name | Engine | Used by (code) | Direction | Objects / datasets | Catalog |
|------|--------|----------------|-----------|--------------------|---------|
| `\\SRVFILES01\SalesExports` | SMB share | `src/sales_insights/ingest.py` · [pipeline](modules/pipeline.md) | read | `sales_<YYYYMM>.csv`, `regions.csv` | yes |
| `SRVPLATDAT` | SQL Server | `src/sales_insights/ingest.py` | read | `dbo.DimCustomer` (customer attributes join) | yes |
| `s3://corp-lake-processed` | S3 | `src/sales_insights/load.py` | write | `sales/dt=<run-date>/*.parquet` | yes |
| `data/processed/` | Parquet files | `src/sales_insights/load.py` · `analysis/` | read/write | local mirror of the S3 output | no (repo-local) |

## How data flows

- `\\SRVFILES01\SalesExports\sales_<YYYYMM>.csv` + `SRVPLATDAT.dbo.DimCustomer` → `ingest.py` →
  `transform.py` → `load.py` → `data/processed/*.parquet` and `s3://corp-lake-processed/sales/`.
- `analysis/` and `notebooks/` read `data/processed/` only — never the raw share.

See [architecture](architecture.md) for the stage boundaries.

## Gotchas & constraints

- **The share is written once a month**, around the 3rd working day. A missing
  `sales_<YYYYMM>.csv` means the export hasn't landed yet — not a bug. Don't retry in a loop.
- **The share is read-only** from this repo. Processed output goes to `data/processed/` and S3, never
  back to `\\SRVFILES01\`.
- `SRVPLATDAT` is a **read replica**; it lags the OLTP source by up to 15 minutes. Irrelevant for a
  monthly batch, but don't build anything near-real-time on it.
- Raw CSVs are **Latin-1 with a trailing total row** — `ingest.py` strips it. All such quirks stay in
  `ingest.py` (see [conventions](conventions.md)).
- S3 writes are **partitioned by run date**; re-running the same day overwrites that partition.

## Local / dev substitutes

| Real source | Substitute | How to use it |
|-------------|------------|---------------|
| `\\SRVFILES01\SalesExports` | files placed in `data/raw/` | the default — `RAW_DIR` in `.env` |
| `s3://corp-lake-processed` | `data/processed/` only | leave `S3_BUCKET` unset to skip the upload |

## Related

- [architecture](architecture.md) · [recipes](recipes.md#add-a-data-source) · [pipeline](modules/pipeline.md)
