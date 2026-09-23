---
updated: 2026-09-23
covers: [recipes, how-to]
status: current
---

# Recipes

## Run locally

```bash
uv sync                                   # install deps into .venv
cp .env.example .env                      # set DATABASE_URL
uv run alembic upgrade head               # apply migrations
uv run uvicorn app.main:app --reload      # http://localhost:8000  (docs at /docs)
```

## Run tests

```bash
uv run pytest                             # all
uv run pytest tests/test_tasks.py         # one file
uv run pytest tests/test_tasks.py::test_create   # one test
uv run pytest -k create                   # by keyword
```

## Lint / format / typecheck

```bash
uv run ruff check .        # lint (add --fix to autofix)
uv run ruff format .       # format
uv run mypy app            # typecheck
```

## Add a dependency

```bash
uv add <pkg>               # runtime
uv add --dev <pkg>         # dev
```

## Add an endpoint

1. Add/extend the router in `app/api/<resource>.py` (`APIRouter`); create it for a new resource.
2. Define request/response schemas in `app/api/schemas.py`.
3. Use `Depends(get_session)` for DB access; query models from `app/db/models.py`.
4. Include the router in `app/main.py` (`app.include_router(...)`) if new.
5. Add a test in `tests/` and run `uv run pytest`.

## Add a migration

1. Edit `app/db/models.py`.
2. `uv run alembic revision --autogenerate -m "<change>"` — review the generated file in `alembic/versions/`.
3. `uv run alembic upgrade head` to apply. Update affected endpoints/tests.
