---
description: Refresh the .llm-wiki/ knowledge base after code changes — update affected pages, add pages for new subsystems, repair cross-links, and append a log entry.
argument-hint: "[optional: what changed, or a commit/diff range]"
---

# /llm-wiki:update

Bring the repo's `.llm-wiki/` back in sync with the code after changes. What changed (if the user
said): $ARGUMENTS

Requires an existing `.llm-wiki/`. If there is none, suggest `/llm-wiki:init` instead.

## Steps

1. **Determine what changed.** Use `$ARGUMENTS` if given. Otherwise inspect recent changes: the git
   diff against the last commit or a range (`git diff`, `git log --stat`), or the working-tree status.
   Identify which files/modules were added, removed, renamed, or had interfaces changed.

2. **Decide if it's substantive.** Update the wiki for: new/removed/renamed modules or files, changed
   public interfaces, new conventions or patterns, moved responsibilities, new dependencies. Skip
   pure formatting, comments, and trivial one-liners.
   - **Tooling changes are substantive too:** a changed lockfile / package manager / runtime version,
     renamed or added `package.json` scripts or `pyproject.toml` `[tool.*]` entries, changed CI
     workflow steps, or a new workspace package. For T-SQL: a changed `.sqlproj` (SDK/target
     platform/references), added or edited publish profiles or SQLCMD variables, new pre/post-deploy
     includes, a new SSIS package or SQL Agent job, or a new script in the deploy run order. For
     PostgreSQL: a new/removed script in the `\ir` run list, a changed `psql` driver or variables, a
     new extension or role, a new one-shot change, or a new `pg_cron` job. For R: `renv.lock` /
     `DESCRIPTION` dependency changes, new targets in `_targets.R`, a new Quarto report or Shiny
     module. For Slurm: a new or removed job script, changed `#SBATCH` resources/partition/account,
     new `module load` versions, or a changed dependency chain in the submit script.
     Refresh `recipes.md`, `conventions.md`, and the `index.md` Stack/Packages block so the recorded
     commands stay runnable. See `${CLAUDE_PLUGIN_ROOT}/skills/llm-wiki/references/stacks.md`.
   - **Database changes are substantive** when they add/remove/rename a schema, table, view or proc,
     change a proc's parameters, result set or `THROW` numbers (update the contract page), change a
     warehouse grain/SCD type, or move a load step. Renames in an SSDT project must also appear in
     the `.refactorlog` — if one doesn't, flag it to the user. For PostgreSQL the same applies to
     functions and views (arguments, `RETURNS` shape, `ERRCODE`s raised, grants/RLS); a new
     re-runnable script that isn't idempotent, or one missing from the run list, should be flagged.
   - **Data-source changes are substantive:** a new or changed database connection (a new server/DSN,
     a changed driver or auth model) → **upsert** the user-global catalog
     `~/.claude/llm-wiki/data-sources.md` (match by host/DSN name; record engine / connect-via / driver
     / auth / credential env-var **names** only; never a secret). See
     `${CLAUDE_PLUGIN_ROOT}/skills/llm-wiki/references/data-sources.md`.

3. **Update the affected pages:**
   - `index.md` — fix rows whose key files/paths/purpose changed; add rows for new areas.
   - `modules/<name>.md` — update the pages for changed subsystems; create a new one from
     `${CLAUDE_PLUGIN_ROOT}/templates/wiki/modules/_TEMPLATE.md` for any significant new subsystem.
   - `architecture.md`, `conventions.md`, `glossary.md`, `recipes.md` — update only if the change
     actually touched them.
   - Bump each edited page's `updated:` frontmatter date; set `status: current`.

4. **Repair cross-references** invalidated by moves/renames/deletes. Remove or redirect dead links.

5. **Append a `log.md` entry**: `## [<today>] update | <short summary of what changed and pages touched>`.

6. **Refresh pointer blocks if needed.** Only if the wiki's entry points changed; edit inside the
   `<!-- BEGIN llm-wiki --> … <!-- END llm-wiki -->` block only, never the user's surrounding content.

7. **Report** what you updated, any data-source catalog entries added or changed, and anything you
   chose not to touch.

## Principles

- Keep pages current and small — link, don't duplicate. Code is the source of truth; when the wiki
  disagreed with the code, you fixed the wiki.
