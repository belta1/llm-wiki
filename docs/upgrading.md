# Upgrading an existing `.llm-wiki/`

When the plugin changes what a wiki should contain, wikis already installed in repos don't follow
along. `/llm-wiki:upgrade` is the command that retrofits them.

## Why the other commands can't do it

- **`/llm-wiki:init` refuses.** Its first step is "if `.llm-wiki/` already exists, stop" — it must
  never clobber pages a human has curated. That's the right behavior, and it means `init` can't be the
  upgrade path.
- **`/llm-wiki:update` is code-driven.** It reacts to a `git diff`. It creates `data-sources.md` only
  "if the repo just gained its first external source", and refreshes pointer blocks only "if the
  wiki's entry points changed". A repo whose *code* didn't change gets nothing — even if the
  *templates* did.
- **`/llm-wiki:lint` only reports.** Its check 9e suggests creating `data-sources.md`, but that's a
  judgement fix, so `lint fix` won't apply it. Lint audits; it doesn't backfill.

So the gap was structural: nothing compared an installed wiki against the current templates.

## The contract version

`index.md` carries a `wiki_contract:` key — the wiki's **layout** version:

```yaml
---
updated: 2026-10-18
covers: [overview, navigation]
status: current
wiki_contract: 2
---
```

**It is not the plugin version.** `plugin.json` moves on every release; the contract moves only when
the wiki's layout actually changes. A bugfix release, or a new stack added to `stacks.md`, leaves every
wiki correctly marked current instead of flagging them all stale.

The levels and the per-level deltas live in
[`skills/llm-wiki/references/wiki-contract.md`](../skills/llm-wiki/references/wiki-contract.md), which
is the one file to edit when the layout next changes. `/llm-wiki:upgrade` reads its delta tables rather
than hard-coding them.

## The three states

| `index.md` says | What `upgrade` does |
|---|---|
| no `wiki_contract` | **Bootstrap** — diagnose by content against the templates, fix, then stamp. Every wiki in the wild takes this path once. |
| `wiki_contract` below current | Apply only the listed deltas, idempotently, then restamp. No content scan. |
| `wiki_contract` == current | No-op. Stops immediately. |

Content detection is the bootstrap, the stamp is the steady state. That's deliberate: it works on
every wiki ever generated, including hand-edited ones, without needing a marker to have been there
first — and after one run, staleness is a cheap integer compare.

A fresh `/llm-wiki:init` writes the stamp with the pages, so new wikis are born current.

## What it touches, and what it won't

**Does:** creates `data-sources.md` when the repo genuinely connects to something; adds the three
`index.md` hooks and the `README.md` Layout row; refreshes the three pointer managed blocks; adds
`.llm-wiki/view/` to `.gitignore`; copies missing Copilot prompt files; adds missing frontmatter keys.

**Won't, without asking:**

- **Write outside the repo.** Full two-tier data-source detection upserts
  `~/.claude/llm-wiki/data-sources.md`. Upgrade populates the repo page from a repo-local scan only and
  *offers* the catalog pass.
- **Rewrite page prose.** Missing scaffolding is upgrade's job; wrong claims are `lint`'s and
  `update`'s.
- **Generate the HTML view.** Offered, not run.
- **Touch content outside a pointer's `<!-- BEGIN llm-wiki -->` … `<!-- END llm-wiki -->` block.**

Declining an offer doesn't block the stamp — those items are optional by design, and `lint` catches a
genuinely missing `data-sources.md` on its own, by content. So you never get trapped in a re-prompt
loop.

## Rolling it out

Per repo, when you next work in it:

```
cd some-repo && claude
> /llm-wiki:upgrade
```

The always-on `llm-wiki` skill reads `index.md` first anyway, so it sees the stamp for free and will
mention `/llm-wiki:upgrade` once per session in a wiki that's behind — then get on with the task.
`/llm-wiki:lint` check 10 reports the same thing.

There's deliberately no batch sweep script: each run makes judgement calls about data sources worth
seeing, and the `log.md` entry records what happened.
