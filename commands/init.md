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

This plugin is optimized for **Python** and **Node.js** repos. Read
`${CLAUDE_PLUGIN_ROOT}/skills/llm-wiki/references/stacks.md` for detection rules. Work in three steps:
(1) which languages are present — **more than one ⇒ a hybrid/polyglot repo**, map it by component;
(2) each language's toolchain; (3) the **project archetype — don't assume a web app.** A repo may be
a web service, a data/ETL pipeline, an orchestrated workflow (Airflow/Dagster/Prefect), an
automation/scripting/file-processing job, a worker/queue consumer, a serverless function set, an ML
project, notebooks, a CLI, or a library — or a hybrid of these. Then mirror the closest worked
example for page shape and brevity:
- `${CLAUDE_PLUGIN_ROOT}/examples/node-app/.llm-wiki/` — Express + TypeScript
- `${CLAUDE_PLUGIN_ROOT}/examples/python-webapp/.llm-wiki/` — FastAPI + SQLAlchemy web service
- `${CLAUDE_PLUGIN_ROOT}/examples/python-analytics/.llm-wiki/` — pandas/polars ETL, no web, no ORM

(Other stacks/archetypes still work; fall back to generic detection.)

## Steps

1. **Check for an existing wiki.** If `.llm-wiki/` already exists, stop and suggest `/llm-wiki:update`
   or `/llm-wiki:lint` instead of overwriting. Do not clobber existing pages.

2. **Detect the stack (read-only), guided by `references/stacks.md`.** Determine:
   - **Package manager** from the lockfile (pnpm/yarn/bun/npm; uv/poetry/pipenv/pip) — the lockfile
     wins. This decides how every recipe command is spelled (`pnpm test`, `uv run pytest`, …).
   - **Real commands** for install, run/dev, build, test (+ single test), lint, format, typecheck —
     read `package.json` scripts / `pyproject.toml` `[tool.*]` / Makefile/tox/nox. Record what a dev
     would actually type; never guess a command that isn't configured.
   - **Archetype** (web service, data/ETL, orchestration, automation/jobs, file-processing, worker,
     serverless, ML, notebooks, CLI, library — per `stacks.md` Step 3) — decides which module pages
     and archetype-specific recipes to write. Detect **persistence** separately.
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
     (serverless), add an endpoint / migration (web + ORM). Only include recipes whose tooling
     actually exists.
   - `modules/<name>.md` — one page per natural unit for the archetype (router/app, pipeline stage,
     DAG/flow, job/automation, worker, serverless function, ML concern, CLI group), from
     `modules/_TEMPLATE.md`.
   - `log.md` — seed with the first entry (see step 5).

3b. **Hybrid (polyglot) and monorepo repos.** If Step 1 found **more than one language** (e.g.
   `package.json` *and* `pyproject.toml`), or you detected workspaces (`workspaces` in `package.json`,
   `pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `lerna.json`, or multiple `pyproject.toml`), map it
   **by component/package**: create **one `modules/<component>.md` each**, add a **Components/Packages**
   table to `index.md` (name → path → toolchain → purpose → module page), and record how to run each
   part plus the combined dev flow (`Makefile`/`docker-compose`/`Procfile`/`turbo`/`nx`). For a
   hybrid, **document the seam between languages** (subprocess, HTTP, shared queue/DB/files) — it's
   the highest-value page. See the Hybrid section of `references/stacks.md`.

4. **Generate root pointer files** from `${CLAUDE_PLUGIN_ROOT}/templates/pointers/`:
   - `CLAUDE.md`, `AGENTS.md`, and `.github/copilot-instructions.md` (create `.github/` if needed).
   - Each pointer's content goes inside a delimited managed block:
     `<!-- BEGIN llm-wiki -->` … `<!-- END llm-wiki -->`.
   - **If a target file already exists**, do NOT overwrite it. Insert or replace only the managed
     block, preserving all of the user's existing content.

5. **Append the first `log.md` entry**: `## [<today>] init | <one-line summary of what was created>`.

6. **Report** to the user: the pages created, the modules covered, and anything you were unsure about
   or deliberately left thin, so they can direct follow-ups.

## Principles

- Favor **locations and gotchas** over restating code. Link, don't duplicate.
- Keep pages within the size budgets in `page-formats.md`.
- Be honest about uncertainty — mark thin/guessed pages `status: draft` in frontmatter.
