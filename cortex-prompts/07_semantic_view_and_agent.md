# CoCo Prompt 07 — Semantic View & Cortex Agent

Paste these prompts into **Cortex Code (CoCo)** to create the semantic view and Cortex Agent that powers natural language querying over your pipeline.

> **Run this after:** All 5 Dynamic Tables exist and have been loaded with data.

---

## Prompt — Create the semantic view

```
Create a semantic view called olist_semantic_model in olist_db.analytics
over all 5 dynamic tables in the analytics schema:
  orders_enriched, order_items_enriched, order_fact,
  daily_sales_metrics, and product_performance_metrics.

Define the following relationships:
  orders_enriched.order_id = order_fact.order_id
  order_items_enriched.order_id = order_fact.order_id

Define these facts (measurable numeric values):
  order_fact.price as "Item price (BRL)"
  order_fact.freight_value as "Freight value (BRL)"
  order_fact.total_item_value as "Total item value (BRL)"
  order_fact.delivery_delay_days as "Delivery delay (days)"
  order_fact.review_score as "Review score (1-5)"
  daily_sales_metrics.total_revenue as "Daily total revenue (BRL)"
  daily_sales_metrics.total_orders as "Daily total orders"
  daily_sales_metrics.avg_review_score as "Daily avg review score"
  product_metrics.total_revenue as "Product total revenue (BRL)"
  product_metrics.satisfaction_rate as "Product satisfaction rate"

Define these dimensions (categorical grouping fields):
  order_fact.order_date as "Order date"
  order_fact.day_name as "Day of week"
  order_fact.order_hour as "Order hour"
  order_fact.customer_state as "Customer state"
  order_fact.seller_state as "Seller state"
  order_fact.category_english as "Product category"
  order_fact.order_status as "Order status"
  order_fact.payment_type as "Payment type"
  order_fact.is_delivered as "Is delivered"
  order_fact.has_review as "Has review"
```

---

## Prompt — Create the Cortex Agent

```
Create a Cortex Agent called olist_analytics_agent in olist_db.analytics
that uses olist_db.analytics.olist_semantic_model as its Cortex Analyst tool.
Set the display name to "Olist E-Commerce Analytics Agent".
```

---

## How to access your agent

1. In Snowsight, go to **AI & ML → Snowflake Intelligence**
2. Select **olist_analytics_agent** from the agent list
3. Start asking questions in plain English

---

## Sample questions to try

| Question | What it demonstrates |
|---|---|
| "What are the top 10 product categories by revenue?" | Aggregation over product_performance_metrics |
| "Show me daily revenue trends for the past 30 days" | Time-series over daily_sales_metrics |
| "Which customer states have the worst average delivery delays?" | Filtering + grouping on delivery_delay_days |
| "Compare weekend vs weekday order volumes" | day_name dimension |
| "Which sellers have the highest satisfaction rate with at least 50 reviews?" | HAVING-style filter on product metrics |
| "What payment types are most common for high-value orders?" | payment_type dimension + price fact |
| "Show me categories where freight is more than 20% of the item price" | Derived metric from avg_freight_ratio |

---

## Prompt — Monitor the agent (optional)

```
Show me a summary of all Cortex Agents and semantic views defined in olist_db.analytics.
```
