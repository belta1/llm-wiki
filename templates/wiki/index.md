---
updated: YYYY-MM-DD
covers: [overview, navigation]
status: draft
---

# Index — <REPO NAME>

The map of this repository. **Read this first, then jump to the files it points to.** One-line
description of what this project is and does: _<fill in>_.

## Stack

- **Languages / runtime:** _<e.g. TypeScript, Node 20>_
- **Build / package:** _<e.g. pnpm, Vite>_
- **Test:** _<e.g. Vitest — `pnpm test>`_
- **Run locally:** _<e.g. `pnpm dev>`_

## Map

| Area | Key files / dirs | Purpose | More |
|------|------------------|---------|------|
| _Auth_ | `src/auth/` | _Login, sessions, tokens_ | [auth](modules/auth.md) |
| _API_ | `src/api/` `src/routes/` | _HTTP endpoints_ | [api](modules/api.md) |
| _Data_ | `src/db/` `db/migrations/` | _Models, persistence_ | [data](modules/data.md) |
| _..._ | _..._ | _..._ | _..._ |

_Every "key files" cell holds real paths so an agent can open them directly._

## Where to start by task

- **Fix a bug in _<area>_** → [_<module>_](modules/_<module>_.md), `<key file>`
- **Add a _<feature type>_** → [recipes](recipes.md#_<recipe>_), [_<module>_](modules/_<module>_.md)
- **Change the data model** → [recipes](recipes.md#_<recipe>_), `<migrations dir>`
- **Run / debug locally** → [recipes](recipes.md#run-locally)

## Also see

- [architecture](architecture.md) — how the pieces fit together
- [conventions](conventions.md) — how to write code that matches this repo
- [glossary](glossary.md) — domain terms
- [log](log.md) — recent wiki changes
