---
updated: 2026-09-25
covers: [conventions, patterns, r]
status: current
---

# Conventions

## Structure

- One file per stage in `R/` (`ingest.R`, `clean.R`, `weights.R`, `models.R`, `plots.R`,
  `tables.R`); functions named `verb_noun()` (`read_wave()`, `recode_satisfaction()`,
  `rake_weights()`, `plot_trend()`).
- `_targets.R` loads everything in `R/` with `tar_source()` — no `source()` calls elsewhere.
- Targets named `snake_case` nouns (`clean`, `weighted`, `model_fit`, `fig_trend`, `tbl_region`).

## Style

- tidyverse style, native pipe `|>` (not `%>%`), 2-space indent, `<-` for assignment.
- Call non-core packages with `pkg::fn()` inside functions (`survey::svydesign()`,
  `ordinal::clm()`); package loading happens once via `tar_option_set(packages = …)`.
- Paths via `here::here()` or `config::get()$paths`; **no `setwd()`**, no absolute paths.
- Column names `snake_case`; survey items keep their questionnaire code (`q12_satisfaction`) and
  get a readable label in `R/clean.R`'s codebook, not a rename.

## Data rules

- Never write into `data-raw/`. Never commit real survey data (`data-raw/` is git-ignored except
  `data-raw/sample/`, which is synthetic).
- Don't commit `_targets/` or `reports/_output/`.
- Missing codes (`-99`, `-98`) become `NA` in `clean` — downstream code assumes that.

## Tooling & config locations

- **renv:** `renv.lock`, `renv/` (`renv/library` git-ignored), `.Rprofile` (activates renv).
- **Lint/format:** `.lintr` (line length 100, `object_name_linter(styles = "snake_case")`);
  `styler::style_dir()` before committing.
- **Config:** `config.yml` — `default` (team drive paths) and `ci` (sample data, HTML only).
- **Quarto:** `_quarto.yml` (project type `default`, `execute: freeze: false`; targets does the caching).

## Testing

- testthat 3e; one `tests/testthat/test-<file>.R` per `R/` file; `tests/testthat/setup.R` sources
  `R/`. Test functions on small inline tibbles — never on real data.
- New recode or weighting logic ships with a test. CI fails on lint warnings and test failures.

## Do / don't

- ✅ Add a package with `renv::install()` **then `renv::snapshot()`** — commit `renv.lock`.
- ✅ Put logic in `R/` and a target in `_targets.R`; rerun with `tar_make()`.
- ❌ Don't `install.packages()` or `library()` in committed code.
- ❌ Don't compute in report chunks or edit `_targets/` by hand (use `tar_invalidate()`).
