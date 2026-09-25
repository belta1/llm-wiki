---
updated: 2026-09-25
covers: [overview, navigation]
status: current
---

# Index — billing-db

The **PostgreSQL 16 database** behind the Billing service, deployed from **plain `psql` scripts**
(no migration tool). `db/deploy.sql` is the run list: every object script in it re-runs on each
deploy and is written **idempotently**; destructive or data-moving changes are **one-shot** scripts
in `db/changes/`, applied once and tracked in `ops.applied_change`. The Billing service (Node,
separate repo) may only call the `api` schema. **Read this first, then open the files it points to.**

## Stack

- **Target:** PostgreSQL 16 + `pg_cron`, `pgcrypto`, `pg_trgm`; local via `docker compose up -d db`
  (image built from `docker/Dockerfile`, adds `pg_cron` + `pgtap`)
- **Toolchain:** `psql` 16, `make`, `pg_prove` (pgTAP), `sqlfluff`, `squawk`
- **Connection:** `PGSERVICE=billing_local|billing_dev|billing_prod` (entries in `pg_service.conf`
  from `pg_service.conf.example`); passwords in `~/.pgpass`, never in the repo
- **Deploy:** `make deploy ENV=local` → `scripts/deploy.sh`, which runs
  `psql -X -v ON_ERROR_STOP=1 -1 -f db/deploy.sql` then applies pending `db/changes/*.sql`
- **Reset local:** `make db-reset` (drops + recreates the container volume, then deploys)
- **Test:** `make test` → `PGSERVICE=billing_local pg_prove -r db/tests/` · single file:
  `PGSERVICE=billing_local pg_prove db/tests/api_create_invoice.sql`
- **Lint:** `make lint` → `sqlfluff lint db --dialect postgres` + `squawk db/changes/*.sql`
- **CI (ground truth):** `.github/workflows/db.yml` — Postgres service container, deploy **twice**
  (proves idempotency), pgTAP, lint

## Map

| Area | Key files / dirs | Purpose | More |
|------|------------------|---------|------|
| Run list | `db/deploy.sql` `scripts/deploy.sh` `Makefile` | order of every re-runnable script; the deploy driver | [architecture](architecture.md#deploy-flow) |
| Bootstrap | `db/bootstrap/roles.sql` | cluster-level roles; run once per server by a superuser | [architecture](architecture.md#roles) |
| Billing tables | `db/20_tables/billing/` | customers, invoices, lines, payments | [billing](modules/billing.md) |
| Api (contract) | `db/30_functions/api/` `db/40_views/api/` `db/50_grants/` | the only functions/views the service may call | [api-contract](modules/api-contract.md) |
| Seed data | `db/90_seed/` | `billing.currency`, `billing.invoice_status` via `ON CONFLICT` | [billing](modules/billing.md#reference-data) |
| One-shot changes | `db/changes/` `db/10_schemas/ops.sql` | backfills, drops, type changes; tracked in `ops.applied_change` | [recipes](recipes.md#add-a-one-shot-change) |
| Scheduled jobs | `db/60_cron/jobs.sql` `db/30_functions/ops/` | overdue marking, partition upkeep, cleanup | [maintenance](modules/maintenance.md) |
| Tests | `db/tests/*.sql` | pgTAP, one file per api function | [recipes](recipes.md#add-a-pgtap-test) |

## Where to start by task

- **Add a column / table** → [recipes](recipes.md#add-a-table-or-column), [billing](modules/billing.md)
- **Expose something new to the service** → [api-contract](modules/api-contract.md), [recipes](recipes.md#add-an-api-function)
- **Backfill / drop / change a type** → [recipes](recipes.md#add-a-one-shot-change)
- **Index a big table** → [recipes](recipes.md#change-a-big-table-safely)
- **A nightly job failed** → [maintenance](modules/maintenance.md#when-a-job-fails)

## Also see

- [architecture](architecture.md) · [conventions](conventions.md) · [glossary](glossary.md) · [log](log.md)
