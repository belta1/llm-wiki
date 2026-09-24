---
updated: 2026-09-23
covers: [overview, navigation]
status: current
---

# Index — tasks-service

A small REST API for managing tasks. **Read this first, then open the files it points to.**
FastAPI service backed by Postgres via SQLAlchemy, migrations with Alembic.

## Stack

- **Language / runtime:** Python 3.12
- **Package manager:** uv (`uv.lock`, `pyproject.toml`)
- **Run locally:** `uv run uvicorn app.main:app --reload` (port 8000)
- **Test:** `uv run pytest` · single: `uv run pytest tests/test_tasks.py::test_create`
- **Lint / format:** `uv run ruff check` · `uv run ruff format`
- **Typecheck:** `uv run mypy app`

## Map

| Area | Key files / dirs | Purpose | More |
|------|------------------|---------|------|
| API | `app/api/` `app/main.py` | FastAPI app, routers, dependencies | [api](modules/api.md) |
| DB | `app/db/` `alembic/` | SQLAlchemy models, session, migrations | [db](modules/db.md) |
| Config | `app/config.py` | Settings via pydantic-settings | — |

## Where to start by task

- **Fix an endpoint bug** → [api](modules/api.md), `app/api/tasks.py`
- **Add an endpoint** → [recipes](recipes.md#add-an-endpoint), [api](modules/api.md)
- **Change the model / add a migration** → [recipes](recipes.md#add-a-migration), `app/db/models.py`
- **Run / debug locally** → [recipes](recipes.md#run-locally)

## Also see

- [architecture](architecture.md) · [conventions](conventions.md) · [glossary](glossary.md) · [log](log.md)
