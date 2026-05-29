# CoCo Prompt 05 — Generate Test Data (Incremental Refresh Demo)

Paste this prompt into **Cortex Code (CoCo)** to create a stored procedure that generates synthetic orders. Used to demonstrate incremental refresh without needing a live data stream.

---

## Prompt — Create the procedure

```
Create a stored procedure olist_db.raw.generate_incremental_orders(num_rows INTEGER)
using SQL language that generates synthetic orders. It should:

- Capture row counts in orders and order_items before insertion
- Sample num_rows random existing orders from olist_db.raw.orders into a
  temporary table, assigning new unique order IDs (UUID_STRING()) while
  keeping the original order_id as original_order_id
- Set order_purchase_timestamp to today's date while preserving the
  original time-of-day using DATEADD and DATEDIFF
- Insert the new orders into olist_db.raw.orders
- For each new order, copy the corresponding order_items records from the
  original order, generating new order_ids and applying random price
  variation of plus or minus 20% using UNIFORM(0.8::FLOAT, 1.2::FLOAT, RANDOM())
- Capture row counts after insertion
- Clean up the temporary table
- Return a summary string showing how many orders and order items were inserted
```

---

## Prompt — Run the incremental refresh test

After the procedure is created, paste this series of prompts **one at a time**:

### Step 1 — Establish a baseline

```
How many rows are currently in olist_db.raw.orders and olist_db.raw.order_items?
```

### Step 2 — Insert synthetic orders

```
Call olist_db.raw.generate_incremental_orders(500)
```

### Step 3 — Trigger refresh (Gold layer only — Snowflake cascades upstream)

```
Refresh daily_sales_metrics and product_performance_metrics in olist_db.analytics.
```

### Step 4 — Verify incremental behaviour

```
Query olist_db.information_schema.dynamic_table_refresh_history() for each of
the 5 dynamic tables in olist_db.analytics. Show the most recent refresh_action,
state, refresh_trigger, and duration in seconds for each table.
```

### Step 5 — View updated results

```
Query olist_db.analytics.daily_sales_metrics ordered by order_date descending,
limit 5. Then query olist_db.analytics.product_performance_metrics ordered by
total_revenue descending, limit 10.
```

---

## What to observe

| Table                         | Expected refresh_action | Why                                                                       |
| ----------------------------- | ----------------------- | ------------------------------------------------------------------------- |
| `orders_enriched`             | `INCREMENTAL`           | Only the 500 new order rows are processed                                 |
| `order_items_enriched`        | `INCREMENTAL`           | Only new item rows processed                                              |
| `order_fact`                  | `INCREMENTAL`           | Joins only the new rows                                                   |
| `daily_sales_metrics`         | `INCREMENTAL`           | New date rows appended                                                    |
| `product_performance_metrics` | `FULL`                  | Existing product aggregate rows must be recalculated — expected behaviour |

> **Why FULL on product_performance_metrics?** When 500 new orders arrive for products that already exist in the table, their aggregate rows (total_revenue, avg_review_score, etc.) must be updated. Snowflake rewrites the affected groups. This mirrors the behaviour documented in the original Tasty Bytes quickstart and is still far more efficient than processing the full source dataset.
