-- ============================================================
-- 02_upload_and_load.sql
-- Upload CSVs via SnowSQL PUT, then COPY INTO each raw table.
--
-- Run from your terminal:
--   snowsql -c my_connection -f setup/02_upload_and_load.sql
--
-- Or upload CSVs manually via Snowsight → Data → Add Data,
-- then run just the COPY INTO statements below.
-- ============================================================

USE ROLE      olist_role;
USE WAREHOUSE olist_wh;
USE DATABASE  olist_db;

-- ----------------------------------------------------------
-- PUT  (SnowSQL only — comment out if uploading via UI)
-- ----------------------------------------------------------
PUT file://data/raw/olist_orders_dataset.csv                @olist_db.raw.olist_stage/orders/         AUTO_COMPRESS=TRUE;
PUT file://data/raw/olist_order_items_dataset.csv           @olist_db.raw.olist_stage/order_items/    AUTO_COMPRESS=TRUE;
PUT file://data/raw/olist_order_payments_dataset.csv        @olist_db.raw.olist_stage/order_payments/ AUTO_COMPRESS=TRUE;
PUT file://data/raw/olist_order_reviews_dataset.csv         @olist_db.raw.olist_stage/order_reviews/  AUTO_COMPRESS=TRUE;
PUT file://data/raw/olist_customers_dataset.csv             @olist_db.raw.olist_stage/customers/      AUTO_COMPRESS=TRUE;
PUT file://data/raw/olist_sellers_dataset.csv               @olist_db.raw.olist_stage/sellers/        AUTO_COMPRESS=TRUE;
PUT file://data/raw/olist_products_dataset.csv              @olist_db.raw.olist_stage/products/       AUTO_COMPRESS=TRUE;
PUT file://data/raw/product_category_name_translation.csv   @olist_db.raw.olist_stage/categories/     AUTO_COMPRESS=TRUE;

-- ----------------------------------------------------------
-- COPY INTO
-- ----------------------------------------------------------
COPY INTO olist_db.raw.orders
  FROM @olist_db.raw.olist_stage/orders/
  FILE_FORMAT = olist_db.public.csv_format ON_ERROR = CONTINUE;

COPY INTO olist_db.raw.order_items
  FROM @olist_db.raw.olist_stage/order_items/
  FILE_FORMAT = olist_db.public.csv_format ON_ERROR = CONTINUE;

COPY INTO olist_db.raw.order_payments
  FROM @olist_db.raw.olist_stage/order_payments/
  FILE_FORMAT = olist_db.public.csv_format ON_ERROR = CONTINUE;

COPY INTO olist_db.raw.order_reviews
  FROM @olist_db.raw.olist_stage/order_reviews/
  FILE_FORMAT = olist_db.public.csv_format ON_ERROR = CONTINUE;

COPY INTO olist_db.raw.customers
  FROM @olist_db.raw.olist_stage/customers/
  FILE_FORMAT = olist_db.public.csv_format ON_ERROR = CONTINUE;

COPY INTO olist_db.raw.sellers
  FROM @olist_db.raw.olist_stage/sellers/
  FILE_FORMAT = olist_db.public.csv_format ON_ERROR = CONTINUE;

COPY INTO olist_db.raw.products
  FROM @olist_db.raw.olist_stage/products/
  FILE_FORMAT = olist_db.public.csv_format ON_ERROR = CONTINUE;

COPY INTO olist_db.raw.product_category_name_translation
  FROM @olist_db.raw.olist_stage/categories/
  FILE_FORMAT = olist_db.public.csv_format ON_ERROR = CONTINUE;

-- Verify row counts
SELECT 'orders'                            AS tbl, COUNT(*) AS rows FROM olist_db.raw.orders
UNION ALL SELECT 'order_items',                     COUNT(*) FROM olist_db.raw.order_items
UNION ALL SELECT 'order_payments',                  COUNT(*) FROM olist_db.raw.order_payments
UNION ALL SELECT 'order_reviews',                   COUNT(*) FROM olist_db.raw.order_reviews
UNION ALL SELECT 'customers',                       COUNT(*) FROM olist_db.raw.customers
UNION ALL SELECT 'sellers',                         COUNT(*) FROM olist_db.raw.sellers
UNION ALL SELECT 'products',                        COUNT(*) FROM olist_db.raw.products
UNION ALL SELECT 'product_category_name_translation', COUNT(*) FROM olist_db.raw.product_category_name_translation
ORDER BY tbl;
