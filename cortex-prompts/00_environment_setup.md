# CoCo Prompt 00 — Environment Setup

Paste this prompt into **Cortex Code (CoCo)** in Snowsight to create the full Snowflake environment, schemas, raw tables, file format, and internal stage in one shot.

> **Before you start:** Make sure you are running as `ACCOUNTADMIN` in Snowsight.

---

## Prompt 1 - to setup environment.

```
Using ACCOUNTADMIN, create a role called olist_role and grant it CREATE WAREHOUSE
and CREATE DATABASE privileges on the account. Then switch to olist_role and:

- Create a database called olist_db with two schemas: raw and analytics
- Create an XL standard warehouse called olist_wh with 60s auto-suspend and
  auto-resume enabled
- Create these tables in olist_db.raw:

  orders: order_id (STRING NOT NULL), customer_id, order_status,
    order_purchase_timestamp (TIMESTAMP_NTZ), order_approved_at (TIMESTAMP_NTZ),
    order_delivered_carrier_date (TIMESTAMP_NTZ),
    order_delivered_customer_date (TIMESTAMP_NTZ),
    order_estimated_delivery_date (TIMESTAMP_NTZ)

  order_items: order_id (STRING NOT NULL), order_item_id (NUMBER NOT NULL),
    product_id, seller_id, shipping_limit_date (TIMESTAMP_NTZ),
    price (NUMBER 12,2), freight_value (NUMBER 12,2)

  order_payments: order_id (STRING NOT NULL), payment_sequential (NUMBER),
    payment_type, payment_installments (NUMBER), payment_value (NUMBER 12,2)

  order_reviews: review_id (STRING NOT NULL), order_id, review_score (NUMBER),
    review_comment_title, review_comment_message,
    review_creation_date (TIMESTAMP_NTZ), review_answer_timestamp (TIMESTAMP_NTZ)

  customers: customer_id (STRING NOT NULL), customer_unique_id,
    customer_zip_code_prefix, customer_city, customer_state

  sellers: seller_id (STRING NOT NULL), seller_zip_code_prefix,
    seller_city, seller_state

  products: product_id (STRING NOT NULL), product_category_name,
    product_name_lenght (NUMBER), product_description_lenght (NUMBER),
    product_photos_qty (NUMBER), product_weight_g (NUMBER),
    product_length_cm (NUMBER), product_height_cm (NUMBER),
    product_width_cm (NUMBER)

  product_category_name_translation: product_category_name (STRING NOT NULL),
    product_category_name_english

- Create a CSV file format in olist_db.public with FIELD_OPTIONALLY_ENCLOSED_BY='"',
  SKIP_HEADER=1, and NULL_IF=('NULL','null','\\N','')
- Create an internal stage olist_db.raw.olist_stage using the CSV file format
```

---

## What CoCo will create

| Object                       | Type        | Notes                                      |
| ---------------------------- | ----------- | ------------------------------------------ |
| `olist_role`                 | Role        | Granted CREATE WAREHOUSE + CREATE DATABASE |
| `olist_wh`                   | Warehouse   | XL, 60s auto-suspend                       |
| `olist_db`                   | Database    |                                            |
| `olist_db.raw`               | Schema      | Source tables land here                    |
| `olist_db.analytics`         | Schema      | Dynamic Tables land here                   |
| 8 raw tables                 | Tables      | Matching Olist CSV structure               |
| `olist_db.public.csv_format` | File format | CSV with quoted fields                     |
| `olist_db.raw.olist_stage`   | Stage       | Internal stage for CSV upload              |

---

## Expected output

CoCo will ask for permission to execute each CREATE statement. Choose **Allow CREATE** to approve all DDL statements for the session.

If you see a permission error on role creation, confirm you are running as `ACCOUNTADMIN` before switching to `olist_role`.
