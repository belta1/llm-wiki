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
   any significant new subsystem), and `architecture.md`/`conventions.md`/`glossary.md`/`recipes.md`/`data-sources.md`
   where the change touched them. Bump each edited page's `updated:` date.
3b. **Data sources** — if the change added or altered a connection to anything outside the repo (a
   database server/DSN, warehouse account, object-store bucket, network share, broker, named API or
   SFTP host — or a changed driver, auth model, or set of objects read/written):
   - update **`data-sources.md`** — its rows, code paths, direction and objects — creating it from
     the plugin's `templates/wiki/data-sources.md` if the repo just gained its first external source
     (then add the `index.md` Map row), and bump its `updated:` date like any other page;
   - note the connection facts (engine, connect-via, driver, auth model, credential env-var **names**
     only) so the user can record them in the cross-project catalog
     `~/.claude/llm-wiki/data-sources.md`.
   **Never** inline or record a password, token, key or presigned/SAS URL. Flag any secret you find
   hard-coded in a connection string.
4. **Repair cross-links** invalidated by moves/renames/deletes.
5. **Check your own work.** If `.llm-wiki/bin/llm-wiki` exists, run
   `python3 .llm-wiki/bin/llm-wiki lint --fail-on warning` (`python` on Windows) and fix
   what it reports. Step 4 is exactly
   where a dead link gets left behind, and this confirms you got them all for no model cost.
6. **Append** a `log.md` entry: `## [<today>] update | <short summary>`.

Keep pages current and small — link, don't duplicate. The code is the source of truth; where the wiki
disagreed with the code, fix the wiki. Tell me what you updated when done.
