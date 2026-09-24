---
updated: 2026-09-23
covers: [architecture, seam]
status: current
---

# Architecture

Two independently-deployed processes in one repo, decoupled by a Redis queue. Neither imports the
other; the **only** coupling is the JSON message contract on Redis (see [seam](modules/seam.md)).

## Flow

```
client → POST /jobs (web, Express/TS)
       → LPUSH "jobs" {id, type, input, params}   (Redis)
       → 202 { id }

worker (Python)  BRPOP "jobs"  → process (Pillow) → SET "result:<id>" {status, output}

client → GET /jobs/:id (web) → GET "result:<id>" (Redis) → 200 result | 404 pending
```

## Components

- **web** (`web/`) — Express API. `POST /jobs` validates input, writes the uploaded file, enqueues a
  job message, returns the id. `GET /jobs/:id` reads `result:<id>`. See [web](modules/web.md).
- **worker** (`worker/`) — a blocking consumer loop (`BRPOP`) that dispatches on `type` to a handler,
  runs the image transform, and writes the result. See [worker](modules/worker.md).
- **Redis** — queue (`jobs` list) + result store (`result:<id>` keys, TTL). Also the shared file
  location convention (`uploads/`, `processed/`) both sides agree on.

## The seam (most important boundary)

The contract — queue name, message shape, result shape, key names, file paths — is defined once in
[seam](modules/seam.md) and implemented on both sides. **Changing it means editing both `web/` and
`worker/` together**; that's the one place a change can't stay on one side.

## Decisions

- **Redis + plain JSON**, not BullMQ or Celery — those job formats are language-specific and don't
  interoperate. A hand-rolled JSON message keeps the seam language-neutral.
- Processes are stateless; scale the worker horizontally by running more of it.
- Files pass by path on a shared volume, not inline in the message (keeps messages small).
