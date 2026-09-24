---
updated: 2026-09-23
covers: [data, prisma, persistence]
status: current
---

# Data

Persistence: Prisma over Postgres. Repositories are the only code that touches the Prisma client.

## Key files & entry points

- `prisma/schema.prisma` — data model + datasource; source of truth for the DB schema.
- `prisma/migrations/` — generated migration history.
- `src/data/client.ts` — the shared `PrismaClient` singleton.
- `src/data/tasks.repository.ts` — CRUD for the Task aggregate.

## How it works

Controllers call repository functions; repositories use the singleton client and return domain
objects. Schema changes flow through `prisma migrate` (see
[recipes](../recipes.md#add-a-migration)), which regenerates the typed client.

## Gotchas

- Import the client only from `src/data/client.ts` — never `new PrismaClient()` (connection storms).
- After editing `schema.prisma`, run `pnpm prisma migrate dev` so the generated client matches, or
  types drift.

## Related

- [http-api](http-api.md) · [architecture](../architecture.md) · [glossary](../glossary.md)
