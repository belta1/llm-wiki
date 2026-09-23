---
updated: 2026-09-23
covers: [conventions, patterns]
status: current
---

# Conventions

## Naming & structure

- Flat package layout under `app/`. API routers in `app/api/<resource>.py`, one router per resource.
- Pydantic schemas in `app/api/schemas.py`; SQLAlchemy models in `app/db/models.py`. Keep them
  distinct — schemas cross the HTTP boundary, models don't.

## Patterns to reuse

- **Settings:** import the `settings` singleton from `app/config.py`; don't read `os.environ`.
- **DB session:** depend on `get_session` (`app/db/session.py`); never instantiate a `Session`/engine
  inline.
- **Response models:** every endpoint declares `response_model=<Schema>`; return schema objects.
- **Errors:** raise `HTTPException` (or a helper in `app/api/errors.py`) with the right status.

## Tooling & config locations

- **Package manager:** uv. Add deps with `uv add <pkg>` / `uv add --dev <pkg>`; run tools with
  `uv run <tool>`.
- **Ruff:** `[tool.ruff]` in `pyproject.toml` (lint + format).
- **mypy:** `[tool.mypy]` in `pyproject.toml`; type-annotate new code.
- **pytest:** `[tool.pytest.ini_options]` in `pyproject.toml`.

## Testing

- pytest. Run: `uv run pytest`; single: `uv run pytest tests/test_tasks.py::test_create`;
  by keyword: `uv run pytest -k create`.
- API tests use `fastapi.testclient.TestClient` against `app.main:app` with an override of
  `get_session` bound to a test database/transaction.
- New endpoints ship with a test covering success + a validation/404 case.

## Do / don't

- ✅ Endpoint → `Depends(get_session)` → model query → return a pydantic schema.
- ❌ Don't return SQLAlchemy model instances directly from endpoints.
- ❌ Don't read `os.environ` outside `app/config.py`.
