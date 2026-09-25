---
updated: 2026-09-25
covers: [recipes, how-to, deploy, tsql]
status: current
---

# Recipes

Commands assume the repo root and PowerShell or bash. `$DACPAC` =
`src/OrdersDb/bin/Debug/OrdersDb.dacpac`.

## Set up

```bash
cp .env.example .env              # set MSSQL_SA_PASSWORD
docker compose up -d sql          # SQL Server 2022 on localhost,1433
dotnet tool restore               # installs the pinned sqlpackage
```

## Build

```bash
dotnet build src/OrdersDb/OrdersDb.sqlproj      # → $DACPAC ; fails on unresolved references (SQL71501/71502)
```

## Preview what a publish will do

Always do this before publishing to a shared environment, and read the output.

```bash
dotnet sqlpackage /Action:Script /SourceFile:$DACPAC /Profile:profiles/Local.publish.xml /OutputPath:deploy-preview.sql
dotnet sqlpackage /Action:DeployReport /SourceFile:$DACPAC /Profile:profiles/Local.publish.xml /OutputPath:deploy-report.xml
```

Red flags in the preview: a table rebuild (`tmp_ms_xx_`), `DROP` of anything you didn't delete, or a
drop+create where you expected a rename.

## Publish to local

```bash
dotnet sqlpackage /Action:Publish /SourceFile:$DACPAC /Profile:profiles/Local.publish.xml /TargetPassword:$MSSQL_SA_PASSWORD
```

Test/prod are published by `azure-pipelines.yml` only.

## Run tests (tSQLt)

```bash
dotnet build tests/OrdersDb.Tests/OrdersDb.Tests.sqlproj
dotnet sqlpackage /Action:Publish /SourceFile:tests/OrdersDb.Tests/bin/Debug/OrdersDb.Tests.dacpac /Profile:profiles/Local.publish.xml /TargetPassword:$MSSQL_SA_PASSWORD
sqlcmd -S localhost,1433 -U sa -P "$MSSQL_SA_PASSWORD" -C -d OrdersDb -b -Q "EXEC tSQLt.RunAll"
sqlcmd … -Q "EXEC tSQLt.Run 'test_PlaceOrder'"                              # one class
sqlcmd … -Q "EXEC tSQLt.Run 'test_PlaceOrder.[test rejects empty order]'"    # one test
```

(`-C` trusts the container's self-signed cert; `-b` makes failures return a non-zero exit code.)

## Lint

```bash
sqlfluff lint src --dialect tsql       # sqlfluff fix src --dialect tsql to autofix
```

## Add a table or column

1. Create/edit `src/OrdersDb/<Schema>/Tables/<Name>.sql` as a full `CREATE TABLE` with named
   constraints ([conventions](conventions.md#naming)). **Adding a column = editing the CREATE.**
2. New `NOT NULL` column on a table with rows → give it a named default (`DF_…`) or the publish
   blocks on possible data loss.
3. Build, [preview](#preview-what-a-publish-will-do), publish locally, run tests.

## Add an API procedure

1. Add `src/OrdersDb/Api/StoredProcedures/usp_<Verb><Noun>.sql` using the proc shape in
   [conventions](conventions.md#procedure-shape); read/write `Sales` tables inside it.
2. Pick an unused `THROW` range and record the proc, params, result set, and errors in
   [api-contract](modules/api-contract.md).
3. Add a `test_<Proc>` class in `tests/OrdersDb.Tests/` ([below](#add-a-tsqlt-test)).
4. `AppRole` already has `EXECUTE ON SCHEMA::Api` — no new grant needed.

## Add or change reference data

See [reference-data](modules/reference-data.md): edit the MERGE in
`src/OrdersDb/Scripts/PostDeployment/RefData/<Table>.sql`; it runs on every publish.

## Rename a column or object safely

1. In Visual Studio / VS Code SQL Database Projects: right-click the name → **Rename** (or
   *Refactor → Rename*). This edits the file **and** appends to `OrdersDb.refactorlog`.
2. Commit both files. The preview should show `sp_rename`, not `DROP`/`CREATE`.
3. Renaming an `Api` object breaks the app — add the new name and keep the old one for a release
   instead ([api-contract](modules/api-contract.md#changing-the-contract)).

## Add a tSQLt test

1. `tests/OrdersDb.Tests/test_<Proc>/test_<Proc>.sql` — `EXEC tSQLt.NewTestClass 'test_<Proc>';`
   (existing classes show the pattern).
2. Add `CREATE PROCEDURE test_<Proc>.[test <behaviour>]` files: `tSQLt.FakeTable` the `Sales`
   tables, call the proc, assert with `tSQLt.AssertEqualsTable` / `tSQLt.ExpectException`.
3. Build + publish the test project, then run the class (see [Run tests](#run-tests-tsqlt)).

## Add a dependency on another database

Add an `<ArtifactReference>` (or `<PackageReference>` to a dacpac package) in `OrdersDb.sqlproj` with
a `DatabaseSqlCmdVariable`, declare the variable, set it in every profile, and reference objects as
`[$(VarName)].schema.object`.
