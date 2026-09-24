---
updated: 2026-09-23
covers: [recipes, how-to]
status: current
---

# Recipes

## Set up

```bash
uv sync                       # install deps into .venv
cp .env.example .env          # set data paths / params if overriding defaults
# place input files under data/raw/  (not committed)
```

## Run the pipeline

```bash
uv run python -m sales_insights.pipeline            # full ingest → transform → load
uv run python -m sales_insights.pipeline --stage transform   # a single stage, if supported
```

Outputs land in `data/processed/`.

## Work in a notebook

```bash
uv run jupyter lab            # open notebooks/ ; import from sales_insights.*
```

## Run tests

```bash
uv run pytest                                   # all
uv run pytest tests/test_transform.py           # one file
uv run pytest tests/test_transform.py::test_dedupe   # one test
uv run pytest -k dedupe                          # by keyword
```

## Lint / format / typecheck

```bash
uv run ruff check .     # add --fix to autofix
uv run ruff format .
uv run mypy src/sales_insights
```

## Add a dependency

```bash
uv add <pkg>            # runtime (e.g. polars, duckdb)
uv add --dev <pkg>      # dev (e.g. pytest plugins)
```

## Add a data source

1. Add a reader in `src/sales_insights/ingest.py` (one function per source; set dtypes explicitly).
2. Have `pipeline.py` call it and pass the frame into `transform`.
3. Add a small fixture under `tests/fixtures/` and a test.

## Add a transform

1. Add a pure `DataFrame -> DataFrame` function in `src/sales_insights/transform.py`.
2. Wire it into the transform sequence in `pipeline.py`.
3. Add a test with a tiny in-memory frame (`assert_frame_equal`), then `uv run pytest`.

## Add a metric / report

1. Add a reusable function in `src/sales_insights/analysis/`.
2. Use it from a notebook or a report script; add a test if it's non-trivial.
