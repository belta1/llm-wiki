---
description: Bootstrap a .llm-wiki/ codebase knowledge base in the current repo and generate pointer files for Claude, Codex/AGENTS.md, and GitHub Copilot.
argument-hint: "[optional: focus areas or notes to emphasize]"
---

# /llm-wiki:init

Bootstrap a `.llm-wiki/` knowledge base for the **current repository** so AI coding agents orient
fast and use fewer tokens. Extra guidance from the user, if any: $ARGUMENTS

Templates live in the plugin at `${CLAUDE_PLUGIN_ROOT}/templates/`. Copy from there; fill from what
you actually find in the repo. Before writing pages, read the plugin's page conventions:
`${CLAUDE_PLUGIN_ROOT}/skills/llm-wiki/references/page-formats.md` and `token-efficiency.md`.

This plugin is optimized for **Python**, **Node.js**, **T-SQL / SQL Server**, **PostgreSQL**, and
**R** repos, plus **Slurm** batch pipelines on top of any of them. Read
`${CLAUDE_PLUGIN_ROOT}/skills/llm-wiki/references/stacks.md` for detection rules. Work in three steps:
(1) which languages are present — **more than one ⇒ a hybrid/polyglot repo**, map it by component;
(2) each language's toolchain; (3) the **project archetype — don't assume a web app.** A repo may be
a web service, a data/ETL pipeline, an orchestrated workflow (Airflow/Dagster/Prefect), an
automation/scripting/file-processing job, a worker/queue consumer, a serverless function set, an ML
project, notebooks, a CLI, a library, a **SQL Server database project** (`.sqlproj`), a **SQL
script / DBA repo**, an **SSIS / data-warehouse ETL** repo, a **PostgreSQL `psql` script repo**, an
**R package / analysis (targets) / Shiny app / Quarto reports**, or an **HPC pipeline submitted to
Slurm** — or a hybrid of these. Then mirror the
closest worked example for page shape and brevity:
- `${CLAUDE_PLUGIN_ROOT}/examples/node-app/.llm-wiki/` — Express + TypeScript
- `${CLAUDE_PLUGIN_ROOT}/examples/python-webapp/.llm-wiki/` — FastAPI + SQLAlchemy web service
- `${CLAUDE_PLUGIN_ROOT}/examples/python-analytics/.llm-wiki/` — pandas/polars ETL, no web, no ORM
- `${CLAUDE_PLUGIN_ROOT}/examples/hybrid-app/.llm-wiki/` — hybrid Node web + Python worker over Redis
  (Components table + a `seam` module page for the cross-language contract)
- `${CLAUDE_PLUGIN_ROOT}/examples/tsql-database/.llm-wiki/` — SDK-style `.sqlproj` + sqlpackage +
  tSQLt behind an app (schema module pages + an `api-contract` page for the stored-proc contract)
- `${CLAUDE_PLUGIN_ROOT}/examples/tsql-warehouse/.llm-wiki/` — SQL Server DW: SSIS + ordered sqlcmd
  scripts + SQL Agent jobs (Components table + per-layer module pages)
- `${CLAUDE_PLUGIN_ROOT}/examples/postgres-database/.llm-wiki/` — PostgreSQL psql script repo +
  pgTAP + `pg_cron` behind a Node API (schema module pages + an `api-contract` page for the SQL
  function contract)
- `${CLAUDE_PLUGIN_ROOT}/examples/r-analysis/.llm-wiki/` — R analysis: renv + targets pipeline +
  Quarto report + testthat (pipeline / report module pages)
- `${CLAUDE_PLUGIN_ROOT}/examples/hpc-slurm/.llm-wiki/` — Python preprocessing + R models run as
  chained Slurm array jobs (Components table + a `jobs` page as the seam)

(Other stacks/archetypes still work; fall back to generic detection.)

## Steps

1. **Check for an existing wiki.** If `.llm-wiki/` already exists, stop and suggest `/llm-wiki:update`
   or `/llm-wiki:lint` instead of overwriting. Do not clobber existing pages.

