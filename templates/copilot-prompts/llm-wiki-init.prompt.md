---
description: Populate or refresh this repo's .llm-wiki/ knowledge base so Copilot orients fast and uses fewer tokens.
---

# Populate the LLM Wiki

You are maintaining `.llm-wiki/`, a compiled knowledge base for AI coding agents. **Scan this
repository and fill in (or create) the pages** so an agent can orient from `.llm-wiki/index.md` alone
instead of searching the whole tree. Read the code — the code is the source of truth. If `.llm-wiki/`
doesn't exist yet, create it.

## 1. Detect the stack — don't guess, and don't assume it's a web app

- **Languages present** — check manifests at the root *and* in subdirectories: `package.json` /
  `deno.json` (Node/Deno), `pyproject.toml` / `requirements*.txt` / `pixi.toml` (Python), `*.sqlproj`
  / `*.dtproj` / folders of `*.sql` (T-SQL / SQL Server — or PostgreSQL, see below), `DESCRIPTION` /
  `renv.lock` / `*.Rproj` / `_targets.R` / `*.R` (R). Shell scripts with `#SBATCH` lines ⇒ jobs run on
  a **Slurm** cluster. More than one language ⇒ a **polyglot/hybrid** repo: map it by component.
- **SQL dialect** — `*.sql` alone doesn't say. T-SQL: `GO`, `:r`, `SET NOCOUNT`, `NVARCHAR`,
  `CREATE OR ALTER`. PostgreSQL: `$$` bodies, `LANGUAGE plpgsql`, `\i`/`\ir`/`\set`, `JSONB`,
  `TIMESTAMPTZ`, `ON CONFLICT`. Record the dialect per folder.
- **Package manager** from the lockfile — Node: `pnpm-lock.yaml` / `yarn.lock` / `bun.lock` or
  `bun.lockb` / `deno.lock` / `package-lock.json` (and `packageManager` in `package.json` pins it);
  Python: `uv.lock` / `poetry.lock` / `pdm.lock` / `pixi.lock` / `Pipfile.lock` / `requirements*.txt`
  (Hatch: `[tool.hatch.envs]`). The lockfile decides how every command is spelled (`pnpm test`,
  `uv run pytest`, …). Record the runtime version (`.nvmrc`, `.python-version`, `engines`,
  `requires-python`).
- **T-SQL toolchain** —
  - SDK-style `.sqlproj` (`<Project Sdk="Microsoft.Build.Sql">`) → `dotnet build` → `.dacpac`;
    classic SSDT `.sqlproj` → MSBuild / Visual Studio. Deploy with `sqlpackage /Action:Publish
    /Profile:<env>.publish.xml`; **preview** with `/Action:Script` or `/Action:DeployReport`. Note
    SQLCMD variables, pre/post-deploy scripts, the `.refactorlog`, and tSQLt tests
    (`EXEC tSQLt.RunAll` / `tSQLt.Run '<class>'`).
  - Script repos (no project file) → `sqlcmd -S … -d … -b -i <file>`; find the **run order**
    (`deploy.sql` with `:r`, numbered folders) and whether scripts are idempotent (`CREATE OR ALTER`,
    `IF NOT EXISTS`).
  - SSIS (`*.dtproj`, `*.dtsx`) → build to `.ispac`, deploy to SSISDB, run via SQL Agent job or
    `dtexec /ISServer`; note SSISDB environments and scripted Agent jobs (`sp_add_job`).
- **PostgreSQL toolchain** (psql script repos) — find the **run list** (`deploy.sql` of `\ir` lines,
  numbered folders, or a driver script) and the exact call, which must include
  `psql -X -v ON_ERROR_STOP=1 [-1] -f …`; which scripts re-run every deploy (must be idempotent:
  `IF NOT EXISTS`, `CREATE OR REPLACE`, `ON CONFLICT`) vs one-shot changes and how those are tracked;
  `\set` / `-v` variables; connection via `PG*` env / `service=` (never a password in a recipe);
  roles, grants, RLS; extensions and server version; pgTAP tests (`pg_prove -d <db> db/tests/`);
  `pg_cron` jobs. Migration tools (Sqitch, Flyway, dbmate, …) — record their deploy/status commands.
