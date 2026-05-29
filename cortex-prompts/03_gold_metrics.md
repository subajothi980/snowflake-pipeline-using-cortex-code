# CoCo Prompt 03 — Gold Layer: Aggregated Metrics

Paste this prompt into **Cortex Code (CoCo)** to build both Gold layer aggregated metric tables.

> **Note:** `order_fact` (Silver Layer) must exist before running this prompt.

---

## Prompt

```
Build 2 Gold Layer dynamic tables in olist_db.analytics using warehouse olist_wh.
Use INITIALIZE = 'ON_SCHEDULE' and TARGET_LAG = '1 hour' for both tables.

Table 1 — daily_sales_metrics:
  Aggregate olist_db.analytics.order_fact by order_date, day_name, customer_state.
  Include:
  - COUNT DISTINCT order_id as total_orders
  - COUNT DISTINCT customer_id as unique_customers
  - SUM order_item_id as total_line_items
  - ROUND SUM price as total_revenue (2 decimals)
  - ROUND AVG price as avg_order_value (2 decimals)
  - ROUND SUM freight_value as total_freight (2 decimals)
  - ROUND SUM total_item_value as total_gmv (2 decimals)
  - COUNT DISTINCT order_id where is_delivered=true as delivered_orders
  - COUNT DISTINCT order_id where delivery_delay_days > 0 as late_orders
  - ROUND AVG delivery_delay_days where is_delivered=true as avg_delay_days (2 decimals)
  - ROUND AVG review_score as avg_review_score (2 decimals)
  - COUNT rows where has_review=true as reviews_received
  - COUNT rows where is_positive_review=true as positive_reviews

Table 2 — product_performance_metrics:
  Aggregate olist_db.analytics.order_fact by product_id, category_english,
    seller_id, seller_state.
  Include:
  - COUNT DISTINCT order_id as order_count
  - SUM order_item_id as total_units_sold
  - ROUND SUM price as total_revenue (2 decimals)
  - ROUND AVG price as avg_price (2 decimals)
  - ROUND MIN price as min_price (2 decimals)
  - ROUND MAX price as max_price (2 decimals)
  - ROUND SUM freight_value as total_freight (2 decimals)
  - ROUND AVG freight_value as avg_freight (2 decimals)
  - ROUND AVG freight_ratio as avg_freight_ratio (4 decimals)
  - ROUND AVG review_score as avg_review_score (2 decimals)
  - COUNT rows where has_review=true as reviews_received
  - COUNT rows where is_positive_review=true as positive_reviews
  - ROUND positive_reviews / NULLIF(reviews_received, 0) as satisfaction_rate (4 decimals)
  - ROUND AVG delivery_delay_days where is_delivered=true as avg_delivery_delay_days (2 decimals)
```

---

## What CoCo will create

| Dynamic Table                           | Grain                  | TARGET_LAG | Key metrics                                      |
| --------------------------------------- | ---------------------- | ---------- | ------------------------------------------------ |
| `analytics.daily_sales_metrics`         | Date × customer state  | 1 hour     | Revenue, orders, delivery KPIs, review scores    |
| `analytics.product_performance_metrics` | Product × seller state | 1 hour     | Revenue, units, freight ratio, satisfaction rate |

---

## What to verify before executing

- [ ] Both tables use `TARGET_LAG = '1 hour'` (quoted string, not keyword)
- [ ] Both tables use `INITIALIZE = ON_SCHEDULE`
- [ ] Source is `olist_db.analytics.order_fact` (Silver layer — not raw tables)
- [ ] `satisfaction_rate` uses `NULLIF(reviews_received, 0)` to avoid division by zero
- [ ] `avg_delay_days` and `avg_delivery_delay_days` filter on `is_delivered = true` (only meaningful for completed orders)

---

## Why 1 hour lag for Gold layer tables?

Tier 3 tables are the ones dashboards and the Cortex Agent query directly. Setting `TARGET_LAG = '1 hour'` means:

- Aggregates are never more than 1 hour stale
- Refreshes happen on a schedule — no manual trigger needed after the initial load
- Snowflake automatically cascades to Silver layer enrichment and fact table when a Gold layer refresh fires
