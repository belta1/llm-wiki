---
updated: 2026-09-23
covers: [glossary, domain]
status: current
---

# Glossary

- **Task** — the core domain entity: `id`, `title`, `done`, `created_at`. SQLAlchemy model in
  `app/db/models.py`; see [db](modules/db.md).
- **Schema** — a pydantic model (`app/api/schemas.py`) used for request/response at the HTTP edge;
  distinct from the ORM model.
- **Session** — a SQLAlchemy `Session` provided to endpoints via the `get_session` dependency
  (`app/db/session.py`).
- **Settings** — the pydantic-settings config singleton (`app/config.py`).
