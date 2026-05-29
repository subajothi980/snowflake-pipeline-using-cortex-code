# CoCo Prompt 06 — Pipeline Monitoring

Paste any of these prompts into **Cortex Code (CoCo)** to monitor pipeline health conversationally.

---

## Prompt — Full monitoring summary

```
Show a monitoring summary for all dynamic tables in olist_db.analytics.
For each table show its name, target_lag, scheduling_state, and — from
olist_db.information_schema.dynamic_table_refresh_history() — the most
recent refresh_action, state, and duration in seconds. Use a window function
to get only the latest refresh per table.
```

---

## Prompt — Check the dependency graph

```
Show me all dynamic tables in olist_db.analytics with their target lag settings,
current row counts, and scheduling state.
```

---

## Prompt — Investigate a slow or failed refresh

```
Query olist_db.information_schema.dynamic_table_refresh_history() for the last
24 hours for all tables in the analytics schema. Show table name, refresh_action,
state, error_message (if any), and duration in seconds, ordered by
refresh_start_time descending.
```

---

## Prompt — Validate data after a refresh

```
Validate the pipeline output after the latest refresh:
- Count rows in each of the 5 analytics dynamic tables
- Count distinct order_id in order_fact
- Show the max order_date in daily_sales_metrics to confirm fresh data
- Show the top 3 categories by total_revenue in product_performance_metrics
```

---

## Key columns to watch

| Column | Healthy value | Action if not healthy |
|---|---|---|
| `refresh_action` | `INCREMENTAL` (after first run) | `FULL` is expected on first load or for product_performance_metrics |
| `state` | `SUCCEEDED` | Check `error_message` column if `FAILED` |
| `scheduling_state` | `ACTIVE` | `SUSPENDED` means the table has been paused — run `ALTER DYNAMIC TABLE ... RESUME` |
| `duration_seconds` | Seconds, not minutes | Investigate source table row counts if unexpectedly slow |

---

## Useful manual SQL

```sql
-- Resume a suspended dynamic table
ALTER DYNAMIC TABLE olist_db.analytics.daily_sales_metrics RESUME;

-- Suspend a table (pause automatic refreshes)
ALTER DYNAMIC TABLE olist_db.analytics.daily_sales_metrics SUSPEND;

-- Force a manual refresh of all Tier 3 tables
ALTER DYNAMIC TABLE olist_db.analytics.daily_sales_metrics         REFRESH;
ALTER DYNAMIC TABLE olist_db.analytics.product_performance_metrics REFRESH;

-- View the dependency graph programmatically
SELECT name, target_lag, scheduling_state
FROM olist_db.information_schema.dynamic_tables
WHERE schema_name = 'ANALYTICS'
ORDER BY name;
```
