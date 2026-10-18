---
updated: 2026-09-25
covers: [overview, navigation]
status: current
wiki_contract: 2
---

# Index — orders-db

The **SQL Server database** behind the Orders app, as a state-based **SDK-style database project**
(`Microsoft.Build.Sql`). The `.sql` files declare the desired schema; publishing diffs a built
`.dacpac` against the target and generates the ALTERs. The app lives in another repo and may only
call the `Api` schema. **Read this first, then open the files it points to.**

## Stack

- **Target:** SQL Server 2022 (`<DSP>` Sql160 in `OrdersDb.sqlproj`); local via `docker compose up -d sql`
- **Toolchain:** .NET 8 SDK + `sqlpackage` as a local dotnet tool (`.config/dotnet-tools.json` →
  `dotnet tool restore`)
- **Build:** `dotnet build src/OrdersDb/OrdersDb.sqlproj` → `src/OrdersDb/bin/Debug/OrdersDb.dacpac`
- **Preview deploy:** `dotnet sqlpackage /Action:Script … /Profile:profiles/Local.publish.xml` —
  see [recipes](recipes.md#preview-what-a-publish-will-do)
- **Publish (local):** `dotnet sqlpackage /Action:Publish … /Profile:profiles/Local.publish.xml`
- **Test:** tSQLt — `EXEC tSQLt.RunAll` after publishing `tests/OrdersDb.Tests` · single class:
  `EXEC tSQLt.Run 'test_PlaceOrder'`
- **Lint:** `sqlfluff lint src --dialect tsql` (config `.sqlfluff`)
- **CI (ground truth):** `azure-pipelines.yml` — build → publish to a throwaway container → tSQLt

## Map

| Area | Key files / dirs | Purpose | More |
|------|------------------|---------|------|
| Project | `src/OrdersDb/OrdersDb.sqlproj` `profiles/*.publish.xml` | build settings, SQLCMD vars, per-env deploy options | [architecture](architecture.md) |
| Sales | `src/OrdersDb/Sales/` | core tables + internal procs (orders, lines, customers) | [sales](modules/sales.md) |
| Api (contract) | `src/OrdersDb/Api/` `src/OrdersDb/Security/` | the only procs/views the app may call; `AppRole` grants | [api-contract](modules/api-contract.md) |
| Reference data | `src/OrdersDb/Ref/` `src/OrdersDb/Scripts/PostDeployment/` | lookup tables + MERGE seed scripts | [reference-data](modules/reference-data.md) |
| Renames | `src/OrdersDb/OrdersDb.refactorlog` | makes publish emit `sp_rename`, not drop+create | [recipes](recipes.md#rename-a-column-or-object-safely) |
| Tests | `tests/OrdersDb.Tests/` | tSQLt test classes, one per Api proc | [recipes](recipes.md#add-a-tsqlt-test) |

## Where to start by task

- **Add a column / table** → [recipes](recipes.md#add-a-table-or-column), [sales](modules/sales.md)
- **Expose something new to the app** → [api-contract](modules/api-contract.md), [recipes](recipes.md#add-an-api-procedure)
- **Change a lookup value** → [reference-data](modules/reference-data.md)
- **Rename anything** → [recipes](recipes.md#rename-a-column-or-object-safely) (never by hand)
- **See what a deploy will do** → [recipes](recipes.md#preview-what-a-publish-will-do)

## Also see

- [architecture](architecture.md) · [conventions](conventions.md) · [glossary](glossary.md) · [log](log.md)
