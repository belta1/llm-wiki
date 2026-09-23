---
updated: 2026-09-23
covers: [recipes, how-to, hybrid]
status: current
---

# Recipes

Commands are per-component. Run web scripts with `pnpm --dir web …`, worker tools with
`uv run --project worker …`, or bring the whole system up with Docker.

## Run everything

```bash
cp .env.example .env            # REDIS_URL, DATA_DIR
docker compose up               # redis + web (:3000) + worker
```

## Run one component

```bash
# web only (needs a Redis running)
pnpm --dir web install
pnpm --dir web dev              # http://localhost:3000

# worker only (needs a Redis running)
uv sync --project worker
uv run --project worker python -m worker.main
```

## Run tests

```bash
pnpm --dir web test                         # Vitest
uv run --project worker pytest              # pytest
# single:
pnpm --dir web test -- src/routes/jobs.test.ts
uv run --project worker pytest tests/test_handlers.py::test_resize
```

## Lint / format / typecheck

```bash
pnpm --dir web lint      && pnpm --dir web format      && pnpm --dir web typecheck
uv run --project worker ruff check . && uv run --project worker ruff format . && uv run --project worker mypy worker
```

## Add a dependency

```bash
pnpm --dir web add <pkg>            # (dev: -D)
uv add --project worker <pkg>       # (dev: --dev)
```

## Add a job type

This is the canonical cross-component change — it touches **both** sides and the contract:

1. **Contract:** add the new `type` and its `params` to [seam](modules/seam.md).
2. **web:** accept/validate it in `web/src/routes/jobs.ts` (extend the zod schema); no other web
   change needed — enqueuing is generic.
3. **worker:** add a handler in `worker/worker/handlers.py` and register it in the dispatch map in
   `worker/worker/main.py`.
4. **Tests:** a web test for validation, a worker test for the handler. Run both test suites above.
