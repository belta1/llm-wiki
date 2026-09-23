---
updated: 2026-09-23
covers: [overview, navigation, hybrid]
status: current
---

# Index — media-jobs

A **hybrid Node + Python** app. A TypeScript/Express **web** service accepts image-processing
requests and enqueues them; a Python **worker** consumes the queue, processes images (Pillow), and
writes results back. They communicate over **Redis** with a small JSON contract — no shared code.
**Read this first, then open the files it points to.**

## Components

| Component | Path | Toolchain | Purpose | Module page |
|-----------|------|-----------|---------|-------------|
| web | `web/` | pnpm · Express · TypeScript | HTTP API; enqueue jobs, serve results | [web](modules/web.md) |
| worker | `worker/` | uv · Python 3.12 · Pillow | consume queue, process images, write results | [worker](modules/worker.md) |
| seam | Redis | JSON over a list + result keys | the contract between web and worker | [seam](modules/seam.md) |

## Stack (per component)

- **web:** pnpm (`web/pnpm-lock.yaml`). Run `pnpm --dir web dev` · test `pnpm --dir web test`
  (Vitest) · `pnpm --dir web lint` · `pnpm --dir web typecheck`.
- **worker:** uv (`worker/uv.lock`). Run `uv run --project worker python -m worker.main` · test
  `uv run --project worker pytest` · lint `uv run --project worker ruff check`.
- **Everything together:** `docker compose up` (redis + web + worker). See [recipes](recipes.md#run-everything).

## Where to start by task

- **Understand how the two sides talk** → [seam](modules/seam.md), [architecture](architecture.md)
- **Add a new job type** → [recipes](recipes.md#add-a-job-type) (touches **both** web and worker)
- **Fix the HTTP API** → [web](modules/web.md), `web/src/routes/jobs.ts`
- **Fix processing** → [worker](modules/worker.md), `worker/worker/handlers.py`
- **Run it locally** → [recipes](recipes.md#run-everything)

## Also see

- [architecture](architecture.md) · [conventions](conventions.md) · [glossary](glossary.md) · [log](log.md)
