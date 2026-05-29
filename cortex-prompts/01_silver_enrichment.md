# CoCo Prompt 02 — Silver Layer: Enrichment Dynamic Tables

Paste this prompt into **Cortex Code (CoCo)** to build both Silver Layer Dynamic Tables.

> **Tip:** Before submitting, press **Shift+Tab** to switch CoCo into **Plan mode**. Review the generated SQL before letting it execute — useful for large DDL changes like this.

---

## Prompt

```
Build Silver Layer dynamic tables in olist_db.analytics using warehouse olist_wh.
Use INITIALIZE = 'ON_SCHEDULE' and TARGET_LAG = DOWNSTREAM for both tables.

Table 1 — orders_enriched:
  Source: olist_db.raw.orders joined with olist_db.raw.customers on customer_id.
  Include: order_id, customer_id, customer_unique_id, customer_city,
    customer_state, customer_zip_code_prefix, order_status.
  Rename order_purchase_timestamp as order_timestamp.
  Add temporal dimensions: order_date (DATE), day_name (DAYNAME),
    order_hour (HOUR of order_purchase_timestamp).
  Include: order_delivered_customer_date, order_estimated_delivery_date.
  Calculate delivery_delay_days as DATEDIFF(day, order_estimated_delivery_date,
    order_delivered_customer_date) — positive means late, negative means early.
  Add is_delivered boolean (true when order_status = 'delivered').
  Filter out null order_id.

Table 2 — order_items_enriched:
  Source: olist_db.raw.order_items joined with olist_db.raw.products on product_id,
    joined with olist_db.raw.sellers on seller_id,
    left joined with olist_db.raw.product_category_name_translation
    on product_category_name.
  Include: order_id, order_item_id, product_id, seller_id, shipping_limit_date,
    price, freight_value, product_category_name, seller_city, seller_state,
    seller_zip_code_prefix, product_weight_g, product_photos_qty.
  Add category_english as COALESCE(translation, original product_category_name).
  Calculate total_item_value as price + freight_value.
  Calculate freight_ratio as ROUND(freight_value / NULLIF(price, 0), 4).
  Filter out null order_id and null product_id.
```

---

## What CoCo will create

| Dynamic Table                    | Source                                                           | TARGET_LAG | Key additions                                                                 |
| -------------------------------- | ---------------------------------------------------------------- | ---------- | ----------------------------------------------------------------------------- |
| `analytics.orders_enriched`      | `raw.orders` + `raw.customers`                                   | DOWNSTREAM | `order_date`, `day_name`, `order_hour`, `delivery_delay_days`, `is_delivered` |
| `analytics.order_items_enriched` | `raw.order_items` + `raw.products` + `raw.sellers` + translation | DOWNSTREAM | `category_english`, `total_item_value`, `freight_ratio`                       |

---

## What to verify before executing

- [ ] Both tables use `TARGET_LAG = DOWNSTREAM`
- [ ] Both tables use `INITIALIZE = ON_SCHEDULE`
- [ ] `orders_enriched` joins on `customer_id`
- [ ] `order_items_enriched` uses LEFT JOIN for category translation (not INNER — some products may have no translation)
- [ ] `delivery_delay_days` uses `DATEDIFF('day', estimated, actual)` — order matters
- [ ] `freight_ratio` uses `NULLIF(price, 0)` to avoid division by zero

---

## Why DOWNSTREAM?

Silver Layer tables set `TARGET_LAG = DOWNSTREAM` because they exist solely to feed (`order_fact`). There is no reason to refresh them on a schedule — they refresh on demand, only when the fact table needs them. This avoids unnecessary compute.
