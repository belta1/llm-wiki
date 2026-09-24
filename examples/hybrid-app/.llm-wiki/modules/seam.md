---
updated: 2026-09-23
covers: [seam, contract, redis, hybrid-boundary]
status: current
---

# Seam — the web ↔ worker contract

**The only coupling between the two languages.** Both [web](web.md) and [worker](worker.md) implement
this by hand; there is no shared code. **A change here must land in the same commit on both sides.**

## Redis keys

- `jobs` — a **list** used as a queue. web `LPUSH`es; worker `BRPOP`s.
- `result:<id>` — a **string** holding the result JSON. worker `SET`s it with a TTL (default 1h); web
  `GET`s it.

## Job message (web → worker)

```json
{
  "id": "b1c2…",          // uuid; also the file basename
  "type": "resize",        // dispatch key; must have a worker handler
  "input": "uploads/b1c2.png",
  "params": { "width": 800, "height": 600 }
}
```

## Result (worker → web)

```json
{
  "id": "b1c2…",
  "status": "done",        // "done" | "error"
  "output": "processed/b1c2.png",   // present when done
  "error": null             // message when status = "error"
}
```

## Files

Passed by **path** on the shared data volume, never inline: web writes `uploads/<id>.<ext>`, worker
writes `processed/<id>.<ext>`. `DATA_DIR` env is shared.

## Job types (keep in sync with handlers)

| `type` | `params` | web validation | worker handler |
|--------|----------|----------------|----------------|
| `resize` | `width`, `height` | `web/src/routes/jobs.ts` | `handlers.resize` |
| `thumbnail` | `size` | `web/src/routes/jobs.ts` | `handlers.thumbnail` |

Adding a row = the [add-a-job-type recipe](../recipes.md#add-a-job-type).

## Related

- [architecture](../architecture.md) · [web](web.md) · [worker](worker.md) · [conventions](../conventions.md)
