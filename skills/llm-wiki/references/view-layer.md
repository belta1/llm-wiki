# The HTML view layer (canon vs. view)

The `.llm-wiki/` **Markdown canon** is the source of truth. It is read by AI agents, so it is kept
token-light, greppable, and git-diff-friendly (see [token-efficiency.md](token-efficiency.md) and
[page-formats.md](page-formats.md)). None of that changes.

The **view layer** is a single derived HTML file, `.llm-wiki/view/index.html`, generated from the
canon by `/llm-wiki:view` (or the Copilot `/llm-wiki-view` prompt). It exists for **humans**: a
review dashboard with visual density the Markdown can't give a quick skim — a map grid, a page
link-graph, a freshness heatmap, module cards, and the log as a timeline.

## Why a separate layer, not HTML pages

- **Agents read source; humans read render.** HTML markup inflates tokens per read, breaks the
  `grep "^## \[" log.md` and YAML-frontmatter idioms, and GitHub sanitizes raw `.html` so it won't
  render live. The canon must stay Markdown. The view adds the human benefits *without* touching the
  agent read-path.
- **Derived, never canonical.** The view is a build artifact. It is regenerated on demand and
  `.gitignore`d by default (`.llm-wiki/view/`). If the canon is wrong, fix it with `/llm-wiki:update`
  — never by hand-editing the HTML.
- **Agents never read `view/`.** The pointer files flag it as human-only. Reading it would just cost
  tokens for markup the agent doesn't need.

## Generation model (data-driven)

The viewer template `templates/view/index.html` is fixed: all HTML, CSS, and JS live in it and never
change per repo. The only thing a generator writes is the JSON **data blob** between the
`<script id="wiki-data" type="application/json">` … `</script>` tags. `/llm-wiki:view` parses the
canon into that object and injects it; the template renders it. This keeps the agent's work tiny and
the output consistent.

Generation is **static** (the data is baked into the file), not a runtime `fetch` of the `.md`
files, because browsers block `file://` cross-file fetches — so the page must work when opened
directly or in VS Code's Simple Browser.

## Data shape

```jsonc
{
  "repo": "tasks-api",
  "summary": "One-line description from index.md.",
  "generated": "2026-10-12",          // date the view was built
  "today": "2026-10-12",              // reference date for freshness math
  "stack":  [{ "label": "Package manager", "value": "pnpm" }],
  "map":    [{ "area": "HTTP API", "files": ["src/http/"], "purpose": "…", "module": "http-api" }],
  "tasks":  [{ "label": "Add an endpoint", "targets": ["recipes", "http-api"] }],
  "pages":  [{
    "id": "http-api",                 // module base filename; "index" for index.md; etc.
    "title": "HTTP API",
    "kind": "index|page|module|log",
    "updated": "2026-09-23",
    "status": "current|stale|draft",
    "covers": ["http", "routes"],
    "purpose": "…",                   // modules only
    "files": ["src/app.ts"]           // modules only
  }],
  "links":  [{ "from": "index", "to": "http-api" }],   // by page id
  "log":    [{ "date": "2026-09-23", "op": "init", "summary": "…" }],
  "dataSources": [{                                    // optional; omit if the repo connects to nothing
    "name": "tasks-db",
    "engine": "PostgreSQL",                            // SQL Server | Oracle | PostgreSQL | SAS | …
    "connectVia": "Prisma (DATABASE_URL)",
    "auth": "User + password",
    "notes": "env: DATABASE_URL (name only)"           // names/shape only — NEVER a secret value
  }]
}
```

- `map[].module`, `tasks[].targets`, and both ends of `links[]` reference a page `id`. A `tasks`
  target that is a raw path (not a page id) renders as a code chip.
- Freshness color is computed from `status` and the age of `updated:` vs `today`: `draft` and `stale`
  always flag; otherwise `≤30d` fresh, `≤90d` aging, older overdue.
- `dataSources` renders a panel (hidden when empty) of the external engines the repo connects to —
  SQL Server, Oracle, PostgreSQL, SAS (saspy) and others, each with an engine-colored dot. It carries
  connection shape and credential **names** only; never a secret value. The generator fills it from the
  repo's connection code and (for Claude) the cross-project catalog
  [`data-sources.md`](data-sources.md), filtered to the sources this repo uses.

## Per-tool review

- **Claude** — `.llm-wiki/view/index.html` renders directly as an **Artifact**; publish it for
  in-app review, or open the file in a browser.
- **GitHub Copilot (VS Code)** — open it in the **Simple Browser** (Command Palette → "Simple
  Browser: Show"). The `/llm-wiki-view` prompt builds it; `install-copilot --view` scaffolds the
  template.
- **GitHub.com** — raw HTML is sanitized, so Markdown remains the canonical rendered view there. Host
  the view via GitHub Pages only if a live site is wanted.
