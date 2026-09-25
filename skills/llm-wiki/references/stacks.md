# Stack playbook — Python, Node.js, T-SQL, PostgreSQL & R (plus Slurm/HPC, and hybrids)

This plugin is optimized for **Python**, **Node.js**, **T-SQL / SQL Server**, **PostgreSQL**, and
**R** repos of any shape — web services, data pipelines, orchestrated workflows, automations/scripts,
file-processing jobs, workers, serverless functions, CLIs, libraries, **database projects**, **DBA /
`psql` script repos**, **SSIS / data-warehouse ETL**, **R packages, analyses and Shiny apps**, and
**HPC batch pipelines submitted to Slurm** — and **repos that mix languages**. Read this before
filling a wiki so the recipes carry *real, runnable* commands and the module pages match what the
repo actually is.

Three rules govern everything below:

1. **Detect, don't guess.** Read the lockfile / manifest / project file / scripts and record exactly
   what a dev on this repo would type. A recipe with the wrong package manager or deploy tool is worse
   than none.
2. **Don't presume a shape.** "Node" doesn't mean web frontend; "Python" doesn't mean web + ORM;
   "SQL" doesn't mean migrations — or one dialect (T-SQL and PostgreSQL deploy and fail in very
   different ways); "R" doesn't mean a package. Identify the *archetype(s)* from dependencies and layout, and a repo
   may be polyglot.
