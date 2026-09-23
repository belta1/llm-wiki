---
updated: YYYY-MM-DD
covers: [overview, navigation]
status: draft
---

# Index — <REPO NAME>

The map of this repository. **Read this first, then jump to the files it points to.** One-line
description of what this project is and does: _<fill in>_.

## Stack

_Fill with the REAL commands for this repo (inferred from the lockfile / scripts), not guesses._

- **Language / runtime:** _<e.g. TypeScript, Node 20 — or Python 3.12>_
- **Package manager:** _<e.g. pnpm (`pnpm-lock.yaml`) — or uv (`uv.lock`)>_
- **Run locally:** _<e.g. `pnpm dev` — or `uv run uvicorn app.main:app --reload`>_
- **Build:** _<e.g. `pnpm build` — or n/a>_
- **Test:** _<e.g. `pnpm test` — or `uv run pytest`>_ · single: _<e.g. `pnpm test -- <file>`>_
- **Lint / format:** _<e.g. `pnpm lint` / `pnpm format` — or `uv run ruff check` / `ruff format`>_
- **Typecheck:** _<e.g. `pnpm typecheck` — or `uv run mypy <pkg>`>_

<!-- Monorepo OR hybrid (multi-language) repos: list each package/component with its OWN toolchain.
     Delete this block for single-component repos.
## Components

| Component | Path | Toolchain | Purpose | Module page |
|-----------|------|-----------|---------|-------------|
| _web_ | `web/` | _pnpm · Next.js_ | _UI + API routes_ | [web](modules/web.md) |
| _worker_ | `worker/` | _uv · Celery_ | _background jobs_ | [worker](modules/worker.md) |

For a hybrid repo, also document the **seam** between components (how they talk: subprocess / HTTP /
shared queue / shared files/DB) — see [architecture](architecture.md).
-->


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
