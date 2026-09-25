---
updated: 2026-09-25
covers: [recipes, how-to, r, targets]
status: current
---

# Recipes

Commands assume the repo root. Every `make` target is a thin wrapper — the underlying `Rscript` call
is shown once so it works without `make` (e.g. on Windows).

## Set up

```bash
Rscript -e 'renv::restore()'        # installs the exact versions in renv.lock (make restore)
quarto check                        # Quarto 1.5+ on PATH
# point config.yml's default paths at the team drive, or: export R_CONFIG_ACTIVE=ci  (sample data)
```

## Run the pipeline

```bash
make run                                              # Rscript -e 'targets::tar_make()'
Rscript -e 'targets::tar_outdated()'                  # what would rebuild, without building
Rscript -e 'targets::tar_make(names = model_fit)'     # one target (+ anything it needs)
Rscript -e 'print(targets::tar_read(estimates))'      # inspect a result
Rscript -e 'targets::tar_invalidate(clean)'           # force a rebuild of one target
```

Failures: `Rscript -e 'targets::tar_meta(fields = error, complete_only = TRUE)'`; then
`tar_make(callr_function = NULL)` to debug in the current session.

## Render the report

```bash
make report                                  # tar_make(names = report) → reports/_output/
quarto preview reports/report.qmd            # live preview; reads existing targets via tar_read()
```

## Run tests

```bash
make test                                                           # all
Rscript -e 'testthat::test_dir("tests/testthat")'                   # same, without make
Rscript -e 'testthat::test_file("tests/testthat/test-weights.R")'   # one file
```

testthat has no per-`test_that()` filter from the CLI — run the file.

## Lint / format

```bash
make lint                          # Rscript -e 'lintr::lint_dir()'
Rscript -e 'styler::style_dir()'   # reformat in place
```

## Add a dependency

```bash
Rscript -e 'renv::install("<pkg>")'
# add "<pkg>" to tar_option_set(packages = …) in _targets.R if targets need it loaded
Rscript -e 'renv::snapshot()'      # commit renv.lock with the code that uses it
```

## Add a new survey wave

1. Put the export in `data-raw/<YYYYQn>/` (same filenames as prior waves).
2. If questions changed, update the codebook in `R/clean.R` (`wave_codebook()`); add a test.
3. `make run` — only the new `clean` branch and downstream targets rebuild. Check
   `tar_read(estimates)` against the previous wave for jumps before sharing.

## Add a variable end to end

1. Recode it in `R/clean.R` (keep the questionnaire code as the column name) + test.
2. If it's weighted or modelled, extend `R/weights.R` / `R/models.R`; if it's reported, add a
   figure/table function.
3. Wire any new target in `_targets.R`; `tar_outdated()` should show only what you expect.

## Add a figure to the report

1. `plot_<name>()` in `R/plots.R` (returns a ggplot; no `ggsave`).
2. Target `fig_<name> = plot_<name>(estimates)` in `_targets.R`.
3. In `reports/report.qmd`: a chunk with `targets::tar_read(fig_<name>)` and a `#| fig-cap:`.
   `tar_quarto` picks up the dependency automatically. See [report](modules/report.md).

## Add a test

`tests/testthat/test-<file>.R`; build a tiny tibble inline, call the function, `expect_equal()` /
`expect_snapshot()`. Run the file (above).
