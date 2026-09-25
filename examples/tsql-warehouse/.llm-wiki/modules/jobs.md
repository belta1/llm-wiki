---
updated: 2026-09-25
covers: [jobs, sql-agent, orchestration, schedule]
status: current
---

# Jobs & orchestration

How the load is ordered and scheduled.

## Key files & entry points

- `ssis/SalesDW.ETL/Master.dtsx` — Execute Package Tasks: `Stg_LoadCrm` ∥ `Stg_LoadErp` → all
  `Dw_LoadDim*` → `Dw_LoadFactSales` ∥ `Dw_LoadFactReturns`.
- `jobs/SalesDW_Nightly.sql` — scripted Agent job (drop-and-recreate, idempotent): step 1 runs
  `Master.dtsx` from the catalog with the `Prod`/`Test`/`Dev` environment (`$(Env)`), step 2
  `EXEC dw.usp_RefreshAggregates`, schedule daily 02:00, notify operator `DW-Oncall` on failure.
- `jobs/SalesDW_Maintenance.sql` — Sunday 05:00 index/statistics maintenance.

## How it works

Agent step 1 is an SSIS-type step (`@subsystem = N'SSIS'`) pointing at
`\SSISDB\SalesDW\SalesDW.ETL\Master.dtsx`. The catalog records a full execution report
(SSMS → Integration Services Catalogs → Reports → All Executions); `etl.LoadLog` has the per-package
row counts.

## When a run fails

1. `SELECT TOP 20 * FROM etl.LoadLog ORDER BY LoadId DESC;` — find the failed package + error.
2. Catalog detail: `SELECT * FROM SSISDB.catalog.event_messages WHERE operation_id = <id> AND message_type = 120;`
3. Fix, then re-run from the failed package onward ([recipes](../recipes.md#run-one-package)) — the
   watermarks didn't move, so nothing is skipped.

## Gotchas

- The Agent job is created from the script; editing the job in SSMS is overwritten on the next deploy.
- The job's proxy account (`SSIS_Proxy`) needs access to the ERP ODBC DSN on the **server**; a package
  that works in Visual Studio can still fail under Agent.
- Backfills of more than ~3 months exceed the 02:00–06:00 window; run them month by month outside it.

## Related

- [staging](staging.md) · [warehouse](warehouse.md) · [architecture](../architecture.md)
