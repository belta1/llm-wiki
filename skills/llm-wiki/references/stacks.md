# Stack playbook — Python & Node.js (and hybrids)

This plugin is optimized for **Python** and **Node.js** repos of any shape — web services, data
pipelines, orchestrated workflows, automations/scripts, file-processing jobs, workers, serverless
functions, CLIs, libraries — and **repos that mix both languages**. Read this before filling a wiki
so the recipes carry *real, runnable* commands and the module pages match what the repo actually is.

Two rules govern everything below:

1. **Detect, don't guess.** Read the lockfile / manifest / scripts and record exactly what a dev on
   this repo would type. A recipe with the wrong package manager is worse than none.
2. **Don't presume a shape.** "Node" doesn't mean web frontend; "Python" doesn't mean web + ORM.
   Identify the *archetype(s)* from dependencies and layout, and a repo may be polyglot.

Work in three steps: (1) which languages are present, (2) each language's toolchain, (3) the
archetype(s). Then write.

---

## Step 1 — Which languages are present?

Check for manifests at the root **and in subdirectories**:

- **Node:** `package.json` (+ a lockfile).
- **Python:** `pyproject.toml`, `setup.py/.cfg`, `requirements*.txt`, `Pipfile`, `environment.yml`.

Both present ⇒ **hybrid/polyglot** — see [that section](#hybrid--polyglot-repos-node--python). Also
scan for other languages you should at least name in the wiki (Go, Rust, shell, Dockerfiles, IaC),
even if this plugin focuses on Node/Python.

---

## Step 2 — Per-language toolchain

### Node.js — package manager (lockfile wins)

| Signal file | Package manager | Install | Run script |
|-------------|-----------------|---------|-----------|
| `pnpm-lock.yaml` | pnpm | `pnpm install` | `pnpm <script>` |
| `yarn.lock` | yarn | `yarn` | `yarn <script>` |
| `bun.lockb` | bun | `bun install` | `bun run <script>` |
| `package-lock.json` (or none) | npm | `npm install` | `npm run <script>` |

Also check `packageManager` in `package.json` — authoritative when present. Capture the **real
`scripts`**: run/dev (`dev`/`start`), `build`, `test` (+ single-test filter), `lint`, `format`,
`typecheck`. `tsconfig.json` ⇒ TypeScript (note `strict`, `outDir`); no tsconfig ⇒ plain JS, don't
invent a typecheck recipe.

### Python — package manager / workflow (lockfile or manifest wins)

| Signal file | Tooling | Install | Run a tool |
|-------------|---------|---------|-----------|
| `uv.lock` | uv | `uv sync` | `uv run <tool>` |
| `poetry.lock` | Poetry | `poetry install` | `poetry run <tool>` |
| `Pipfile.lock` | pipenv | `pipenv install` | `pipenv run <tool>` |
| `environment.yml` | conda/mamba | `conda env create -f environment.yml` | `conda run <tool>` |
| `requirements*.txt` (only) | pip/venv | `pip install -r requirements.txt` | `<tool>` (in venv) |
| `pyproject.toml` (no lock) | pip/build | `pip install -e .` | `<tool>` |

Prefer `uv run` / `poetry run` prefixes so recipes work without a pre-activated venv. Capture real
invocations from `pyproject.toml` `[tool.*]`, `Makefile`, `tox.ini`, `noxfile.py`: test (`pytest` /
`python -m unittest`, + single-test), lint/format (`ruff`, or `black`+`flake8`+`isort`), typecheck
(`mypy`/`pyright`), and the **run entry** — which depends entirely on the archetype (Step 3).

---

## Step 3 — Identify the archetype(s) (language-neutral)

Match the repo against these from its **dependencies and layout**. A repo can be several; document the
dominant one(s). Signals are examples, not exhaustive.

| Archetype | Python signals | Node signals | Entry points & what to document |
|-----------|----------------|--------------|---------------------------------|
| **Web service / API** | `fastapi`, `flask`, `django`, `starlette` | `express`, `fastify`, `@nestjs/core`, `koa` | app object + routers/views; run cmd (`uvicorn`, `manage.py`, `node server`); one module page per router/app. Models/migrations **only if an ORM is present**. |
| **Frontend / SSR** | (rare) | `next`, `nuxt`, `vite`, `react`, `vue`, `@angular/core` | pages/components/routing; dev server + build; App vs Pages router (Next). |
| **Data / analytics / ETL** | `pandas`, `polars`, `numpy`, `pyarrow`, `duckdb`, `dask` | `danfojs`, `arquero`, SQL runners | pipeline/script entry; ingest → transform → output; raw vs processed data locations. Module pages per **stage/dataset**. |
| **Orchestration / workflows** | `airflow`, `dagster`, `prefect`, `luigi` | workflow libs, `bullmq` flows | where DAGs/flows/tasks are defined; the schedule/trigger; how to run one task locally vs the whole DAG; the scheduler/UI. Module page per **DAG/flow**. |
| **Automation / scripting / jobs** | `schedule`, `apscheduler`, `watchdog`, `requests`/`httpx`, `scrapy`, `playwright`; `scripts/`, cron entries | `node-cron`, `chokidar` (file watch), `puppeteer`/`playwright`, `discord.js`/`telegraf`, `scripts/` | each job's **trigger** (cron / manual / file/event / webhook), its entry command, inputs/outputs and what it touches (filesystem, APIs). Module page per **job/automation**. |
| **File-processing / batch** | `watchdog`, `glob`, `pathlib`, `Pillow`, `openpyxl` | `chokidar`, `fs`, `sharp`, `exceljs` | input/output dirs, the processing step, idempotency/retry, where processed files go. |
| **Worker / queue consumer** | `celery`, `rq`, `dramatiq`, `kafka`/`aio-pika` | `bullmq`, `bee-queue`, `kafkajs` | the broker, queue names, task/handler entry, how to run a worker locally. |
| **Serverless / functions** | Lambda/Cloud Function handlers, `serverless`, `chalice`, `functions-framework` | Lambda handlers, Vercel/Netlify functions, `serverless` | handler entry per function, event source, local invoke + deploy commands. |
| **ML / modeling** | `scikit-learn`, `torch`, `tensorflow`, `xgboost`, `transformers`, `mlflow` | `@tensorflow/tfjs`, `onnxruntime-node` | train/eval/predict entries; data + feature code; experiment/model tracking; artifacts location. |
| **Notebooks / research** | `jupyter`, `ipykernel`; `*.ipynb`, `notebooks/` | Observable/JS notebooks (rare) | how to launch; which notebooks matter and their order; reusable code extracted into the package. |
| **CLI** | `click`, `typer`, `argparse`; `[project.scripts]` | `commander`, `oclif`, `yargs`; `bin` in `package.json` | command entry + command groups. |
| **Library / package** | public API in `__init__.py` | `main`/`exports` in `package.json` | the package layout and its public surface; publish flow if any. |

Natural **module-page boundaries** follow the archetype: a router/app, a pipeline stage, a DAG/flow,
a job/automation, a queue worker, a serverless function, an ML train/serve concern, a notebook group,
a CLI command group, or a workspace package.

---

## Persistence & external state (a separate axis — detect independently)

Do **not** tie storage to "web". Detect it on its own and document only what exists:

- **Relational + ORM:** `sqlalchemy`, Django ORM, `sqlmodel`, `peewee`; `prisma`, `typeorm`,
  `drizzle`, `knex` → document models + **migrations** (`alembic`, `manage.py migrate`,
  `prisma migrate`, `drizzle-kit`).
- **Files / object storage / warehouse:** parquet/CSV on disk, S3/GCS, DuckDB, BigQuery, Snowflake →
  document the data layout, not migrations.
- **Cache / broker:** Redis, RabbitMQ, Kafka → document connection + what uses it.
- **No datastore:** many automations/scripts/libraries have none — don't invent one.

`pydantic` is validation/settings (common in web *and* data/automation code) — note it, but it is
**not** a signal of a web app or a database.

---

## Hybrid / polyglot repos (Node + Python)

Common in practice: a Node frontend/API with a Python data/ML/automation backend; a Python service
that shells out to Node tooling; a repo of mixed scripts; JS glue around Python workers. When Step 1
finds more than one language:

- **Map by component, not by language.** In `index.md`, give each component its own row (and module
  page) with **its own toolchain** — e.g. `web/` (pnpm, Next.js) and `worker/` (uv, Celery). Use a
  **Components** table like the monorepo Packages table.
- **Record each part's real commands** in `recipes.md` under clear headings (e.g. "Run the web app"
  vs "Run the worker"), plus the **combined dev flow** if there is one (a top-level `Makefile`,
  `docker-compose.yml`, `Procfile`, `turbo`/`nx` task, or a root `scripts/dev`).
