---
description: Bootstrap a .llm-wiki/ codebase knowledge base in the current repo and generate pointer files for Claude, Codex/AGENTS.md, and GitHub Copilot.
argument-hint: "[optional: focus areas or notes to emphasize]"
---

# /llm-wiki:init

Bootstrap a `.llm-wiki/` knowledge base for the **current repository** so AI coding agents orient
fast and use fewer tokens. Extra guidance from the user, if any: $ARGUMENTS

Templates live in the plugin at `${CLAUDE_PLUGIN_ROOT}/templates/`. Copy from there; fill from what
you actually find in the repo. Before writing pages, read the plugin's page conventions:
`${CLAUDE_PLUGIN_ROOT}/skills/llm-wiki/references/page-formats.md` and `token-efficiency.md`.

## Steps

1. **Check for an existing wiki.** If `.llm-wiki/` already exists, stop and suggest `/llm-wiki:update`
   or `/llm-wiki:lint` instead of overwriting. Do not clobber existing pages.

2. **Scan the repo (read-only).** Detect:
   - Languages, package managers, build/test tooling (read manifest files like `package.json`,
     `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, etc.).
   - Top-level structure and the significant subsystems (source dirs, not vendored/generated ones).
   - Entry points (main/server/CLI/app bootstrap), routing, data layer, tests location.
   - Existing conventions (naming, error handling, test style) by sampling a few representative files.
   Keep this efficient — sample, don't read everything.

3. **Create `.llm-wiki/`** by copying `${CLAUDE_PLUGIN_ROOT}/templates/wiki/` and filling each page:
   - `README.md` — leave as-is (explains the dir to humans).
   - `index.md` — the map table (area → key file paths → purpose → module link) and the
     "Where to start by task" router. This is the most important page; make paths real.
   - `architecture.md` — system shape, main components, data/control flow, boundaries.
   - `conventions.md` — naming, patterns to reuse, testing approach, error handling, do/don't.
   - `glossary.md` — domain terms and key entities.
   - `recipes.md` — step-by-step playbooks for the common tasks in this repo (e.g. add an endpoint,
     add a migration, run tests, release).
   - `modules/<name>.md` — one page per significant subsystem, from `modules/_TEMPLATE.md`.
   - `log.md` — seed with the first entry (see step 5).

4. **Generate root pointer files** from `${CLAUDE_PLUGIN_ROOT}/templates/pointers/`:
   - `CLAUDE.md`, `AGENTS.md`, and `.github/copilot-instructions.md` (create `.github/` if needed).
   - Each pointer's content goes inside a delimited managed block:
     `<!-- BEGIN llm-wiki -->` … `<!-- END llm-wiki -->`.
   - **If a target file already exists**, do NOT overwrite it. Insert or replace only the managed
     block, preserving all of the user's existing content.

5. **Append the first `log.md` entry**: `## [<today>] init | <one-line summary of what was created>`.

6. **Report** to the user: the pages created, the modules covered, and anything you were unsure about
   or deliberately left thin, so they can direct follow-ups.

## Principles

- Favor **locations and gotchas** over restating code. Link, don't duplicate.
- Keep pages within the size budgets in `page-formats.md`.
- Be honest about uncertainty — mark thin/guessed pages `status: draft` in frontmatter.
