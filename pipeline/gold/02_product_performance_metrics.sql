-- ============================================================
-- Tier 3 — product_performance_metrics
-- Aggregates revenue, satisfaction, and logistics KPIs per
-- product, category, seller, and seller state.
-- TARGET_LAG = '1 hour'
-- INITIALIZE  = ON_SCHEDULE
-- ============================================================

USE ROLE      olist_role;
USE WAREHOUSE olist_wh;
USE DATABASE  olist_db;
USE SCHEMA    olist_db.analytics;

CREATE OR REPLACE DYNAMIC TABLE olist_db.analytics.product_performance_metrics
  TARGET_LAG = '1 hour'
  WAREHOUSE  = olist_wh
  INITIALIZE = ON_SCHEDULE
AS
SELECT
  product_id,
  category_english,
  seller_id,
  seller_state,

  -- Volume
  COUNT(DISTINCT order_id)        AS order_count,
  SUM(order_item_id)              AS total_units_sold,

  -- Revenue & pricing
  ROUND(SUM(price), 2)            AS total_revenue,
  ROUND(AVG(price), 2)            AS avg_price,
  ROUND(MIN(price), 2)            AS min_price,
  ROUND(MAX(price), 2)            AS max_price,

  -- Freight / logistics
  ROUND(SUM(freight_value), 2)    AS total_freight,
  ROUND(AVG(freight_value), 2)    AS avg_freight,
  ROUND(AVG(freight_ratio), 4)    AS avg_freight_ratio,

  -- Satisfaction
  ROUND(AVG(review_score), 2)     AS avg_review_score,
  COUNT(CASE WHEN has_review           THEN 1 END) AS reviews_received,
  COUNT(CASE WHEN is_positive_review   THEN 1 END) AS positive_reviews,
  ROUND(
    COUNT(CASE WHEN is_positive_review THEN 1 END)
    / NULLIF(COUNT(CASE WHEN has_review THEN 1 END), 0),
    4
  )                               AS satisfaction_rate,

  -- Delivery (product/seller level)
  ROUND(AVG(CASE WHEN is_delivered THEN delivery_delay_days END), 2)
                                  AS avg_delivery_delay_days

FROM olist_db.analytics.order_fact
GROUP BY product_id, category_english, seller_id, seller_state;
