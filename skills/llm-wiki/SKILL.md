---
name: llm-wiki
description: Use when working in a repository that contains a `.llm-wiki/` directory (a compiled codebase knowledge base). Read `.llm-wiki/index.md` before broad code searches to find where things live cheaply, and after making substantive code changes, update the affected wiki pages and append a `log.md` entry. Keeps the wiki current so future sessions start warm and use fewer tokens.
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
patterns, moved responsibilities, new dependencies, or anything that makes an existing wiki page
wrong or incomplete. (Skip pure formatting, comments, or trivial one-liners.)

Update the wiki in the same session:

1. **Fix the affected pages.** Update `index.md` rows, the relevant `modules/<name>.md`, and
   `architecture.md`/`conventions.md`/`glossary.md`/`recipes.md` if the change touched them.
2. **Add a module page** for any significant new subsystem, from `modules/_TEMPLATE.md`.
3. **Repair cross-references** you invalidated (moved/renamed/deleted files).
4. **Append a `log.md` entry** using the parseable prefix:
   `## [YYYY-MM-DD] update | <short summary>`.

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
- Why and how the wiki saves tokens, plus page-size budgets: see
  [references/token-efficiency.md](references/token-efficiency.md).

## Related commands

If the plugin is installed, these commands drive the wiki explicitly:
`/llm-wiki:init` (bootstrap), `/llm-wiki:update` (refresh after changes), `/llm-wiki:lint`
(health-check). You can also do any of this by hand following the guidance above.
