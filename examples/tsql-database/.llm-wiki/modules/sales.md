---
updated: 2026-09-25
covers: [sales, orders, schema]
status: current
---

# Sales schema

The core order data and the internal procs that maintain it. Private to the database: the app reaches
it only through [api-contract](api-contract.md).

## Key files & entry points

- `src/OrdersDb/Sales/Tables/Customer.sql` — customers; `Email` has a unique filtered index
  (`WHERE IsDeleted = 0`).
- `src/OrdersDb/Sales/Tables/Order.sql` — header; `StatusId` → `Ref.OrderStatus`; `RowVersion` for
  optimistic concurrency.
- `src/OrdersDb/Sales/Tables/OrderLine.sql` — lines; `CK_OrderLine_Quantity` (> 0).
- `src/OrdersDb/Sales/StoredProcedures/usp_RecalculateOrderTotal.sql` — the only writer of
  `Order.Total`.
- `src/OrdersDb/Sales/StoredProcedures/usp_WriteAudit.sql` — writes to `[$(AuditDb)].dbo.AuditEvent`.

## Database objects

| Object | Kind | Notes |
|--------|------|-------|
| `Sales.Customer` | table | soft delete (`IsDeleted`) — filter it everywhere |
| `Sales.Order` | table | `Total` is derived; `RowVersion rowversion` |
| `Sales.OrderLine` | table | FK to `Order` with `ON DELETE CASCADE` |
| `Sales.usp_RecalculateOrderTotal` | proc | called by every Api proc that touches lines |
| `Sales.usp_WriteAudit` | proc | cross-DB via `$(AuditDb)` |

## How it works

Api procs validate input, write `Order`/`OrderLine` inside one transaction, then call
`usp_RecalculateOrderTotal` and `usp_WriteAudit`. Status transitions are enforced in the Api layer
against `Ref.OrderStatusTransition` (see [reference-data](reference-data.md)).

## Gotchas

- **Don't update `Order.Total` directly** — always go through `usp_RecalculateOrderTotal`, or totals
  drift from lines.
- `Customer` is soft-deleted; forgetting `IsDeleted = 0` returns deleted customers.
- Changing `OrderLine`'s PK or clustering causes a **table rebuild** on publish — check the
  [preview](../recipes.md#preview-what-a-publish-will-do) and plan it with a DBA.
- `usp_WriteAudit` needs `$(AuditDb)` set in the profile; locally it points at `OrdersAudit` created
  by `docker/init.sql`.

## Related

- [api-contract](api-contract.md) · [reference-data](reference-data.md) · [conventions](../conventions.md) · [recipes](../recipes.md#add-a-table-or-column)
