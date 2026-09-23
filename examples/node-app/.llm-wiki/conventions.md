---
updated: 2026-09-23
covers: [conventions, patterns]
status: current
---

# Conventions

## Naming & structure

- One file per role, suffix by role: `*.routes.ts`, `*.controller.ts`, `*.repository.ts`,
  `*.test.ts`. Colocate tests next to the code they cover.
- HTTP code in `src/http/`, persistence in `src/data/`. Nothing else imports Prisma.

## Patterns to reuse

- **Config:** import the typed object from `src/config.ts`; never read `process.env` elsewhere.
- **Prisma client:** import the singleton from `src/data/client.ts`; don't `new PrismaClient()`.
- **Validation:** define a zod schema per endpoint in the controller; parse `req.body`/`req.params`.
- **Errors:** throw `AppError` (`src/http/errors.ts`); the error middleware maps it to a status.

## Tooling & config locations

- **Package manager:** pnpm. Add deps with `pnpm add <pkg>` / `pnpm add -D <pkg>`.
- **ESLint:** `eslint.config.js` (flat config). **Prettier:** `.prettierrc`.
- **TypeScript:** `tsconfig.json`, `strict: true`, `moduleResolution: NodeNext` — import local files
  with a `.js` suffix (e.g. `import { x } from "./config.js"`).

## Testing

- Vitest. Run: `pnpm test`; single file: `pnpm test -- <path>`; watch: `pnpm test -- --watch`.
- HTTP tests use `supertest` against the Express `app` (not a live server).
- New endpoints ship with a `*.test.ts` covering happy path + validation failure.

## Do / don't

- ✅ Route → controller → repository → Prisma.
- ❌ Don't call Prisma from a controller or route handler.
- ❌ Don't read `process.env` outside `src/config.ts`.
