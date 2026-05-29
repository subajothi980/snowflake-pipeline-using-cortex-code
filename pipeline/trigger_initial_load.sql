-- ============================================================
-- trigger_initial_load.sql
-- Manually triggers a refresh of the two Gold layer aggregate tables.
-- Snowflake resolves the dependency graph automatically and
-- refreshes Silver layer enriched → Silver layer fact → Gold layer aggregates in the correct order.
-- ============================================================

USE ROLE      olist_role;
USE WAREHOUSE olist_wh;

ALTER DYNAMIC TABLE olist_db.analytics.daily_sales_metrics         REFRESH;
ALTER DYNAMIC TABLE olist_db.analytics.product_performance_metrics REFRESH;