3. **CI is the ground truth.** When `package.json` scripts, a README, and CI disagree, the commands
   CI actually runs are the ones that work. See [Ground truth for commands](#ground-truth-for-commands).

Work in three steps: (1) which languages are present, (2) each language's toolchain, (3) the
archetype(s). Then write.

---

## Step 1 — Which languages are present?

Check for manifests at the root **and in subdirectories**:

- **Node:** `package.json` (+ a lockfile). **Deno:** `deno.json` / `deno.jsonc` / `deno.lock`.
- **Python:** `pyproject.toml`, `setup.py/.cfg`, `requirements*.txt`, `Pipfile`, `environment.yml`,
  `pixi.toml`.
- **T-SQL / SQL Server:**
  - `*.sqlproj` — a database project. **SDK-style** if it starts `<Project Sdk="Microsoft.Build.Sql">`
    (builds with `dotnet`); **classic SSDT** if it has `ToolsVersion`/`<Import … SSDT …>` (builds with
    Visual Studio / MSBuild). A `*.sln` may reference one or several.
  - `*.dtproj` / `*.dtsx` / `*.conmgr` / `Project.params` — an **SSIS** project.
  - `*.publish.xml` — sqlpackage publish profiles (one per environment, usually).
  - Folders of `*.sql` organised by schema or object type (`dbo/Tables/`, `Stored Procedures/`,
    `Views/`) or by run order (`001_…sql`, `deploy/`), `*.sqlcmd` files, `:r` include lists — a
    **script repo** even without a project file.
  - `.sqlfluff` with `dialect = tsql`; `tSQLt` classes (`EXEC tSQLt.NewTestClass`) — lint/test tools.
  - Migration tools (`flyway.conf`, `V1__*.sql`, DbUp `.csproj`, `liquibase.properties`) — note the
    tool and its `migrate` command; this playbook doesn't go deeper on them.
- **PostgreSQL:**
  - `*.sql` using PostgreSQL syntax: `$$`-quoted bodies, `LANGUAGE plpgsql`, psql meta-commands
    (`\i`, `\ir`, `\set`, `\gexec`, `:'var'`), `JSONB`, `TIMESTAMPTZ`, `BIGSERIAL`,
    `GENERATED … AS IDENTITY`, `CREATE EXTENSION`, `ON CONFLICT`, `CREATE OR REPLACE FUNCTION`.
  - A run list — `deploy.sql` / `init.sql` of `\ir` lines, numbered folders (`00_extensions/`,
    `10_schemas/`, …), or a shell/Make driver calling `psql -f` — ⇒ a **psql script repo**.
  - `.psqlrc`, `pg_service.conf`, `.pgpass` references, `PG*` variables in `.env.example`;
    `postgres:` / `postgis/postgis` images in compose; `docker-entrypoint-initdb.d/` mounts.
  - `.sqlfluff` with `dialect = postgres`; `squawk` config; pgTAP tests (`CREATE EXTENSION pgtap`,
    `SELECT plan(…)`, `t/*.sql` / `test/*.pg`, run by `pg_prove`); `pg_cron` (`cron.schedule(…)`).
  - Migration tools — note the tool and its migrate/status commands, don't go deeper: Sqitch
    (`sqitch.plan`, `deploy/ revert/ verify/`), Flyway (`V1__*.sql`), Liquibase, dbmate
    (`db/migrations/*.sql` with `-- migrate:up`), golang-migrate (`*.up.sql`/`*.down.sql`),
    graphile-migrate (`.gmrc`), Supabase (`supabase/migrations/`, `supabase db push`).
- **T-SQL or PostgreSQL?** `*.sql` alone doesn't say. Sample a few files:

  | T-SQL markers | PostgreSQL markers |
  |---------------|--------------------|
  | `GO` batch separators, `:r` / `:setvar` (SQLCMD) | `\i` / `\ir` / `\set` (psql) |
  | `SET NOCOUNT ON`, `CREATE OR ALTER PROC`, `sp_`/`sys.` | `LANGUAGE plpgsql`, `$$ … $$`, `pg_catalog` |
  | `NVARCHAR`, `DATETIME2`, `BIT`, `IDENTITY(1,1)`, `[bracketed]` names | `TEXT`, `TIMESTAMPTZ`, `JSONB`, `BIGSERIAL`, `"quoted"` names |
  | `TRY…CATCH` + `THROW` | `RAISE EXCEPTION … USING ERRCODE`, `ON CONFLICT` |

  A repo can hold both (e.g. a Postgres app DB plus SQL Server extracts) — record the dialect per
  folder in the index.
- **R:**
  - `DESCRIPTION` with `Package:` ⇒ an **R package** (plus `NAMESPACE`, `R/`, `man/`, `tests/testthat/`).
  - `renv.lock` / `renv/` (renv), `rix` / `default.nix` (Nix), `DESCRIPTION` without `Package:` used
    only for dependencies — the dependency manager.
  - `*.Rproj` (RStudio project), `_targets.R` (targets pipeline), `Snakefile`/`Makefile` driving
    `Rscript`, `_quarto.yml` / `*.qmd` / `*.Rmd` (Quarto / R Markdown), `app.R` or `ui.R`+`server.R`
    / `golem` / `rhino` (Shiny), `plumber.R` (API), `.lintr`, `.Rprofile`.
- **Slurm / HPC:** not a language but an execution layer on top of one — detect it separately.
  - `*.sbatch`, `*.slurm`, `*.job`, or **any shell script with `#SBATCH` lines**; `sbatch` / `srun`
    calls in a `submit.sh` / Makefile; `module load …` lines; `$SLURM_ARRAY_TASK_ID` / `$SLURM_*`
    in Python/R code.
  - Workflow managers configured for Slurm: Snakemake (`profile/config.yaml` with `executor: slurm`,
    `--executor slurm`), Nextflow (`process.executor = 'slurm'`), targets + `crew.cluster` /
    `clustermq` / `batchtools` templates (`*.tmpl`), Dask-jobqueue, `submitit`.

More than one language ⇒ **hybrid/polyglot** — see [that section](#hybrid--polyglot-repos). Also
scan for other languages you should at least name in the wiki (C#/.NET, Go, Rust, Julia,
shell/PowerShell, Dockerfiles, IaC), even if this plugin focuses on Node/Python/SQL/R.

---

## Step 2 — Per-language toolchain

### Node.js — package manager (lockfile wins)

| Signal file | Package manager | Install | Run script |
|-------------|-----------------|---------|-----------|
| `pnpm-lock.yaml` | pnpm | `pnpm install` | `pnpm <script>` |
| `yarn.lock` | yarn (check `.yarnrc.yml` ⇒ Berry/v2+) | `yarn` | `yarn <script>` |
| `bun.lock` (text, Bun ≥ 1.2) or `bun.lockb` | bun | `bun install` | `bun run <script>` |
| `deno.json` / `deno.lock` | Deno | `deno install` | `deno task <task>` |
| `package-lock.json` (or none) | npm | `npm install` (CI: `npm ci`) | `npm run <script>` |

- `packageManager` in `package.json` (Corepack pin, e.g. `"pnpm@9.12.0"`) is **authoritative** when
  present — record the version.
- **Runtime version:** `.nvmrc`, `.node-version`, `.tool-versions`, or `engines.node` — record it; a
  wrong Node major is a common "works on CI, fails locally" cause.
- **Module system:** `"type": "module"` ⇒ ESM (`import`, `.js` extensions in TS imports under
  `NodeNext`); otherwise CJS. Note it in conventions — agents get this wrong often.
- Capture the **real `scripts`**: run/dev (`dev`/`start`), `build`, `test` (+ single-test filter),
  `lint`, `format`, `typecheck`. `tsconfig.json` ⇒ TypeScript (note `strict`, `module`, `outDir`); no
  tsconfig ⇒ plain JS, don't invent a typecheck recipe.
- **Lint/format:** `biome.json` ⇒ Biome does both (`biome check --write`); otherwise ESLint
  (`eslint.config.*` flat config vs legacy `.eslintrc*`) + Prettier (`.prettierrc*`).

**Single-test syntax differs per runner** — detect the runner from devDependencies/config:

| Runner | Signal | One file | One test by name |
|--------|--------|----------|------------------|
| Vitest | `vitest`, `vitest.config.*` | `<pm> vitest run <file>` | `<pm> vitest run -t "<name>"` |
| Jest | `jest`, `jest.config.*` | `<pm> jest <file>` | `<pm> jest -t "<name>"` |
| node:test | `node --test` in scripts | `node --test <file>` | `node --test --test-name-pattern="<name>"` |
| Mocha | `mocha`, `.mocharc*` | `<pm> mocha <file>` | `<pm> mocha -g "<name>"` |
| Playwright | `@playwright/test` | `<pm> playwright test <file>` | `<pm> playwright test -g "<name>"` |
| Deno | `deno.json` | `deno test <file>` | `deno test --filter "<name>"` |

(`<pm>` = `pnpm`/`npx`/`yarn`/`bunx`. When going through an npm script, `npm test -- <args>` needs
the `--`; `pnpm test <args>` doesn't.)

### Python — package manager / workflow (lockfile or manifest wins)

| Signal file | Tooling | Install | Run a tool |
|-------------|---------|---------|-----------|
| `uv.lock` | uv | `uv sync` | `uv run <tool>` |
| `poetry.lock` | Poetry | `poetry install` | `poetry run <tool>` |
| `pdm.lock` | PDM | `pdm install` | `pdm run <tool>` |
| `[tool.hatch.envs]` in `pyproject.toml` | Hatch | (implicit) | `hatch run <env>:<script>` |
| `pixi.toml` / `pixi.lock` | pixi (conda-forge) | `pixi install` | `pixi run <task>` |
| `Pipfile.lock` | pipenv | `pipenv install` | `pipenv run <tool>` |
| `environment.yml` | conda/mamba | `conda env create -f environment.yml` | `conda run <tool>` |
| `requirements*.txt` (only) | pip/venv | `pip install -r requirements.txt` | `<tool>` (in venv) |
| `pyproject.toml` (no lock) | pip/build | `pip install -e .` | `<tool>` |

- Prefer `uv run` / `poetry run` / `pdm run` prefixes so recipes work without a pre-activated venv.
- **Runtime version:** `.python-version`, `requires-python`, `.tool-versions` — record it.
- Capture real invocations from `pyproject.toml` `[tool.*]`, `Makefile`, `tox.ini`, `noxfile.py`:
  test (`pytest` / `python -m unittest`), lint/format (`ruff`, or `black`+`flake8`+`isort`),
  typecheck (`mypy`/`pyright`), and the **run entry** — which depends entirely on the archetype.
- **`.pre-commit-config.yaml`** present ⇒ `pre-commit run --all-files` is the one-shot lint entry;
  note which hooks it runs so agents don't run a different formatter.
- **Single test:** pytest — `pytest <file>::<test>` / `pytest -k "<expr>"`; unittest —
  `python -m unittest <pkg.module.Class.test>`.

### T-SQL — build / deploy toolchain (project file wins)

| Signal | Toolchain | Build | Deploy / run | Test |
|--------|-----------|-------|--------------|------|
| SDK-style `*.sqlproj` (`Microsoft.Build.Sql`) | .NET SDK + sqlpackage | `dotnet build <Db>.sqlproj` → `bin/<cfg>/<Db>.dacpac` | `sqlpackage /Action:Publish /SourceFile:<dacpac> /Profile:<env>.publish.xml` | tSQLt (see below) |
| Classic SSDT `*.sqlproj` | Visual Studio / Build Tools MSBuild + sqlpackage | `msbuild <Db>.sqlproj /p:Configuration=Release` | same sqlpackage publish (or VS *Publish…*) | tSQLt |
| Loose scripts (no project) | sqlcmd / PowerShell | n/a | `sqlcmd -S <srv> -d <db> -E -b -i <file.sql>` (in run order) | ad-hoc / tSQLt |
| SSIS (`*.dtproj`) | Visual Studio + SSIS extension | build → `bin/<cfg>/<Project>.ispac` | deploy to SSISDB (`ISDeploymentWizard` or catalog procs); run via SQL Agent job or `SSISDB.catalog.start_execution` | run package against a dev DB; row-count checks |

Details worth recording when present:

- **Preview before publish:** `sqlpackage /Action:Script` (emits the diff script) and
  `/Action:DeployReport` (XML of changes). This is the safe "what will this do" recipe — always include it
  for SSDT repos. `/p:BlockOnPossibleDataLoss=true` is the default; note if a profile turns it off.
- **Publish profiles** (`*.publish.xml`) hold target DB, SQLCMD variable values, and deploy options
  per environment. Recipes should name the profile, never paste a connection string. Flag profiles
  that contain passwords.
- **SQLCMD variables** (`$(DatabaseName)`, `$(Environment)`, cross-DB references like `$(StagingDb)`)
  are declared in the `.sqlproj` and set by profile or `/v:Name=Value`. Document each one.
- **Pre/post-deploy scripts** (`Script.PreDeployment.sql`, `Script.PostDeployment.sql`, usually with
  `:r` includes) — where reference/seed data and one-off data fixes live.
- **Refactor log** (`*.refactorlog`) — records renames so publish emits `sp_rename` instead of
  drop+create. Renames must go through it (VS *Rename* / `Refactor`), never by hand-editing names.
- **Database references** (`<ArtifactReference>` / `<PackageReference>` to `master.dacpac`,
  `msdb.dacpac`, or another project) — note cross-database dependencies.
- **Tests:** tSQLt test classes (schemas created via `tSQLt.NewTestClass`), often in a separate
  `*.Tests.sqlproj` that references the main one. Run all with `EXEC tSQLt.RunAll;`, one class with
  `EXEC tSQLt.Run 'TestClassName';`, one test with `EXEC tSQLt.Run 'TestClass.[test name]';` (via
  `sqlcmd -Q`). A local SQL Server (Docker `mcr.microsoft.com/mssql/server`, LocalDB
  `(localdb)\MSSQLLocalDB`) is usually required — record which.
- **Lint:** `sqlfluff lint --dialect tsql <path>` when `.sqlfluff` exists; SSDT's own build
  warnings (`SQL71502` unresolved reference etc.) — note any suppressed codes in the `.sqlproj`.
- **Scripts repos:** find the run order (numeric prefixes, a master `deploy.sql` with `:r` lines, a
  PowerShell driver using `Invoke-Sqlcmd` / dbatools), whether scripts are **idempotent**
  (`CREATE OR ALTER`, `IF NOT EXISTS`, `DROP … IF EXISTS`), and how environments are targeted.
- **SQL Agent jobs:** scripted jobs (`msdb.dbo.sp_add_job` / `sp_add_jobstep` / `sp_add_schedule`)
  — record the schedule and which package/proc each step runs.

### PostgreSQL — psql script repos (run list wins)

| Signal | Toolchain | Deploy / run | Preview | Test |
|--------|-----------|--------------|---------|------|
| `deploy.sql` of `\ir` lines / numbered folders | psql | `psql -X -v ON_ERROR_STOP=1 [-1] -f db/deploy.sql` | run in a throwaway DB, or diff `pg_dump --schema-only` before/after | pgTAP: `pg_prove -d <db> db/tests/` |
| shell / Make driver (`deploy.sh`, `make db`) | psql via the driver | use the driver (`make db ENV=dev`) and name the underlying `psql` call once | the driver's dry-run target, if any | per driver |
| `docker-entrypoint-initdb.d/` mounts | postgres image init | `docker compose down -v && docker compose up -d db` (re-inits from scratch) | n/a | same pgTAP run against the container |
| migration tool (Sqitch, Flyway, dbmate, …) | the tool | its migrate command (`sqitch deploy`, `dbmate up`, …) | `sqitch status`, `flyway info`, `dbmate status` | pgTAP / `sqitch verify` |

Details worth recording when present:

- **Always `-v ON_ERROR_STOP=1`.** Without it psql keeps going after an error and exits 0 — the
  single most common cause of half-applied deploys. `-X` skips the user's `~/.psqlrc`; `-1` wraps
  the whole file in one transaction — note whether the repo uses it (it can't be used when a script
  contains `CREATE INDEX CONCURRENTLY`, `VACUUM`, or `ALTER TYPE … ADD VALUE` on older servers).
- **Run order:** where the list lives (`\ir` lines in `deploy.sql`, folder numbering, a `Makefile`),
  and whether new files are picked up by glob or must be registered by hand. `\ir` resolves relative
  to the *including file*; `\i` relative to the *current directory* — note which is used.
- **Re-runnable vs one-shot:** most script repos re-run every object script on each deploy, so those
  must be **idempotent** (`CREATE TABLE IF NOT EXISTS`, `ALTER TABLE … ADD COLUMN IF NOT EXISTS`,
  `CREATE OR REPLACE FUNCTION/VIEW`, `DROP … IF EXISTS`, `DO $$ BEGIN IF NOT EXISTS (…) THEN … END IF;
  END $$`, `INSERT … ON CONFLICT DO UPDATE` for seed data). Destructive or data-moving changes often
  live in dated one-shot scripts (`changes/2026-09-01_split_name.sql`) tracked in a table
  (`ops.applied_change`) — find and document that mechanism.
- **Variables & connection:** `\set` / `-v name=value` and their use as `:name` / `:'name'` /
  `:"name"`; connection via `PGHOST`/`PGDATABASE`/`PGUSER`, `service=<name>` in `pg_service.conf`,
  or `.pgpass`. Recipes name the service/env vars, **never a connection string with a password**.
- **Roles & grants:** which roles own objects vs. the app's runtime role; `ALTER DEFAULT
  PRIVILEGES`; RLS policies (`CREATE POLICY`, `ENABLE ROW LEVEL SECURITY`) — note them, they're
  invisible in most app code.
- **Locking / online DDL:** `CREATE INDEX CONCURRENTLY`, `ADD CONSTRAINT … NOT VALID` +
  `VALIDATE CONSTRAINT`, `SET lock_timeout` — record the repo's rules for changing big tables.
- **Extensions & version:** `CREATE EXTENSION` list (PostGIS, `pg_trgm`, `pgcrypto`, `pg_cron`,
  `pgtap`) and the server major (compose image tag, `server_version_num` checks, CI service image).
- **Tests:** pgTAP files (`SELECT plan(n); … SELECT * FROM finish();` inside `BEGIN; … ROLLBACK;`),
  run all with `pg_prove -d <db> -r db/tests/`, one file with `pg_prove -d <db> db/tests/<file>.sql`.
- **Lint:** `sqlfluff lint --dialect postgres <path>`; `squawk <file.sql>` for migration-safety lint.
- **Scheduled jobs:** `pg_cron` (`cron.schedule('name', '<cron>', $$…$$)`) or external cron /
  systemd timers running `psql -f` — record schedule and what each touches.

### R — dependency manager / workflow (lockfile or project file wins)

| Signal | Tooling | Install / restore | Run |
|--------|---------|-------------------|-----|
| `renv.lock` | renv | `Rscript -e 'renv::restore()'` | `Rscript <file.R>` / `Rscript -e '<expr>'` (renv auto-activates via `.Rprofile`) |
| `DESCRIPTION` with `Package:` | package dev (devtools / R CMD) | `Rscript -e 'pak::local_install_deps()'` (or `remotes::install_deps()`) | `Rscript -e 'devtools::load_all()'` |
| `_targets.R` | targets | (via renv) | `Rscript -e 'targets::tar_make()'` |
| `_quarto.yml` / `*.qmd` | Quarto | (via renv) | `quarto render [<file>]` / `quarto preview` |
| `*.Rmd` (no Quarto) | R Markdown | (via renv) | `Rscript -e 'rmarkdown::render("<file>")'` |
| `app.R` / `ui.R`+`server.R` / `golem` | Shiny | (via renv) | `Rscript -e 'shiny::runApp("<dir>")'` |
| `default.nix` / `rix` | Nix | `nix-shell` | commands inside the shell |

- **R version:** `renv.lock` `"R": {"Version": …}`, `Depends: R (>= …)` in `DESCRIPTION`, a
  `.Rversion`/rig pin, or the CI `r-version` — record it.
- **Adding a dependency:** renv ⇒ `renv::install("<pkg>")` then **`renv::snapshot()`** (commit
  `renv.lock`); package ⇒ also add it to `Imports:` in `DESCRIPTION` (`usethis::use_package()`).
- **Package dev commands:** `devtools::document()` (roxygen → `NAMESPACE` + `man/` — **never hand-edit
  those**), `devtools::test()`, `devtools::check()` / `R CMD build . && R CMD check <tar.gz>`.
- **Single test (testthat):** one file `testthat::test_file("tests/testthat/test-<x>.R")` or
  `devtools::test(filter = "<x>")`; there is no per-`test_that()` filter — note that.
- **targets:** `tar_make()` all, `tar_make(names = c(<target>))` one target + upstream,
  `tar_outdated()` / `tar_visnetwork()` to see what will run, `tar_read(<target>)` to inspect,
  `tar_invalidate(<target>)` to force a rebuild. The store (`_targets/`) is output — never edit or
  commit it. Parallel/cluster backends (`crew`, `crew.cluster`, `clustermq`) — note the controller.
- **Lint/format:** `lintr::lint_dir()` / `lintr::lint_package()` (`.lintr`), `styler::style_dir()`
  (or `air format .`); `pre-commit` with `lorenzwalthert/precommit` hooks.
- **Paths & state:** `here::here()` vs relative paths, `.Rprofile` side effects, `options()` set at
  startup, `config.yml` (`config::get()`) per environment — record them; no `setwd()`.

### Slurm / HPC — submit layer (the batch scripts win)

| Signal | Submit | Watch | Inspect / cancel |
|--------|--------|-------|------------------|
| `#SBATCH` scripts | `sbatch slurm/<job>.sbatch [args]` | `squeue -u $USER` / `squeue --me` | `sacct -j <jobid> --format=JobID,State,Elapsed,MaxRSS,ExitCode`; `scancel <jobid>` |
| `submit.sh` chaining jobs | `bash slurm/submit.sh` (parses `sbatch --parsable` ids, `--dependency=afterok:<id>`) | same | `sacct` per id |
| Snakemake / Nextflow profile | `snakemake --profile profile/slurm` / `nextflow run … -profile slurm` | the workflow's log + `squeue` | the workflow's resume/rerun flags |
| targets + `crew.cluster` / `clustermq` | `tar_make()` from a login node or an `sbatch` wrapper | `tar_poll()` / `squeue` | `tar_meta(fields = error)` |

Details worth recording when present:

- **Resources per job:** `--partition`, `--account`, `--qos`, `--time`, `--mem` /
  `--mem-per-cpu`, `--cpus-per-task`, `--gres=gpu:…`, `--nodes`/`--ntasks` — as a table per script;
  agents otherwise invent partitions that don't exist on this cluster.
- **Arrays:** `--array=0-99%10` (the `%` throttle), how `$SLURM_ARRAY_TASK_ID` maps to inputs (a
  line of `params.csv`, a file index) and where each task writes. Record the max array size policy.
- **Dependencies:** `--dependency=afterok:<id>` / `afterany` / `singleton`; draw the job graph in the
  jobs module page.
- **Environment setup** inside the script: `module purge; module load R/4.4 python/3.12`,
  `source .venv/bin/activate` / `conda activate`, renv via `.Rprofile`, containers
  (`apptainer exec <img>.sif …`). Record the exact module names/versions — they're cluster-specific.
- **Storage:** `$SCRATCH` / `/scratch/$USER` (fast, purged) vs project/home (backed up, quota);
  which job writes where; what must be copied back.
- **Logs:** `#SBATCH -o logs/%x_%A_%a.out` patterns (`%x` name, `%j` job id, `%A` array master,
  `%a` task) — and that the `logs/` dir must exist before `sbatch` or the job dies silently.
- **Test small first:** `sbatch --test-only`, `--array=0-1`, a `debug` / `short` partition, or
  `salloc … srun --pty bash` for an interactive session — record which the cluster supports.
- **Login-node rule:** heavy compute never runs on login nodes; recipes must go through
  `sbatch`/`srun`/`salloc`. Note the cluster name and any site docs URL.
- **Local runs:** how to run one task without Slurm (`SLURM_ARRAY_TASK_ID=3 bash slurm/sim.sbatch`
  or the underlying `Rscript`/`python` call) — the fastest debug loop.

---

## Step 3 — Identify the archetype(s)

Match the repo against these from its **dependencies and layout**. A repo can be several; document the
dominant one(s). Signals are examples, not exhaustive.

### Application archetypes (Python / Node)

| Archetype | Python signals | Node signals | Entry points & what to document |
|-----------|----------------|--------------|---------------------------------|
| **Web service / API** | `fastapi`, `flask`, `django`, `starlette`, `litestar` | `express`, `fastify`, `@nestjs/core`, `koa`, `hono` | app object + routers/views; run cmd (`uvicorn`, `manage.py`, `node server`); one module page per router/app. Models/migrations **only if an ORM is present**. |
| **Frontend / SSR** | (rare) | `next`, `nuxt`, `vite`, `react`, `vue`, `@angular/core`, `astro`, `@sveltejs/kit` | pages/components/routing; dev server + build; App vs Pages router (Next). |
| **Data / analytics / ETL** | `pandas`, `polars`, `numpy`, `pyarrow`, `duckdb`, `dask`, `dbt-*` | `danfojs`, `arquero`, SQL runners | pipeline/script entry; ingest → transform → output; raw vs processed data locations. Module pages per **stage/dataset**. |
| **Orchestration / workflows** | `airflow`, `dagster`, `prefect`, `luigi` | workflow libs, `bullmq` flows | where DAGs/flows/tasks are defined; the schedule/trigger; how to run one task locally vs the whole DAG; the scheduler/UI. Module page per **DAG/flow**. |
| **Automation / scripting / jobs** | `schedule`, `apscheduler`, `watchdog`, `requests`/`httpx`, `scrapy`, `playwright`; `scripts/`, cron entries | `node-cron`, `chokidar`, `puppeteer`/`playwright`, `discord.js`/`telegraf`, `scripts/` | each job's **trigger** (cron / manual / file/event / webhook), its entry command, inputs/outputs and what it touches. Module page per **job/automation**. |
| **File-processing / batch** | `watchdog`, `glob`, `pathlib`, `Pillow`, `openpyxl` | `chokidar`, `fs`, `sharp`, `exceljs` | input/output dirs, the processing step, idempotency/retry, where processed files go. |
| **Worker / queue consumer** | `celery`, `rq`, `dramatiq`, `kafka`/`aio-pika` | `bullmq`, `bee-queue`, `kafkajs` | the broker, queue names, task/handler entry, how to run a worker locally. |
| **Serverless / functions** | Lambda/Cloud Function handlers, `serverless`, `chalice`, `functions-framework` | Lambda handlers, Vercel/Netlify functions, `serverless` | handler entry per function, event source, local invoke + deploy commands. |
| **ML / modeling** | `scikit-learn`, `torch`, `tensorflow`, `xgboost`, `transformers`, `mlflow` | `@tensorflow/tfjs`, `onnxruntime-node` | train/eval/predict entries; data + feature code; experiment/model tracking; artifacts location. |
| **Notebooks / research** | `jupyter`, `ipykernel`; `*.ipynb`, `notebooks/` | Observable/JS notebooks (rare) | how to launch; which notebooks matter and their order; reusable code extracted into the package. |
| **CLI** | `click`, `typer`, `argparse`; `[project.scripts]` | `commander`, `oclif`, `yargs`; `bin` in `package.json` | command entry + command groups. |
| **Library / package** | public API in `__init__.py` | `main`/`exports` in `package.json` | the package layout and its public surface; publish flow if any. |

### Database archetypes (T-SQL)

| Archetype | Signals | Entry points & what to document |
|-----------|---------|---------------------------------|
| **Database project (state-based)** | `*.sqlproj`, `*.publish.xml`, `*.refactorlog`, folders per schema/object type | the `.sqlproj` + profiles; schemas and who owns them; pre/post-deploy scripts; reference data; the build → dacpac → diff → publish flow. Module page per **schema / domain area** (plus one for reference data, and one for the app-facing contract if an app calls it). |
| **Script / DBA repo** | `*.sql` in run-ordered folders, `deploy.sql` with `:r`, `Invoke-Sqlcmd`/dbatools drivers, Agent job scripts, maintenance procs | run order and how to execute it; idempotency rules; environment targeting; what each script group touches (which DBs/servers). Module page per **script group / job**. |
| **Data warehouse / SSIS ETL** | `*.dtproj`/`*.dtsx`, `stg`/`dw`/`mart` (or `bronze/silver/gold`) schemas, `Dim*`/`Fact*` tables, watermark/audit tables, Agent schedules | the layers and load order; each package's source → target; full vs incremental loads and watermarks; SCD handling; the schedule and dependencies between jobs. Module page per **layer / package group / subject area**. |

### Database archetypes (PostgreSQL)

| Archetype | Signals | Entry points & what to document |
|-----------|---------|---------------------------------|
| **psql script repo** | `deploy.sql` with `\ir`, numbered folders, idempotent DDL, `psql -f` drivers, pgTAP | the run list and how to execute it (with `ON_ERROR_STOP`); re-runnable vs one-shot scripts; roles/grants/RLS; extensions; scheduled jobs (`pg_cron`). Module page per **schema / domain area** (plus one for maintenance jobs). |
| **Migration-tool repo** | Sqitch / Flyway / dbmate / golang-migrate / Supabase layout | the tool and its deploy/status/revert commands; naming rules for new migrations; never edit an applied migration. Module page per **schema / domain area**. |
| **App + Postgres** | an app (any language) plus a `db/` of the above | the **function/view contract** the app calls (signatures, return shapes, `ERRCODE`s raised), RLS/role assumptions, which app files call what — as a `api-contract` / seam page. |

### R archetypes

| Archetype | Signals | Entry points & what to document |
|-----------|---------|---------------------------------|
| **R package** | `DESCRIPTION` with `Package:`, `NAMESPACE`, `R/`, `man/`, `tests/testthat/` | exported API (roxygen `@export`), internal helpers, the document → test → check loop, vignettes, CRAN/r-universe release if any. Module page per **functional area of `R/`**. |
| **Analysis / pipeline** | `_targets.R`, `R/` of functions, `data-raw/`, `analysis/`, `Makefile` of `Rscript` calls | the pipeline graph (targets or scripts in order), raw vs derived data locations, how to rerun one step, outputs (figures/tables/models). Module page per **pipeline stage**. |
| **Shiny app** | `app.R`, `ui.R`/`server.R`, `golem`/`rhino`, `modules/` | run command, module layout (`mod_*`), data loading, deploy target (shinyapps.io, Posit Connect `rsconnect`, Docker). Module page per **Shiny module / tab**. |
| **Reports / site / book** | `_quarto.yml`, `*.qmd`/`*.Rmd`, `_bookdown.yml` | render commands, parameters (`params:`), freeze/cache (`_freeze/`), publish target. Module page per **report / chapter group**. |

### HPC / Slurm batch archetypes (combine with the language archetype above)

| Archetype | Signals | Entry points & what to document |
|-----------|---------|---------------------------------|
| **Job-per-stage pipeline** | one `*.sbatch` per step, `submit.sh` chaining with `afterok` | the job graph, each job's resources/inputs/outputs, the submit command, how to rerun one stage. Module page for **jobs** (the scheduler is the seam) plus one per stage's code. |
| **Parameter sweep / simulation** | `--array`, `params.csv`/grid files, `$SLURM_ARRAY_TASK_ID` in code | task-id → parameter mapping, per-task outputs, the aggregation step, how to rerun failed tasks only. |
| **Workflow manager on Slurm** | Snakemake/Nextflow profiles, targets + `crew.cluster` | the workflow's own run/resume commands, the Slurm profile's resource defaults, where logs land. |

Natural **module-page boundaries** follow the archetype: a router/app, a pipeline stage, a DAG/flow,
a job/automation, a queue worker, a serverless function, an ML train/serve concern, a notebook group,
a CLI command group, a workspace package, a DB schema/subject area, a warehouse layer, an SSIS
package group, an R package area or Shiny module, a report group, or a Slurm job group.

---

## Persistence & external state (a separate axis — detect independently)

Do **not** tie storage to "web". Detect it on its own and document only what exists:

- **Relational + ORM:** `sqlalchemy`, Django ORM, `sqlmodel`, `peewee`; `prisma`, `typeorm`,
  `drizzle`, `knex` → document models + **migrations** (`alembic`, `manage.py migrate`,
  `prisma migrate`, `drizzle-kit`).
- **Database-as-code (T-SQL repos):** the database **is** the codebase. Document schemas, the deploy
  model (state-based dacpac vs ordered scripts vs migration tool), and environments. In an SSDT
  project the `.sql` files declare the **desired state** — never hand-write `ALTER TABLE` in them;
  the dacpac diff generates the ALTERs at publish time. Data changes go in post-deploy scripts,
  renames go through the refactorlog.
- **Database-as-code (PostgreSQL script repos):** there is no diff engine — scripts both declare
  *and* change state, so what matters is **run order** and **idempotency**. Document which scripts
  re-run every deploy (must be idempotent) vs. one-shot changes (and how they're tracked), plus
  roles, grants and RLS.
- **Files / object storage / warehouse:** parquet/CSV/RDS on disk, S3/GCS, DuckDB, BigQuery,
  Snowflake → document the data layout, not migrations. On HPC, note scratch vs project storage and
  purge policies.
- **Cache / broker:** Redis, RabbitMQ, Kafka → document connection + what uses it.
- **No datastore:** many automations/scripts/libraries have none — don't invent one.

`pydantic` is validation/settings (common in web *and* data/automation code) — note it, but it is
**not** a signal of a web app or a database.

---

## Ground truth for commands

Before trusting a script name, check what actually runs:

- **CI workflows** — `.github/workflows/*.yml`, `azure-pipelines.yml`, `.gitlab-ci.yml`,
  `Jenkinsfile`. The install/build/test/lint steps there are proven to work; copy them (minus
  CI-only flags). For T-SQL repos, CI often shows the only complete build → publish → tSQLt sequence.
- **Task runners** — `Makefile`, `justfile`, `Taskfile.yml`, `tox.ini`, `noxfile.py`, PowerShell
  `build.ps1`/`psake`. If a task runner wraps the tooling, recipes should use the runner
  (`make test`, `just test`) and mention the underlying command once.
- **Containers** — `Dockerfile`, `docker-compose.yml`/`compose.yaml`, `.devcontainer/`: note the
  combined dev flow (`docker compose up`) and any local SQL Server / Redis / Postgres containers.
- **Environment** — `.env.example` / `.env.sample` / `appsettings.Development.json` list the required
  variables; name them in the Stack block or conventions (never copy real values).

When sources disagree, prefer CI, note the discrepancy in the page, and mark it `status: draft`.

---

## Hybrid / polyglot repos

Common in practice: a Node frontend/API with a Python data/ML/automation backend; a Python service
that shells out to Node tooling; JS glue around Python workers; **an app (C#/.NET, Python, Node) plus
a `.sqlproj` for its database**; SSIS packages next to Python ingestion scripts; **an app over a
Postgres `db/` script folder**; **Python preprocessing feeding R models**; **any of these submitted
to a Slurm cluster**. When Step 1 finds more than one language:

- **Map by component, not by language.** In `index.md`, give each component its own row (and module
  page) with **its own toolchain** — e.g. `web/` (pnpm, Next.js), `worker/` (uv, Celery),
  `db/` (dotnet, SDK-style sqlproj). Use a **Components** table like the monorepo Packages table.
- **Record each part's real commands** in `recipes.md` under clear headings (e.g. "Run the web app"
  vs "Publish the database"), plus the **combined dev flow** if there is one (`Makefile`,
  `docker-compose.yml`, `Procfile`, `turbo`/`nx` task, a root `scripts/dev`).
- **Document the seam explicitly** — the highest-value thing in a hybrid repo. How do the parts talk?
  Subprocess/CLI call, HTTP/gRPC, a shared queue, shared files/DB, FFI — or, for app + database, the
  **stored-procedure / view contract**: which procs/views the app calls, their parameters and
  result-set shapes, error numbers raised with `THROW`, and which app files call them; for app +
  Postgres the **function/view contract** (signatures, `RETURNS TABLE` shapes, `ERRCODE`s from
  `RAISE`, the role the app connects as, RLS policies it relies on). For Python ↔ R it's usually
  **files** (parquet/feather/CSV paths and schemas) or `reticulate`/`rpy2`. For Slurm pipelines the
  **scheduler is the seam**: which job produces which files, the dependency chain, and array-task
  indexing. Give it its own module page.
- **Per-language conventions** live in `conventions.md` under separate subsections; don't force one
  toolchain's rules onto the other.

Treat a hybrid repo much like a monorepo whose "packages" happen to be different languages.

---

## Monorepos / workspaces

Detect and, when present, create **one module page per package** plus a **Packages** table in
`index.md` (package → path → purpose → module page).

| Signal | Ecosystem | Packages live in |
|--------|-----------|------------------|
| `workspaces` in `package.json` | npm/yarn/bun | globs there (often `packages/*`, `apps/*`) |
| `pnpm-workspace.yaml` | pnpm | globs in that file |
| `turbo.json` | Turborepo | per workspaces; note pipeline tasks |
| `nx.json` | Nx | `apps/`, `libs/`; note project targets |
| `lerna.json` | Lerna | `packages` field |
| `[tool.uv.workspace]` in root `pyproject.toml` | uv | `members` globs |
| multiple `pyproject.toml` | Python (poetry/pdm/hatch) | each dir with a `pyproject.toml` |
| `*.sln` with several `*.sqlproj` | SQL Server | one project per database (plus `*.Tests.sqlproj`) |
| several `DESCRIPTION` files | R | one package per dir (often `pkgs/*`); renv may be shared at the root |

Record how to run a task for **one package** (`pnpm --filter <pkg> test`, `turbo run test
--filter=<pkg>`, `nx test <project>`, `uv run --package <pkg> pytest`,
`dotnet build db/<Db>/<Db>.sqlproj`, `Rscript -e 'devtools::test("pkgs/<pkg>")'`). A polyglot monorepo combines this with the hybrid guidance
above.

---

## What to put on each page

- **`index.md` Stack block:** runtime version(s), package manager(s)/toolchain, and the real
  run/build/test/lint/typecheck (or build/preview/publish/test for databases) commands. Slurm repos
  add a **Cluster** line (cluster name, default partition/account, module versions). Monorepo →
  Packages table; hybrid → Components table (one row per component with its own toolchain).
- **`recipes.md`:** install, run, test (+ single test), lint/format/typecheck, add a dependency — then
  the **archetype-specific** tasks, and only those that apply. Examples:
  - web + ORM → add an endpoint, add a migration;
  - data/ETL → run the pipeline, add a data source, add a transform;
  - orchestration → run a task vs the whole DAG, add a task, trigger/backfill;
  - automation/jobs → run the job, its schedule/trigger, add a new job;
  - worker → start a worker, enqueue a job, add a task;
  - serverless → invoke locally, deploy;
  - ML → train, evaluate, run inference; CLI → run/add a command;
  - **database project** → build the dacpac, **preview the deploy script**, publish to local, add a
    table / proc / view, add reference data (post-deploy), rename safely (refactorlog), add a tSQLt
    test;
  - **script repo** → run the deploy in order against an environment, add a script in the right
    place (idempotent), add/alter an Agent job;
  - **warehouse / SSIS** → run a package locally, run the nightly job, add a dimension / fact, add an
    incremental load (watermark), backfill a date range;
  - **psql script repo** → reset + deploy a local DB, deploy to an environment (`ON_ERROR_STOP`),
    add an idempotent object script and register it in the run list, add a one-shot data change,
    change a big table safely (concurrent index / `NOT VALID`), add a pgTAP test, add a `pg_cron` job;
  - **R package** → load/document/test/check, add a function (roxygen + export), add a dependency
    (`DESCRIPTION` + renv snapshot), add a test;
  - **R analysis / targets** → run the pipeline, rerun one target, add a target, render the report;
  - **Shiny** → run the app, add a module, deploy;
  - **Slurm** → submit the pipeline, submit one stage, test small (`--array=0-1` / debug partition),
    check status and failures (`sacct`), rerun failed array tasks, run one task locally, add a job.
  Never write an endpoint/migration recipe for a repo with no web/ORM tooling, never an
  `ALTER TABLE` recipe for a state-based SSDT project, and never a Slurm recipe that computes on the
  login node.
- **`conventions.md`:** package manager(s), runtime version, formatter/linter/type-check config
  locations, import boundaries, ESM vs CJS, TS `strict` / Python typing, plus archetype conventions
  (data: raw vs processed layout, don't-commit-data, reproducibility; automation: idempotency,
  logging, secrets/env). **T-SQL conventions** to capture from the code, not from best practice:
  object naming (`usp_` prefixes or not, `PK_`/`FK_`/`IX_`/`DF_` constraint names), schema ownership,
  `SET NOCOUNT ON` / `SET XACT_ABORT ON` in procs, error handling (`TRY…CATCH` + `THROW` vs
  `RAISERROR`, custom error numbers), explicit column lists (no `SELECT *` in procs/views),
  schema-qualified names, `$(DatabaseName)` for cross-DB refs, `CREATE OR ALTER` in scripts,
  date/time types, and no secrets in publish profiles. **PostgreSQL conventions:** `snake_case`
  identifiers (no quoted mixed case), schema-qualified names vs `search_path`, `timestamptz` over
  `timestamp`, `text` over `varchar(n)`, identity vs `serial`, constraint naming, idempotency idioms
  per script kind, function language/volatility (`STABLE`, `SECURITY DEFINER` + `SET search_path`),
  custom `ERRCODE`s, grant/role rules, online-DDL rules. **R conventions:** tidyverse vs base style,
  `pkg::fn` vs `library()`, roxygen tags, `here::here()` paths, where data/outputs live, seeds for
  reproducibility, `renv::snapshot()` after dependency changes. **Slurm conventions:** script
  header order, default resources, log naming, `set -euo pipefail`, module versions, scratch usage,
  array sizing/throttle. Hybrid → one subsection per language.
- **`modules/*`:** one per natural unit for the archetype (see Step 3) or per package/component. For
  DB-shaped modules, fill the template's optional **Database objects** block; for Slurm job groups,
  its optional **Jobs** block.

Mirror the bundled worked example closest to the repo's archetype for shape and brevity:
`examples/node-app/` (Express + TS web service), `examples/python-webapp/` (FastAPI + SQLAlchemy),
`examples/python-analytics/` (pandas/polars ETL — no web, no ORM), `examples/hybrid-app/` (Node web +
Python worker over Redis — Components table + a `seam` module page for the cross-language contract),
`examples/tsql-database/` (SDK-style `.sqlproj` + tSQLt behind an app — schema module pages +
an `api-contract` page for the proc contract), `examples/tsql-warehouse/` (SSIS + ordered sqlcmd
scripts + SQL Agent jobs — layer module pages), `examples/postgres-database/` (psql script repo +
pgTAP + `pg_cron` behind a Node API — schema pages + an `api-contract` page for the function
contract), `examples/r-analysis/` (renv + targets + Quarto + testthat — pipeline/report pages), and
`examples/hpc-slurm/` (Python preprocessing + R models submitted as chained Slurm array jobs —
Components table + a `jobs` page as the seam). The same page shapes extend to orchestration,
automation, worker, R package and Shiny repos.
