-- ============================================================
-- Tier 1 — order_items_enriched
-- Joins raw.order_items with raw.products, raw.sellers,
-- and raw.product_category_name_translation.
-- TARGET_LAG = DOWNSTREAM
-- INITIALIZE  = ON_SCHEDULE
-- ============================================================

USE ROLE      olist_role;
USE WAREHOUSE olist_wh;
USE DATABASE  olist_db;
USE SCHEMA    olist_db.analytics;

CREATE OR REPLACE DYNAMIC TABLE olist_db.analytics.order_items_enriched
  TARGET_LAG = DOWNSTREAM
  WAREHOUSE  = olist_wh
  INITIALIZE = ON_SCHEDULE
AS
SELECT
  i.order_id,
  i.order_item_id,
  i.product_id,
  i.seller_id,
  i.shipping_limit_date,
  i.price,
  i.freight_value,

  -- Derived cost metrics
  (i.price + i.freight_value)                       AS total_item_value,
  ROUND(i.freight_value / NULLIF(i.price, 0), 4)   AS freight_ratio,

  -- Product attributes
  p.product_category_name,
  COALESCE(t.product_category_name_english,
           p.product_category_name)                 AS category_english,
  p.product_weight_g,
  p.product_photos_qty,

  -- Seller geography
  s.seller_city,
  s.seller_state,
  s.seller_zip_code_prefix

FROM olist_db.raw.order_items i
LEFT JOIN olist_db.raw.products                           p ON i.product_id = p.product_id
LEFT JOIN olist_db.raw.sellers                            s ON i.seller_id  = s.seller_id
LEFT JOIN olist_db.raw.product_category_name_translation  t
       ON p.product_category_name = t.product_category_name

WHERE i.order_id   IS NOT NULL
  AND i.product_id IS NOT NULL;