- **R toolchain** — renv (`Rscript -e 'renv::restore()'`, `renv::snapshot()` after adding deps) and
  the R version; package (`DESCRIPTION` with `Package:` → `devtools::document()` / `test()` /
  `check()`, never hand-edit `NAMESPACE`/`man/`); targets (`targets::tar_make()`,
  `tar_make(names = …)`); Quarto (`quarto render`) / R Markdown; Shiny (`shiny::runApp()`);
  testthat single file (`testthat::test_file(…)`); lintr/styler.
- **Slurm** — per job script: `#SBATCH` resources (partition/account/time/mem/cpus/gpus), arrays and
  how `$SLURM_ARRAY_TASK_ID` maps to inputs, the `--dependency=afterok` chain / submit wrapper,
  `module load` versions and env activation, scratch vs project storage, log paths; how to test small
  (`--array=0-1`, debug partition) and run one task locally. Never write a recipe that computes on a
  login node.
- **Real commands** (only those actually configured): install, run/dev, build, test (+ single test in
  the detected runner's syntax — vitest `-t`, jest `-t`, `node --test --test-name-pattern`,
  pytest `file::test`), lint, format, typecheck — from `package.json` scripts, `pyproject.toml`
  `[tool.*]`, `.pre-commit-config.yaml`, `biome.json`, `.sqlfluff`, Makefile/justfile/Taskfile/tox/nox.
  **Check them against CI** (`.github/workflows/*.yml`, `azure-pipelines.yml`) — CI is the ground
  truth when sources disagree.
- **Project archetype** — one or more of: web service, data/analytics/ETL, orchestration
  (Airflow/Dagster/Prefect), automation/scripting/jobs, file-processing, worker/queue consumer,
  serverless, ML, notebooks, CLI, library, **database project** (state-based `.sqlproj`), **SQL
  script / DBA repo**, **data warehouse / SSIS ETL**, **PostgreSQL psql script repo**, **R package /
  analysis (targets) / Shiny app / Quarto reports**, **HPC batch pipeline on Slurm**. Shape the pages
  to what the repo *actually is*.
