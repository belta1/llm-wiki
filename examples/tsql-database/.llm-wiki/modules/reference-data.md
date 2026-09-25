---
updated: 2026-09-25
covers: [reference-data, lookups, post-deploy]
status: current
---

# Reference data

Lookup tables whose **rows are code**: defined in source control and re-applied on every publish by
the post-deploy script.

## Key files & entry points

- `src/OrdersDb/Ref/Tables/OrderStatus.sql` · `OrderStatusTransition.sql` — the lookup tables.
- `src/OrdersDb/Scripts/PostDeployment/Script.PostDeployment.sql` — entry; `:r` includes each file
  below, in dependency order.
- `src/OrdersDb/Scripts/PostDeployment/RefData/OrderStatus.sql` — `MERGE` of the canonical rows.
- `src/OrdersDb/Scripts/PostDeployment/TestData/*.sql` — sample customers/orders; included only
  when `'$(Environment)' = 'Local'`.

## How it works

Each RefData file is a `MERGE Ref.<Table> AS t USING (VALUES …) AS s ON t.Id = s.Id WHEN MATCHED …
WHEN NOT MATCHED BY TARGET … INSERT`, so it's idempotent and runs safely on every publish. Rows are
keyed by a fixed `Id` (no `IDENTITY` on Ref tables) so ids match across environments.

## Gotchas

- **No `WHEN NOT MATCHED BY SOURCE THEN DELETE`** — removing a status that old orders reference would
  fail the FK. Retire a value with `IsActive = 0` instead.
- Order of `:r` lines matters: `OrderStatus` before `OrderStatusTransition`.
- The post-deploy script is **not** an object; it's excluded from the model (`<PostDeploy>` in the
  `.sqlproj`). Syntax errors show up only at publish time — publish locally before pushing.
- `TestData/` must stay behind the `$(Environment)` guard — it would insert fake orders in prod.

## Related

- [sales](sales.md) · [glossary](../glossary.md) · [conventions](../conventions.md#do--dont)
