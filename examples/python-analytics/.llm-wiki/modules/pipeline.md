---
updated: 2026-09-23
covers: [pipeline, etl, ingest, transform]
status: current
---

# Pipeline

The batch ETL: read raw sales exports, clean/transform, write processed datasets.

## Key files & entry points

- `src/sales_insights/pipeline.py` — orchestrator + entry point (`python -m sales_insights.pipeline`);
  runs ingest → transform → load in order.
- `src/sales_insights/ingest.py` — one reader per source; raw files → DataFrames, dtypes set here.
- `src/sales_insights/transform.py` — pure `DataFrame -> DataFrame` functions (clean, dedupe, join).
- `src/sales_insights/load.py` — writes `data/processed/*.parquet` with stable schemas.
- `src/sales_insights/config.py` — data paths and run parameters.

## How it works

`pipeline.py` reads paths/params from config, calls `ingest` for each source, threads the frames
through the `transform` sequence, and hands results to `load`. All file I/O is confined to
`ingest`/`load`; transforms are pure so they unit-test with tiny in-memory frames. See
[architecture](../architecture.md).

## Gotchas

- Keep transforms **pure** — no reads/writes inside them, or tests and reuse break
  ([conventions](../conventions.md)).
- Set dtypes on ingest; don't rely on pandas type inference (silent object columns cause downstream
  surprises).
- Sort before writing so processed outputs are deterministic and diffable.

## Related

- [analysis](analysis.md) · [architecture](../architecture.md) · [recipes](../recipes.md#add-a-transform)
