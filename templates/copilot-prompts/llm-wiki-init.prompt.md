---
mode: agent
description: Populate or refresh this repo's .llm-wiki/ knowledge base so Copilot orients fast and uses fewer tokens.
---

# Populate the LLM Wiki

You are maintaining `.llm-wiki/`, a compiled knowledge base for AI coding agents. **Scan this
repository and fill in (or create) the pages** so an agent can orient from `.llm-wiki/index.md` alone
instead of searching the whole tree. Read the code — the code is the source of truth. If `.llm-wiki/`
doesn't exist yet, create it.

## 1. Detect the stack — don't guess, and don't assume it's a web app

- **Languages present** — check manifests at the root *and* in subdirectories. A `package.json` *and*
  a `pyproject.toml` ⇒ a **polyglot/hybrid** repo: map it by component.
- **Package manager** from the lockfile — Node: `pnpm-lock.yaml` / `yarn.lock` / `bun.lockb` /
  `package-lock.json`; Python: `uv.lock` / `poetry.lock` / `Pipfile.lock` / `requirements*.txt`. The
  lockfile decides how every command is spelled (`pnpm test`, `uv run pytest`, …).
- **Real commands** (only those actually configured): install, run/dev, build, test (+ single test),
  lint, format, typecheck — from `package.json` scripts, `pyproject.toml` `[tool.*]`, Makefile/tox/nox.
- **Project archetype** — one or more of: web service, data/analytics/ETL, orchestration
  (Airflow/Dagster/Prefect), automation/scripting/jobs, file-processing, worker/queue consumer,
  serverless, ML, notebooks, CLI, library. Shape the pages to what the repo *actually is*.
- **Persistence is a separate axis** — document models + migrations only if an ORM is present
  (SQLAlchemy, Django, Prisma, Drizzle…). Many analytics/automation repos have no database; don't
  invent a migration recipe for them.

## 2. Fill the pages (each starts with frontmatter: `updated`, `covers: [..]`, `status`)

- **index.md** — the MAP (most important). A table `Area | key file paths (real!) | purpose | module
  page`; a **Stack** block with the real commands from step 1; a "Where to start by task" list.
  Monorepo/hybrid ⇒ a **Packages/Components** table, one row per package/component with its own
  toolchain.
- **architecture.md** — components, data/control flow, boundaries, key decisions. For a hybrid repo,
  document the **seam** (how the languages talk: subprocess / HTTP / shared queue / shared files/DB).
- **conventions.md** — package manager, lint/format/type-check config locations, naming, patterns to
  reuse, testing approach, do/don't.
- **glossary.md** — domain terms and key entities.
- **recipes.md** — step-by-step playbooks for this repo's common tasks, with the **real commands**;
  include only the tasks that fit the archetype (e.g. "run the pipeline / add a data source" for ETL,
  "add an endpoint / add a migration" only for web + ORM).
- **modules/<name>.md** — one page per significant subsystem (or framework unit / pipeline stage /
  package / component): purpose, key files & entry points, how it works, gotchas, related links.
- **log.md** — append: `## [<today>] init | <one-line summary of what you created>`.

## 3. Principles

- **Link, don't duplicate** — the wiki is a map, not a copy of the code. Keep pages short.
- **Real file paths everywhere**, so the reader opens the right file directly.
- Be honest about uncertainty — mark thin/guessed pages `status: draft`.

When done, briefly tell me which pages and modules you created and anything you were unsure about.
