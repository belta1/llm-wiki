---
updated: 2026-09-25
covers: [architecture, pipeline, targets]
status: current
---

# Architecture

A **`targets` pipeline**. `_targets.R` declares targets (each a function call over upstream
targets); `targets::tar_make()` builds only what's outdated and caches every result in the
`_targets/` store. Scripts are never run top-to-bottom by hand — if you find yourself `source()`-ing
files in order, you're bypassing the cache.

## Flow

```
data-raw/<wave>/*.sav ──▶ raw_files ──▶ raw ──▶ clean ──▶ weighted ──▶ estimates ─┐
data/margins.csv ─────────────────────────────▶ margins ─┘        └──▶ model_fit ─┤
                                                                                   ▼
                                                        figures, tables ──▶ report (tar_quarto)
                                                                              → reports/_output/
```

- `raw_files` is a `format = "file"` target over `data-raw/`, so a new or changed export
  invalidates everything downstream automatically.
- `clean` is **dynamically branched by wave** (`pattern = map(raw)`), so adding a wave only builds
  the new branch.
- `report` is a `tarchetypes::tar_quarto()` target: it depends on the targets the `.qmd` reads with
  `tar_read()`, so editing a figure function re-renders the report.

## Boundaries

- **`R/`** holds pure-ish functions (data in, data out); no file I/O except in `R/ingest.R`.
- **`_targets.R`** only wires functions together — no data manipulation inline.
- **`reports/report.qmd`** only reads targets (`tar_read()`) and formats; no modelling in chunks.
- **`data-raw/`** is read-only input (on the team drive, git-ignored); outputs go to the store and
  `reports/_output/`.

## Key decisions & constraints

- **renv, not a package.** There's no `DESCRIPTION`; `renv.lock` is the dependency record, so every
  new package must be snapshotted.
- **Weights are raked** to `data/margins.csv` (age × region, gender); changing the margins file
  changes every weighted number — it's versioned and reviewed like code.
- **Seeds:** `tar_option_set(seed = 20240101)`; targets derives per-target seeds from it, so results
  are reproducible without `set.seed()` calls inside functions.
- `R_CONFIG_ACTIVE=ci` swaps paths to `data-raw/sample/` and skips the PDF render.
