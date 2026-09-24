---
updated: 2026-09-23
covers: [glossary, domain, hybrid]
status: current
---

# Glossary

- **Job** — a unit of work enqueued by web and consumed by the worker. JSON message on the `jobs`
  Redis list; shape defined in [seam](modules/seam.md).
- **Result** — the worker's output for a job, stored at `result:<id>` (JSON, with a TTL) and read
  back by web on `GET /jobs/:id`.
- **Seam** — the JSON contract + Redis keys that connect web and worker; the only coupling between
  them. See [seam](modules/seam.md).
- **Handler** — a worker function that processes one job `type` (`worker/worker/handlers.py`).
- **web / worker** — the Node HTTP service (`web/`) and the Python consumer (`worker/`); see their
  module pages.
