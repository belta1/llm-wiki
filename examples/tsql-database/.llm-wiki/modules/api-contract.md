---
updated: 2026-09-25
covers: [api, contract, seam, security]
status: current
---

# Api schema — the app ↔ database contract

**The only surface the Orders app may call.** The app (separate repo, Dapper) maps these parameters
and result sets by name. Anything not listed here is private and may change freely.

## Key files

- `src/OrdersDb/Api/StoredProcedures/*.sql` · `src/OrdersDb/Api/Views/*.sql`
- `src/OrdersDb/Api/UserDefinedTypes/OrderLineList.sql` — table type for order lines
- `src/OrdersDb/Security/AppRole.sql` — `GRANT EXECUTE ON SCHEMA::Api` + `SELECT ON SCHEMA::Api`

## Contract

| Object | Params | Returns | Errors (`THROW`) |
|--------|--------|---------|------------------|
| `Api.usp_PlaceOrder` | `@CustomerId int`, `@Lines Api.OrderLineList` | 1 row: `OrderId`, `Total`, `StatusCode` | 50101 unknown customer · 50102 empty order · 50103 bad quantity |
| `Api.usp_GetOrder` | `@OrderId int` | RS1 header (`OrderId, CustomerId, StatusCode, Total, CreatedAt`), RS2 lines (`Sku, Quantity, UnitPrice`) | 50201 not found |
| `Api.usp_CancelOrder` | `@OrderId int`, `@RowVersion binary(8)` | none | 50301 not found · 50302 not cancellable · 50303 concurrency conflict |
| `Api.vw_OrderSummary` | — | `OrderId, CustomerEmail, StatusCode, Total, CreatedAt` | — |

`StatusCode` is the `Ref.OrderStatus.Code` string (`PENDING`, `PAID`, …), never the numeric id.

## Changing the contract

- **Additive only within a release:** new optional params (with defaults) and new trailing result
  columns are safe. Removing/renaming params or columns, or changing types, is breaking.
- To break: add `usp_<Name>V2`, ship the app on it, then delete the old proc in a later release.
- Error numbers are part of the contract — the app switches on them. Reserve a new `50x00` block per
  proc and add it to the table above.

## Gotchas

- Result-set **column order** doesn't matter to the app, **names** do.
- `Api` views must not expose `Sales.Customer` rows with `IsDeleted = 1`.
- Every change here needs a tSQLt test ([recipes](../recipes.md#add-a-tsqlt-test)) and a note in the
  app repo's changelog.

## Related

- [sales](sales.md) · [architecture](../architecture.md) · [recipes](../recipes.md#add-an-api-procedure)
