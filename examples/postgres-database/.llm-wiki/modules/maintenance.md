---
updated: 2026-09-25
covers: [maintenance, pg_cron, ops, jobs]
status: current
---

# Maintenance & scheduled jobs

Housekeeping that runs **inside the database** via `pg_cron`, plus the deploy bookkeeping in the
`ops` schema.

## Key files & entry points

- `db/60_cron/jobs.sql` — `cron.schedule(…)` calls; re-runnable (`cron.schedule` upserts by name).
- `db/30_functions/ops/mark_overdue_invoices.sql` · `ops/prune_audit.sql` ·
  `ops/ensure_payment_partitions.sql` — what the jobs call.
- `db/10_schemas/ops.sql` — `ops.applied_change` (one-shot change log) and `ops.job_run` (job log).
- `scripts/deploy.sh` — applies `db/changes/` and writes `ops.applied_change`.

## Jobs

| Name | Schedule (UTC) | Calls | Touches |
|------|----------------|-------|---------|
| `mark-overdue` | `15 1 * * *` | `ops.mark_overdue_invoices()` | `billing.invoice.status` issued → overdue |
| `payment-partitions` | `0 2 1 * *` | `ops.ensure_payment_partitions(3)` | creates next 3 monthly partitions of `billing.payment` |
| `prune-audit` | `30 3 * * 0` | `ops.prune_audit(interval '400 days')` | deletes old `ops.job_run` / audit rows |

`pg_cron` is installed **in the `billing` database** (`cron.database_name = 'billing'` in
`docker/postgresql.conf` and on the servers), which is why `jobs.sql` can sit in the run list.

## When a job fails

```sql
SELECT jobid, jobname, status, return_message, start_time
FROM cron.job_run_details ORDER BY start_time DESC LIMIT 20;
SELECT * FROM ops.job_run WHERE ok = false ORDER BY started_at DESC;
```

Every `ops.*` function is idempotent, so re-running it by hand (`SELECT ops.mark_overdue_invoices();`
as `billing_owner`) is safe.

## Add a job

1. Write the function in `db/30_functions/ops/<name>.sql` (idempotent; logs to `ops.job_run`).
2. Add `SELECT cron.schedule('<name>', '<cron>', $$SELECT ops.<name>()$$);` to
   `db/60_cron/jobs.sql`; both files must be in `db/deploy.sql`.
3. Add it to the table above. Locally the container has `pg_cron` too — check
   `SELECT * FROM cron.job;` after `make deploy`.

## Gotchas

- `billing.payment` is **partitioned by month**; if `payment-partitions` stops, inserts fail on the
  1st of a new month. Monitor it.
- Removing a job from `jobs.sql` does **not** unschedule it — add `cron.unschedule('<name>')` as a
  one-shot change.
- `ops.applied_change` rows are the only record of which one-shots ran; never delete them.

## Related

- [billing](billing.md) · [architecture](../architecture.md#deploy-flow) · [recipes](../recipes.md#add-a-one-shot-change)
