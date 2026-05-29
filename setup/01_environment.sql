-- ============================================================
-- 01_environment.sql
-- Creates role, warehouse, database, schemas, and raw tables.
-- Run as ACCOUNTADMIN in Snowsight or via SnowSQL.
-- ============================================================

USE ROLE ACCOUNTADMIN;

-- Role & privileges
CREATE ROLE IF NOT EXISTS olist_role;
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE olist_role;
GRANT CREATE DATABASE  ON ACCOUNT TO ROLE olist_role;
GRANT ROLE olist_role TO ROLE SYSADMIN;

USE ROLE olist_role;

-- Warehouse
CREATE WAREHOUSE IF NOT EXISTS olist_wh
  WAREHOUSE_SIZE = 'X-LARGE'
  AUTO_SUSPEND   = 60
  AUTO_RESUME    = TRUE
  COMMENT        = 'Olist pipeline warehouse';

-- Database & schemas
CREATE DATABASE IF NOT EXISTS olist_db;
CREATE SCHEMA  IF NOT EXISTS olist_db.raw;
CREATE SCHEMA  IF NOT EXISTS olist_db.analytics;

USE DATABASE  olist_db;
USE WAREHOUSE olist_wh;

-- ----------------------------------------------------------
-- RAW TABLES
-- ----------------------------------------------------------

CREATE TABLE IF NOT EXISTS olist_db.raw.orders (
  order_id                        STRING        NOT NULL,
  customer_id                     STRING,
  order_status                    STRING,
  order_purchase_timestamp        TIMESTAMP_NTZ,
  order_approved_at               TIMESTAMP_NTZ,
  order_delivered_carrier_date    TIMESTAMP_NTZ,
  order_delivered_customer_date   TIMESTAMP_NTZ,
  order_estimated_delivery_date   TIMESTAMP_NTZ
);

CREATE TABLE IF NOT EXISTS olist_db.raw.order_items (
  order_id            STRING        NOT NULL,
  order_item_id       NUMBER        NOT NULL,
  product_id          STRING,
  seller_id           STRING,
  shipping_limit_date TIMESTAMP_NTZ,
  price               NUMBER(12, 2),
  freight_value       NUMBER(12, 2)
);

CREATE TABLE IF NOT EXISTS olist_db.raw.order_payments (
  order_id              STRING NOT NULL,
  payment_sequential    NUMBER,
  payment_type          STRING,
  payment_installments  NUMBER,
  payment_value         NUMBER(12, 2)
);

CREATE TABLE IF NOT EXISTS olist_db.raw.order_reviews (
  review_id               STRING        NOT NULL,
  order_id                STRING,
  review_score            NUMBER,
  review_comment_title    STRING,
  review_comment_message  STRING,
  review_creation_date    TIMESTAMP_NTZ,
  review_answer_timestamp TIMESTAMP_NTZ
);

CREATE TABLE IF NOT EXISTS olist_db.raw.customers (
  customer_id              STRING NOT NULL,
  customer_unique_id       STRING,
  customer_zip_code_prefix STRING,
  customer_city            STRING,
  customer_state           STRING
);

CREATE TABLE IF NOT EXISTS olist_db.raw.sellers (
  seller_id               STRING NOT NULL,
  seller_zip_code_prefix  STRING,
  seller_city             STRING,
  seller_state            STRING
);

CREATE TABLE IF NOT EXISTS olist_db.raw.products (
  product_id                  STRING NOT NULL,
  product_category_name       STRING,
  product_name_lenght         NUMBER,
  product_description_lenght  NUMBER,
  product_photos_qty          NUMBER,
  product_weight_g            NUMBER,
  product_length_cm           NUMBER,
  product_height_cm           NUMBER,
  product_width_cm            NUMBER
);

CREATE TABLE IF NOT EXISTS olist_db.raw.product_category_name_translation (
  product_category_name         STRING NOT NULL,
  product_category_name_english STRING
);

-- CSV file format
CREATE FILE FORMAT IF NOT EXISTS olist_db.public.csv_format
  TYPE                         = CSV
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  SKIP_HEADER                  = 1
  NULL_IF                      = ('NULL', 'null', '\\N', '');

-- Internal stage
CREATE STAGE IF NOT EXISTS olist_db.raw.olist_stage
  FILE_FORMAT = olist_db.public.csv_format
  COMMENT     = 'Olist CSV upload stage';
