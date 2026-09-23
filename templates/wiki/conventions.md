---
updated: YYYY-MM-DD
covers: [conventions, patterns]
status: draft
---

# Conventions

How to write code that matches this repo, so agents reuse existing patterns instead of inventing new
ones. Derive these from the actual code, not from generic best practice.

## Naming & structure

- _File / module / test naming conventions._
- _Where new code of each kind goes (e.g. "endpoints in `src/routes/`, one file per resource")._

## Patterns to reuse

- _<Pattern>_ — _where it's defined (`<path>`) and when to use it._
- _Shared utilities/helpers agents should prefer over rolling their own (`<path>`)._

## Error handling

- _How errors are raised, wrapped, logged, surfaced to callers._

## Testing

- _Framework and how to run: `<command>`._
- _Where tests live, naming, and the expected style (unit/integration/e2e)._
- _Whether new code is expected to ship with tests._

## Do / don't

- ✅ _<a thing this repo consistently does>_
- ❌ _<a thing to avoid — e.g. "don't import across module boundary X→Y directly">_
