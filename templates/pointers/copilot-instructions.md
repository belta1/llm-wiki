<!-- BEGIN llm-wiki -->
# Copilot instructions

This repository has a compiled knowledge base under `.llm-wiki/` — a map of where code lives, how the
system fits together, its conventions, and recipes for common tasks.

When answering questions or suggesting edits about this codebase:

- **Consult `.llm-wiki/index.md` first** to locate the relevant files and module page, instead of
  guessing or scanning broadly. Each index row lists real file paths.
- **Follow `.llm-wiki/conventions.md`** so suggestions match the repo's existing patterns, naming,
  error handling, and testing style.
- **Use `.llm-wiki/recipes.md`** for the established steps to do common tasks in this repo.
- Treat the **code as the source of truth**; if a wiki page looks out of date, prefer the code.

See `.llm-wiki/README.md` for the full contract. When you make a substantive change, the affected
`.llm-wiki/` pages should be updated and a line appended to `.llm-wiki/log.md` — the `/llm-wiki-update`
prompt in `.github/prompts/` does this. `/llm-wiki-lint` health-checks the wiki (it starts from
`python3 .llm-wiki/bin/llm-wiki lint` when that script is present) and `/llm-wiki-upgrade` brings an
older wiki up to the current structure.

For people (not Copilot): the `/llm-wiki-view` prompt builds a rendered review dashboard at
`.llm-wiki/view/index.html` — open it in VS Code's Simple Browser. Base suggestions on the Markdown
pages above, not the generated HTML.
<!-- END llm-wiki -->
