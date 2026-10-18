---
description: Generate a human-facing HTML review dashboard (.llm-wiki/view/index.html) from the Markdown canon — map, page graph, freshness heatmap, modules, and activity log.
argument-hint: "[optional: 'diff' to highlight what changed since the last commit]"
---

# /llm-wiki:view

Build or refresh the **HTML view layer** for this repo's `.llm-wiki/`. The view is a single
self-contained `.llm-wiki/view/index.html` dashboard that renders the Markdown **canon** for humans
to review at a glance — a map grid, a page link-graph, a freshness heatmap, module cards, and the
log as a timeline. Extra request, if any: $ARGUMENTS

**This changes nothing about the canon.** The Markdown pages stay the source of truth that agents
read; the view is *derived*, human-only, and never loaded into an agent's context. Read
`${CLAUDE_PLUGIN_ROOT}/skills/llm-wiki/references/view-layer.md` for the contract and the exact data
shape before generating.

Requires an existing `.llm-wiki/`. If there is none, suggest `/llm-wiki:init` first.

## Steps

1. **Read the canon.** Parse the existing `.llm-wiki/` pages — do not rewrite them:
   - `index.md` — the repo name/summary (heading + intro), the **Stack** block (label → value), the
     **Map** table (area → key files → purpose → module link), and the "Where to start by task" list.
   - Each `modules/<name>.md` — title, frontmatter `covers`, the one-line purpose, and the "Key files
     & entry points" paths.
   - Every page's YAML frontmatter — `updated`, `status`, `covers`.
   - The cross-links between pages (the relative `*.md` links in each page's body).
   - `log.md` — each `## [YYYY-MM-DD] <op> | <summary>` entry.
   - Skip the two non-page subdirectories: `view/` (this command's own output) and `bin/` (the
     deterministic lint CLI). Neither is canon and neither belongs in the dashboard.
   - **Data sources this repo uses** — read `data-sources.md` **first** if the wiki has one: it is
     the authoritative repo-scoped list (Name, Engine, Used by, Direction, Objects, Catalog). Only if
     that page is absent, fall back to scanning the repo's connection code (pyodbc / SQLAlchemy /
     `DBI::dbConnect` / `saspy.SASsession` / `boto3` / `snowflake.connector` / `duckdb`, `Server=`/
     `DSN=`/`s3://` strings, UNC paths, `pg_service`, `sascfg_personal.py`). Then, for Claude, join
     each source by **Name** to the cross-project catalog `~/.claude/llm-wiki/data-sources.md` for its
     connect-via and auth model. Record engine, connect-via, auth model, and credential **names**
     only — **never a secret value**.

2. **Build the data object** matching the shape in `references/view-layer.md`: `repo`, `summary`,
   `generated` (today's date), `today`, `stack[]`, `map[]`, `tasks[]`, `pages[]` (each with `id`,
   `title`, `kind` = `index`|`page`|`module`|`log`, `updated`, `status`, `covers[]`, and for modules
   `purpose` + `files[]`), `links[]` (`{from, to}` by page id), `log[]` (`{date, op, summary}`), and
   `dataSources[]` (`{name, engine, connectVia, auth, notes}` — names/shape only, no secrets; omit or
   leave empty if the repo connects to nothing).
   Use the module page's **base filename** (e.g. `http-api`, not `modules/http-api.md`) as its `id`,
   and reference that id from `map[].module`, `tasks[].targets`, and both ends of `links[]`.

3. **Write `.llm-wiki/view/index.html`.** Copy the viewer template
   `${CLAUDE_PLUGIN_ROOT}/templates/view/index.html` and replace **only** the JSON between the
   `<script id="wiki-data" type="application/json">` … `</script>` tags with the object from step 2.
   Leave all HTML, CSS, and JS in the template unchanged. Create `.llm-wiki/view/` if needed.

4. **Keep the view out of agent reads.** Ensure the repo's `.gitignore` contains
   `.llm-wiki/view/` (add it inside a `# llm-wiki` comment if not already present). The view is a
   build artifact, regenerated on demand; gitignoring it avoids diff noise and stale HTML in history.
   If the user explicitly wants to publish the view (e.g. GitHub Pages), skip this and tell them.

5. **Diff mode (if `$ARGUMENTS` mentions "diff", or you were just run after `/llm-wiki:update`).**
   Also capture `git diff` of the `.llm-wiki/*.md` canon since the last commit and add a `changed[]`
   array to the data (page ids whose canon changed) so the view can flag them. If the template in use
   doesn't render `changed[]`, just report the changed pages to the user instead.

6. **Report**: the path written, how many pages/modules/links were rendered, whether `.gitignore` was
   touched, and how to open it (see below).

## Opening the view

- **Claude Code / desktop / web:** the file renders directly as an **Artifact** — offer to publish
  `.llm-wiki/view/index.html` so the user can review it in-app, or they can open the file in a browser.
- **VS Code (Copilot users):** open `.llm-wiki/view/index.html` in the **Simple Browser**
  (Command Palette → "Simple Browser: Show") or any browser.
- **GitHub.com:** raw HTML is sanitized and won't render live there — Markdown stays the canonical
  rendered view on GitHub. Host the view via GitHub Pages only if the user wants a live site.

## Principles

- Derived, not canonical. Never edit the `.md` pages from this command; if the canon is wrong, that's
  a job for `/llm-wiki:update`.
- The template does the rendering; this command only supplies data. Don't hand-write HTML into the
  output beyond the JSON blob.
