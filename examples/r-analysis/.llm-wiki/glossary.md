---
updated: 2026-09-25
covers: [glossary, domain, r]
status: current
---

# Glossary

- **Wave** — one quarterly survey fielding (`2026Q2`); one folder in `data-raw/`, one dynamic
  branch of `clean`.
- **Target** — a named, cached step in `_targets.R`; built by `tar_make()`, read with `tar_read()`.
- **Store** — `_targets/`: cached target values + metadata. Output, not source.
- **Outdated** — a target whose code, inputs or upstream targets changed since its last build.
- **Margins** — population totals by age band × region and by gender (`data/margins.csv`) used for
  raking.
- **Raking** — iterative proportional fitting of weights to margins (`survey::rake`); weights are
  trimmed to [0.3, 5].
- **CSAT** — `q12_satisfaction`, 5-point ordinal; the model outcome.
- **Top-2 box** — share answering 4 or 5 on a 5-point item; the headline metric.
- **renv snapshot** — writing the current library's versions to `renv.lock`.
