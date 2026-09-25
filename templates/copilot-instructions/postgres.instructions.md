---
applyTo: "**/*.sql"
description: PostgreSQL / psql script guidance from the llm-wiki knowledge base (installed by llm-wiki; re-running the installer replaces this file).
---

# PostgreSQL files in this repo

> If the `.llm-wiki/index.md` Stack block says this repo's SQL (or this folder's SQL) is **T-SQL /
> SQL Server**, ignore this file for those files.

Before editing SQL, open `.llm-wiki/index.md` and the module page for the schema you're touching —
it lists the objects, who calls them, and the gotchas. Follow `.llm-wiki/conventions.md` for naming,
types, and error codes; use `.llm-wiki/recipes.md` for deploy / reset / test commands. If the wiki and
the code disagree, the code wins.

**Work out how this file is deployed first** (the index Stack block says):

- **psql script repo** — scripts run from a run list (`\ir` lines in `deploy.sql`, numbered folders,
  or a driver script).
  - Object scripts re-run on every deploy, so they must be **idempotent**: `CREATE TABLE IF NOT
    EXISTS`, `ALTER TABLE … ADD COLUMN IF NOT EXISTS`, `CREATE OR REPLACE FUNCTION/VIEW`,
    `DROP … IF EXISTS`, `DO $$ … $$` guards, `INSERT … ON CONFLICT` for seed data.
  - Destructive or data-moving changes go in the repo's **one-shot change** mechanism (see the wiki),
    not in re-runnable object scripts.
  - **Register new files in the run list** in dependency order; an unlisted script never runs.
  - Deploys use `psql -X -v ON_ERROR_STOP=1 …` — never suggest a psql call without `ON_ERROR_STOP`.
- **Migration tool** (Sqitch, Flyway, dbmate, …) — add a **new** migration with the tool's naming
  scheme; never edit one that has been applied.

**General PostgreSQL rules** (unless `.llm-wiki/conventions.md` says otherwise):

- `snake_case` identifiers, never quoted mixed case; schema-qualify objects rather than relying on
  `search_path`.
- Types: `timestamptz` (not `timestamp`), `text` (not `varchar(n)` without a reason),
  `bigint GENERATED … AS IDENTITY` (not `serial`), `jsonb` (not `json`), `numeric` for money.
- Name constraints and indexes explicitly (`<table>_pkey`, `<table>_<col>_fkey`, `<table>_<col>_idx`,
  or the repo's scheme).
- Functions: declare volatility (`STABLE`/`IMMUTABLE`) where true; `SECURITY DEFINER` functions must
  `SET search_path`; raise errors with `RAISE EXCEPTION … USING ERRCODE = '<code>'` using the repo's
  codes. Functions and views an application calls are a **contract** — changing arguments, return
  columns or error codes is breaking; check the wiki's contract page.
- Large tables: `CREATE INDEX CONCURRENTLY` (outside a transaction), `ADD CONSTRAINT … NOT VALID`
  then `VALIDATE CONSTRAINT`, and a `SET lock_timeout` — avoid long `ACCESS EXCLUSIVE` locks.
- Grant explicitly to the repo's roles; keep RLS policies next to their table. Never hard-code
  passwords, hosts, or environment names — use psql variables (`:'var'`) or `PG*` env vars.
- Set-based over row-by-row loops in PL/pgSQL.

After a substantive schema change, update the affected `.llm-wiki/` pages and append to
`.llm-wiki/log.md`: `## [YYYY-MM-DD] update | <summary>`.
