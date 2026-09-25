---
updated: 2026-09-25
covers: [report, quarto, figures, tables]
status: current
---

# Report (Quarto + figures/tables)

The quarterly survey report. Built as the `report` target, so it re-renders whenever a figure,
table, or estimate it reads changes.

## Key files & entry points

- `reports/report.qmd` — the document; reads targets with `targets::tar_read()`.
- `_quarto.yml` — formats (`html` always; `pdf` via Typst except under `R_CONFIG_ACTIVE=ci`),
  output dir `reports/_output/`.
- `R/plots.R` — `plot_trend()`, `plot_region_map()`, `plot_drivers()` (from `model_fit`).
- `R/tables.R` — `tbl_region()`, `tbl_model()` (gt tables).
- `reports/_brand.yml` — colours/fonts; `R/plots.R` reads it via `theme_survey()`.

## How it works

`tarchetypes::tar_quarto(report, "reports/report.qmd")` scans the `.qmd` for `tar_read()` /
`tar_load()` calls and makes those targets dependencies. `fig_*` and `tbl_*` targets hold ggplot /
gt objects; the chunks just print them. Parameters (`params: wave`) default to the latest wave.

## Gotchas

- **No computation in chunks** — a `dplyr` pipeline in the `.qmd` isn't cached or tested, and
  `tar_quarto` can't see its inputs. Add a target instead.
- `quarto preview` reads whatever is in the store — run `make run` first or you'll see stale numbers.
- PDF needs Typst (bundled with Quarto ≥ 1.4); if the PDF step fails locally, check `quarto check`.
- Figure sizes are set per chunk (`#| fig-width`), not in `plot_*()` functions.

## Related

- [pipeline](pipeline.md) · [recipes](../recipes.md#add-a-figure-to-the-report) · [conventions](../conventions.md)