2. **Detect the stack (read-only), guided by `references/stacks.md`.** Determine:
   - **Package manager** from the lockfile (pnpm/yarn/bun/npm/deno; uv/poetry/pdm/hatch/pixi/pipenv/
     pip) — the lockfile wins, and `packageManager` in `package.json` pins it. This decides how every
     recipe command is spelled (`pnpm test`, `uv run pytest`, …). Record the runtime version
     (`.nvmrc`, `.python-version`, `engines`, `requires-python`).
   - **T-SQL toolchain** when `*.sqlproj` / `*.dtproj` / `*.sql` are present: SDK-style
     (`Microsoft.Build.Sql` → `dotnet build`) vs classic SSDT (MSBuild/Visual Studio); publish
     profiles (`*.publish.xml`) and SQLCMD variables; pre/post-deploy scripts and the refactorlog;
     tSQLt tests; for script repos the **run order** (`deploy.sql` with `:r`, numbered folders) and
     idempotency; for SSIS the packages, SSISDB environments, and SQL Agent jobs.
   - **SQL dialect** — `*.sql` alone doesn't say: check for T-SQL (`GO`, `SET NOCOUNT`, `NVARCHAR`)
     vs PostgreSQL (`$$`, `plpgsql`, `\ir`, `JSONB`, `TIMESTAMPTZ`) markers, per folder.
   - **PostgreSQL toolchain**: the run list (`deploy.sql` with `\ir`, numbered folders, a driver
     script) and the exact `psql -X -v ON_ERROR_STOP=1 …` call; re-runnable (idempotent) vs one-shot
     scripts and how one-shots are tracked; `\set` / `-v` variables and connection via `PG*` /
     `service=`; roles, grants, RLS; extensions and server major; pgTAP (`pg_prove`); `pg_cron`
     jobs; or the migration tool (Sqitch/Flyway/dbmate/…) and its commands.
   - **R toolchain**: renv (`renv::restore()` / `snapshot()`), R version; package (`DESCRIPTION`,
     `devtools::document/test/check`), targets (`tar_make()`, one target), Quarto/R Markdown
     render, Shiny run/deploy; testthat single-file syntax; lintr/styler.
   - **Slurm** when `#SBATCH` scripts exist: each job's resources (partition/account/time/mem/
     cpus/gpus), arrays and task-id mapping, `afterok` dependency chain / submit wrapper, `module
     load` versions and env activation, scratch vs project storage, log paths, and how to test small
     and run one task locally.
   - **Real commands** for install, run/dev, build, test (+ single test using the detected runner's
     syntax), lint, format, typecheck — and for databases build → **preview** (`sqlpackage
     /Action:Script`, or a throwaway-DB / `pg_dump --schema-only` diff for Postgres) → publish →
     test. Read `package.json` scripts / `pyproject.toml` `[tool.*]` /
     `.sqlproj` / Makefile/justfile/Taskfile/tox/nox — and **check them against CI**
     (`.github/workflows/`, `azure-pipelines.yml`), which is the ground truth. Record what a dev would
     actually type; never guess a command that isn't configured.
   - **Archetype** (web service, data/ETL, orchestration, automation/jobs, file-processing, worker,
     serverless, ML, notebooks, CLI, library, database project, SQL script repo, warehouse/SSIS,
     psql script repo, R package / analysis / Shiny / reports, Slurm batch pipeline — per
     `stacks.md` Step 3) — decides which module pages and archetype-specific recipes to write. Detect
     **persistence** separately.
   - **Hybrid / monorepo** (see step 3b).
   - Top-level structure, entry points, routing, data layer, tests location; existing conventions by
     sampling a few representative files. Keep it efficient — sample, don't read everything.

