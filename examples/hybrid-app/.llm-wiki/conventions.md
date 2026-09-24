---
updated: 2026-09-23
covers: [conventions, patterns, hybrid]
status: current
---

# Conventions

This is a polyglot repo. Each component keeps its own toolchain and idioms — **don't force one
language's conventions on the other.** Shared rules live under "Cross-component".

## web/ (Node + TypeScript)

- **Package manager:** pnpm (run from repo root with `pnpm --dir web <script>`).
- Structure: routes in `web/src/routes/`, Redis access in `web/src/queue.ts`, config in
  `web/src/config.ts`. One route file per resource.
- **ESLint** `web/eslint.config.js`, **Prettier** `web/.prettierrc`, **TS** `web/tsconfig.json`
  (`strict: true`, ESM/NodeNext → import local files with `.js`).
- Tests: Vitest + supertest against the Express `app`.

## worker/ (Python)

- **Package manager:** uv (`uv run --project worker <tool>`).
- Structure: entry `worker/worker/main.py` (the consume loop), handlers in
  `worker/worker/handlers.py` (one per job `type`), config in `worker/worker/config.py`.
- **Ruff** (`[tool.ruff]` in `worker/pyproject.toml`), **mypy** for types.
- Handlers are pure-ish: input path + params → output path; no queue/Redis code inside a handler.

## Cross-component (the shared contract)

- **The message/result JSON contract is authoritative** and defined in [seam](modules/seam.md). Both
  sides must match it; change it in the same commit on both sides.
- **Redis keys & queue names** come from config on each side but must agree: `jobs` (list),
  `result:<id>`. Don't hardcode them ad hoc.
- **File paths:** `uploads/<id>.<ext>` (web writes) and `processed/<id>.<ext>` (worker writes),
  under the shared volume. Never inline file bytes in a message.
- **Env:** both read `REDIS_URL` and the shared data dir from env (`.env` at root; `docker-compose`
  passes them in).

## Do / don't

- ✅ Add a job type by editing **both** sides + the seam page (see [recipes](recipes.md#add-a-job-type)).
- ❌ Don't share source code between `web/` and `worker/` — the seam is the JSON contract, nothing else.
- ❌ Don't swap in BullMQ/Celery expecting cross-language interop.
