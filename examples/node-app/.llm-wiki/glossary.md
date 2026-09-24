---
updated: 2026-09-23
covers: [glossary, domain]
status: current
---

# Glossary

- **Task** — the core domain entity: an item with `id`, `title`, `done`, `createdAt`. Schema in
  `prisma/schema.prisma`; see [data](modules/data.md).
- **Repository** — a thin data-access object wrapping Prisma for one aggregate (`src/data/*.repository.ts`).
- **Controller** — an Express handler that validates input and maps between HTTP and repositories
  (`src/http/*.controller.ts`).
- **AppError** — the app's typed error class (`src/http/errors.ts`), mapped to HTTP status by the
  error middleware.