3. **Create `.llm-wiki/`** by copying `${CLAUDE_PLUGIN_ROOT}/templates/wiki/` and filling each page:
   - `README.md` — leave as-is (explains the dir to humans).
   - `index.md` — the map table (area → key file paths → purpose → module link) and the
     "Where to start by task" router. This is the most important page; make paths real. Fill the
     **Stack** block with the package manager and the real run/build/test/lint/typecheck commands
     from step 2.
   - `architecture.md` — system shape, main components, data/control flow, boundaries.
   - `conventions.md` — package manager, formatter/linter/type-check config locations, naming,
     patterns to reuse, testing approach, error handling, import boundaries, do/don't.
   - `glossary.md` — domain terms and key entities.
   - `recipes.md` — step-by-step playbooks with the **real commands** from step 2 (run, test + single
     test, lint/format/typecheck, add a dependency) plus the **archetype-specific** tasks from
     `stacks.md` — e.g. run the pipeline / add a data source (ETL), run a task vs the whole DAG
     (orchestration), run/schedule a job (automation), start a worker (queue), invoke/deploy
     (serverless), add an endpoint / migration (web + ORM), preview/publish + add a table/proc +
     rename via refactorlog + add a tSQLt test (database project), deploy in run order + add an
     idempotent script (SQL script repo), run a package / add a dimension / backfill (warehouse/SSIS),
     reset + deploy with `ON_ERROR_STOP` / add an object script to the run list / one-shot data
     change / safe big-table change / pgTAP test (psql script repo), document-test-check / add a
     dependency with renv snapshot (R package), `tar_make()` / rerun one target / render (R
     analysis), submit / test small / check `sacct` / rerun failed array tasks / run one task locally
     (Slurm). Only include recipes whose tooling actually exists — never an `ALTER TABLE` recipe for
     a state-based `.sqlproj`, never a Slurm recipe that computes on the login node.
   - `modules/<name>.md` — one page per natural unit for the archetype (router/app, pipeline stage,
     DAG/flow, job/automation, worker, serverless function, ML concern, CLI group, DB schema/subject
     area, warehouse layer, SSIS package group, R package area / Shiny module / report group, Slurm
     job group), from `modules/_TEMPLATE.md` (fill its optional **Database objects** table for
     DB-shaped modules and its **Jobs** table for Slurm job groups).
   - `log.md` — seed with the first entry (see step 5).

3b. **Hybrid (polyglot) and monorepo repos.** If Step 1 found **more than one language** (e.g.
   `package.json` *and* `pyproject.toml`), or you detected workspaces (`workspaces` in `package.json`,
   `pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `lerna.json`, `[tool.uv.workspace]`, multiple
   `pyproject.toml`, several R `DESCRIPTION` files, or a `.sln` with several `.sqlproj`), map it **by component/package**: create
   **one `modules/<component>.md` each**, add a **Components/Packages** table to `index.md` (name →
   path → toolchain → purpose → module page), and record how to run each part plus the combined dev
   flow (`Makefile`/`docker-compose`/`Procfile`/`turbo`/`nx`). For a hybrid, **document the seam
   between languages** (subprocess, HTTP, shared queue/DB/files — or, for an app + `.sqlproj`, the
   stored-procedure/view contract: params, result sets, error numbers, callers; for an app +
   Postgres, the function/view contract: signatures, return shapes, `ERRCODE`s, roles/RLS; for a
   Slurm pipeline, the job graph and the files each job hands to the next) — it's the
   highest-value page. See the Hybrid section of `references/stacks.md`.

4. **Generate root pointer files** from `${CLAUDE_PLUGIN_ROOT}/templates/pointers/`:
   - `CLAUDE.md`, `AGENTS.md`, and `.github/copilot-instructions.md` (create `.github/` if needed).
   - Each pointer's content goes inside a delimited managed block:
     `<!-- BEGIN llm-wiki -->` … `<!-- END llm-wiki -->`.
   - **If a target file already exists**, do NOT overwrite it. Insert or replace only the managed
     block, preserving all of the user's existing content.
   - **Path-scoped Copilot instructions:** for each stack detected, copy
     `${CLAUDE_PLUGIN_ROOT}/templates/copilot-instructions/<stack>.instructions.md` to
     `.github/instructions/<stack>.instructions.md` — `tsql` (T-SQL `*.sql`, `.sqlproj`, SSIS),
     `postgres` (PostgreSQL `*.sql`), `r` (`*.R`/`*.Rmd`/`*.qmd`), `slurm` (`*.sbatch`/`*.slurm`).
     Detect the SQL **dialect** first; install both SQL files only if both dialects are present.
     These files are plugin-owned; replace them if they exist. If the repo's `#SBATCH` scripts are
     plain `*.sh`, widen the `slurm` file's `applyTo` to their real paths (e.g.
     `"**/*.{sbatch,slurm},slurm/**/*.sh"`).

5. **Append the first `log.md` entry**: `## [<today>] init | <one-line summary of what was created>`.

6. **Report** to the user: the pages created, the modules covered, and anything you were unsure about
   or deliberately left thin, so they can direct follow-ups.

## Principles

- Favor **locations and gotchas** over restating code. Link, don't duplicate.
- Keep pages within the size budgets in `page-formats.md`.
- Be honest about uncertainty — mark thin/guessed pages `status: draft` in frontmatter.
