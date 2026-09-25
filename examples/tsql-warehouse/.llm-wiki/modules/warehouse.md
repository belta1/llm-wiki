---
updated: 2026-09-25
covers: [dw, dimensions, facts, marts, scd]
status: current
---

# Warehouse (`dw`) & marts (`mart`)

The conformed star schema and the reporting views on top of it.

## Key files & entry points

- `sql/20_tables/dw/` — `dw.DimCustomer` (SCD2), `dw.DimProduct` (SCD1), `dw.DimDate`,
  `dw.FactSales`, `dw.FactReturns`.
- `sql/40_procs/dw/dw.usp_MergeDimCustomer.sql` — the SCD2 reference implementation.
- `sql/40_procs/dw/dw.usp_LoadFactSales.sql` — the incremental fact reference implementation.
- `ssis/SalesDW.ETL/Dw_*.dtsx` — thin wrappers: Execute SQL Task → proc → set watermark.
- `sql/30_views/mart/` — `mart.vw_Sales`, `mart.vw_Customer`, `mart.vw_Product`.

## Database objects

| Object | Grain / type | Keys |
|--------|--------------|------|
| `dw.DimCustomer` | one row per customer **version** | `CustomerKey` (SK), `CustomerBK`, `IsCurrent` |
| `dw.DimProduct` | one row per product | `ProductKey`, `ProductBK` |
| `dw.DimDate` | one row per day 2000–2040 | `DateKey int` (`yyyymmdd`) |
| `dw.FactSales` | one row per order line | `DateKey`, `CustomerKey`, `ProductKey`, `SalesOrderLineBK` |
| `dw.FactReturns` | one row per return line | as above + `ReturnReasonCode` |

## How it works

- **SCD2 (`usp_MergeDimCustomer`)**: hash the tracked columns (`HASHBYTES('SHA2_256', CONCAT_WS('|', …))`);
  changed hash ⇒ close current row (`ValidTo = load date`, `IsCurrent = 0`) and insert a new version.
  SCD1 columns are updated on all versions.
- **Facts (`usp_LoadFactSales`)**: delete rows for the `DateKey`s present in stg, insert from stg joined
  to dims on BK (and, for SCD2, the version valid at the order date); unmatched → `-1`, counted in
  `LoadLog.UnknownKeys`.

## Marts

`mart` views are the **Power BI contract**: renaming or removing a column breaks the published dataset.
Add columns freely; for breaking changes, add a new view and coordinate with the BI team. Views select
from `dw` only and filter `IsCurrent = 1` where a "current state" view is intended.

## Gotchas

- Joining facts to `DimCustomer` on BK alone multiplies rows — always add the SCD2 validity predicate
  or `IsCurrent = 1`.
- `FactSales` is clustered columnstore; single-row updates are slow — keep loads set-based.
- Changing the SCD2 hash column list re-versions every customer on the next run; do it deliberately.

## Related

- [staging](staging.md) · [jobs](jobs.md) · [recipes](../recipes.md#add-a-dimension) · [conventions](../conventions.md#naming)
