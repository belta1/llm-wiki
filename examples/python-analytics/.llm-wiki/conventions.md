---
updated: 2026-09-23
covers: [conventions, patterns]
status: current
---

# Conventions

## Structure

- `src/`-layout package `src/sales_insights/`. Pipeline stages are separate modules
  (`ingest.py`/`transform.py`/`load.py`); reusable analysis in `analysis/`.
- Exploratory work in `notebooks/`, named `NN-topic.ipynb` (ordered). Notebooks import from the
  package; they don't define reusable logic themselves.

## Tooling & config locations

- **Package manager:** uv. Add deps with `uv add <pkg>` / `uv add --dev <pkg>`; run with `uv run`.
- **Ruff:** `[tool.ruff]` in `pyproject.toml` (lint + format). **mypy:** `[tool.mypy]`.
- **pytest:** `[tool.pytest.ini_options]`.

## Data & reproducibility

- **Never commit data.** `data/raw/` and `data/processed/` are git-ignored. Paths come from
  `config.py`, not hardcoded.
- **Transforms are pure** `DataFrame -> DataFrame` — no file reads/writes, no globals. This is what
  makes them testable.
- **Determinism:** seed any sampling/model step; sort before writing so outputs are stable and
  diffable.
- **Schemas:** write processed outputs as parquet with explicit dtypes; keep column names stable
  (downstream notebooks depend on them).

## pandas / polars

- Prefer method-chaining pipelines; avoid mutating a frame in place across functions (assign new
  frames). Set dtypes explicitly on ingest rather than relying on inference.

## Testing

- pytest with small in-memory frames. Run: `uv run pytest`; single:
  `uv run pytest tests/test_transform.py::test_dedupe`.
- Every transform function has a test; use `pandas.testing.assert_frame_equal` for expected outputs.

## Do / don't

- ✅ Put logic in `transform.py`/`analysis/` with tests; keep notebooks thin.
- ❌ Don't read/write files inside a transform function.
- ❌ Don't hardcode paths or commit anything under `data/`.
