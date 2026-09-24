---
mode: agent
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
   changes** (a changed lockfile/package manager, renamed scripts, a new workspace package — refresh
   `recipes.md`, `conventions.md`, and the `index.md` Stack block). Skip formatting/comment-only edits.
3. **Update the affected pages** — `index.md` rows, the relevant `modules/<name>.md` (add a new one for
   any significant new subsystem), and `architecture.md`/`conventions.md`/`glossary.md`/`recipes.md`
   where the change touched them. Bump each edited page's `updated:` date.
4. **Repair cross-links** invalidated by moves/renames/deletes.
5. **Append** a `log.md` entry: `## [<today>] update | <short summary>`.

Keep pages current and small — link, don't duplicate. The code is the source of truth; where the wiki
disagreed with the code, fix the wiki. Tell me what you updated when done.
