---
updated: 2026-09-23
covers: [web, node, express, api]
status: current
---

# web (Node + Express + TypeScript)

The HTTP side: accept requests, enqueue jobs, serve results. Knows nothing about how images are
processed — only the [seam](seam.md) contract.

## Key files & entry points

- `web/src/server.ts` — process entry; starts the listener.
- `web/src/app.ts` — Express `app` (importable by tests).
- `web/src/routes/jobs.ts` — `POST /jobs` (validate → save upload → enqueue) and `GET /jobs/:id`
  (read `result:<id>`).
- `web/src/queue.ts` — Redis client; `enqueue(job)` (`LPUSH jobs`) and `getResult(id)`.
- `web/src/config.ts` — `REDIS_URL`, data dir, queue/result key names (must match the worker).

## How it works

`POST /jobs` validates the body with zod, writes the upload under `uploads/<id>`, and `enqueue()`s a
message per the [seam](seam.md) contract. `GET /jobs/:id` returns the stored result or 404 while
pending. See [architecture](../architecture.md).

## Gotchas

- Enqueue is **generic** — it doesn't need changing for a new job type; only the input validation
  does. New processing logic lives in the [worker](worker.md).
- Queue/result key names must match the worker's ([conventions](../conventions.md)); both from config.
- ESM/NodeNext: import local modules with a `.js` suffix.

## Related

- [worker](worker.md) · [seam](seam.md) · [recipes](../recipes.md#add-a-job-type)
