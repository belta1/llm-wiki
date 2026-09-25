---
updated: 2026-09-25
covers: [architecture, deploy, postgres]
status: current
---

# Architecture

A **script-based** PostgreSQL repo. There is no diff engine and no migration tool: the scripts *are*
the deploy. Two kinds of script, with different rules:

- **Re-runnable object scripts** (everything listed in `db/deploy.sql`) run on **every** deploy, so
  each must be idempotent — safe on an empty database and on production alike.
- **One-shot changes** (`db/changes/YYYY-MM-DD_<slug>.sql`) run **once per database**, in filename
  order, and are recorded in `ops.applied_change`. Anything destructive, data-moving, or not
  expressible idempotently goes here.

## Deploy flow

```
scripts/deploy.sh  (PGSERVICE=billing_<env>)
  │
  ├─ psql -X -v ON_ERROR_STOP=1 -1 -f db/deploy.sql         one transaction, all-or-nothing
  │     \ir 00_extensions/  → 10_schemas/  → 20_tables/  → 30_functions/
  │     \ir 40_views/       → 50_grants/   → 60_cron/    → 90_seed/
  │
  └─ for f in db/changes/*.sql not in ops.applied_change:
        psql -X -v ON_ERROR_STOP=1 -1 -f "$f"  &&  INSERT INTO ops.applied_change(...)
        (files starting with `-- no-transaction` run without -1, e.g. CREATE INDEX CONCURRENTLY)
```

Order matters: tables before the functions that reference them (`LANGUAGE sql` bodies are checked
at create time), views after functions, grants after everything. Dev/prod deploys run only from
`.github/workflows/deploy.yml` (manual approval on prod).

## Schemas

- **`billing`** — tables and internal functions. Owned by `billing_owner`; the service can't touch
  it directly. See [billing](modules/billing.md).
- **`api`** — `SECURITY DEFINER` functions and views over `billing`: the **contract** with the
  service. See [api-contract](modules/api-contract.md).
- **`ops`** — deploy bookkeeping (`ops.applied_change`) and maintenance functions called by
  `pg_cron`. See [maintenance](modules/maintenance.md).

## Roles

Created once per cluster by `db/bootstrap/roles.sql` (superuser; **not** in the run list, because
roles are cluster-wide): `billing_owner` (owns all objects; deploys connect as it),
`billing_app` (the service; `USAGE` on `api` + `EXECUTE` on its functions only), `billing_readonly`
(analysts; `SELECT` on `api` views). `ALTER DEFAULT PRIVILEGES` in `50_grants/` keeps new objects
consistent.

## Key decisions & constraints

- **`-1` (single transaction) for the run list** — a failed deploy leaves nothing half-applied. The
  cost: nothing in `deploy.sql` may use `CONCURRENTLY` or other non-transactional commands.
- **CI deploys twice** to the same database. The second run must succeed with no changes — the
  practical test that every object script is idempotent.
- **No `DROP` in object scripts** except `DROP FUNCTION IF EXISTS` for signature changes (a changed
  argument list creates an overload otherwise). Dropping tables/columns is a one-shot change.
- The service is versioned independently, so `api` changes must stay **backward compatible** for one
  release (see [api-contract](modules/api-contract.md#changing-the-contract)).
