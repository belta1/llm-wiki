---
updated: 2026-09-25
covers: [conventions, patterns, tsql]
status: current
---

# Conventions

## Structure

- One object per file, path = `src/OrdersDb/<Schema>/<ObjectType>/<Name>.sql`
  (`Sales/Tables/Order.sql`, `Api/StoredProcedures/usp_PlaceOrder.sql`). SDK-style projects include
  every `*.sql` under the project dir by default — no need to edit the `.sqlproj` to add a file.
- Scripts that are *not* schema objects (pre/post-deploy, seed data) live under `Scripts/` and are
  marked `<None>` / `<PostDeploy>` in the `.sqlproj` so the build doesn't treat them as objects.

## Naming

- Tables singular PascalCase (`Sales.Order`, `Sales.OrderLine`); key column `<Table>Id` (`OrderId`).
- Procs `usp_<Verb><Noun>`, views `vw_<Noun>`, functions `ufn_<Noun>`.
- Constraints named explicitly — `PK_Order`, `FK_OrderLine_Order`, `IX_Order_CustomerId`,
  `DF_Order_CreatedAt`, `CK_OrderLine_Quantity`. Unnamed constraints get random names and cause
  noisy diffs.
- Always schema-qualify (`Sales.Order`, never `Order`); cross-DB refs via `[$(AuditDb)].dbo.X`.

## Procedure shape

```sql
CREATE PROCEDURE Api.usp_PlaceOrder @CustomerId INT, @Lines Api.OrderLineList READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRAN;
        -- …
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
```

- Business-rule failures use `THROW 50xxx, '<message>', 1;` — the number range per proc is listed in
  [api-contract](modules/api-contract.md). Don't use `RAISERROR`.
- Explicit column lists in every `SELECT`/`INSERT`; no `SELECT *` (it breaks the app's result
  mapping when a column is added).
- Dates are `datetime2(3)` in UTC (`SYSUTCDATETIME()`); money is `decimal(19,4)`.

## Tooling & config locations

- **Build/deploy:** `OrdersDb.sqlproj` (`<DSP>`, SQLCMD vars, suppressed warnings), `profiles/*.publish.xml`.
  Profiles contain **no passwords** — CI injects `/TargetConnectionString`; locally the password
  comes from `MSSQL_SA_PASSWORD` in `.env` (see `.env.example`).
- **Lint:** `.sqlfluff` (`dialect = tsql`, uppercase keywords, 4-space indent).
- **sqlpackage:** pinned in `.config/dotnet-tools.json`; run as `dotnet sqlpackage`.

## Testing

- tSQLt, one test class (schema) per Api proc: `test_PlaceOrder`, `test_GetOrder`, …, in
  `tests/OrdersDb.Tests/`. Isolate with `tSQLt.FakeTable` / `tSQLt.SpyProcedure`; never depend on
  seeded data except `Ref` tables.
- New or changed `Api` procs ship with tests. CI fails on any tSQLt failure.

## Do / don't

- ✅ Change a table by editing its `CREATE TABLE` — the dacpac diff writes the `ALTER`.
- ✅ Put data changes (backfills, lookup rows) in pre/post-deploy scripts, written idempotently.
- ❌ Don't write `ALTER TABLE` in `src/` or add migration-style scripts — the build will reject or
  double-apply them.
- ❌ Don't rename by editing names — use the refactorlog ([recipes](recipes.md#rename-a-column-or-object-safely)).
- ❌ Don't grant the app anything outside `SCHEMA::Api`.
