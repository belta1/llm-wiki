---
description: Refresh this repo's .llm-wiki/ after code changes — update affected pages, add pages for new subsystems, fix cross-links, append a log entry.
---

# Update the LLM Wiki

Bring `.llm-wiki/` back in sync with the code after recent changes. (If there is no `.llm-wiki/`, run
the `llm-wiki-init` prompt instead.)

## Steps

1. **Find what changed** — inspect the recent git diff / working tree (or ask me if unclear). Identify
   added, removed, renamed, or interface-changed files and modules.
2. **Decide if it's substantive** — update the wiki for: new/removed/renamed modules or files, changed
   public interfaces, new conventions/patterns, moved responsibilities, new dependencies, or **tooling
   changes** (a changed lockfile/package manager/runtime version, renamed scripts, changed CI steps,
   a new workspace package — refresh `recipes.md`, `conventions.md`, and the `index.md` Stack block).
   In **T-SQL** repos also: added/removed/renamed schemas, tables, views or procs; changed proc
   parameters, result sets or `THROW` numbers (update the contract page); a changed `.sqlproj`,
   publish profile or SQLCMD variable; a new SSIS package, SQL Agent job, or script in the deploy run
   order. Renames in a `.sqlproj` must also be in the `.refactorlog` — flag it if not. In
   **PostgreSQL** repos: changed functions/views (arguments, return shape, `ERRCODE`s, grants/RLS),
   scripts added to or missing from the `\ir` run list, new one-shot changes, extensions or `pg_cron`
   jobs. In **R** repos: `renv.lock` / `DESCRIPTION` dependency changes, new targets, reports or Shiny
   modules. With **Slurm**: new/removed job scripts, changed `#SBATCH` resources or `module load`
   versions, a changed dependency chain. Skip formatting/comment-only edits.
3. **Update the affected pages** — `index.md` rows, the relevant `modules/<name>.md` (add a new one for
   any significant new subsystem), and `architecture.md`/`conventions.md`/`glossary.md`/`recipes.md`
   where the change touched them. Bump each edited page's `updated:` date.
3b. **Data sources** — if the change added or altered a database connection (a named server/DSN,
   driver, or auth model), note it so it can be recorded in the cross-project data-source catalog
   (`~/.claude/llm-wiki/data-sources.md`): engine, connect-via, driver, auth model, and credential
   env-var **names** only — **never** inline or record a password/token. Flag any secret you find
   hard-coded in a connection string.
4. **Repair cross-links** invalidated by moves/renames/deletes.
5. **Append** a `log.md` entry: `## [<today>] update | <short summary>`.

Keep pages current and small — link, don't duplicate. The code is the source of truth; where the wiki
disagreed with the code, fix the wiki. Tell me what you updated when done.
