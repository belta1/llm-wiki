---
updated: 2026-09-23
covers: [overview, navigation]
status: current
---

# Index — sales-insights

A batch **data pipeline + analysis** project: ingest raw sales exports, clean/transform them, and
produce processed datasets and reports. **Read this first, then open the files it points to.**
No web server, no database — files in, files out. Python + pandas/polars.

## Stack

- **Language / runtime:** Python 3.12
- **Package manager:** uv (`uv.lock`, `pyproject.toml`)
- **Run the pipeline:** `uv run python -m sales_insights.pipeline`
- **Notebooks:** `uv run jupyter lab` (exploratory work in `notebooks/`)
- **Test:** `uv run pytest` · single: `uv run pytest tests/test_transform.py::test_dedupe`
- **Lint / format:** `uv run ruff check .` · `uv run ruff format .`
- **Typecheck:** `uv run mypy src/sales_insights`

## Map

| Area | Key files / dirs | Purpose | More |
|------|------------------|---------|------|
| Pipeline | `src/sales_insights/pipeline.py` `ingest.py` `transform.py` `load.py` | ingest → transform → write processed data | [pipeline](modules/pipeline.md) |
| Analysis | `src/sales_insights/analysis/` `notebooks/` | reusable metrics + exploratory notebooks | [analysis](modules/analysis.md) |
| Data | `data/raw/` `data/processed/` | inputs & outputs (git-ignored) | — |
| Config | `src/sales_insights/config.py` | paths, params via pydantic-settings | — |

## Where to start by task

- **Add a data source** → [recipes](recipes.md#add-a-data-source), `src/sales_insights/ingest.py`
- **Add / change a transform** → [recipes](recipes.md#add-a-transform), [pipeline](modules/pipeline.md)
- **Add a metric or report** → [analysis](modules/analysis.md), `src/sales_insights/analysis/`
- **Explore interactively** → [recipes](recipes.md#work-in-a-notebook), `notebooks/`
- **Run the whole pipeline** → [recipes](recipes.md#run-the-pipeline)

## Also see

- [architecture](architecture.md) · [conventions](conventions.md) · [glossary](glossary.md) · [log](log.md)
