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
   - **Tooling changes are substantive too:** a changed lockfile / package manager, renamed or added
     `package.json` scripts or `pyproject.toml` `[tool.*]` entries, or a new workspace package.
     Refresh `recipes.md`, `conventions.md`, and the `index.md` Stack/Packages block so the recorded
     commands stay runnable. See `${CLAUDE_PLUGIN_ROOT}/skills/llm-wiki/references/stacks.md`.

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

7. **Report** what you updated and anything you chose not to touch.

## Principles

- Keep pages current and small — link, don't duplicate. Code is the source of truth; when the wiki
  disagreed with the code, you fixed the wiki.
