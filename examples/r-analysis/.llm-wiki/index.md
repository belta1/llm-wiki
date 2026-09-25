---
updated: 2026-09-25
covers: [overview, navigation]
status: current
---

# Index — survey-analysis

An **R analysis project** that turns quarterly customer-survey exports into weighted estimates, a
satisfaction model, and a **Quarto report**. It's a **`targets` pipeline**, not a package: logic
lives in functions under `R/`, wired together in `_targets.R`; dependencies are pinned with
**renv**. No web app, no database. **Read this first, then open the files it points to.**

## Stack

- **Runtime:** R 4.4.1 (`renv.lock`), Quarto 1.5 (CI pins it)
- **Dependencies:** renv — `Rscript -e 'renv::restore()'`; `.Rprofile` activates renv automatically
- **Run the pipeline:** `make run` → `Rscript -e 'targets::tar_make()'` · one target:
  `Rscript -e 'targets::tar_make(names = model_fit)'`
- **What's stale:** `Rscript -e 'targets::tar_outdated()'` (or `tar_visnetwork()` in RStudio)
- **Render the report:** part of `tar_make()` (`tarchetypes::tar_quarto`); standalone preview:
  `quarto preview reports/report.qmd`
- **Test:** `make test` → `Rscript -e 'testthat::test_dir("tests/testthat")'` · one file:
  `Rscript -e 'testthat::test_file("tests/testthat/test-weights.R")'`
- **Lint / format:** `make lint` → `lintr::lint_dir()` (`.lintr`) · `styler::style_dir()`
- **Config:** `config.yml` (`config::get()`), selected by `R_CONFIG_ACTIVE` (`default` | `ci`)
- **CI (ground truth):** `.github/workflows/check.yml` — `r-lib/actions/setup-renv`, lint, tests,
  `tar_make()` on `data-raw/sample/` with `R_CONFIG_ACTIVE=ci`

## Map

| Area | Key files / dirs | Purpose | More |
|------|------------------|---------|------|
| Pipeline definition | `_targets.R` | every target and its dependencies | [pipeline](modules/pipeline.md) |
| Ingest & clean | `R/ingest.R` `R/clean.R` | read `.sav` exports, harmonise waves, recode | [pipeline](modules/pipeline.md#stages) |
| Weighting | `R/weights.R` | raking to population margins (`survey::rake`) | [pipeline](modules/pipeline.md#stages) |
| Models | `R/models.R` | ordinal satisfaction model (`ordinal::clm`) | [pipeline](modules/pipeline.md#stages) |
| Figures & tables | `R/plots.R` `R/tables.R` | ggplot2 figures, gt tables consumed by the report | [report](modules/report.md) |
| Report | `reports/report.qmd` `_quarto.yml` | the quarterly report (HTML + PDF) | [report](modules/report.md) |
| Inputs | `data-raw/` (git-ignored) `data-raw/sample/` (committed) `data/margins.csv` | raw exports; tiny sample for CI; population margins | [pipeline](modules/pipeline.md#data-locations) |
| Tests | `tests/testthat/` | unit tests for `R/` helpers | [recipes](recipes.md#add-a-test) |

## Where to start by task

- **A new survey wave arrived** → [recipes](recipes.md#add-a-new-survey-wave)
- **Add a question / variable** → [recipes](recipes.md#add-a-variable-end-to-end), [pipeline](modules/pipeline.md)
- **Add a figure or table to the report** → [recipes](recipes.md#add-a-figure-to-the-report), [report](modules/report.md)
- **Numbers changed unexpectedly** → [pipeline](modules/pipeline.md#gotchas) (weights, recodes)
- **Add a package** → [recipes](recipes.md#add-a-dependency)

## Also see

- [architecture](architecture.md) · [conventions](conventions.md) · [glossary](glossary.md) · [log](log.md)
