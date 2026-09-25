---
updated: 2026-09-25
covers: [recipes, how-to, deploy, postgres]
status: current
---

# Recipes

Commands assume the repo root and bash. `PGSERVICE` picks the target (default in the `Makefile`:
`billing_local`).

## Set up

```bash
cp pg_service.conf.example ~/.pg_service.conf   # or export PGSERVICEFILE=$PWD/pg_service.conf
cp .env.example .env                            # POSTGRES_PASSWORD for the container
docker compose up -d db                         # postgres:16 + pg_cron + pgtap on localhost:5432
psql -X -v ON_ERROR_STOP=1 service=billing_local_super -f db/bootstrap/roles.sql   # once per server
make deploy ENV=local
```

## Deploy

```bash
make deploy ENV=local          # = PGSERVICE=billing_local scripts/deploy.sh
make db-reset                  # local only: drop the volume, re-create, bootstrap roles, deploy
```

Under the hood: `psql -X -v ON_ERROR_STOP=1 -1 -f db/deploy.sql`, then each pending
`db/changes/*.sql`. **Never** run `psql -f` without `-v ON_ERROR_STOP=1`. Dev/prod deploys run only
from `.github/workflows/deploy.yml`.

## Preview what a deploy will change

There's no diff tool, so compare schema dumps:

```bash
pg_dump -s service=billing_dev > before.sql          # schema only
make db-reset && pg_dump -s service=billing_local > after.sql
diff before.sql after.sql
```

Or run a script inside a transaction you roll back:
`psql -X -v ON_ERROR_STOP=1 service=billing_local -c 'BEGIN' -f db/changes/<file>.sql -c 'ROLLBACK'`.

## Run tests (pgTAP)

```bash
make test                                                  # PGSERVICE=billing_local pg_prove -r db/tests/
PGSERVICE=billing_local pg_prove db/tests/api_create_invoice.sql   # one file
```

Tests wrap themselves in `BEGIN; … ROLLBACK;`, so they leave no data behind.

## Lint

```bash
make lint      # sqlfluff lint db --dialect postgres && squawk db/changes/*.sql
```

## Add a table or column

1. New table: `db/20_tables/billing/<name>.sql` with `CREATE TABLE IF NOT EXISTS`, named
   constraints ([conventions](conventions.md#naming)); add `\ir 20_tables/billing/<name>.sql` to
   `db/deploy.sql` **before** anything that references it.
2. New column on an existing table: add it to the `CREATE TABLE` **and** an
   `ALTER TABLE … ADD COLUMN IF NOT EXISTS` line below it. `NOT NULL` needs a `DEFAULT` (or a
   one-shot backfill first).
3. `make db-reset && make deploy ENV=local` (second deploy must be a no-op), then `make test`.

## Add an API function

1. `db/30_functions/api/<verb>_<noun>.sql` using the [function shape](conventions.md#function-shape);
   if you change an existing function's **arguments**, add `DROP FUNCTION IF EXISTS api.<old
   signature>;` first (otherwise you create an overload).
2. Add it to `db/deploy.sql`; add `GRANT EXECUTE ON FUNCTION … TO billing_app` in
   `db/50_grants/api.sql`.
3. Pick unused `BLnnn` codes and record signature, return shape and errors in
   [api-contract](modules/api-contract.md).
4. Add `db/tests/api_<verb>_<noun>.sql` ([below](#add-a-pgtap-test)).

## Add a one-shot change

For backfills, drops, renames, type changes — anything that shouldn't run twice.

1. `db/changes/$(date +%F)_<slug>.sql`. It runs in one transaction unless the first line is
   `-- no-transaction`.
2. Make the matching object scripts reflect the end state (e.g. remove a dropped column from the
   `CREATE TABLE`).
3. `make deploy ENV=local` twice — the second run must skip it (check `ops.applied_change`).

## Change a big table safely

`billing.invoice_line` and `billing.payment` are large; long `ACCESS EXCLUSIVE` locks take the service
down.

- Indexes: a one-shot change starting `-- no-transaction` with `CREATE INDEX CONCURRENTLY IF NOT
  EXISTS …`; then add the plain `CREATE INDEX IF NOT EXISTS` to the object script for fresh DBs.
- Constraints: `ADD CONSTRAINT … NOT VALID` in one change, `VALIDATE CONSTRAINT` in a later one.
- Start each such change with `SET lock_timeout = '5s';` so it fails instead of queueing.

## Add a pgTAP test

1. `db/tests/<area>_<name>.sql`: `BEGIN; SELECT plan(n); … SELECT * FROM finish(); ROLLBACK;`.
2. Use `has_function`, `results_eq`, `throws_ok(<sql>, 'BL001')`; insert fixtures inside the test.
3. `PGSERVICE=billing_local pg_prove db/tests/<file>.sql`.

## Add a scheduled job

See [maintenance](modules/maintenance.md#add-a-job).
