---
name: llm-wiki
description: Use when working in a repository that contains a `.llm-wiki/` directory (a compiled codebase knowledge base) — Python, Node.js, T-SQL/SQL Server (sqlproj, SQL scripts, SSIS), PostgreSQL (psql scripts), R (packages, targets, Shiny, Quarto), Slurm/HPC batch jobs, or mixed. Read `.llm-wiki/index.md` before broad code searches to find where things live cheaply, and after making substantive code or schema changes, update the affected wiki pages and append a `log.md` entry. Also maintains a cross-project data-source catalog — recognizing and remembering common connections (named SQL Servers, ODBC DSNs, Oracle/Postgres sources) so you reuse the right driver/auth without storing secrets. Keeps the wiki current so future sessions start warm and use fewer tokens.
---

# LLM Wiki maintainer

A `.llm-wiki/` directory is a small, persistent, agent-maintained knowledge base committed inside a
repo. It is a **compiled map** of the codebase — where things live, how the system fits together, the
conventions to follow, and step-by-step recipes for common tasks. Reading it first means you orient
in one cheap read instead of many expensive `grep`/`glob` sweeps and whole-file reads.

You are the maintainer. The human curates and directs; you do the bookkeeping.

## When you start work in a repo that has `.llm-wiki/`

1. **Read `.llm-wiki/index.md` first.** It is the map: area → key file paths → one-line purpose →
   link to a module page, plus a "Where to start by task" section. Use it to jump straight to the
   relevant files instead of scanning the whole tree.
2. **Drill into the relevant module page(s)** under `.llm-wiki/modules/` for the area you're touching.
   These list entry points, key files, data flow, and gotchas.
3. **Consult `conventions.md` and `recipes.md`** before writing new code, so your changes match
   existing patterns and you reuse what's already there.

Trust the wiki as a starting point, but the code is the source of truth. If the wiki disagrees with
the code, the code wins — and you fix the wiki (see below).

## After you make substantive code changes

Substantive = new/removed/renamed modules or files, changed public interfaces, new conventions or
patterns, moved responsibilities, new dependencies, changed build/test/deploy commands, or anything
that makes an existing wiki page wrong or incomplete. In database repos that includes added/removed/
renamed schemas, tables, views or procs, changed proc parameters/result sets/error numbers, new SSIS
packages or Agent jobs, new scripts in the deploy run order, and changed Postgres function signatures
/ `ERRCODE`s / grants. In R repos: dependency changes (`renv.lock`, `DESCRIPTION`) and new targets;
with Slurm: new job scripts, changed `#SBATCH` resources, or a changed job chain. (Skip pure
formatting, comments, or trivial one-liners.)

Update the wiki in the same session:

1. **Fix the affected pages.** Update `index.md` rows, the relevant `modules/<name>.md`, and
   `architecture.md`/`conventions.md`/`glossary.md`/`recipes.md`/`data-sources.md` if the change
   touched them.
2. **Add a module page** for any significant new subsystem, from `modules/_TEMPLATE.md`.
3. **Repair cross-references** you invalidated (moved/renamed/deleted files).
4. **Append a `log.md` entry** using the parseable prefix:
   `## [YYYY-MM-DD] update | <short summary>`.

## Data sources (two tiers)

Named data sources recur across repos — a SQL Server like `SRVDATSCIENCE02`, an ODBC DSN like
`ORABIPROD`, a Postgres service, a warehouse account, an `s3://` bucket, a `\\server\share`. They get
recorded in **two** places, answering two different questions, joined on the source **Name**:

- **User-global catalog** — `~/.claude/llm-wiki/data-sources.md` (Windows:
  `%USERPROFILE%\.claude\llm-wiki\data-sources.md`): *how to connect* — engine, connect-via,
  driver/DSN, auth model, credential env-var **names**, and the repos that use it. Lives in your home,
  **not** in the repo, shared across all repos. Create it on first need.
- **Repo page** — `.llm-wiki/data-sources.md`: *what this repo does with it* — which code paths touch
  each source, direction, the objects/prefixes/topics actually used, repo-specific gotchas. Committed
  wiki canon; optional (a repo that connects to nothing has no such page). Create it from
  `templates/wiki/data-sources.md` when the repo gains its first external source, and add the
  `index.md` Map row.

A fact true in every repo that uses the source belongs in the catalog; a fact true only here belongs
on the page. Don't duplicate across the two.

- **Consult both** when you start work that touches data access, and whenever you write connection code.
- **Recognize:** when you see a connection in code (`pyodbc.connect`, SQLAlchemy `create_engine`,
  `DBI::dbConnect`, `saspy.SASsession`, `boto3.client("s3")`, `snowflake.connector`, `duckdb.connect`,
  `KafkaConsumer`, a `Server=`/`DSN=`/`s3://` string or a UNC path, `pg_service`,
  `sascfg_personal.py`), match it to a catalog entry and reuse that driver and auth model.
  **Remember:** if it's not there, add it (upsert by name — never duplicate an existing source).
- **Never store secrets.** Record engine / host / DSN / driver / auth *method* and the **names** of the
  env vars or secret-store entries that hold credentials — never a password, token or presigned URL. If
  you find a credential inlined in code, record the source without it and flag the leak.
- The dedicated **`data-sources` skill** carries this protocol in full and fires in any repo, with or
  without a wiki. Detection signatures and the threshold for what counts as a key source are in
  [references/data-source-detection.md](references/data-source-detection.md); the table format,
  auth-model inference and the GitHub Copilot mirror are in
  [references/data-sources.md](references/data-sources.md).

