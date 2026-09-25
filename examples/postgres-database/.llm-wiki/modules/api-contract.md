---
updated: 2026-09-25
covers: [api, contract, seam, security]
status: current
---

# api schema — the service ↔ database contract

**The only surface the Billing service may call.** The service (Node, `pg` driver, separate repo)
connects as `billing_app` and calls these functions with positional parameters, mapping result
columns by name. Anything not listed here is private and may change freely.

## Key files

- `db/30_functions/api/*.sql` · `db/40_views/api/*.sql`
- `db/50_grants/api.sql` — `GRANT USAGE ON SCHEMA api`, `EXECUTE` per function, `SELECT` on views
- Service side (other repo): `src/db/billing.ts` — the only file that calls these

## Contract

| Object | Arguments | Returns | Errors (`SQLSTATE`) |
|--------|-----------|---------|---------------------|
| `api.create_invoice` | `p_customer_id bigint, p_currency char(3), p_lines jsonb` | `TABLE(invoice_id bigint, total numeric, status text)` | BL001 unknown customer · BL002 empty lines · BL003 bad quantity · BL004 unknown currency |
| `api.issue_invoice` | `p_invoice_id bigint, p_version int` | `TABLE(status text, due_on date)` | BL101 not found · BL102 not draft · BL103 version conflict |
| `api.record_payment` | `p_invoice_id bigint, p_amount numeric, p_paid_at timestamptz` | `TABLE(payment_id bigint, status text, balance numeric)` | BL201 not found · BL202 invoice void · BL203 amount ≤ 0 |
| `api.get_invoice` | `p_invoice_id bigint` | `jsonb` (header + `lines` array) | BL301 not found |
| `api.invoice_summary` | view | `invoice_id, customer_email, status, total, balance, issued_on, due_on` | — |

`p_lines` is a JSON array of `{"sku": text, "quantity": int, "unit_price": "numeric-as-string"}`.
Unknown keys are ignored; missing keys raise BL003.

## Changing the contract

- **Additive only within a release:** new functions, new arguments **with defaults** at the end,
  new result columns. Removing/renaming arguments or columns, or changing types, is breaking.
- A changed argument list is a **new overload** in Postgres — add `DROP FUNCTION IF EXISTS` for the
  old signature only after the service has stopped calling it.
- `BL` codes are part of the contract; reserve a new `BLn00` block per function and list it above.

## Gotchas

- Functions are `SECURITY DEFINER` + `SET search_path = ''` — every name inside must be
  schema-qualified, or it fails at call time, not at deploy.
- `numeric` comes back to Node as a **string**; the service parses it. Don't switch to `float8`.
- New functions need an explicit `GRANT EXECUTE … TO billing_app` — default privileges cover
  views, not functions, here.

## Related

- [billing](billing.md) · [architecture](../architecture.md#roles) · [recipes](../recipes.md#add-an-api-function)
