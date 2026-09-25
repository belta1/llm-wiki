---
updated: 2026-09-25
covers: [billing, invoices, schema]
status: current
---

# billing schema

The core invoicing data and the internal functions that maintain it. Private to the database: the
service reaches it only through [api-contract](api-contract.md).

## Key files & entry points

- `db/20_tables/billing/customer.sql` — customers; `email` unique via `lower(email)` index;
  soft delete (`deleted_at`).
- `db/20_tables/billing/invoice.sql` — header; `status` → `billing.invoice_status`; `total` is
  derived.
- `db/20_tables/billing/invoice_line.sql` — lines; `quantity > 0`; FK `ON DELETE CASCADE`.
- `db/20_tables/billing/payment.sql` — payments; `amount > 0`; many per invoice.
- `db/30_functions/billing/recalculate_invoice_total.sql` — the only writer of `invoice.total`.
- `db/90_seed/currency.sql` · `db/90_seed/invoice_status.sql` — lookup rows via `ON CONFLICT`.

## Database objects

| Object | Kind | Notes |
|--------|------|-------|
| `billing.customer` | table | soft delete — filter `deleted_at IS NULL` everywhere |
| `billing.invoice` | table | `total numeric(19,4)` derived; `version int` for optimistic locking |
| `billing.invoice_line` | table | large; see [safe changes](../recipes.md#change-a-big-table-safely) |
| `billing.payment` | table | large; partitioned monthly by `paid_at` ([maintenance](maintenance.md)) |
| `billing.recalculate_invoice_total(bigint)` | function | called by every api function touching lines |
| `billing.invoice_status` / `billing.currency` | lookup tables | rows are code — seeded, not edited by hand |

## How it works

`api` functions validate input, write `invoice`/`invoice_line` in one transaction, then call
`billing.recalculate_invoice_total`. Status transitions are checked against
`billing.invoice_status_transition` (seeded). Payments move an invoice to `paid` once
`sum(payment.amount) >= total`.

## Reference data

Edit the `INSERT … ON CONFLICT DO UPDATE` in `db/90_seed/<table>.sql`; it re-runs every deploy.
Removing a row is a one-shot change (it may be referenced).

## Gotchas

- **Don't update `invoice.total` directly** — always via `recalculate_invoice_total`.
- `customer` is soft-deleted; forgetting `deleted_at IS NULL` returns deleted customers.
- Adding a column means editing the `CREATE TABLE` **and** adding `ADD COLUMN IF NOT EXISTS`
  ([conventions](../conventions.md#idempotency-idioms-object-scripts)).
- Row-level security is **off** here; access control is the `api` schema boundary.

## Related

- [api-contract](api-contract.md) · [maintenance](maintenance.md) · [conventions](../conventions.md) · [recipes](../recipes.md#add-a-table-or-column)
