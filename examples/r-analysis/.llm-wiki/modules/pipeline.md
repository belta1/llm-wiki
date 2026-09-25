---
updated: 2026-09-25
covers: [pipeline, targets, ingest, weights, models]
status: current
---

# Pipeline (`_targets.R` + `R/`)

Everything from raw exports to model results. The report consumes its outputs — see
[report](report.md).

## Key files & entry points

- `_targets.R` — `tar_option_set(packages = …, seed = 20240101)`, `tar_source("R")`, and the target
  list. **Start here** to see how anything is produced.
- `R/ingest.R` — `list_wave_files()`, `read_wave()` (haven `.sav` → tibble, labels kept).
- `R/clean.R` — `wave_codebook()`, `recode_satisfaction()`, `harmonise_waves()`.
- `R/weights.R` — `rake_weights(clean, margins)` → `survey.design` with trimmed weights.
- `R/models.R` — `fit_csat_model()` (`ordinal::clm`, CSAT ~ tenure + channel + region).
- `data/margins.csv` — raking margins; `config.yml` — input paths per config.

## Stages

| Target | Built from | Output | Notes |
|--------|-----------|--------|-------|
| `raw_files` | `data-raw/` | file paths (`format = "file"`) | invalidates on any export change |
| `raw` | `raw_files` | list of tibbles, one per wave | |
| `clean` | `raw` (`pattern = map(raw)`) | tibble per wave, then combined | missing codes → `NA` |
| `margins` | `data/margins.csv` | tibble | |
| `weighted` | `clean`, `margins` | `survey.design` | raked, trimmed [0.3, 5] |
| `estimates` | `weighted` | top-2-box by wave × region, with SEs | headline numbers |
| `model_fit` | `weighted` | `clm` fit | slowest target (~3 min) |

## Data locations

- Raw: `data-raw/<YYYYQn>/*.sav` on the team drive (path in `config.yml` `default`); git-ignored.
- Sample: `data-raw/sample/` — synthetic, committed, used by CI (`R_CONFIG_ACTIVE=ci`).
- Derived: only in the `_targets/` store. Nothing is written to `data/` by the pipeline.

## Gotchas

- **Numbers moved?** Check `margins.csv` history and the wave's codebook first — a recode change or
  a new margin silently shifts every weighted estimate.
- A wave whose export lacks a variable yields `NA` columns after `harmonise_waves()`; estimates for
  that wave drop out rather than erroring. Look for warnings in `tar_meta(fields = warnings)`.
- `read_wave()` keeps haven labels; convert with `haven::as_factor()` in `clean`, not later.
- Don't call `tar_read()` inside `R/` functions — pass values in as arguments.

## Related

- [report](report.md) · [architecture](../architecture.md) · [recipes](../recipes.md#run-the-pipeline) · [conventions](../conventions.md)
