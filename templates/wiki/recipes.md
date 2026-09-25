---
updated: YYYY-MM-DD
covers: [recipes, how-to]
status: draft
---

# Recipes

Step-by-step playbooks for the common tasks in this repo. Fill each with the **real commands** for
the detected toolchain (e.g. `pnpm`/`npm`/`yarn`/`bun`, `uv`/`poetry`/`pip`, or
`dotnet`+`sqlpackage`/`sqlcmd` for T-SQL, `psql` for PostgreSQL, `Rscript`+renv for R, `sbatch` for
Slurm) — a recipe with the wrong command is worse than none. When
in doubt, copy what CI runs. Delete any recipe whose tooling this repo doesn't use; add repo-specific
ones. Keep the file to the tasks agents actually repeat.

## Run locally

```bash
# install deps, set up env/db, start the app
# Node e.g.:   pnpm install && pnpm dev
# Python e.g.: uv sync && uv run uvicorn app.main:app --reload
# T-SQL e.g.:  docker compose up -d sql && dotnet tool restore
# Postgres e.g.: docker compose up -d db && psql -X -v ON_ERROR_STOP=1 -f db/deploy.sql
# R e.g.:      Rscript -e 'renv::restore()' && Rscript -e 'targets::tar_make()'
```

## Build / deploy (database projects)

```bash
# SDK-style sqlproj e.g.:
#   dotnet build db/Db.sqlproj
#   sqlpackage /Action:Script  /SourceFile:db/bin/Debug/Db.dacpac /Profile:db/Local.publish.xml /OutputPath:preview.sql   # read it first
#   sqlpackage /Action:Publish /SourceFile:db/bin/Debug/Db.dacpac /Profile:db/Local.publish.xml
# Script repo e.g.: sqlcmd -S <server> -d <db> -E -b -i sql/deploy.sql -v Env=Dev
# psql script repo e.g.: PGSERVICE=billing_dev psql -X -v ON_ERROR_STOP=1 -1 -f db/deploy.sql
```

## Submit jobs (Slurm)

```bash
# e.g.: bash slurm/submit.sh                      # whole chain (afterok dependencies)
#       sbatch --array=0-1 slurm/simulate.sbatch  # test small first
#       squeue --me ; sacct -j <jobid> --format=JobID,State,Elapsed,MaxRSS,ExitCode
```

## Run tests

```bash
# all / single file / single test
# Node e.g.:   pnpm test            | pnpm vitest run <file>       | pnpm vitest run -t "<name>"
# Python e.g.: uv run pytest        | uv run pytest <file>         | uv run pytest <file>::<test>
# T-SQL e.g.:  sqlcmd … -Q "EXEC tSQLt.RunAll" | "EXEC tSQLt.Run 'test_Class'" | "EXEC tSQLt.Run 'test_Class.[test name]'"
# Postgres e.g.: pg_prove -d <db> -r db/tests/ | pg_prove -d <db> db/tests/<file>.sql
# R e.g.:      Rscript -e 'devtools::test()' | Rscript -e 'testthat::test_file("tests/testthat/test-<x>.R")'
```

## Lint / format / typecheck

```bash
# Node e.g.:   pnpm lint | pnpm format | pnpm typecheck      (Biome: pnpm biome check --write)
# Python e.g.: uv run ruff check . | uv run ruff format . | uv run mypy <pkg>   (or: pre-commit run --all-files)
# T-SQL e.g.:  sqlfluff lint <dir> --dialect tsql      (Postgres: --dialect postgres; squawk <file>)
# R e.g.:      Rscript -e 'lintr::lint_dir()' | Rscript -e 'styler::style_dir()'
```

## Add a dependency

```bash
# Node e.g.:   pnpm add <pkg>   (dev: pnpm add -D <pkg>)
# Python e.g.: uv add <pkg>     (dev: uv add --dev <pkg>)
# T-SQL e.g.:  <ArtifactReference>/<PackageReference> to a dacpac in the .sqlproj + a SQLCMD variable
# R e.g.:      Rscript -e 'renv::install("<pkg>"); renv::snapshot()'   (package: also Imports: in DESCRIPTION)
```

## _<Archetype task — keep the ones that fit this repo, delete the rest>_

Pick the tasks that match what this repo actually is (see the plugin's `stacks.md`). Examples:

- **Web + ORM** — _add an endpoint_ (route → handler → wire up → test); _add a migration_
  (`prisma migrate dev` / `alembic revision --autogenerate` / `manage.py makemigrations`).
- **Data / ETL** — _run the pipeline_; _add a data source_; _add a transform_.
- **Orchestration** — _run one task_ vs _the whole DAG/flow_; _add a task_; _trigger / backfill_.
- **Automation / job** — _run the job_; its _schedule / trigger_; _add a new job_.
- **Worker / queue** — _start a worker_; _enqueue a job_; _add a task_.
- **Serverless** — _invoke locally_; _deploy_.
- **ML** — _train_; _evaluate_; _run inference_.
- **CLI** — _run a command_; _add a command_.
- **Database project (SSDT/sqlproj)** — _preview the deploy script_; _add a table / column / proc_
  (edit the `CREATE`, never write `ALTER`); _add reference data_ (post-deploy MERGE); _rename safely_
  (refactorlog); _add a tSQLt test_.
- **SQL script / DBA repo** — _deploy in run order_; _add an idempotent script_ (`CREATE OR ALTER`,
  `IF NOT EXISTS`) and register it in the run list; _add / change an Agent job_.
- **Warehouse / SSIS** — _run one package_; _run the nightly job_; _add a dimension / fact_; _add an
  incremental load (watermark)_; _backfill a date range_.
- **PostgreSQL psql script repo** — _reset + deploy a local DB_; _deploy to an environment_
  (`ON_ERROR_STOP`); _add an idempotent object script_ and register it in the `\ir` run list; _add a
  one-shot data change_; _change a big table safely_ (`CONCURRENTLY`, `NOT VALID`); _add a pgTAP
  test_; _add a `pg_cron` job_.
- **R package** — _document / test / check_; _add an exported function_ (roxygen); _add a
  dependency_; _add a test_.
- **R analysis / targets** — _run the pipeline_; _rerun one target_; _add a target_; _render the
  report_. **Shiny** — _run the app_; _add a module_; _deploy_.
- **Slurm** — _submit the chain_; _submit one stage_; _test small_; _check failures_ (`sacct`);
  _rerun failed array tasks_; _run one task locally_; _add a job_. Never compute on a login node.

For each kept task, write the concrete steps and the files to touch:

1. _<create/extend `<path>`>_
2. _<wire it up / register / configure>_
3. _<add a test at `<path>` and run the test command above>_

## Release / deploy

_How a change gets shipped (if relevant)._
