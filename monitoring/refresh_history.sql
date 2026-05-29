-- ============================================================
-- refresh_history.sql
-- Pipeline observability — run anytime after initial load.
-- ============================================================

USE ROLE      olist_role;
USE WAREHOUSE olist_wh;
USE DATABASE  olist_db;

-- ----------------------------------------------------------
-- 1. Most recent refresh per dynamic table
-- ----------------------------------------------------------
WITH latest AS (
  SELECT
    name,
    refresh_action,
    state,
    refresh_trigger,
    DATEDIFF('second', refresh_start_time, refresh_end_time) AS duration_seconds,
    refresh_start_time,
    ROW_NUMBER() OVER (PARTITION BY name ORDER BY refresh_start_time DESC) AS rn
  FROM TABLE(olist_db.information_schema.dynamic_table_refresh_history())
  WHERE schema_name = 'ANALYTICS'
)
SELECT name, refresh_action, state, refresh_trigger, duration_seconds, refresh_start_time
FROM latest
WHERE rn = 1
ORDER BY name;

-- ----------------------------------------------------------
-- 2. Pipeline health (target lag vs scheduling state)
-- ----------------------------------------------------------
SELECT name, target_lag, scheduling_state, last_suspended_on
FROM olist_db.information_schema.dynamic_tables
WHERE schema_name = 'ANALYTICS'
ORDER BY name;

-- ----------------------------------------------------------
-- 3. All refreshes in last 24 hours
-- ----------------------------------------------------------
SELECT
  name,
  refresh_action,
  state,
  DATEDIFF('second', refresh_start_time, refresh_end_time) AS duration_seconds,
  refresh_start_time
FROM TABLE(olist_db.information_schema.dynamic_table_refresh_history())
WHERE schema_name        = 'ANALYTICS'
  AND refresh_start_time >= DATEADD('hour', -24, CURRENT_TIMESTAMP())
ORDER BY refresh_start_time DESC;

-- ----------------------------------------------------------
-- 4. Quick data validation
-- ----------------------------------------------------------
SELECT 'order_fact rows'              AS metric, COUNT(*) AS value FROM olist_db.analytics.order_fact
UNION ALL SELECT 'daily_sales_metrics rows',     COUNT(*) FROM olist_db.analytics.daily_sales_metrics
UNION ALL SELECT 'product_performance rows',     COUNT(*) FROM olist_db.analytics.product_performance_metrics
UNION ALL SELECT 'distinct orders in fact',      COUNT(DISTINCT order_id) FROM olist_db.analytics.order_fact
UNION ALL SELECT 'distinct products in perf',   COUNT(DISTINCT product_id) FROM olist_db.analytics.product_performance_metrics;
