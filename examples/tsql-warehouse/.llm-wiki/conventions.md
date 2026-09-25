---
updated: 2026-09-25
covers: [conventions, patterns, tsql, ssis]
status: current
---

# Conventions

## Script layout & run order

- `sql/00_database/` → `10_schemas/` → `20_tables/<schema>/` → `30_views/<schema>/` →
  `40_procs/<schema>/` → `50_data/` → `60_security/`. `sql/deploy.sql` lists every file with `:r`
  **in that order** — a new file isn't deployed until it's added there.
- One object per file, named `<schema>.<Object>.sql`.

## Scripts must be idempotent

`deploy.sql` runs the **whole** set every time, so every script must be re-runnable:

- Procs, views, functions: `CREATE OR ALTER`.
- Tables: `IF OBJECT_ID(N'dw.DimCustomer', N'U') IS NULL CREATE TABLE …`.
- Column adds: `IF COL_LENGTH(N'dw.DimCustomer', N'Segment') IS NULL ALTER TABLE … ADD …`.
- Indexes: `IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_…')`.
- Data: `MERGE` or `IF NOT EXISTS … INSERT`. Never a bare `INSERT`.
- Destructive changes (drop/rename column) go in `sql/90_oneoff/YYYYMMDD_<desc>.sql`, guarded, run
  once by hand, and noted in [log](log.md).

## Naming

- Dims `dw.Dim<Entity>` with surrogate key `<Entity>Key int IDENTITY` and business key
  `<Entity>BK`; facts `dw.Fact<Process>`. SCD2 columns: `ValidFrom`, `ValidTo` (`9999-12-31` open),
  `IsCurrent`.
- Staging tables `stg.<Source>_<Entity>` (`stg.Crm_Customer`), keeping source column names.
- Procs `<schema>.usp_<Verb><Noun>`; packages `Stg_Load<Source>.dtsx`, `Dw_Load<Table>.dtsx`.

## SSIS

- Packages are thin: a data flow into `stg`, or an Execute SQL Task calling a `dw.usp_*` proc. Put
  transformation logic in T-SQL procs (reviewable, testable), not in Derived Column/Script tasks.
- Every package starts with `etl.usp_StartLoad` and ends with `etl.usp_EndLoad` (writes `LoadLog`)
  — copy an existing package's control flow.
- Project parameters for anything environment-specific; bind them to SSISDB environment variables.
  `ProtectionLevel = DontSaveSensitive` — never commit credentials in `.dtsx`/`.params`.
- Keep `.dtsx` diffs reviewable: don't reformat packages; one logical change per commit.

## Procs

- `SET NOCOUNT ON; SET XACT_ABORT ON;`, `TRY…CATCH` + `THROW` after logging to `etl.LoadLog`.
- Set-based only — no cursors over fact rows.

## Tooling

- `sqlfluff` (`.sqlfluff`, `dialect = tsql`) on `sql/` in CI.
- Data-quality checks in `sql/tests/` return rows only on failure; `run_all.sql` fails (`THROW`) if
  any do.

## Do / don't

- ✅ Add new columns as nullable or with a default; backfill in a separate step.
- ❌ Don't query `stg` from `mart` or Power BI — only `dw`.
- ❌ Don't edit objects in SSMS on a shared server without a matching script in `sql/`.
