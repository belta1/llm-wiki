---
updated: 2026-09-25
covers: [staging, extract, watermark, ssis]
status: current
---

# Staging (`stg`) & extract

Lands source data as-is so everything downstream is plain T-SQL against local tables.

## Key files & entry points

- `ssis/SalesDW.ETL/Stg_LoadCrm.dtsx` — CRM (SQL Server) → `stg.Crm_*`.
- `ssis/SalesDW.ETL/Stg_LoadErp.dtsx` — ERP (Oracle via ODBC) → `stg.Erp_*`.
- `sql/20_tables/stg/` — staging tables. `sql/20_tables/etl/etl.Watermark.sql`,
  `sql/40_procs/etl/etl.usp_GetWatermark.sql` / `etl.usp_SetWatermark.sql` / `etl.usp_ResetWatermark.sql`.

## Database objects

| Object | Kind | Notes |
|--------|------|-------|
| `stg.Crm_Customer`, `stg.Crm_Account` | table | full load (small) |
| `stg.Erp_SalesLine`, `stg.Erp_Return` | table | incremental by `MODIFIED_AT` |
| `etl.Watermark` | table | PK `(SourceEntity)`; `LastModifiedAt datetime2` |
| `etl.LoadLog` | table | `LoadId`, package, start/end, rows, status, error |

## How it works

Each package: `etl.usp_StartLoad` → `TRUNCATE` its stg tables → for incremental entities read
`etl.usp_GetWatermark` minus the `LookbackDays` project parameter (default 2, catches late updates) →
data flow → `etl.usp_EndLoad`. It does **not** move the watermark — see below.

## Watermarks

`etl.usp_SetWatermark` is called by the **fact/dim** package after its load commits, setting the
watermark to `MAX(MODIFIED_AT)` of what was staged. A failure anywhere leaves it untouched, so the next
run re-extracts the same window. Reset for backfills with `etl.usp_ResetWatermark`
([recipes](../recipes.md#backfill-a-date-range)).

## Gotchas

- ERP timestamps are **local time (Europe/Madrid)**; the extract converts with `AT TIME ZONE` in the
  source query. Don't compare raw ERP times to UTC columns.
- Oracle `NUMBER` without precision arrives as `DT_NUMERIC(38,0)`/`DT_R8` — cast explicitly in the
  source query or decimals get truncated.
- Staging tables are all-nullable on purpose; enforce rules in the `dw` procs, not with stg constraints
  (one bad row would fail the whole extract).

## Related

- [warehouse](warehouse.md) · [jobs](jobs.md) · [architecture](../architecture.md#layers)
