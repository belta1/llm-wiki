---
applyTo: "**/*.{py,sql,R,r,cs,ini,toml,json,config,sas},**/.env*"
description: Common data sources (servers / DSNs) from the llm-wiki catalog — how to connect, and never to inline secrets. Installed by llm-wiki into your VS Code user profile; the block below is regenerated from ~/.claude/llm-wiki/data-sources.md.
---

# Known data sources (llm-wiki catalog)

When you write code that connects to a database, check whether it targets one of the named data
sources below and **reuse the documented driver and auth model** instead of inventing a new connection
string. For a **Trusted (Windows)** source, don't pass a username/password. For a **user + password**
source, read the credentials from the environment variables named in the entry — **never inline a
password, token, or key**. This covers SQL Server, Oracle, PostgreSQL and **SAS** (saspy): for a SAS
source, use the documented `cfgname` from `sascfg_personal.py` and let saspy read credentials from the
`authinfo` file — don't put `omrpw` / passwords in code. If you connect to a source that isn't listed
here, tell the user so it can be added to the catalog (via `/llm-wiki:init` or `/llm-wiki:update` in
Claude Code).

This is a **user-global** instruction file (it applies in every workspace) and is **VS Code-only** —
github.com Copilot and other editors read committed repo files only.

<!-- BEGIN llm-wiki -->
_No data-source catalog found yet. Run `/llm-wiki:init` in Claude Code, or create
`~/.claude/llm-wiki/data-sources.md`, then re-run the installer's data-source option to fill this in._
<!-- END llm-wiki -->
