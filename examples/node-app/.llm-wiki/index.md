---
updated: 2026-09-23
covers: [overview, navigation]
status: current
---

# Index — tasks-api

A small REST API for managing tasks. **Read this first, then open the files it points to.**
Express + TypeScript service backed by Postgres via Prisma.

## Stack

- **Languages / runtime:** TypeScript, Node 20 (ESM)
- **Package manager:** pnpm (`pnpm-lock.yaml`)
- **Run locally:** `pnpm dev` (tsx watch, port 3000)
- **Build:** `pnpm build` (tsc → `dist/`)
- **Test:** `pnpm test` (Vitest) · single: `pnpm test -- src/http/tasks.test.ts`
- **Lint / format:** `pnpm lint` (ESLint) · `pnpm format` (Prettier)
- **Typecheck:** `pnpm typecheck` (`tsc --noEmit`, `strict: true`)

## Map

| Area | Key files / dirs | Purpose | More |
|------|------------------|---------|------|
| HTTP API | `src/http/` `src/app.ts` `src/server.ts` | Express app, routes, controllers, middleware | [http-api](modules/http-api.md) |
| Data | `src/data/` `prisma/schema.prisma` | Prisma client, repositories, migrations | [data](modules/data.md) |
| Config | `src/config.ts` | Env parsing (zod), typed config | — |

## Where to start by task

- **Fix an endpoint bug** → [http-api](modules/http-api.md), `src/http/tasks.controller.ts`
- **Add an endpoint** → [recipes](recipes.md#add-an-endpoint), [http-api](modules/http-api.md)
- **Change the schema / add a migration** → [recipes](recipes.md#add-a-migration), `prisma/schema.prisma`
- **Run / debug locally** → [recipes](recipes.md#run-locally)

## Also see

- [architecture](architecture.md) · [conventions](conventions.md) · [glossary](glossary.md) · [log](log.md)
