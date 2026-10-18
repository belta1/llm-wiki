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
  pages, an optional **data-sources** page, and an append-only **log**.
- Generates root pointer files so every tool uses the same knowledge base:
  - `CLAUDE.md` — Claude Code
  - `AGENTS.md` — Codex and other agents
  - `.github/copilot-instructions.md` — GitHub Copilot
- Bundles an always-on **skill** that makes agents read the wiki before searching and keep it current
  after edits, plus a **`data-sources`** skill that recognizes the external data a repo connects to —
  in any repo, wiki or not — and never stores a secret.

## Optimized for Python, Node.js, T-SQL, PostgreSQL & R (plus Slurm)

`init` detects the ecosystem and records the **real, runnable** commands for it — the package manager
is inferred from the lockfile (npm/pnpm/yarn/bun/deno; pip/poetry/uv/pdm/hatch/pixi/pipenv), the
runtime version from `.nvmrc`/`.python-version`, the single-test syntax from the actual test runner
(Vitest, Jest, `node --test`, pytest, …), and everything is cross-checked against **CI workflows**,
which are treated as the ground truth. Recipes come out as e.g. `pnpm vitest run -t "<name>"` or
`uv run pytest file::test`, not guesses.

It also detects the **project archetype** instead of assuming a web app. A repo may be a web service,
a data/analytics/ETL pipeline, an orchestrated workflow (Airflow/Dagster/Prefect), an
automation/scripting/file-processing job, a worker/queue consumer, a serverless function set, an ML
project, notebooks, a CLI, a library, a database repo, an R package / analysis / Shiny app, or an
HPC pipeline submitted to Slurm — so the module pages and recipes are shaped to what the repo
actually is (pipeline stages and "add a data source" for ETL; "run the job / its schedule" for
automations; routers and "add a migration" only when a web framework + ORM are present). Persistence
is detected on its own axis, so an analytics or automation repo with no database never gets a
migration recipe.

It handles **monorepos/workspaces** (pnpm/yarn/npm workspaces, Turborepo, Nx, uv/poetry) and — because
real automations are often polyglot — **hybrid repos** (Node + Python, Python + R, app + database):
each is mapped by component with its own toolchain (a Components table in the index, a module page
each), and for hybrids the **seam between languages** (subprocess, HTTP, shared queue/DB/files, a SQL
contract, a Slurm job chain) gets documented explicitly.

### T-SQL / SQL Server

Database repos are first-class, not "generic SQL":

- **Database projects** — SDK-style (`Microsoft.Build.Sql`, built with `dotnet build`) and classic
  SSDT `.sqlproj`. The wiki records the build → **preview** (`sqlpackage /Action:Script`) → publish →
  tSQLt flow, publish profiles and SQLCMD variables, pre/post-deploy scripts, and the refactorlog —
  and it knows a state-based project must never get an `ALTER TABLE` recipe.
- **SQL script / DBA repos** — ordered, idempotent `sqlcmd` deployments (`deploy.sql` with `:r`),
  SQL Agent job scripts, environment targeting.
- **SSIS / data warehouses** — packages and SSISDB environments, `stg` → `dw` → `mart` layers,
  watermarks, SCD handling, Agent schedules, backfills.
- **App + database hybrids** — the stored-procedure/view contract (params, result sets, `THROW`
  numbers) gets its own page as the seam.

### PostgreSQL

Focused on **`psql` script repos** — the common "folder of SQL files and a deploy script" setup:

- The **run list** (`deploy.sql` of `\ir` includes, numbered folders, or a driver script) and the exact
  `psql -X -v ON_ERROR_STOP=1 [-1] -f …` call — the wiki never records a `psql` recipe without
  `ON_ERROR_STOP`.
- **Re-runnable vs one-shot scripts**: idempotency idioms (`IF NOT EXISTS`, `CREATE OR REPLACE`,
  `ON CONFLICT`) for object scripts, and how one-shot data changes are tracked.
