---
updated: 2026-09-25
covers: [architecture, etl, layers]
status: current
---

# Architecture

A nightly batch warehouse. No application writes to it; the only writers are the SSIS packages and
the procs they call. Power BI reads `mart` views only.

## Data flow

```
CRM (SQL Server)  ─┐  Stg_LoadCrm.dtsx   ┐
ERP (Oracle, ODBC) ┘  Stg_LoadErp.dtsx   ┴─▶  stg.*    (truncate + load, incremental by watermark)
                                                 │
                     Dw_LoadDim*.dtsx  → dw.usp_MergeDim*   (SCD1/SCD2 MERGE)
                     Dw_LoadFact*.dtsx → dw.usp_LoadFact*   (surrogate-key lookup, late-arriving → -1)
                                                 ▼
                                             dw.Dim* / dw.Fact*
                                                 │
                                             mart.vw_*  ──▶ Power BI
```

`Master.dtsx` runs the packages in that order (staging in parallel, then dims, then facts); SQL Agent
job `SalesDW - Nightly` runs `Master.dtsx` at 02:00 and then refreshes aggregates. See
[jobs](modules/jobs.md).

## Layers

- **`stg`** — one table per source entity, source column names, all nullable, plus `LoadId`. Truncated
  at the start of each package. See [staging](modules/staging.md).
- **`dw`** — conformed dims (`DimCustomer` SCD2, `DimProduct` SCD1, `DimDate` static) and facts
  (`FactSales`, `FactReturns`) at order-line grain. See [warehouse](modules/warehouse.md).
- **`mart`** — views only; business-friendly names; the Power BI dataset's contract.
- **`etl`** — control tables: `Watermark` (last loaded `ModifiedAt` per source), `LoadLog` (one row per
  package run, rows read/written, status).

## Deploy model

Schema changes are **ordered, idempotent scripts** under `sql/NN_<kind>/…`, stitched together by
`sql/deploy.sql` via `:r`. Re-running a deploy is safe by design (see
[conventions](conventions.md#scripts-must-be-idempotent)). SSIS is deployed separately as an
`.ispac` to the SSIS catalog; environment-specific values (connection strings, `LookbackDays`) live
in SSISDB environments `Dev`/`Test`/`Prod`, not in the project.

## Key decisions & constraints

- Watermarks advance **only after** the dim/fact load succeeds, so a failed night reprocesses the
  same window next time.
- Facts never reject rows: unmatched dimension keys map to the `-1` "Unknown" member and are logged.
- `DimDate` is generated once (`sql/50_data/DimDate.sql`, 2000–2040); don't load it in ETL.
