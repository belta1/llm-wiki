---
applyTo: "**/*.{R,r,Rmd,rmd,qmd}"
description: R guidance from the llm-wiki knowledge base (installed by llm-wiki; re-running the installer replaces this file).
---

# R files in this repo

Before editing R code, open `.llm-wiki/index.md` and the module page for the area you're touching —
it says whether this is a package, a targets pipeline, a Shiny app, or reports, and where data and
outputs live. Follow `.llm-wiki/conventions.md` for style; use `.llm-wiki/recipes.md` for restore /
run / test / render commands. If the wiki and the code disagree, the code wins.

**Dependencies (renv):** after adding a package, install it with `renv::install("<pkg>")` and run
`renv::snapshot()` so `renv.lock` changes with the code. In a package, also add it to `Imports:` in
`DESCRIPTION` (`usethis::use_package()`).

**By project shape** (the index Stack block says):

- **Package** (`DESCRIPTION` with `Package:`) — no `library()` / `require()` inside `R/`; call
  `pkg::fn()` or import via roxygen `@importFrom`. Document with roxygen and regenerate with
  `devtools::document()`; **never hand-edit `NAMESPACE` or `man/`**. Add tests under
  `tests/testthat/test-<file>.R`.
- **targets pipeline** (`_targets.R`) — put logic in functions under `R/` and wire them as targets in
  `_targets.R`; never edit or commit the `_targets/` store; rerun with `targets::tar_make()`.
- **Shiny** — keep UI and server logic in modules (`mod_*_ui` / `mod_*_server`); no long-running
  work at app top level.
- **Quarto / R Markdown** — keep heavy computation in the pipeline or `R/` functions and read results
  in the document; respect the project's `freeze` / cache settings.

**General R rules** (unless `.llm-wiki/conventions.md` says otherwise):

- No `setwd()` and no absolute paths — use `here::here()` or project-relative paths.
- No `rm(list = ls())`, no `install.packages()` in committed code, no writing into input-data folders.
- Set seeds explicitly where results must be reproducible.
- Prefer vectorised / set-based code over growing objects in loops.
- Match the repo's style (tidyverse vs base, pipe `|>` vs `%>%`); keep `lintr` / `styler` clean.

After a substantive change, update the affected `.llm-wiki/` pages and append to
`.llm-wiki/log.md`: `## [YYYY-MM-DD] update | <summary>`.