- Connections via `PGSERVICE` / `pg_service.conf` (never a password), roles/grants/RLS, extensions,
  online-DDL rules (`CONCURRENTLY`, `NOT VALID`), pgTAP via `pg_prove`, `pg_cron` jobs,
  `sqlfluff --dialect postgres` / `squawk`.
- **App + Postgres**: the SQL-function/view contract (signatures, return shapes, `ERRCODE`s) as the
  seam page. Migration tools (Sqitch, Flyway, dbmate, …) are detected and their commands recorded.

T-SQL and PostgreSQL are told apart by **dialect markers** (`GO`/`SET NOCOUNT`/`NVARCHAR` vs
`$$`/`plpgsql`/`\ir`/`JSONB`), not by the `.sql` extension, so each gets the right rules.

### R

- **renv** restore/snapshot and the R version; **packages** (`DESCRIPTION`, roxygen →
  `devtools::document()/test()/check()`, never hand-edited `NAMESPACE`); **targets** pipelines
  (`tar_make()`, rerun one target, never touch `_targets/`); **Quarto / R Markdown** reports;
  **Shiny** apps; testthat single-file runs; lintr/styler.

### Slurm / HPC

An execution layer on top of any language, detected from `#SBATCH` scripts (or Snakemake/Nextflow/
targets Slurm backends):

- Per-job **resources** (partition/account/time/mem/cpus/gpus), **arrays** and how
  `$SLURM_ARRAY_TASK_ID` maps to inputs, the **`afterok` dependency chain**, `module load` versions,
  scratch vs project storage, log paths.
- Recipes to submit, **test small first** (`--test-only`, tiny arrays, debug partition), inspect with
  `sacct`/`seff`, rerun only failed array tasks, and debug one task under `salloc` — never computing
  on the login node. The jobs page is treated as the seam between pipeline stages.

### Path-scoped Copilot instructions

For Copilot users, the installer also adds `.github/instructions/<stack>.instructions.md` for each
stack it finds, so Copilot follows the right rules while editing those files:

| File | `applyTo` | Installed when the repo has |
|------|-----------|-----------------------------|
| `tsql.instructions.md` | `**/*.sql` | `*.sqlproj` / `*.dtsx`, or `*.sql` with T-SQL syntax |
| `postgres.instructions.md` | `**/*.sql` | `*.sql` with PostgreSQL syntax, `.psqlrc`, `sqitch.plan` |
| `r.instructions.md` | `**/*.{R,r,Rmd,rmd,qmd}` | `*.R` / `*.Rmd`, `renv.lock`, `*.Rproj`, `_targets.R`, an R package `DESCRIPTION` |
| `slurm.instructions.md` | `**/*.{sbatch,slurm}` | `*.sbatch` / `*.slurm`, or shell scripts containing `#SBATCH` |

In a repo with both SQL dialects both SQL files are installed; each tells Copilot to defer to the
dialect the wiki's index records for that folder. If your `#SBATCH` scripts are plain `*.sh`, widen
`applyTo` in `slurm.instructions.md` to their paths (`/llm-wiki:init` does this for you).

The detection rules live in
[skills/llm-wiki/references/stacks.md](skills/llm-wiki/references/stacks.md), and there are fully
worked reference wikis the generator mirrors:
[examples/node-app/](examples/node-app/.llm-wiki/) (Express + TypeScript),
[examples/python-webapp/](examples/python-webapp/.llm-wiki/) (FastAPI + SQLAlchemy),
[examples/python-analytics/](examples/python-analytics/.llm-wiki/) (pandas/polars ETL — no web, no
ORM), [examples/hybrid-app/](examples/hybrid-app/.llm-wiki/) (Node web + Python worker over Redis,
with a `seam` page documenting the cross-language contract),
[examples/tsql-database/](examples/tsql-database/.llm-wiki/) (SDK-style `.sqlproj` + sqlpackage +
tSQLt, with an `api-contract` page for the procs an app calls), and
[examples/tsql-warehouse/](examples/tsql-warehouse/.llm-wiki/) (SSIS + ordered sqlcmd scripts + SQL
Agent jobs), [examples/postgres-database/](examples/postgres-database/.llm-wiki/) (psql script repo
+ one-shot changes + pgTAP + `pg_cron`, with an `api-contract` page for the SQL functions a service
calls), [examples/r-analysis/](examples/r-analysis/.llm-wiki/) (renv + targets + Quarto +
testthat), and [examples/hpc-slurm/](examples/hpc-slurm/.llm-wiki/) (Python preprocessing + R
models run as chained Slurm array jobs, with a `jobs` page as the seam). Other stacks still work via
generic detection.

