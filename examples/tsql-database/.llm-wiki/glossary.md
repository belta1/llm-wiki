---
updated: 2026-09-25
covers: [glossary, domain, tsql]
status: current
---

# Glossary

- **dacpac** — the build output (`OrdersDb.dacpac`): a zipped model of every object. The unit that
  gets deployed, not a script.
- **Publish** — `sqlpackage /Action:Publish`: diff the dacpac against a live DB and apply the
  generated script. **Script** / **DeployReport** are the dry-run variants.
- **Publish profile** — `profiles/<env>.publish.xml`: target DB, SQLCMD variable values, deploy
  options (`BlockOnPossibleDataLoss`, `DropObjectsNotInSource`).
- **Refactorlog** — `OrdersDb.refactorlog`: rename history, so publish emits `sp_rename` instead of
  drop+create (which would lose data).
- **Pre/post-deploy** — scripts that run before/after the generated diff on every publish; must be
  idempotent. Post-deploy seeds [reference data](modules/reference-data.md).
- **Api schema** — the procs/views the app may call; the [contract](modules/api-contract.md).
- **AppRole** — the database role the app's login is in; `EXECUTE` on `SCHEMA::Api` only.
- **Order** — a customer purchase (`Sales.Order`) with one or more **OrderLines**; lifecycle tracked
  by **OrderStatus** (`Ref.OrderStatus`: Pending → Paid → Shipped, or Cancelled).
- **tSQLt test class** — a schema (`test_<Proc>`) holding `[test …]` procs; run with `tSQLt.Run`.
