---
updated: 2026-09-25
covers: [overview, navigation, warehouse]
status: current
---

# Index — sales-dw

The **SQL Server sales data warehouse**: SSIS packages pull CRM and ERP extracts into `stg`, conform
them into a Kimball star in `dw`, and `mart` views serve Power BI. Schema is deployed from **ordered
T-SQL scripts** with `sqlcmd` (no `.sqlproj`); a nightly **SQL Agent job** runs the load. **Read this
first, then open the files it points to.**

## Components

| Component | Path | Toolchain | Purpose | Module page |
|-----------|------|-----------|---------|-------------|
| SQL scripts | `sql/` (entry `sql/deploy.sql`) | sqlcmd · run-ordered, idempotent | schemas, tables, procs, views for `stg`/`dw`/`mart`/`etl` | [warehouse](modules/warehouse.md) |
| SSIS | `ssis/SalesDW.ETL/` | VS 2022 + SSIS Projects ext · SSISDB | extract to `stg`, load dims/facts | [staging](modules/staging.md), [warehouse](modules/warehouse.md) |
| Jobs | `jobs/` | SQL Agent (`msdb`) scripts | nightly schedule, step order, alerts | [jobs](modules/jobs.md) |

## Stack

- **Target:** SQL Server 2019, database `SalesDW`, SSIS catalog folder `/SSISDB/SalesDW`
- **Deploy schema:** `sqlcmd -S <server> -d SalesDW -E -b -i sql/deploy.sql -v Env=Dev`
- **Build SSIS:** `devenv.com ssis/SalesDW.ETL.sln /Build Development` → `ssis/SalesDW.ETL/bin/Development/SalesDW.ETL.ispac`
- **Deploy SSIS:** `ISDeploymentWizard.exe /Silent /SourcePath:<ispac> /DestinationServer:<server> /DestinationPath:/SSISDB/SalesDW/SalesDW.ETL`
- **Run the load:** `EXEC msdb.dbo.sp_start_job N'SalesDW - Nightly'` · one package: see [recipes](recipes.md#run-one-package)
- **Checks:** `sql/tests/*.sql` data-quality queries (`sqlcmd -i sql/tests/run_all.sql`) · lint `sqlfluff lint sql --dialect tsql`
- **CI (ground truth):** `azure-pipelines.yml` — `SSISBuild@1`, `SSISDeploy@1`, then `sqlcmd` deploy to Test

## Map

| Area | Key files / dirs | Purpose | More |
|------|------------------|---------|------|
| Staging | `sql/20_tables/stg/` `ssis/SalesDW.ETL/Stg_*.dtsx` | raw-ish copies of source extracts, truncated each run | [staging](modules/staging.md) |
| Dimensions & facts | `sql/20_tables/dw/` `sql/40_procs/dw/` `ssis/SalesDW.ETL/Dw_*.dtsx` | conformed star schema, SCD2 customer | [warehouse](modules/warehouse.md) |
| Marts | `sql/30_views/mart/` | reporting views for Power BI | [warehouse](modules/warehouse.md#marts) |
| ETL control | `sql/20_tables/etl/` (`etl.Watermark`, `etl.LoadLog`) | watermarks, run log | [staging](modules/staging.md#watermarks) |
| Orchestration | `ssis/SalesDW.ETL/Master.dtsx` `jobs/SalesDW_Nightly.sql` | package order + schedule | [jobs](modules/jobs.md) |

## Where to start by task

- **A load failed last night** → [jobs](modules/jobs.md#when-a-run-fails), `etl.LoadLog`
- **Add a column from a source** → [recipes](recipes.md#add-a-source-column-end-to-end)
- **Add a dimension / fact** → [recipes](recipes.md#add-a-dimension), [warehouse](modules/warehouse.md)
- **Reload a date range** → [recipes](recipes.md#backfill-a-date-range)
- **Change the schedule** → [jobs](modules/jobs.md)

## Also see

- [architecture](architecture.md) · [conventions](conventions.md) · [glossary](glossary.md) · [log](log.md)