## Why it saves tokens

The index says *where* code is, so the agent reads a couple of targeted files instead of sweeping the
whole tree. Module pages give entry points and gotchas; recipes encode how to do common tasks once.
See [skills/llm-wiki/references/token-efficiency.md](skills/llm-wiki/references/token-efficiency.md).

## Data sources (two tiers)

Most repos read or write data that lives somewhere else: a SQL Server, a warehouse account, an
`s3://` bucket, a `\\server\share`, a Kafka cluster, a named API. A separate **`data-sources`**
skill recognizes those connections — relational, warehouse, object store and share, embedded,
queue/stream, API/SFTP, SAS — and fires in **any** repo, with or without a `.llm-wiki/`.

What it finds is recorded in two places, joined on the source's **Name**:

| | `~/.claude/llm-wiki/data-sources.md` | `.llm-wiki/data-sources.md` |
|---|---|---|
| Answers | *how do I connect to it?* | *what does **this** repo do with it?* |
| Scope | user-global, **never committed** | one repo, committed wiki canon (optional) |
| Holds | engine, connect-via, driver/DSN, auth model, credential env-var **names**, which repos use it | the code paths that touch it, direction, the objects/prefixes/topics used, repo gotchas, dev substitutes |

**Never a secret, in either** — only the *names* of the env vars or secret-store entries that supply
credentials (a presigned or SAS URL *is* a secret). A credential found inlined in code is reported,
not copied. `/llm-wiki:lint` checks both tiers for leaks and for drift between them.

A repo that connects to nothing gets no page. See
[skills/llm-wiki/references/data-sources.md](skills/llm-wiki/references/data-sources.md) for the
record formats and [data-source-detection.md](skills/llm-wiki/references/data-source-detection.md)
for the detection signatures and the threshold that keeps telemetry hosts and package registries out
of the catalog. Worked example:
[examples/python-analytics/.llm-wiki/data-sources.md](examples/python-analytics/.llm-wiki/data-sources.md).

## Reviewing the wiki (HTML view)

The `.llm-wiki/` pages are **Markdown on purpose** — that's what keeps them cheap for an agent to read
(token-light, greppable, diff-friendly), and it's the whole point of the plugin. But Markdown is a
wall of text to *skim*. So the plugin separates two jobs:

- **Canon** — the `.llm-wiki/*.md` pages. The source of truth that **agents read**. Never changes
  shape.
- **View** — a single derived `.llm-wiki/view/index.html` dashboard that **humans read**: the Map as a
  filterable grid, a page link-graph (inline SVG), a freshness heatmap driven by each page's
  `updated:`/`status:`, the data sources it connects to (SQL Server, Oracle, PostgreSQL, SAS…),
  module cards, and the log as a timeline.

