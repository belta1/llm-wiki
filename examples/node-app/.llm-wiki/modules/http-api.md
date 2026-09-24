---
updated: 2026-09-23
covers: [http, routes, controllers]
status: current
---

# HTTP API

The Express layer: routing, request validation, response shaping, error handling.

## Key files & entry points

- `src/server.ts` — process entry; reads config, starts the HTTP listener.
- `src/app.ts` — builds the Express `app`, mounts routers and middleware (importable by tests).
- `src/http/tasks.routes.ts` — `/tasks` routes → controller.
- `src/http/tasks.controller.ts` — handlers; zod validation; calls the tasks repository.
- `src/http/error.middleware.ts` — central error handler; maps `AppError` → status.
- `src/http/errors.ts` — `AppError` and subclasses.

## How it works

`app.ts` wires routers; each router delegates to a controller. Controllers validate with zod, call a
repository from [data](data.md), and return JSON. Thrown errors reach `error.middleware.ts`. Tests
import `app` and drive it with `supertest` — no live port. See [architecture](../architecture.md).

## Gotchas

- Handlers must not touch Prisma directly — go through a repository ([conventions](../conventions.md)).
- ESM + NodeNext: import local modules with the `.js` suffix in TS sources.
- Async handler errors must be forwarded to `next(err)` (or use the async wrapper in `src/http/`),
  or the error middleware won't catch them.

## Related

- [data](data.md) · [conventions](../conventions.md) · [recipes](../recipes.md#add-an-endpoint)
