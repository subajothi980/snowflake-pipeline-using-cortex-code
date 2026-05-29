# CoCo Prompt 02 — Silver Layer : Order Fact Table

Paste this prompt into **Cortex Code (CoCo)** to build the central wide fact table.

> **Note:** Silver Layer tables (`orders_enriched` and `order_items_enriched`) must exist before running this prompt.

---

## Prompt

```
Build a Silver Layer dynamic table order_fact in olist_db.analytics using warehouse olist_wh.
Use INITIALIZE = 'ON_SCHEDULE' and TARGET_LAG = DOWNSTREAM.

Inner join olist_db.analytics.orders_enriched (alias o) with
olist_db.analytics.order_items_enriched (alias i) on order_id.

Include all columns from orders_enriched:
  order_id, customer_id, customer_unique_id, customer_city, customer_state,
  customer_zip_code_prefix, order_status, order_timestamp, order_date,
  day_name, order_hour, is_delivered, delivery_delay_days,
  order_estimated_delivery_date, order_delivered_customer_date.

Include all columns from order_items_enriched:
  order_item_id, product_id, seller_id, seller_city, seller_state,
  product_category_name, category_english, product_weight_g, product_photos_qty,
  shipping_limit_date, price, freight_value, total_item_value, freight_ratio.

Left join payments: aggregate olist_db.raw.order_payments by order_id using
  MAX(payment_type), MAX(payment_installments), SUM(payment_value).
  This avoids row fan-out from multiple payment rows per order.
  Include as: payment_type, payment_installments, payment_value.

Left join reviews: aggregate olist_db.raw.order_reviews by order_id using
  MAX(review_score).
  Include as: review_score.
  Add has_review boolean (review_score IS NOT NULL).
  Add is_positive_review boolean (review_score >= 4).

Filter out null order_id and null product_id.
```

---

## What CoCo will create

| Dynamic Table          | Source                                                | TARGET_LAG | Rows (approx)                   |
| ---------------------- | ----------------------------------------------------- | ---------- | ------------------------------- |
| `analytics.order_fact` | Both Silver layer tables + raw payments + raw reviews | DOWNSTREAM | ~112k (one per order line item) |

---

## What to verify before executing

- [ ] `TARGET_LAG = DOWNSTREAM` — fact table only refreshes when Gold layer asks
- [ ] `INITIALIZE = ON_SCHEDULE`
- [ ] Payment join uses a subquery with `GROUP BY order_id` — NOT a direct join (which would multiply rows)
- [ ] Review join uses a subquery with `GROUP BY order_id` — same reason
- [ ] Both Silver layer source tables are referenced by their analytics schema path: `olist_db.analytics.orders_enriched`

---

## Why pre-aggregate payments and reviews?

`order_payments` can have multiple rows per order (e.g. split payments). Joining directly to `order_fact` — which is already one row per order item — would create a fan-out (1 order item × 3 payments = 3 rows instead of 1).

The subquery solution:

```sql
LEFT JOIN (
  SELECT order_id,
         MAX(payment_type)         AS payment_type,
         MAX(payment_installments) AS payment_installments,
         SUM(payment_value)        AS payment_value
  FROM olist_db.raw.order_payments
  GROUP BY order_id
) p ON o.order_id = p.order_id
```

This collapses each order's payments into a single row before the join — maintaining one fact row per order line item.