- **Document the seam explicitly** — the highest-value thing in a hybrid repo. How do the languages
  talk? Subprocess/CLI call, HTTP/gRPC, a shared queue (Celery/BullMQ), shared files/DB, or FFI. Note
  the contract (payload shape, paths, env) and where it's defined. Give it its own note or module
  page.
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
| multiple `pyproject.toml` | Python (uv/poetry) | each dir with a `pyproject.toml` |

Record how to run a task for **one package** (`pnpm --filter <pkg> test`, `turbo run test
--filter=<pkg>`, `nx test <project>`, `uv run --package <pkg> pytest`). A polyglot monorepo combines
this with the hybrid guidance above.

---

## What to put on each page

- **`index.md` Stack block:** package manager(s) and the real run/build/test/lint/typecheck commands.
  Monorepo → Packages table; hybrid → Components table (one row per component with its own toolchain).
- **`recipes.md`:** install, run, test (+ single test), lint/format/typecheck, add a dependency — then
  the **archetype-specific** tasks, and only those that apply. Examples:
  - web + ORM → add an endpoint, add a migration;
  - data/ETL → run the pipeline, add a data source, add a transform;
  - orchestration → run a task vs the whole DAG, add a task, trigger/backfill;
  - automation/jobs → run the job, its schedule/trigger, add a new job;
  - worker → start a worker, enqueue a job, add a task;
  - serverless → invoke locally, deploy;
  - ML → train, evaluate, run inference; CLI → run/add a command.
  Never write an endpoint/migration recipe for a repo with no web/ORM tooling.
- **`conventions.md`:** package manager(s), formatter/linter/type-check config locations, import
  boundaries, TS `strict` / Python typing, plus archetype conventions (data: raw vs processed layout,
  don't-commit-data, reproducibility; automation: idempotency, logging, secrets/env). Hybrid → one
  subsection per language.
- **`modules/*`:** one per natural unit for the archetype (see Step 3) or per package/component.

Mirror the bundled worked example closest to the repo's archetype for shape and brevity:
`examples/node-app/` (Express + TS web service), `examples/python-webapp/` (FastAPI + SQLAlchemy), and
`examples/python-analytics/` (pandas/polars ETL — no web, no ORM). The same page shapes extend to
orchestration, automation, worker, and hybrid repos.
