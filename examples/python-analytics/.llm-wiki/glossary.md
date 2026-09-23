---
updated: 2026-09-23
covers: [glossary, domain]
status: current
---

# Glossary

- **Raw layer** — untouched source exports in `data/raw/` (git-ignored). Read only by `ingest.py`.
- **Processed layer** — cleaned, typed datasets in `data/processed/` (parquet), produced by `load.py`
  and consumed by analysis/notebooks.
- **Pipeline** — the ordered ingest → transform → load run; entry point `sales_insights.pipeline`.
- **Transform** — a pure `DataFrame -> DataFrame` function in `transform.py` (no I/O); the unit of
  testable logic. See [pipeline](modules/pipeline.md).
- **Metric** — a reusable analysis function in `analysis/` used by notebooks/reports. See
  [analysis](modules/analysis.md).
- **Notebook** — an exploratory `*.ipynb` in `notebooks/`; imports from the package, holds no
  reusable logic.