- **Data sources** — when you find a connection to data outside the repo, across every class:
  relational (pyodbc / SQLAlchemy `create_engine` / `DBI::dbConnect` / `psycopg` / `oracledb`),
  warehouses (`snowflake.connector`, `pandas_gbq`, `databricks.sql`, `redshift_connector`, dbt
  `profiles.yml`), object stores and network shares (`boto3.client("s3")`, `s3://`, `adlfs`,
  `gcsfs`, `pd.read_parquet`/`read_excel` over a UNC or mounted path, SharePoint), local/embedded
  (`duckdb.connect`, `sqlite3.connect`), caches/queues/streams (`redis.Redis`, `pymongo.MongoClient`,
  `KafkaConsumer`, `pika`), named APIs and SFTP (`httpx.Client(base_url=)`, `paramiko`, `ftplib`), and
  SAS (`saspy.SASsession`, `sascfg_personal.py`, `*.sas` `libname`/`signon`) — plus
  `Server=`/`Data Source=`/`DSN=` strings and `pg_service.conf` / `odbc.ini` / `tnsnames.ora`.
  Only count a source that is **external & named, durable & likely shared, and load-bearing**: skip
  telemetry hosts, package registries, `localhost`, temp files and repo-relative fixtures. Keep **one
  entry per source**, never per table/file/topic. Record it in two places:
  - **`.llm-wiki/data-sources.md`** (create it from the template only if you found at least one
    source) — name, engine, the real code paths that touch it, direction, and the
    objects/prefixes/topics used, plus repo gotchas. Then add the matching **Map** row to `index.md`.
  - the cross-project catalog `~/.claude/llm-wiki/data-sources.md` — note engine, connect-via,
    driver/cfgname, auth model, and credential env-var / authinfo-key **names** only, so the user can
    record it (this catalog is user-global, not part of the repo's `.llm-wiki/`).
  **Never** write a password, token, key or presigned/SAS URL into either. Flag any secret hard-coded
  in a connection string so the user can move it to an env var.
- **Persistence is a separate axis** — document models + migrations only if an ORM is present
  (SQLAlchemy, Django, Prisma, Drizzle…). Many analytics/automation repos have no database; don't
  invent a migration recipe for them. In a T-SQL repo the database *is* the code: document schemas
  and the deploy model instead — and never write an `ALTER TABLE` recipe for a state-based
  `.sqlproj` (the dacpac diff generates ALTERs; renames go through the refactorlog). In a Postgres
  script repo, document the run order, idempotency rules and one-shot mechanism instead.

## 2. Fill the pages (each starts with frontmatter: `updated`, `covers: [..]`, `status`)

- **index.md** — the MAP (most important). A table `Area | key file paths (real!) | purpose | module
  page`; a **Stack** block with the real commands from step 1 (for databases: build → preview →
  publish → test; for Slurm repos a **Cluster** line: cluster, partition/account, module versions); a "Where to start by task" list. Monorepo/hybrid ⇒ a **Packages/Components**
  table, one row per package/component with its own toolchain.
- **architecture.md** — components, data/control flow, boundaries, key decisions. For a hybrid repo,
  document the **seam** (how the parts talk: subprocess / HTTP / shared queue / shared files/DB — or,
  for app + database, the stored-procedure / SQL-function / view contract). For a warehouse, the
  layers (e.g. `stg` → `dw` → `mart`) and load order. For a Slurm pipeline, the job graph and the
  files each job hands to the next.
- **conventions.md** — package manager, runtime version, lint/format/type-check config locations,
  naming, patterns to reuse, testing approach, do/don't. T-SQL: object/constraint naming, proc shape
  (`SET NOCOUNT ON`, `TRY…CATCH` + `THROW`), no `SELECT *`, schema-qualified names, idempotency rules
  — derived from the code. PostgreSQL: `snake_case`, `timestamptz`/`text`/identity types, constraint
  naming, idempotency idioms, `ERRCODE`s, grants/RLS. R: style, `pkg::fn` vs `library()`, paths
  (`here::here()`), seeds. Slurm: script header order, default resources, log naming, modules.
- **glossary.md** — domain terms and key entities.
- **data-sources.md** — **only if** the repo connects to something external (see Data sources
  above). Copy the plugin's `templates/wiki/data-sources.md` shape: the sources table (name, engine,
  used-by code paths, direction, objects, whether it's in the user-global catalog), how data flows,
  and the gotchas. No connection details, no secrets. If the repo connects to nothing, don't create
  it — and drop its row from the copied `README.md` Layout table.
- **recipes.md** — step-by-step playbooks for this repo's common tasks, with the **real commands**;
  include only the tasks that fit the archetype (e.g. "run the pipeline / add a data source" for ETL,
  "add an endpoint / add a migration" only for web + ORM, "preview the deploy / add a proc / rename
  safely / add a tSQLt test" for a `.sqlproj`, "deploy in run order / add an idempotent script" for
  script repos, "run a package / add a dimension / backfill" for a warehouse, "reset + deploy / add
  an object script to the run list / one-shot change / add a pgTAP test" for a Postgres script repo,
  "document / test / check / add a dependency" for an R package, "`tar_make()` / rerun one target /
  render the report" for an R analysis, "submit / test small / check `sacct` / rerun failed array
  tasks" for Slurm).
- **modules/<name>.md** — one page per significant subsystem (or framework unit / pipeline stage /
  package / component / DB schema / warehouse layer / SSIS package group / R package area / Shiny
  module / Slurm job group): purpose, key files & entry points, how it works, gotchas, related links.
  DB-shaped modules get a small **Database objects** table (object · kind/grain · notes); Slurm job
  groups a **Jobs** table (script · resources · array · depends on · outputs).
- **log.md** — append: `## [<today>] init | <one-line summary of what you created>`.

If the repo contains T-SQL, PostgreSQL, R or Slurm scripts and the matching
`.github/instructions/{tsql,postgres,r,slurm}.instructions.md` doesn't exist, mention that the
llm-wiki installer can add it (path-scoped Copilot guidance per stack).

## 3. Principles

- **Link, don't duplicate** — the wiki is a map, not a copy of the code. Keep pages short (index
  < ~150 lines, module pages < ~120).
- **Real file paths everywhere**, so the reader opens the right file directly.
- Be honest about uncertainty — mark thin/guessed pages `status: draft`.

When done, briefly tell me which pages and modules you created and anything you were unsure about.
