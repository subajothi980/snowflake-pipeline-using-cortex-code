# CoCo Prompt 04 — Trigger Initial Load

Paste this prompt into **Cortex Code (CoCo)** to kick off the first full data load across all five Dynamic Tables.

> **Run this after:** All five Dynamic Tables have been created (Tier 1, 2, and 3).  
> All were created with `INITIALIZE = ON_SCHEDULE`, so they are currently empty.

---

## Prompt

```
Refresh daily_sales_metrics and product_performance_metrics in olist_db.analytics.
Snowflake will handle the upstream dependencies automatically.
```

---

## What happens

You only trigger the two Tier 3 tables — but Snowflake resolves the full dependency graph and refreshes in this order:

```
1. orders_enriched          (Tier 1 — DOWNSTREAM, triggered by Tier 2)
2. order_items_enriched     (Tier 1 — DOWNSTREAM, triggered by Tier 2)
        ↓
3. order_fact               (Tier 2 — DOWNSTREAM, triggered by Tier 3)
        ↓
4. daily_sales_metrics      (Tier 3 — you triggered this)
5. product_performance_metrics  (Tier 3 — you triggered this)
```

This is the **dependency graph** in action — you only need to trigger the leaf nodes.

---

## What to observe after the refresh

```sql
-- Check the most recent refresh action for each table
SELECT
  name,
  refresh_action,   -- FULL on first load, INCREMENTAL on subsequent runs
  state,            -- SUCCEEDED or FAILED
  refresh_trigger,
  DATEDIFF('second', refresh_start_time, refresh_end_time) AS duration_seconds
FROM TABLE(olist_db.information_schema.dynamic_table_refresh_history())
WHERE schema_name = 'ANALYTICS'
ORDER BY refresh_start_time DESC
LIMIT 10;
```

**Expected:** All 5 tables show `refresh_action = FULL` and `state = SUCCEEDED` on the first run.

---

## Validate row counts

```sql
SELECT 'order_fact rows'              AS metric, COUNT(*) AS value FROM olist_db.analytics.order_fact
UNION ALL SELECT 'daily_sales_metrics rows',     COUNT(*) FROM olist_db.analytics.daily_sales_metrics
UNION ALL SELECT 'product_performance rows',     COUNT(*) FROM olist_db.analytics.product_performance_metrics;
```

Expected approximate values:

| Table | Expected rows |
|---|---|
| `order_fact` | ~112,000 |
| `daily_sales_metrics` | ~5,000–8,000 (date × state combinations) |
| `product_performance_metrics` | ~30,000–40,000 (product × seller state) |
