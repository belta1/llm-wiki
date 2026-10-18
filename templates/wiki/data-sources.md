---
updated: YYYY-MM-DD
covers: [data, connections]
status: draft
---

# Data sources

The external data this repo reads and writes — **which** sources, **where** in the code, and the
repo-specific gotchas. _Keep this page only if the repo actually touches an external source; delete
it (plus its `index.md` links and its `README.md` Layout row) otherwise._

**Connection details are not here.** *How* to connect to a named source — driver, DSN, auth model,
which env var holds which credential — is recorded once per source in the user-global catalog
`~/.claude/llm-wiki/data-sources.md` (Windows: `%USERPROFILE%\.claude\llm-wiki\data-sources.md`),
shared across repos and never committed. This page records what *this* repo does with each one, and
joins to the catalog by **Name**.

**Never record a secret.** Env-var and key **names** only — no passwords, tokens, keys, presigned or
SAS URLs, or connection strings containing them. A credential found inlined in code goes under
Gotchas as `⚠ inlined in <path>` and gets reported, never copied.

_If internal hostnames can't be committed, use a role name here (`<prod-sales-db>`) and let the
uncommitted catalog hold the real host — the role name then becomes the join key._

## Sources this repo uses

| Name | Engine | Used by (code) | Direction | Objects / datasets | Catalog |
|------|--------|----------------|-----------|--------------------|---------|
| `SRVPLATDAT` | _SQL Server_ | `src/etl/extract.py` · [etl](modules/etl.md) | read | _`dbo.Sales`, `dbo.DimCustomer`_ | yes |
| `s3://corp-lake-raw` | _S3_ | `src/etl/land.py` | write | _`raw/sales/dt=<date>/*.parquet`_ | yes |
| `\\SRVFILES01\Finance` | _SMB share_ | `src/ingest/budget.py` | read | _`Budget_<FY>.xlsx`, dropped monthly_ | yes |
| `warehouse.duckdb` | _DuckDB_ | `src/analysis/` | read/write | _local build artifact_ | no (repo-local) |
| _..._ | _..._ | _..._ | _..._ | _..._ | _..._ |

- **Name** — the same match key as the global catalog: host, DSN, account, bucket or share root,
  broker/cluster, service base URL, or path for a repo-local store. **One row per source**, never per
  table, file or topic.
- **Used by (code)** — real paths, plus the module page that owns the access.
- **Direction** — `read` / `write` / `read/write`.
- **Objects / datasets** — the tables, prefixes, topics, file patterns or endpoints this repo
  actually touches — the few that matter, not an inventory.
- **Catalog** — `yes` if the source has a row in the user-global catalog; `no (repo-local)` for a
  store that exists only inside this repo or its dev environment.

## How data flows

_One short list: which source feeds which stage, and what this repo produces. Link to
[architecture](architecture.md) rather than restating it._

- _`SRVPLATDAT.dbo.Sales` → `src/etl/extract.py` → `s3://corp-lake-raw/raw/sales/` →
  `warehouse.duckdb` → the report._

## Gotchas & constraints

- _Non-obvious constraints an agent must know before touching data access: refresh windows ("the
  Finance share is only written on the 3rd working day"), row/size limits, timeouts, replica lag,
  partition layout, rate limits, cost, and any `⚠ inlined in <path>` credential found._

<!-- Optional. Delete if this repo has no local/dev substitute for its real sources.
## Local / dev substitutes

| Real source | Substitute | How to use it |
|-------------|------------|---------------|
| `SRVPLATDAT` | _`docker compose up -d sql` + `db/seed.sql`_ | _set `APP_DB_HOST=localhost`_ |
| `s3://corp-lake-raw` | _`./.data/raw/` (same layout)_ | _set `STORAGE_BACKEND=local`_ |
-->

<!-- Optional. Delete if nothing here is refreshed on a schedule.
## Refresh / schedule

| Source | Refreshed by | When |
|--------|--------------|------|
| `s3://corp-lake-raw` | _`slurm/land.sbatch`_ | _nightly 02:00_ |
-->

## Related

- [architecture](architecture.md) · [recipes](recipes.md) · [conventions](conventions.md)
- The per-module **Data sources used** blocks under [`modules/`](modules/)