The guiding idea: **agents read source; humans read render.** HTML would only *cost* an agent tokens
(and GitHub sanitizes raw HTML so it won't render live there), so the view is generated on demand,
kept out of agent reads, and `.gitignore`d by default — regenerate it any time with `/llm-wiki:view`.
It's a build artifact, not canon: if something's wrong, fix the Markdown with `/llm-wiki:update`, then
rebuild the view.

| Tool | How to review | Notes |
|------|---------------|-------|
| **Claude** | `/llm-wiki:view`, then view `.llm-wiki/view/index.html` as an **Artifact** | Renders in-app; or open the file in a browser |
| **GitHub Copilot** | `/llm-wiki-view` prompt, then VS Code **Simple Browser** | `install-copilot --view` scaffolds the viewer template |
| **GitHub.com** | Markdown stays the canonical rendered view | Raw HTML is sanitized; host via GitHub Pages only if you want a live site |

See [skills/llm-wiki/references/view-layer.md](skills/llm-wiki/references/view-layer.md) for the
generation model and the data shape.

## Install

This repo doubles as a single-plugin marketplace:

```
/plugin marketplace add <local-path-or-git-url-of-this-repo>
/plugin install llm-wiki
```

e.g. `/plugin marketplace add E:\code\llm-wiki` for a local clone, or the repo's Git URL once it's
pushed.

## Usage

Run inside the repo you want to document:

| Command | What it does |
|---------|--------------|
| `/llm-wiki:init` | Scan the repo and bootstrap `.llm-wiki/` + the three pointer files |
| `/llm-wiki:update` | Refresh affected pages after code changes; append a log entry |
| `/llm-wiki:lint` | Health-check for stale claims, orphan pages, broken links, drift |
| `/llm-wiki:upgrade` | Retrofit an existing `.llm-wiki/` to the current structural contract (see [docs/upgrading.md](docs/upgrading.md)) |
| `/llm-wiki:view` | Build a human-only HTML review dashboard (`.llm-wiki/view/index.html`) from the Markdown |

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

**Don't use Claude Code?** Install the Copilot integration directly with the bundled script — it drops
in `.github/copilot-instructions.md` (merging into any existing one via a managed block) and can
scaffold the wiki:

```bash
# macOS / Linux / Git Bash
scripts/install-copilot.sh /path/to/your/repo --scaffold

# Windows PowerShell
scripts\install-copilot.ps1 C:\path\to\your\repo -Scaffold
```

Both are idempotent (re-running replaces the managed block, never duplicating it or clobbering your
own content, and reports `created` / `updated` / `ok` per file). Options:

| bash | PowerShell | Does |
|------|------------|------|
| `--scaffold` | `-Scaffold` | also copy starter `.llm-wiki/` pages (if none exist) |
| `--view` | `-View` | also scaffold the human-only HTML view (`.llm-wiki/view/index.html`) and gitignore it |
| `--all-pointers` | `-AllPointers` | also install the `CLAUDE.md` and `AGENTS.md` pointers |
| `--tsql` | `-Tsql` | install `tsql.instructions.md` even if T-SQL isn't detected |
| `--postgres` | `-Postgres` | install `postgres.instructions.md` even if PostgreSQL isn't detected |
| `--r` | `-R` | install `r.instructions.md` even if R isn't detected |
| `--slurm` | `-Slurm` | install `slurm.instructions.md` even if no Slurm scripts are detected |
| `--no-path-instructions` | `-NoPathInstructions` | never install path-scoped instructions |

The PowerShell script works on Windows PowerShell 5.1 and writes UTF-8 **without** a BOM, so it
won't prepend one to your existing `CLAUDE.md`/`AGENTS.md`. The pointer is most useful once
`.llm-wiki/` is actually filled in (by hand, or via `/llm-wiki:init` in Claude Code).

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

#### Populating (and maintaining) the wiki with Copilot

The pointer only pays off once `.llm-wiki/` is filled in. Copilot has no `/llm-wiki:init` plugin
command, but VS Code supports **prompt files** — reusable prompts that show up as `/`-commands in
Copilot Chat. The installer drops three into `.github/prompts/`:

| Prompt | Copilot Chat command | Does |
|--------|----------------------|------|
| `llm-wiki-init.prompt.md` | `/llm-wiki-init` | scans the repo and fills in / creates the wiki pages |
| `llm-wiki-update.prompt.md` | `/llm-wiki-update` | refreshes affected pages after code changes |
| `llm-wiki-lint.prompt.md` | `/llm-wiki-lint` | health-checks the wiki for drift and broken links |
| `llm-wiki-view.prompt.md` | `/llm-wiki-view` | builds the human-only HTML review dashboard (`.llm-wiki/view/index.html`) |

To populate: run **`/llm-wiki-init`** in Copilot Chat. The prompts carry no `agent:` in their
frontmatter, so they run in whichever mode you have selected — **ask**, **plan**, **agent**, or a
custom agent. Since `init`/`update`/`lint` need to read files and write the wiki, pick an
edit-capable mode (**agent**) when you want the changes applied; **ask**/**plan** work for a
read-only preview. If the command doesn't appear, enable the **`chat.promptFiles`** setting in VS
Code. Re-run `/llm-wiki-update` as the code evolves, and `/llm-wiki-lint` periodically. These prompts
are self-contained (they carry the same archetype-detection guidance as the Claude command), so they
work without the plugin installed.

**No VS Code prompt-file support?** Just paste the contents of
`.github/prompts/llm-wiki-init.prompt.md` into any Copilot agent chat (or the Copilot coding agent on
github.com) — it's a plain prompt.

> Heads-up: VS Code is migrating prompt files to **agent skills**. Prompt files still work with the
> Local agent but are deprecated for newer Agent Host sessions, which auto-migrate them to skills. The
> content here is portable — if your VS Code converts these to skills, they keep working unchanged.

> **Path-scoped instructions:** GitHub also supports `.github/instructions/*.instructions.md` files
> with an `applyTo:` glob. The plugin ships four — `tsql`, `postgres`, `r`, `slurm` (see
> [Path-scoped Copilot instructions](#path-scoped-copilot-instructions)) — installed automatically for
> the stacks detected (by the scripts and by `/llm-wiki:init`). They're plugin-owned and replaced on
> re-install; add your own path-scoped files alongside it for other
> areas.

### Codex / other agents

`init` creates **`AGENTS.md`** at the repo root — the tool-neutral convention read by Codex,
opencode, and a growing set of agents. Same content, pointing into the same `.llm-wiki/`.

## How it's structured

```
.claude-plugin/   plugin.json + marketplace.json
skills/llm-wiki/  SKILL.md + references (page formats, token efficiency, stacks, view layer,
                  wiki contract (the structural levels :upgrade retrofits to),
                  data sources + data-source detection — these two are shared by both skills)
skills/data-sources/  SKILL.md (recognizes data sources in any repo, wiki or not)
commands/         init, update, lint, upgrade, view
templates/        wiki/ (pages copied into .llm-wiki/) + pointers/ (root files)
                  + view/ (the HTML review-dashboard template)
                  + copilot-prompts/ (/llm-wiki-* prompt files) + copilot-instructions/ (path-scoped: T-SQL, PostgreSQL, R, Slurm)
examples/         node-app/ + python-webapp/ + python-analytics/ + hybrid-app/
                  + tsql-database/ + tsql-warehouse/ + postgres-database/ + r-analysis/
                  + hpc-slurm/ (worked reference wikis)
scripts/          install-copilot.sh / .ps1 (install the Copilot integration without Claude Code)
docs/             html-view-layer.md (why the view exists) + upgrading.md (retrofitting old wikis)
```

Pointer files are written as a delimited `<!-- BEGIN llm-wiki --> … <!-- END llm-wiki -->` block, so
`init`/`update` merge into an existing `CLAUDE.md`/`AGENTS.md`/`copilot-instructions.md` without
clobbering your own content.

## The idea

The tedious part of a knowledge base isn't the thinking — it's the bookkeeping: cross-references,
keeping summaries current, noting drift. Humans abandon wikis because maintenance outpaces value. An
agent doesn't get bored and can touch a dozen pages in one pass, so the wiki stays maintained at
near-zero cost. See [LLM Wiki.md](LLM%20Wiki.md) for the full conceptual background.
