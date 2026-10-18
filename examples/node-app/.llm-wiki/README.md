# .llm-wiki — tasks-api

This directory is the **codebase knowledge base for `tasks-api`**, read by AI coding agents (Claude Code, GitHub Copilot,
Codex, and others). It is a compiled map of this repository: where things live, how the system fits
together, the conventions to follow, and recipes for common tasks.

## Why it exists

Without it, an agent re-derives the repo's structure every session — broad searches, reading whole
files to find what matters, rediscovering conventions. That is slow and burns tokens. This wiki lets
an agent orient in one cheap read and then jump straight to the relevant code.

## Contract

- **Agents read [`index.md`](index.md) first**, before searching the codebase.
- **Agents keep it current**: after a substantive code change they update the affected pages and
  append an entry to [`log.md`](log.md).
- **The code is the source of truth.** If a page disagrees with the code, the code wins and the page
  gets fixed.
- Pages are a **map, not a copy** — they link to code and summarize what isn't obvious, rather than
  restating it.

## Layout

| File | What it is |
|------|-----------|
| [`index.md`](index.md) | The map: where everything is + "where to start by task" |
| [`architecture.md`](architecture.md) | System shape, components, data/control flow |
| [`conventions.md`](conventions.md) | Naming, patterns, testing, error handling |
| [`glossary.md`](glossary.md) | Domain terms and key entities |
| [`recipes.md`](recipes.md) | Step-by-step playbooks for common tasks |
| [`modules/`](modules/) | One page per significant subsystem |
| [`log.md`](log.md) | Append-only record of wiki changes |

Maintained with the `llm-wiki` Claude Code plugin (`/llm-wiki:init`, `:update`, `:lint`, `:upgrade`,
`:view`), the Copilot prompt files in `.github/prompts/` (`/llm-wiki-init`, `/llm-wiki-update`,
`/llm-wiki-lint`, `/llm-wiki-upgrade`, `/llm-wiki-view`), or by hand. Humans curate and direct; the
agent does the bookkeeping.

If `bin/llm-wiki` is present, `python3 .llm-wiki/bin/llm-wiki lint` checks this directory's structure
— frontmatter, links, orphans, size budgets, the log format and accidentally committed credentials —
with no model involved, so it is free to run here or in CI (on Windows: `python`). It is the mechanical half of the lint;
the judgement half (does this still describe the code?) needs an agent.
