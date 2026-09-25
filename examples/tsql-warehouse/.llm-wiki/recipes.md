---
updated: 2026-09-25
covers: [recipes, how-to, etl, deploy]
status: current
---

# Recipes

`<server>` = `localhost` for a dev instance (Developer Edition with SSIS + Agent). Use `-E`
(Windows auth) or `-U/-P`; add `-C` with ODBC 18 / go-sqlcmd against a self-signed cert.

## Set up a dev instance

1. Install SQL Server 2019+ Developer with Integration Services; enable SQL Agent; create the SSIS
   catalog (SSMS → Integration Services Catalogs → Create Catalog).
2. `sqlcmd -S localhost -E -b -i sql/deploy.sql -v Env=Dev` — creates `SalesDW` and all objects.
3. `sqlcmd -S localhost -E -b -i sql/setup/ssisdb_environments.sql -v Env=Dev` — folder, `Dev`
   environment, variables (edit the source connection strings locally; never commit them).
4. Build + deploy SSIS ([below](#build-and-deploy-ssis)), then `sqlcmd -i jobs/SalesDW_Nightly.sql`.

## Deploy the schema

```bash
sqlcmd -S <server> -d master -E -b -i sql/deploy.sql -v Env=Dev
```

Safe to re-run (idempotent scripts). `-b` stops on the first error. `Env` gates `sql/50_data/dev/*`.

## Build and deploy SSIS

```bash
devenv.com ssis/SalesDW.ETL.sln /Build Development
ISDeploymentWizard.exe /Silent /SourcePath:ssis/SalesDW.ETL/bin/Development/SalesDW.ETL.ispac /DestinationServer:<server> /DestinationPath:/SSISDB/SalesDW/SalesDW.ETL
```

(Or right-click the project in Visual Studio → Deploy.) Re-bind the `Dev` environment reference if
you added a project parameter.

## Run one package

```bash
dtexec /ISServer "\SSISDB\SalesDW\SalesDW.ETL\Dw_LoadFactSales.dtsx" /Server <server> /EnvReference <id>
```

`<id>`: `SELECT reference_id, environment_name FROM SSISDB.catalog.environment_references;`.
While developing, F5 in Visual Studio runs against the project parameters' design-time values.

## Run the whole nightly load

```sql
EXEC msdb.dbo.sp_start_job N'SalesDW - Nightly';
SELECT TOP (20) * FROM SalesDW.etl.LoadLog ORDER BY LoadId DESC;   -- progress / result
```

## Run data-quality checks & lint

```bash
sqlcmd -S <server> -d SalesDW -E -b -i sql/tests/run_all.sql
sqlfluff lint sql --dialect tsql
```

## Add a source column end to end

1. `sql/20_tables/stg/stg.<Source>_<Entity>.sql` — add a guarded `ALTER TABLE … ADD` (nullable).
2. `Stg_Load<Source>.dtsx` — add the column to the source query and the destination mapping.
3. `sql/20_tables/dw/dw.Dim<Entity>.sql` — guarded add; update `dw.usp_MergeDim<Entity>` (decide SCD1
   vs SCD2 for it — SCD2 columns must be in the change-detection hash).
4. Expose in `mart` if reporting needs it; deploy schema, deploy SSIS, run the two packages; run checks.

## Add a dimension

1. Table `sql/20_tables/dw/dw.Dim<X>.sql` (surrogate key, BK, SCD columns, `-1` Unknown row in
   `sql/50_data/UnknownMembers.sql`).
2. Staging table + `Stg_Load…` data flow if the source isn't staged yet.
3. Proc `sql/40_procs/dw/dw.usp_MergeDim<X>.sql` — copy `usp_MergeDimCustomer` (SCD2) or
   `usp_MergeDimProduct` (SCD1).
4. Package `Dw_LoadDim<X>.dtsx` calling the proc; add it to `Master.dtsx` **before** the facts.
5. Add the `:r` lines to `sql/deploy.sql`; add a checks query in `sql/tests/`.

## Add a fact

Like a dimension, but: define the **grain** first; the proc looks up every surrogate key with
`ISNULL(d.<X>Key, -1)`; load is incremental by watermark ([staging](modules/staging.md#watermarks));
run after all dims in `Master.dtsx`.

## Backfill a date range

```sql
EXEC etl.usp_ResetWatermark @Source = N'Erp_SalesLine', @From = '2026-06-01';
```

Then run `Stg_LoadErp.dtsx` and `Dw_LoadFactSales.dtsx` (or the nightly job). The fact proc deletes
and reloads the affected date keys, so overlaps don't duplicate. For large ranges, run month by
month — see [jobs](modules/jobs.md#gotchas).