## Principles

- **Link, don't duplicate.** Pages stay short; point to the code and to each other rather than
  restating detail. The wiki is a map, not a copy of the codebase.
- **Keep it current, not exhaustive.** A stale wiki is worse than a small one. Only document what
  helps an agent act faster: locations, entry points, gotchas, conventions, recipes.
- **Idempotent pointers.** The root `CLAUDE.md` / `AGENTS.md` / `.github/copilot-instructions.md`
  files contain a delimited `<!-- BEGIN llm-wiki --> … <!-- END llm-wiki -->` block. Edit only inside
  that block; never clobber the human's own content around it.

## Page conventions and rationale

- Page formats (frontmatter, cross-links, the index table shape): see
  [references/page-formats.md](references/page-formats.md).
- **An old wiki can be retrofitted.** You read `index.md` first anyway, so its `wiki_contract:` key is
  free to check. If it is missing, or below `CURRENT_CONTRACT` in
  [references/wiki-contract.md](references/wiki-contract.md), the wiki predates part of the current
  layout — mention `/llm-wiki:upgrade` **once** in the session and carry on with the task. Don't
  backfill it yourself mid-task, and don't raise it again.
- **The Markdown is the canon — don't read or maintain the HTML view as an agent.** `/llm-wiki:view`
  can generate a human-only review dashboard at `.llm-wiki/view/index.html` (derived from these pages,
  gitignored by default). It is for people to skim; never read it to orient (it just costs tokens for
  markup) and never treat it as a source — fix the Markdown, then regenerate. See
  [references/view-layer.md](references/view-layer.md).
- Why and how the wiki saves tokens, plus page-size budgets: see
  [references/token-efficiency.md](references/token-efficiency.md).
- **Data sources** — the two tiers (cross-project catalog + the optional repo page), the table
  format, auth-model inference, the never-store-secrets rule, and the Copilot mirror: see
  [references/data-sources.md](references/data-sources.md). The threshold for "key data source" and
  the detection signatures per engine class (relational, warehouses, object stores and shares,
  embedded, queues/streams, APIs/SFTP, SAS): see
  [references/data-source-detection.md](references/data-source-detection.md).
- Detecting the stack and writing stack-correct recipes/pages: see
  [references/stacks.md](references/stacks.md). It covers Python & Node package managers and tooling,
  the **T-SQL** toolchains (SDK-style/classic `.sqlproj` + sqlpackage, sqlcmd script repos, SSIS +
  SQL Agent, tSQLt), **PostgreSQL** `psql` script repos (run lists, `ON_ERROR_STOP`, pgTAP),
  **R** (renv, devtools, targets, Quarto, Shiny, testthat), **Slurm** batch jobs, and — importantly — how to identify the **project archetype** (web service,
  data/ETL, orchestration, automation/jobs, file-processing, worker, serverless, ML, notebooks, CLI,
  library, database project, script repo, warehouse, R package/analysis/Shiny, HPC pipeline) and
  handle **hybrid** repos (Node+Python, Python+R, app + database, anything + Slurm). Don't assume a web app. Use it whenever you record a command so it matches the
  repo's real tooling (`pnpm test`, `uv run pytest`, `dotnet build Db.sqlproj`,
  `psql -X -v ON_ERROR_STOP=1 -f db/deploy.sql`, `Rscript -e 'targets::tar_make()'`, …) rather than a
  guess — and prefer what CI runs when sources disagree.
- **T-SQL editing rules** worth remembering: in a state-based `.sqlproj`, edit the `CREATE`
  statement (the dacpac diff writes the `ALTER`), rename through the refactorlog, and put data changes
  in pre/post-deploy scripts; in script repos, keep every script idempotent and add it to the run
  list.
- **PostgreSQL editing rules:** re-runnable scripts must be idempotent (`IF NOT EXISTS`,
  `CREATE OR REPLACE`, `ON CONFLICT`) and registered in the `\ir` run list; destructive changes go
  in the repo's one-shot mechanism; every `psql` call gets `-v ON_ERROR_STOP=1`; big-table DDL uses
  `CONCURRENTLY` / `NOT VALID`. Don't carry T-SQL habits into Postgres files or vice versa.
- **R rules:** after adding a package run `renv::snapshot()` (and add it to `DESCRIPTION` in a
  package); regenerate `NAMESPACE`/`man/` with `devtools::document()`, never by hand; don't edit the
  `_targets/` store.
- **Slurm rules:** `#SBATCH` lines before any command; use only the partitions/accounts/modules the
  wiki lists; never run heavy compute on a login node; test with a tiny array or the debug
  partition before a full submit.

## Related commands

If the plugin is installed, these commands drive the wiki explicitly:
`/llm-wiki:init` (bootstrap), `/llm-wiki:update` (refresh after changes), `/llm-wiki:lint`
(health-check), `/llm-wiki:upgrade` (retrofit an older wiki to the current structural contract),
`/llm-wiki:view` (build the human-only HTML review dashboard from the canon). You can
also do any of this by hand following the guidance above.

There is also a deterministic, model-free check:

```
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/llm-wiki" lint .llm-wiki
```

(or `.llm-wiki/bin/llm-wiki` in a repo set up for Copilot). It verifies frontmatter, the contract
stamp, required pages, broken links and anchors, orphan pages, size budgets, the `log.md` format,
leaked credentials and data-source tier violations. Run it after you edit wiki pages — it is far
cheaper than re-reading them, and it catches the mechanical mistakes that are easy to make while
writing Markdown by hand.
