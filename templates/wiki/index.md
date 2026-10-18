---
updated: YYYY-MM-DD
covers: [overview, navigation]
status: draft
wiki_contract: 2
---

# Index — <REPO NAME>

The map of this repository. **Read this first, then jump to the files it points to.** One-line
description of what this project is and does: _<fill in>_.

## Stack

_Fill with the REAL commands for this repo (inferred from the lockfile / project file / scripts, and
checked against CI), not guesses. Delete lines that don't apply._

- **Language / runtime:** _<e.g. TypeScript, Node 20 (`.nvmrc`) — or Python 3.12 (`.python-version`) — or T-SQL, SQL Server 2022 — or PostgreSQL 16 — or R 4.4 (`renv.lock`)>_
- **Package manager / toolchain:** _<e.g. pnpm (`pnpm-lock.yaml`) — or uv (`uv.lock`) — or .NET SDK + sqlpackage (SDK-style `.sqlproj`) — or psql (script run list) — or renv + targets>_
- **Run locally:** _<e.g. `pnpm dev` — or `uv run uvicorn app.main:app --reload` — or `docker compose up -d sql` — or `Rscript -e 'targets::tar_make()'`>_
- **Build:** _<e.g. `pnpm build` — or n/a — or `dotnet build db/Db.sqlproj` → `.dacpac`>_
- **Deploy / publish:** _<DB repos: `sqlpackage /Action:Script …` (preview) and `/Action:Publish /Profile:…`, or `sqlcmd -i deploy.sql`, or `psql -X -v ON_ERROR_STOP=1 -f db/deploy.sql`>_
- **Submit (Slurm):** _<e.g. `bash slurm/submit.sh` — or `sbatch slurm/<job>.sbatch`; watch `squeue --me`, inspect `sacct -j <id>`>_
- **Cluster:** _<Slurm repos: cluster name, partition / account, `module load` versions, scratch path>_
- **Test:** _<e.g. `pnpm test` — or `uv run pytest` — or `EXEC tSQLt.RunAll` — or `pg_prove -d <db> db/tests/` — or `Rscript -e 'devtools::test()'`>_ · single: _<e.g. `pnpm vitest run <file>`>_
- **Lint / format:** _<e.g. `pnpm lint` / `pnpm format` — or `uv run ruff check` / `ruff format` — or `sqlfluff lint --dialect tsql|postgres` — or `lintr::lint_dir()` / `styler::style_dir()`>_
- **Typecheck:** _<e.g. `pnpm typecheck` — or `uv run mypy <pkg>`>_
- **CI (ground truth):** _<e.g. `.github/workflows/ci.yml`>_

<!-- Monorepo OR hybrid (multi-language) repos: list each package/component with its OWN toolchain.
     Delete this block for single-component repos.
## Components

| Component | Path | Toolchain | Purpose | Module page |
|-----------|------|-----------|---------|-------------|
| _web_ | `web/` | _pnpm · Next.js_ | _UI + API routes_ | [web](modules/web.md) |
| _worker_ | `worker/` | _uv · Celery_ | _background jobs_ | [worker](modules/worker.md) |
| _db_ | `db/` | _dotnet · SDK-style sqlproj_ (or _psql · script run list_) | _database schema + procs/functions_ | [db](modules/db.md) |
| _jobs_ | `slurm/` | _Slurm · sbatch arrays_ | _cluster job scripts + submit chain_ | [jobs](modules/jobs.md) |

For a hybrid repo, also document the **seam** between components (how they talk: subprocess / HTTP /
shared queue / shared files/DB / the stored-procedure or SQL-function contract / the Slurm job chain) — see [architecture](architecture.md).
-->


## Map

| Area | Key files / dirs | Purpose | More |
|------|------------------|---------|------|
| _Auth_ | `src/auth/` | _Login, sessions, tokens_ | [auth](modules/auth.md) |
| _API_ | `src/api/` `src/routes/` | _HTTP endpoints_ | [api](modules/api.md) |
| _Data_ | `src/db/` `db/migrations/` | _Models, persistence_ | [data](modules/data.md) |
| _Data sources_ | `src/etl/extract.py` `src/ingest/` | _external DBs / shares / buckets / APIs this repo reads or writes_ | [data-sources](data-sources.md) |
| _..._ | _..._ | _..._ | _..._ |

_Every "key files" cell holds real paths so an agent can open them directly._

## Where to start by task

- **Fix a bug in _<area>_** → [_<module>_](modules/_<module>_.md), `<key file>`
- **Add a _<feature type>_** → [recipes](recipes.md#_<recipe>_), [_<module>_](modules/_<module>_.md)
- **Change the data model** → [recipes](recipes.md#_<recipe>_), `<migrations dir>`
- **Read / write an external source** → [data-sources](data-sources.md), `<ingest file>` _(delete if the repo connects to nothing)_
- **Run / debug locally** → [recipes](recipes.md#run-locally)

## Also see

- [architecture](architecture.md) — how the pieces fit together
<!-- Keep only if the repo connects to external data; delete this block otherwise (and the
     Data sources Map row above, and the data-sources.md row in README.md's Layout table).
- [data-sources](data-sources.md) — the external data this repo reads and writes
-->
- [conventions](conventions.md) — how to write code that matches this repo
- [glossary](glossary.md) — domain terms
- [log](log.md) — recent wiki changes
