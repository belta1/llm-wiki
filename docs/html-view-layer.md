# Markdown canon, HTML view: why llm-wiki adds a dashboard instead of switching formats

*Audience: anyone deciding how llm-wiki should present a knowledge base, and teammates weighing "should
the wiki be HTML?" This explains the reasoning behind the `view` layer so the choice is legible, not
just implemented.*

## The prompt

A widely-shared post — ["Markdown is dead: why Claude is pivoting to
HTML"](https://uxhack.substack.com/p/markdown-is-dead-why-claude-is-pivoting) — argues that HTML beats
Markdown for AI output: visual density, color-coded diffs, rendered SVG diagrams, "a mini-dashboard
instead of a bulleted list." It's a good argument. It raised a fair question for this project: should
`.llm-wiki/` be HTML?

The answer is **no — but add an HTML view.** Here's why, and how to think about it.

## The one distinction that settles it: which direction is the text flowing?

The article is about the **model → human** direction. The AI produces something; a person reviews it;
HTML's density makes that review fast. True.

A `.llm-wiki/` runs the **other way — human/code → model.** It is *input an agent reads into its
context* to orient in a codebase before doing work. Its entire value (see
[`token-efficiency.md`](../skills/llm-wiki/references/token-efficiency.md)) is that the agent can
"orient in one cheap read" instead of sweeping the tree. For that direction, the format priorities
invert:

| | Model → human (the article) | Human/code → model (the wiki) |
|---|---|---|
| Read by | a person, rendered | an agent, as raw text |
| Wins with | visual density, interactivity | few tokens, plain structure |
| HTML markup is | signal (layout = meaning) | overhead (tags = wasted tokens) |
| Diffs / grep | not needed | load-bearing (`grep "^## \["`, git diff) |

Switching the canon to HTML would inflate every agent read, break the greppable `log.md` and YAML
frontmatter, and lose GitHub's native Markdown rendering (GitHub sanitizes raw `.html`). It would
spend the plugin's core advantage to buy a benefit that belongs to a different audience.

So: **keep the canon in Markdown; add a derived HTML view for the human-review moment.** Agents keep
reading source; humans get the render.

## Five ways to think about it

1. **Agents read source; humans read render.** Don't conflate the two directions. The right format
   depends on who's reading and why. The article is right for its direction and wrong for ours.

2. **Compile once, target two audiences.** Treat the wiki like source code: one canon, two build
   targets — a token-lean text target (Markdown, for LLMs) and a visually-dense target (HTML, for
   people). `/llm-wiki:view` is the compiler; `.llm-wiki/view/index.html` is the artifact.

3. **Frontmatter becomes UI.** The `updated:` / `status:` / `covers:` metadata that `lint` already
   reads turns into visual signal in the view — a freshness heatmap, filters, "needs attention"
   counts. The HTML layer is the payoff for metadata the canon was already carrying.

4. **The log becomes a story.** `log.md`'s greppable `## [date] op | summary` lines render as a
   color-coded timeline. Same bytes, two readers: `grep` for the agent, a timeline for the person.

5. **Review ≠ consumption.** HTML earns its token cost only at human-review time. It's generated on
   demand, `.gitignore`d by default, and flagged human-only in the pointer files so no agent wastes
   tokens reading markup. The cost lands where the benefit is.

## What the view shows

A single self-contained `.llm-wiki/view/index.html` (no build step, no dependencies — opens over
`file://`):

- **Summary tiles** — page/module counts, last-updated, a "needs attention" count.
- **Map grid** — the `index.md` Map table, filterable; every path is real and clickable.
- **Task router** — "Where to start by task" as cards.
- **Page graph** — inline-SVG graph of the cross-links between pages; hover to trace a page's edges.
- **Freshness heatmap** — each page colored by `updated:` age and `status:`.
- **Module cards** — purpose + key files per `modules/*.md`.
- **Activity timeline** — `log.md` as init/update/lint events.
- **Diff mode** (after `/llm-wiki:update`) — highlights which canon pages changed, the article's
  color-coded-diff idea applied to the wiki itself.

See [`view-layer.md`](../skills/llm-wiki/references/view-layer.md) for the generation model and data
shape.

## Recommendations per app

### Claude (Claude Code / desktop / web)
- Agents keep reading the Markdown canon — no token regression.
- `/llm-wiki:view` produces the self-contained HTML, which renders directly as a **Claude Artifact**:
  the article's "a fully rendered interface, not a chat bubble," at review time. Publish it for
  in-app review or open the file in a browser.
- The always-on skill is told the HTML is human-only, so agents don't read `view/`.

### GitHub Copilot (VS Code)
- Copilot has no plugin or artifact surface, so the view is opened in VS Code's **Simple Browser**
  (Command Palette → "Simple Browser: Show").
- Build it with the `/llm-wiki-view` prompt file; `install-copilot --view` / `-View` scaffolds the
  viewer template and gitignores it.
- `.github/copilot-instructions.md` carries the same human-only pointer line.

### GitHub.com
- Raw HTML is sanitized, so **Markdown stays the canonical rendered view on GitHub** — which is
  exactly what you want there (the canon renders natively, diffs are readable in PRs).
- The HTML view is a local/dev/artifact surface. If a team wants a hosted, always-current dashboard,
  publish `view/` via GitHub Pages / an Action — opt-in, not the default.

## What did *not* change

The canon rules are untouched: page formats, size budgets, cross-link style, the greppable log, and
the token-efficiency premise all stand exactly as before. The view is purely additive. If you removed
the `view` command tomorrow, every agent workflow would behave identically.
