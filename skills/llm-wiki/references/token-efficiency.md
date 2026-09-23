# Why the wiki saves tokens

The wiki exists to make agents cheaper and faster, not to be comprehensive documentation. Every
design choice serves that goal.

## The problem it solves

Without a wiki, an agent starting a task does something like:

1. `glob **/*` to see the tree.
2. `grep` for a few guessed keywords.
3. Read several whole files to figure out which one is relevant.
4. Read more files to learn the conventions.
5. Finally start the actual work.

Steps 1–4 repeat every session and cost thousands of tokens before any real work happens. The agent
starts cold each time and re-derives the same map.

## How the wiki changes that

With a `.llm-wiki/`, the same task starts:

1. Read `.llm-wiki/index.md` (one small file) → learn where things live and which files matter.
2. Read the one relevant module page → learn entry points and gotchas.
3. Read the 1–2 real source files the map pointed to.
4. Start work, already knowing the conventions.

The map replaces the search. The agent reads what it needs and skips the rest.

## Design rules that keep it efficient

- **Locations over prose.** The index's job is to say *where* code is, so the agent reads targeted
  files instead of sweeping the tree. Real paths in every row.
- **Link, don't duplicate.** Restating code in the wiki doubles maintenance and drifts out of date.
  Point to the code; summarize only what isn't obvious from reading it (intent, gotchas, flow).
- **Small pages, loaded on demand.** An agent reads `index.md` always, and only the module pages for
  the area it's touching. Big monolithic docs defeat this — keep pages under budget (see
  [page-formats](page-formats.md#size-budgets-keep-pages-small)).
- **Recipes encode "how", once.** A recipe ("add an endpoint") captures the sequence of files and
  steps so the agent doesn't rediscover it each time.
- **Current beats complete.** A stale wiki costs tokens *and* misleads. Better to document less and
  keep it accurate. That's why maintenance (update on every substantive change) is part of the
  contract, not an afterthought.

## What NOT to put in the wiki

- Full copies of code or config (link instead).
- Auto-generated API references (those belong in generated docs).
- Long narrative history (that's what `log.md` and git are for).
- Anything an agent can learn faster by reading one obvious file.
