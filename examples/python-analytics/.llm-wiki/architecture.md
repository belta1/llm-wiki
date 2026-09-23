---
updated: 2026-09-23
covers: [architecture]
status: current
---

# Architecture

A batch ETL pipeline. There is no long-running service and no database — the "state" is files on
disk (or object storage): raw inputs in, processed datasets and reports out.

## Data flow

```
data/raw/*.csv
  → ingest.py    (read raw exports → pandas/polars DataFrames)
  → transform.py (clean, dedupe, join, derive columns)
  → load.py      (write data/processed/*.parquet)
  → analysis/    (compute metrics; notebooks read processed/)
```

`pipeline.py` orchestrates ingest → transform → load in order and is the single entry point.

## Components

- **ingest** (`ingest.py`) — reads raw files into frames; one function per source. Isolates all
  file-format quirks here.
- **transform** (`transform.py`) — pure, testable functions `DataFrame -> DataFrame`; no I/O.
- **load** (`load.py`) — writes processed outputs (parquet) with stable schemas.
- **analysis** (`analysis/`) — reusable metric functions imported by both notebooks and reports.
- **config** (`config.py`) — data paths and run parameters (dates, thresholds) via pydantic-settings.

## Boundaries & decisions

- **Transforms are pure and I/O-free** so they're unit-testable with small in-memory frames. Reading
  and writing live only in `ingest`/`load`.
- **Notebooks don't hold logic worth keeping** — anything reusable moves into `analysis/` and gets a
  test. Notebooks are for exploration and presentation.
- **Data is not committed** (`data/` is git-ignored); the pipeline is reproducible from raw inputs.
- `src/` layout: the importable package is `src/sales_insights/`.
