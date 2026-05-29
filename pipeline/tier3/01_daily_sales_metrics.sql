-- ============================================================
-- Tier 3 — daily_sales_metrics
-- Aggregates sales, delivery, and review KPIs by day and
-- customer state.
-- TARGET_LAG = '1 hour'
-- INITIALIZE  = ON_SCHEDULE
-- ============================================================

USE ROLE      olist_role;
USE WAREHOUSE olist_wh;
USE DATABASE  olist_db;
USE SCHEMA    olist_db.analytics;

CREATE OR REPLACE DYNAMIC TABLE olist_db.analytics.daily_sales_metrics
  TARGET_LAG = '1 hour'
  WAREHOUSE  = olist_wh
  INITIALIZE = ON_SCHEDULE
AS
SELECT
  order_date,
  day_name,
  customer_state,

  -- Volume
  COUNT(DISTINCT order_id)                                        AS total_orders,
  COUNT(DISTINCT customer_id)                                     AS unique_customers,
  SUM(order_item_id)                                              AS total_line_items,

  -- Revenue
  ROUND(SUM(price), 2)                                            AS total_revenue,
  ROUND(AVG(price), 2)                                            AS avg_order_value,
  ROUND(SUM(freight_value), 2)                                    AS total_freight,
  ROUND(SUM(total_item_value), 2)                                 AS total_gmv,

  -- Delivery performance
  COUNT(DISTINCT CASE WHEN is_delivered          THEN order_id END) AS delivered_orders,
  COUNT(DISTINCT CASE WHEN delivery_delay_days > 0 THEN order_id END) AS late_orders,
  ROUND(AVG(CASE WHEN is_delivered THEN delivery_delay_days END), 2) AS avg_delay_days,

  -- Satisfaction
  ROUND(AVG(review_score), 2)                                     AS avg_review_score,
  COUNT(CASE WHEN has_review           THEN 1 END)                AS reviews_received,
  COUNT(CASE WHEN is_positive_review   THEN 1 END)                AS positive_reviews

FROM olist_db.analytics.order_fact
GROUP BY order_date, day_name, customer_state;
