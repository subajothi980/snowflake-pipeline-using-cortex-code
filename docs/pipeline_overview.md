# Pipeline Overview

## Design Principles

This pipeline mirrors the Snowflake Tasty Bytes Dynamic Tables quickstart, adapted for the Olist Brazilian E-Commerce dataset.

### Key Concepts

| Concept | Value | Used in |
|---|---|---|
| `TARGET_LAG = DOWNSTREAM` | Refresh only when downstream needs it | Tier 1 & 2 |
| `TARGET_LAG = '1 hour'` | Data is at most 1 hour stale | Tier 3 aggregates |
| `INITIALIZE = 'ON_SCHEDULE'` | Table created empty; first load is triggered manually | All tables |
| Incremental refresh | Only changed rows are processed per cycle | Automatic |

### Tier 1 — Enrichment

Both Tier 1 tables have `TARGET_LAG = DOWNSTREAM`, meaning they only refresh when `order_fact` (Tier 2) requests it.

- **orders_enriched** — adds temporal dimensions (`order_date`, `day_name`, `order_hour`) and delivery delay calculation on top of the raw `orders + customers` join.
- **order_items_enriched** — enriches raw line items with product details, seller geography, and English-translated category names.

### Tier 2 — Fact Table

`order_fact` is the central wide table. It joins both Tier 1 tables and adds pre-aggregated payment and review data (using subqueries to prevent row fan-out from one-to-many relationships).

### Tier 3 — Metrics

- **daily_sales_metrics** — grouped by `order_date`, `day_name`, `customer_state`. Suitable for time-series dashboards and day-of-week analysis.
- **product_performance_metrics** — grouped by product, category, seller, and seller state. Suitable for product scorecards and logistics analysis.

## Incremental Refresh Notes

When `generate_demo_orders(N)` inserts N new rows:

- `orders_enriched` and `order_items_enriched` refresh **incrementally** (only new rows)
- `order_fact` refreshes **incrementally**
- `daily_sales_metrics` refreshes **incrementally** (new date rows appended)
- `product_performance_metrics` may show **FULL** refresh for affected product groups — aggregate rows must be recalculated when existing product sales change. This mirrors the behaviour described in the original Tasty Bytes guide.

## Schema Mapping

| Tasty Bytes | Olist equivalent |
|---|---|
| `order_header` | `orders` + `customers` |
| `order_detail` | `order_items` |
| `menu` | `products` + `sellers` + `product_category_name_translation` |
| Revenue / discount metrics | Revenue + freight + delivery delay + review score |
