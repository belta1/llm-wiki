---
description: Health-check the .llm-wiki/ knowledge base — find stale claims, orphan pages, missing module pages, broken links, and drift from the code. Report, then optionally fix.
argument-hint: "[optional: 'fix' to apply safe fixes automatically]"
---

# /llm-wiki:lint

Audit the repo's `.llm-wiki/` for health and drift. Mode: $ARGUMENTS (if this contains "fix", apply
the safe, unambiguous fixes after reporting; otherwise report only and ask before changing anything).

Requires an existing `.llm-wiki/`. If there is none, suggest `/llm-wiki:init`.

## Checks

1. **Broken cross-links** — links between wiki pages, and paths cited in the index/module pages, that
   point at files or headings that no longer exist.
2. **Stale claims** — pages whose `updated:` date lags well behind the code they describe, or whose
   content contradicts the current code. Spot-check a few high-traffic areas against the source.
3. **Orphan pages** — wiki pages with no inbound links from `index.md` or any other page.
4. **Missing module pages** — significant source subsystems that have no `modules/<name>.md` and no
   index row.
5. **Index accuracy** — index rows pointing at moved/deleted/renamed files.
6. **Convention drift** — `conventions.md` claims that the current code no longer follows.
7. **Stale recipe commands** — recipe/Stack commands that no longer match the detected tooling: the
   package manager or lockfile changed (e.g. `package-lock.json` → `pnpm-lock.yaml`, `requirements.txt`
   → `uv.lock`), a referenced `package.json` script or `pyproject.toml` tool was renamed/removed, or
   a workspace package was added/removed. Check against
   `${CLAUDE_PLUGIN_ROOT}/skills/llm-wiki/references/stacks.md`.
8. **Structure** — pages missing frontmatter or exceeding the size budgets in
   `${CLAUDE_PLUGIN_ROOT}/skills/llm-wiki/references/page-formats.md`.

## Output

Report findings grouped by check, most-impactful first, each with the file and a one-line fix
suggestion. Also suggest new pages/recipes worth adding and gaps worth investigating.

## Fixing

- **Safe fixes** (apply when in "fix" mode): repair/remove broken links, correct index paths, add
  missing `status`/`updated` frontmatter, mark clearly-stale pages `status: stale`.
- **Judgement fixes** (propose, don't auto-apply): rewriting stale content, creating new module
  pages, resolving contradictions — these need the code read carefully; do them like `/llm-wiki:update`.
- Append a `log.md` entry: `## [<today>] lint | <summary of findings and fixes applied>`.
