---
updated: 2026-09-23
covers: [analysis, metrics, notebooks]
status: current
---

# Analysis

Reusable metrics and the exploratory notebooks that use them. Reads the **processed** layer; never
the raw layer directly.

## Key files & entry points

- `src/sales_insights/analysis/` — reusable metric/report functions (e.g. `revenue.py`, `cohorts.py`),
  imported by notebooks and report scripts.
- `notebooks/` — exploratory `NN-topic.ipynb`, run order implied by the numeric prefix.

## How it works

Notebooks load processed parquet from `data/processed/` and call functions in `analysis/`. Anything
worth keeping is extracted from a notebook into `analysis/` with a test, so it can be reused and
maintained. Notebooks stay thin — exploration and presentation only. See
[architecture](../architecture.md).

## Gotchas

- Don't leave analysis logic buried in a notebook; move it to `analysis/` (notebooks aren't tested or
  reviewed like package code).
- Analysis reads `data/processed/`, not `data/raw/` — depend on the pipeline's stable output schema.

## Related

- [pipeline](pipeline.md) · [glossary](../glossary.md) · [recipes](../recipes.md#add-a-metric--report)
