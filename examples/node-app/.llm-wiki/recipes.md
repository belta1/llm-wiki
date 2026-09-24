---
updated: 2026-09-23
covers: [recipes, how-to]
status: current
---

# Recipes

## Run locally

```bash
pnpm install
cp .env.example .env          # set DATABASE_URL
pnpm prisma migrate dev       # apply migrations to local Postgres
pnpm dev                      # tsx watch, http://localhost:3000
```

## Run tests

```bash
pnpm test                     # all
pnpm test -- src/http/tasks.test.ts   # single file
pnpm test -- -t "rejects invalid"     # by test name
```

## Lint / format / typecheck

```bash
pnpm lint      # eslint
pnpm format    # prettier --write
pnpm typecheck # tsc --noEmit
```

## Add a dependency

```bash
pnpm add <pkg>        # runtime
pnpm add -D <pkg>     # dev
```

## Add an endpoint

1. Add the route in `src/http/<resource>.routes.ts` (create the file for a new resource).
2. Add the handler in `src/http/<resource>.controller.ts`; define a zod schema and validate input.
3. If it needs data, add/extend `src/data/<resource>.repository.ts` (only place that uses Prisma).
4. Register the router in `src/app.ts`.
5. Add `src/http/<resource>.test.ts` (happy path + a validation failure) and run `pnpm test`.

## Add a migration

1. Edit `prisma/schema.prisma`.
2. `pnpm prisma migrate dev --name <change>` — creates the migration and updates the client.
3. Update the affected repository in `src/data/` and its tests.
