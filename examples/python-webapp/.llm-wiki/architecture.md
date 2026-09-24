---
updated: 2026-09-23
covers: [architecture]
status: current
---

# Architecture

A FastAPI ASGI service. Stateless; persistence in Postgres via SQLAlchemy (sync engine).

## Components

- **API layer** (`app/api/`) — `APIRouter`s per resource. Endpoints declare pydantic
  request/response models and receive a DB session via `Depends`. See [api](modules/api.md).
- **DB layer** (`app/db/`) — SQLAlchemy models (`models.py`), engine/session factory (`session.py`),
  a `get_session` dependency. Migrations in `alembic/`. See [db](modules/db.md).
- **Config** (`app/config.py`) — `Settings` (pydantic-settings) read from env; imported as a
  singleton.

## Request flow

```
HTTP request → app/main.py (FastAPI, includes routers)
  → router (app/api/tasks.py) with Depends(get_session)
  → pydantic validation → SQLAlchemy query → Postgres
  → pydantic response model → JSON
```

## Boundaries

- Routers get their session through `Depends(get_session)`; they don't build engines or sessions
  themselves.
- Pydantic schemas (`app/api/schemas.py`) are separate from SQLAlchemy models — never return an ORM
  object directly.

## Key decisions

- `src`-less flat layout: the importable package is `app/`.
- Sync SQLAlchemy (not async) for simplicity; endpoints stay `def` where they only do DB work.
