-- ============================================================
-- Silver — orders_enriched
-- Joins raw.orders with raw.customers.
-- Adds temporal dimensions and delivery performance columns.
-- TARGET_LAG = DOWNSTREAM  (refreshes on demand from Silver)
-- INITIALIZE  = ON_SCHEDULE (created empty; first load is manual)
-- ============================================================

USE ROLE      olist_role;
USE WAREHOUSE olist_wh;
USE DATABASE  olist_db;
USE SCHEMA    olist_db.analytics;

CREATE OR REPLACE DYNAMIC TABLE olist_db.analytics.orders_enriched
  TARGET_LAG = DOWNSTREAM
  WAREHOUSE  = olist_wh
  INITIALIZE = ON_SCHEDULE
AS
SELECT
  o.order_id,
  o.customer_id,
  o.order_status,
  o.order_purchase_timestamp                              AS order_timestamp,
  DATE(o.order_purchase_timestamp)                        AS order_date,
  DAYNAME(o.order_purchase_timestamp)                     AS day_name,
  HOUR(o.order_purchase_timestamp)                        AS order_hour,
  o.order_delivered_customer_date,
  o.order_estimated_delivery_date,

  -- Positive = late delivery, negative = early
  DATEDIFF(
    'day',
    o.order_estimated_delivery_date,
    o.order_delivered_customer_date
  )                                                       AS delivery_delay_days,

  (o.order_status = 'delivered')                          AS is_delivered,

  -- Customer geography
  c.customer_unique_id,
  c.customer_city,
  c.customer_state,
  c.customer_zip_code_prefix

FROM olist_db.raw.orders    o
JOIN olist_db.raw.customers c ON o.customer_id = c.customer_id

WHERE o.order_id IS NOT NULL;
