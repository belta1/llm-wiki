# Wiki page formats

Conventions every `.llm-wiki/` page follows. Keep them consistent so pages are scannable by both
humans and agents, and so simple tooling (grep, Dataview) works.

## Frontmatter

Every page starts with YAML frontmatter:

```yaml
---
updated: 2026-09-23        # ISO date of last meaningful edit
covers: [auth, sessions]   # short tags / areas this page describes
status: current            # current | stale | draft
---
```

- `updated` lets `lint` spot pages that haven't kept pace with code.
- `covers` powers future Dataview tables and quick filtering.
- `status` flags pages that need attention.

`index.md` carries one extra key, and no other page does:

```yaml
wiki_contract: 2           # the structural contract this wiki satisfies
```

It records the wiki's *layout* version, not the plugin's, so `/llm-wiki:upgrade` can tell at a glance
whether anything needs backfilling. See [wiki-contract.md](wiki-contract.md).

## Cross-links

Use **relative markdown links** between pages so they work in any viewer and in git hosts:

- To a module page: `[auth](modules/auth.md)`
- To a sibling page: `[conventions](conventions.md)`
- To source code: link by path, e.g. `src/auth/session.ts` (render as a path, not a URL).

Link liberally. The value of the wiki is in the connections, not just the pages.

## `index.md` — the map (most important page)

The index is what agents read first. Keep it compact. Core is a table:

```markdown
## Map

| Area | Key files | Purpose | More |
|------|-----------|---------|------|
| Auth | `src/auth/` | Login, sessions, tokens | [auth](modules/auth.md) |
| API  | `src/api/` `src/routes/` | HTTP endpoints | [api](modules/api.md) |
```

Followed by a task-oriented router:

```markdown
## Where to start by task

- **Fix an auth bug** → [auth](modules/auth.md), `src/auth/session.ts`
- **Add an endpoint** → [recipes](recipes.md#add-an-endpoint), [api](modules/api.md)
- **Change the schema** → [recipes](recipes.md#add-a-migration), `db/migrations/`
```

Every row's key files are **real paths** so the agent can read them directly.

## `modules/<name>.md` — one per significant subsystem

Follow `modules/_TEMPLATE.md`. Each page covers: purpose, key files & entry points, how it fits with
the rest of the system, gotchas/non-obvious constraints, and links to related pages.

## `data-sources.md` — optional, only if the repo connects to anything

A repo that reads or writes data outside itself gets one page listing those sources: a table of
`Name | Engine | Used by (code) | Direction | Objects / datasets | Catalog`, how the data flows, and
the repo-specific gotchas. One row per **source**, never per table, file or topic.

It holds *repo* facts only. *Connection* facts — driver, DSN, auth model, credential names — live
once per source in the user-global catalog `~/.claude/llm-wiki/data-sources.md`, joined by **Name**.
Never a secret in either. A repo with no external sources simply has no such page (and no index row).
See [data-sources.md](data-sources.md) and [data-source-detection.md](data-source-detection.md).

## `log.md` — append-only, parseable

One entry per operation, newest at the bottom, each starting with a fixed prefix:

```markdown
## [2026-09-23] init | scanned repo, created 6 module pages
## [2026-09-24] update | added billing module; index + architecture updated
## [2026-09-25] lint | fixed 3 broken cross-links, flagged stale glossary
## [2026-09-26] upgrade | contract 1 -> 2; added data-sources.md, refreshed pointer blocks
```

`<op>` is one of `init` / `update` / `lint` / `upgrade`.

The prefix `## [YYYY-MM-DD] <op> | <summary>` makes the log greppable:
`grep "^## \[" log.md | tail -5` shows recent activity.

## Size budgets (keep pages small)

- `index.md`: aim under ~150 lines. It's a map, not a manual.
- Module pages: under ~120 lines each. Split or link out if larger.
- `data-sources.md`: under ~80 lines. It's a list of sources, not a data dictionary.
- Prefer more small, focused pages over few large ones — agents read only what they need.
