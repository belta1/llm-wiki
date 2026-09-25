---
updated: 2026-09-25
covers: [glossary, domain, postgres]
status: current
---

# Glossary

- **Run list** — `db/deploy.sql`: the ordered `\ir` includes of every re-runnable object script.
- **Object script** — a re-runnable, idempotent script in the run list (`CREATE … IF NOT EXISTS`,
  `CREATE OR REPLACE`, `ON CONFLICT`).
- **One-shot change** — `db/changes/<date>_<slug>.sql`, applied once per database and recorded in
  `ops.applied_change` (filename, sha256, applied_at).
- **`ON_ERROR_STOP`** — psql variable; without it psql continues after errors and exits 0.
- **Service** — a named connection in `pg_service.conf` (`billing_local`, `billing_dev`,
  `billing_prod`), selected with `PGSERVICE`.
- **api schema** — the functions/views the Billing service may call; the
  [contract](modules/api-contract.md).
- **BL codes** — custom `SQLSTATE`s (`BL001`…) raised by `api` functions.
- **Invoice** — a bill to a customer (`billing.invoice`) with **invoice lines**; lifecycle
  `draft → issued → paid`, or `void`; `overdue` is set nightly by `pg_cron`.
- **Payment** — money received against an invoice (`billing.payment`); partial payments allowed.
- **pgTAP** — the SQL unit-test framework in `db/tests/`; run with `pg_prove`.
