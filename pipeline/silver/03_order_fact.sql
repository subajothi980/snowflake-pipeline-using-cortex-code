-- ============================================================
-- Silver — order_fact
-- Wide fact table. One row per order line item.
-- Joins Silver layer enriched tables with payment and review data.
-- Payment and review are pre-aggregated to order level to
-- prevent row fan-out.
-- TARGET_LAG = DOWNSTREAM
-- INITIALIZE  = ON_SCHEDULE
-- ============================================================

USE ROLE      olist_role;
USE WAREHOUSE olist_wh;
USE DATABASE  olist_db;
USE SCHEMA    olist_db.analytics;

CREATE OR REPLACE DYNAMIC TABLE olist_db.analytics.order_fact
  TARGET_LAG = DOWNSTREAM
  WAREHOUSE  = olist_wh
  INITIALIZE = ON_SCHEDULE
AS
SELECT
  -- Order dimensions
  o.order_id,
  o.customer_id,
  o.customer_unique_id,
  o.customer_city,
  o.customer_state,
  o.customer_zip_code_prefix,
  o.order_status,
  o.order_timestamp,
  o.order_date,
  o.day_name,
  o.order_hour,
  o.is_delivered,
  o.delivery_delay_days,
  o.order_estimated_delivery_date,
  o.order_delivered_customer_date,

  -- Item dimensions
  i.order_item_id,
  i.product_id,
  i.seller_id,
  i.seller_city,
  i.seller_state,
  i.product_category_name,
  i.category_english,
  i.product_weight_g,
  i.product_photos_qty,
  i.shipping_limit_date,

  -- Financial metrics
  i.price,
  i.freight_value,
  i.total_item_value,
  i.freight_ratio,

  -- Payment (aggregated to order level)
  p.payment_type,
  p.payment_installments,
  p.payment_value,

  -- Review
  r.review_score,
  (r.review_score IS NOT NULL)  AS has_review,
  (r.review_score >= 4)         AS is_positive_review

FROM olist_db.analytics.orders_enriched       o
JOIN olist_db.analytics.order_items_enriched  i ON o.order_id = i.order_id

LEFT JOIN (
  SELECT
    order_id,
    MAX(payment_type)         AS payment_type,
    MAX(payment_installments) AS payment_installments,
    SUM(payment_value)        AS payment_value
  FROM olist_db.raw.order_payments
  GROUP BY order_id
) p ON o.order_id = p.order_id

LEFT JOIN (
  SELECT order_id, MAX(review_score) AS review_score
  FROM olist_db.raw.order_reviews
  GROUP BY order_id
) r ON o.order_id = r.order_id

WHERE o.order_id   IS NOT NULL
  AND i.product_id IS NOT NULL;
