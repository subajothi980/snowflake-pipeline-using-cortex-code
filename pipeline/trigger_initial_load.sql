-- ============================================================
-- trigger_initial_load.sql
-- Manually triggers a refresh of the two Tier 3 tables.
-- Snowflake resolves the dependency graph automatically and
-- refreshes Tier 1 → Tier 2 → Tier 3 in the correct order.
-- ============================================================

USE ROLE      olist_role;
USE WAREHOUSE olist_wh;

ALTER DYNAMIC TABLE olist_db.analytics.daily_sales_metrics         REFRESH;
ALTER DYNAMIC TABLE olist_db.analytics.product_performance_metrics REFRESH;
