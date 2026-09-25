---
updated: 2026-09-25
covers: [conventions, patterns, postgres]
status: current
---

# Conventions

## Structure

- Object scripts: `db/<NN>_<kind>/<schema>/<name>.sql`, one object per file
  (`db/20_tables/billing/invoice.sql`, `db/30_functions/api/create_invoice.sql`).
- **A new file does nothing until it's added to `db/deploy.sql`** as `\ir <path>` in dependency
  order. `\ir` resolves relative to `deploy.sql`, so paths start at `db/`.
- One-shot changes: `db/changes/YYYY-MM-DD_<slug>.sql`; never edit one after it has been merged.

## Naming

- `snake_case` everything; never quoted identifiers. Tables singular (`billing.invoice`), key
  column `id`, foreign keys `<table>_id`.
- Constraints/indexes follow Postgres defaults, spelled out explicitly: `invoice_pkey`,
  `invoice_customer_id_fkey`, `invoice_customer_id_idx`, `invoice_line_quantity_check`.
- Always schema-qualify; scripts don't rely on `search_path` (it's set to `''` in `SECURITY DEFINER`
  functions anyway).

## Types

- `bigint GENERATED ALWAYS AS IDENTITY` for keys (no `serial`); `timestamptz` only (no `timestamp`);
  `text` + `CHECK` for bounded strings; money is `numeric(19,4)` with a `currency_code char(3)`.
- Status columns are `text` FKs to lookup tables (`billing.invoice_status.code`), not enums — enum
  changes can't run in the single deploy transaction.

## Idempotency idioms (object scripts)

```sql
CREATE TABLE IF NOT EXISTS billing.invoice ( … );
ALTER TABLE billing.invoice ADD COLUMN IF NOT EXISTS due_on date;
CREATE INDEX IF NOT EXISTS invoice_customer_id_idx ON billing.invoice (customer_id);
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'invoice_due_on_check') THEN
    ALTER TABLE billing.invoice ADD CONSTRAINT invoice_due_on_check CHECK (due_on >= issued_on::date);
  END IF;
END $$;
CREATE OR REPLACE FUNCTION api.get_invoice(p_invoice_id bigint) RETURNS … ;
INSERT INTO billing.currency (code, name) VALUES ('EUR', 'Euro')
  ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name;
```

A column added to the `CREATE TABLE` must **also** get an `ADD COLUMN IF NOT EXISTS` line below it,
or existing databases never receive it.

## Function shape

- `LANGUAGE plpgsql`, `SECURITY DEFINER`, `SET search_path = ''`, explicit volatility
  (`STABLE` for readers). Arguments prefixed `p_`, locals `v_`.
- Business-rule failures: `RAISE EXCEPTION '<message>' USING ERRCODE = 'BLnnn'` — codes per function
  in [api-contract](modules/api-contract.md). The service switches on `SQLSTATE`, not the message.
- Set-based SQL; no row-by-row loops over invoices.

## Tooling & config locations

- **Driver:** `scripts/deploy.sh` (+ `Makefile` targets). `pg_service.conf.example` lists services.
- **Lint:** `.sqlfluff` (`dialect = postgres`, lowercase keywords); `squawk` on `db/changes/` only
  (object scripts are idempotent DDL it misreads).
- **Local server:** `docker/Dockerfile` (postgres:16 + `postgresql-16-cron` + `postgresql-16-pgtap`).

## Do / don't

- ✅ Run every `psql` with `-X -v ON_ERROR_STOP=1`.
- ✅ Put destructive changes, backfills, `CONCURRENTLY` indexes on big tables in `db/changes/`.
- ❌ Don't `DROP TABLE`/`DROP COLUMN` in object scripts.
- ❌ Don't grant `billing_app` anything outside `api`.
- ❌ Don't hard-code hosts, database names or passwords — use `PGSERVICE` and psql variables.
