---
updated: YYYY-MM-DD
covers: [recipes, how-to]
status: draft
---

# Recipes

Step-by-step playbooks for the common tasks in this repo. Fill each with the **real commands** for
the detected package manager (e.g. `pnpm`/`npm`/`yarn`/`bun`, or `uv`/`poetry`/`pip`) — a recipe with
the wrong command is worse than none. Delete any recipe whose tooling this repo doesn't use; add
repo-specific ones. Keep the file to the tasks agents actually repeat.

## Run locally

```bash
# install deps, set up env/db, start the app
# Node e.g.:   pnpm install && pnpm dev
# Python e.g.: uv sync && uv run uvicorn app.main:app --reload
```

## Run tests

```bash
# all / single file / single test
# Node e.g.:   pnpm test            | pnpm test -- <file>          | pnpm test -- -t "<name>"
# Python e.g.: uv run pytest        | uv run pytest <file>         | uv run pytest <file>::<test>
```

## Lint / format / typecheck

```bash
# Node e.g.:   pnpm lint | pnpm format | pnpm typecheck
# Python e.g.: uv run ruff check . | uv run ruff format . | uv run mypy <pkg>
```

## Add a dependency

```bash
# Node e.g.:   pnpm add <pkg>   (dev: pnpm add -D <pkg>)
# Python e.g.: uv add <pkg>     (dev: uv add --dev <pkg>)
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

For each kept task, write the concrete steps and the files to touch:

1. _<create/extend `<path>`>_
2. _<wire it up / register / configure>_
3. _<add a test at `<path>` and run the test command above>_

## Release / deploy

_How a change gets shipped (if relevant)._
