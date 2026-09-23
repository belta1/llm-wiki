---
updated: 2026-09-23
covers: [worker, python, queue, processing]
status: current
---

# worker (Python + uv)

The processing side: consume jobs from Redis, run the image transform, write results. Knows nothing
about HTTP — only the [seam](seam.md) contract.

## Key files & entry points

- `worker/worker/main.py` — entry (`python -m worker.main`); the `BRPOP jobs` loop + the dispatch map
  (`type` → handler).
- `worker/worker/handlers.py` — one function per job `type` (e.g. `resize`, `thumbnail`); input path +
  params → output path.
- `worker/worker/queue.py` — Redis client; read a job, write `result:<id>` with a TTL.
- `worker/worker/config.py` — `REDIS_URL`, data dir, key names (must match web).

## How it works

The loop blocks on `BRPOP jobs`, parses the JSON message ([seam](seam.md)), dispatches on `type` to a
handler, runs it (Pillow), writes `processed/<id>` and sets `result:<id>`. On failure it writes a
result with `status: "error"`. See [architecture](../architecture.md).

## Gotchas

- A new job `type` needs a handler **and** an entry in the dispatch map in `main.py`, or messages of
  that type fail with "unknown type".
- Handlers do no Redis/queue I/O — keep them pure (path + params → path) so they're unit-testable.
- Result keys carry a TTL; a client that polls too late gets a 404 from web. Note the TTL if you
  change it.

## Related

- [web](web.md) · [seam](seam.md) · [recipes](../recipes.md#add-a-job-type)
