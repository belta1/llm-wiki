# llm-wiki

A Claude Code plugin that installs and maintains a **per-repo codebase knowledge base** so AI coding
agents orient fast and burn fewer tokens.

It adapts the [LLM Wiki](LLM%20Wiki.md) pattern — an LLM-maintained, interlinked markdown knowledge
base — from personal research to **code repositories**. Instead of an agent re-deriving your repo's
structure every session (broad searches, reading whole files, rediscovering conventions), each repo
carries a small compiled map under `.llm-wiki/` that the agent reads first.

## What it does

- Installs a `.llm-wiki/` knowledge base into any repo: a **map** of where code lives, an
  **architecture** overview, **conventions**, a **glossary**, **recipes** for common tasks, per-module
  pages, and an append-only **log**.
- Generates root pointer files so every tool uses the same knowledge base:
  - `CLAUDE.md` — Claude Code
  - `AGENTS.md` — Codex and other agents
  - `.github/copilot-instructions.md` — GitHub Copilot
- Bundles an always-on **skill** that makes agents read the wiki before searching and keep it current
  after edits.

## Optimized for Python & Node.js

`init` detects the ecosystem and records the **real, runnable** commands for it — the package manager
is inferred from the lockfile (npm/pnpm/yarn/bun; pip/poetry/uv/pipenv), and recipes come out as e.g.
`pnpm test` or `uv run pytest`, not guesses.

It also detects the **project archetype** instead of assuming a web app. A repo may be a web service,
a data/analytics/ETL pipeline, an orchestrated workflow (Airflow/Dagster/Prefect), an
automation/scripting/file-processing job, a worker/queue consumer, a serverless function set, an ML
project, notebooks, a CLI, or a library — so the module pages and recipes are shaped to what the repo
actually is (pipeline stages and "add a data source" for ETL; "run the job / its schedule" for
automations; routers and "add a migration" only when a web framework + ORM are present). Persistence
is detected on its own axis, so an analytics or automation repo with no database never gets a
migration recipe.

It handles **monorepos/workspaces** (pnpm/yarn/npm workspaces, Turborepo, Nx, uv/poetry) and — because
real automations are often polyglot — **hybrid Node + Python repos**: each is mapped by component with
its own toolchain (a Components table in the index, a module page each), and for hybrids the **seam
between languages** (subprocess, HTTP, shared queue/DB/files) gets documented explicitly.

The detection rules live in
[skills/llm-wiki/references/stacks.md](skills/llm-wiki/references/stacks.md), and there are fully
worked reference wikis the generator mirrors:
[examples/node-app/](examples/node-app/.llm-wiki/) (Express + TypeScript),
[examples/python-webapp/](examples/python-webapp/.llm-wiki/) (FastAPI + SQLAlchemy), and
[examples/python-analytics/](examples/python-analytics/.llm-wiki/) (pandas/polars ETL — no web, no
ORM). Other stacks still work via generic detection.

## Why it saves tokens

The index says *where* code is, so the agent reads a couple of targeted files instead of sweeping the
whole tree. Module pages give entry points and gotchas; recipes encode how to do common tasks once.
See [skills/llm-wiki/references/token-efficiency.md](skills/llm-wiki/references/token-efficiency.md).

## Install

This repo doubles as a single-plugin marketplace:

```
/plugin marketplace add M:\00_repo\llm-wiki
/plugin install llm-wiki
```

(Once pushed to GitHub, use the repo URL in place of the local path.)

## Usage

Run inside the repo you want to document:

| Command | What it does |
|---------|--------------|
| `/llm-wiki:init` | Scan the repo and bootstrap `.llm-wiki/` + the three pointer files |
| `/llm-wiki:update` | Refresh affected pages after code changes; append a log entry |
| `/llm-wiki:lint` | Health-check for stale claims, orphan pages, broken links, drift |

The bundled `llm-wiki` skill also triggers automatically when you work in a repo that already has a
`.llm-wiki/`, reminding the agent to read the index first and maintain the wiki after edits.

## Using it with each tool

`/llm-wiki:init` writes the same knowledge base once (`.llm-wiki/`) and three thin pointer files, one
per tool, each pointing into it. You only run the plugin from Claude Code; the other tools just read
the files it leaves in the repo — no plugin needed on their side.

> **Note:** the pointer files are generated **into the repo you run `init` in**, not into this plugin
> repo. Here they exist only as templates under [`templates/pointers/`](templates/pointers/). So if
> you don't see a `.github/` folder in *this* repo, that's expected — it appears in your target repo
> after `init`.

### Claude Code

`CLAUDE.md` at the repo root is loaded automatically at the start of every session, so the agent is
told to read `.llm-wiki/index.md` first. Nothing else to enable.

### GitHub Copilot

`init` creates **`.github/copilot-instructions.md`** at the target repo's root. This is GitHub's
standard "repository custom instructions" file — Copilot automatically prepends it to its context for
that repo. There's no package to install; the file just has to exist and be committed.

To confirm it's active:

- **VS Code / Visual Studio / JetBrains (Copilot Chat & code generation):** repository instruction
  files are honored when the setting **`github.copilot.chat.codeGeneration.useInstructionFiles`** is
  enabled (it's on by default in current versions). Check: Settings → search "instruction files".
- **github.com and GitHub Mobile Copilot Chat:** the file is picked up automatically for the repo; no
  setting required.
- Commit the file so teammates and the hosted Copilot see it — Copilot reads the committed repo
  contents, not your uncommitted working tree.

You can verify Copilot is using it by asking Copilot Chat a question about the repo; recent Copilot
UIs show `copilot-instructions.md` as a referenced file in the response.

> Optional: GitHub also supports path-scoped instructions under `.github/instructions/*.instructions.md`
> with an `applyTo:` glob. The plugin generates the single repo-wide file by default; you can add
> path-scoped ones by hand if you want area-specific guidance.

### Codex / other agents

`init` creates **`AGENTS.md`** at the repo root — the tool-neutral convention read by Codex,
opencode, and a growing set of agents. Same content, pointing into the same `.llm-wiki/`.

## How it's structured

```
.claude-plugin/   plugin.json + marketplace.json
skills/llm-wiki/  SKILL.md + references (page formats, token efficiency, stacks)
commands/         init, update, lint
templates/        wiki/ (pages copied into .llm-wiki/) + pointers/ (root files)
examples/         node-app/ + python-webapp/ + python-analytics/ (worked reference wikis)
```

Pointer files are written as a delimited `<!-- BEGIN llm-wiki --> … <!-- END llm-wiki -->` block, so
`init`/`update` merge into an existing `CLAUDE.md`/`AGENTS.md`/`copilot-instructions.md` without
clobbering your own content.

## The idea

The tedious part of a knowledge base isn't the thinking — it's the bookkeeping: cross-references,
keeping summaries current, noting drift. Humans abandon wikis because maintenance outpaces value. An
agent doesn't get bored and can touch a dozen pages in one pass, so the wiki stays maintained at
near-zero cost. See [LLM Wiki.md](LLM%20Wiki.md) for the full conceptual background.
