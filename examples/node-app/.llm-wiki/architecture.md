---
updated: 2026-09-23
covers: [architecture]
status: current
---

# Architecture

A single-process Express HTTP service. Stateless; all persistence is in Postgres via Prisma.

## Components

- **HTTP layer** (`src/http/`) — Express routes → controllers. Controllers validate input (zod),
  call repositories, and shape responses. See [http-api](modules/http-api.md).
- **Data layer** (`src/data/`) — one repository per aggregate (e.g. `tasks.repository.ts`) wrapping
  the shared Prisma client (`src/data/client.ts`). See [data](modules/data.md).
- **Config** (`src/config.ts`) — parses `process.env` with zod at boot; fails fast on missing vars.

## Request flow

```
HTTP request → src/server.ts → src/app.ts (Express)
  → router (src/http/tasks.routes.ts)
  → controller (validates, maps) → repository (Prisma) → Postgres
  → JSON response
```

## Boundaries

- Controllers never touch Prisma directly — always through a repository. Enforced by review, noted in
  [conventions](conventions.md).
- Errors bubble to the central error middleware (`src/http/error.middleware.ts`), which maps known
  errors to status codes.

## Key decisions

- ESM-only (`"type": "module"`). Import paths use the `.js` extension in TS sources per NodeNext.
- Validation lives at the HTTP edge with zod; the data layer trusts its inputs.
