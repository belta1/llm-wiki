---
updated: 2026-09-25
covers: [architecture, deploy]
status: current
---

# Architecture

A **state-based** database project. Nothing in `src/` is a migration: each `.sql` file is one
object's `CREATE` statement describing how it should look. The build validates the whole model
(unresolved references fail the build) and emits a `.dacpac`; `sqlpackage` compares that to a live
database and generates the change script.

## Deploy flow

```
src/OrdersDb/**/*.sql  ─ dotnet build ─▶  OrdersDb.dacpac
                                              │
             profiles/<env>.publish.xml ──────┤  (target DB, SQLCMD vars, options)
                                              ▼
                     sqlpackage /Action:Script   → preview .sql   (review this)
                     sqlpackage /Action:Publish  → PreDeployment.sql
                                                  → generated ALTER/CREATE/sp_rename
                                                  → PostDeployment.sql (reference data)
```

Test/prod publishes run **only** from `azure-pipelines.yml` (manual approval on prod); locally you
publish to the Docker instance with `Local.publish.xml`.

## Schemas

- **`Sales`** — the tables and internal procs. Owned by this repo; the app never touches it directly.
  See [sales](modules/sales.md).
- **`Api`** — thin procs/views over `Sales`: the **contract** with the app. `AppRole` has `EXECUTE`
  on `SCHEMA::Api` and nothing else. See [api-contract](modules/api-contract.md).
- **`Ref`** — lookup tables whose rows are code, seeded by post-deploy MERGE scripts. See
  [reference-data](modules/reference-data.md).
- **`tSQLt` + `test_*`** — exist only in the test database (`tests/OrdersDb.Tests` references the
  main dacpac + `tSQLt.dacpac`). Never in a real environment.

## SQLCMD variables

Declared in `OrdersDb.sqlproj`, valued per profile: `$(Environment)` (`Local`/`Test`/`Prod`, gates
post-deploy test data) and `$(AuditDb)` (cross-database reference used by `Sales.usp_WriteAudit`).

## Key decisions & constraints

- **`BlockOnPossibleDataLoss=True`** in every profile. A publish that would drop a column with data
  fails — that is intended. Handle it with a pre-deploy data move, not by flipping the flag.
- **`DropObjectsNotInSource=False`** in `Prod.publish.xml` — objects removed from source are **not**
  dropped in prod automatically; a DBA drops them after confirming nothing calls them.
- The app is versioned independently, so `Api` changes must be **backward compatible** for one
  release (add, don't change; see [api-contract](modules/api-contract.md)).
