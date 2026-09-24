---
updated: 2026-09-23
covers: [api, routers, endpoints]
status: current
---

# API

The FastAPI layer: routers, request/response schemas, dependencies, error handling.

## Key files & entry points

- `app/main.py` — creates the FastAPI `app`, includes routers, sets up middleware. ASGI entry for
  `uvicorn app.main:app`.
- `app/api/tasks.py` — `APIRouter` for `/tasks`; the endpoints.
- `app/api/schemas.py` — pydantic request/response models.
- `app/api/deps.py` — shared dependencies (e.g. re-exports `get_session`).
- `app/api/errors.py` — error helpers → `HTTPException`.

## How it works

Each router declares endpoints with `response_model` and takes `Depends(get_session)` for DB access.
Endpoints validate via pydantic, query models from [db](db.md), and return schema objects. `main.py`
includes each router. Tests drive `app` with `TestClient`, overriding `get_session`. See
[architecture](../architecture.md).

## Gotchas

- Never return a SQLAlchemy model directly — return a pydantic schema ([conventions](../conventions.md)).
- Get the session via `Depends(get_session)`; don't create sessions inline.
- New router? Remember `app.include_router(...)` in `main.py`, or the routes 404.

## Related

- [db](db.md) · [conventions](../conventions.md) · [recipes](../recipes.md#add-an-endpoint)
