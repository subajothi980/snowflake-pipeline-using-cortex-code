# Sample Analytical Queries

Run these against your Dynamic Tables after the initial load completes.

## Revenue by State

```sql
SELECT
  customer_state,
  ROUND(SUM(total_revenue), 2)    AS revenue,
  SUM(total_orders)               AS orders,
  ROUND(AVG(avg_review_score), 2) AS avg_score
FROM olist_db.analytics.daily_sales_metrics
GROUP BY customer_state
ORDER BY revenue DESC
LIMIT 10;
```

## Top Product Categories by Revenue

```sql
SELECT
  category_english,
  ROUND(SUM(total_revenue), 2)           AS revenue,
  SUM(total_units_sold)                  AS units_sold,
  ROUND(AVG(avg_review_score), 2)        AS avg_score,
  ROUND(AVG(satisfaction_rate) * 100, 1) AS satisfaction_pct
FROM olist_db.analytics.product_performance_metrics
GROUP BY category_english
ORDER BY revenue DESC
LIMIT 15;
```

## Delivery Performance by Day of Week

```sql
SELECT
  day_name,
  SUM(total_orders)                    AS orders,
  ROUND(AVG(avg_delay_days), 2)        AS avg_delay,
  SUM(late_orders)                     AS late_orders,
  ROUND(SUM(late_orders)
    / NULLIF(SUM(total_orders), 0) * 100, 1) AS late_pct
FROM olist_db.analytics.daily_sales_metrics
GROUP BY day_name
ORDER BY avg_delay DESC;
```

## High Freight-to-Price Ratio Categories (Logistics Cost Alert)

```sql
SELECT
  category_english,
  ROUND(AVG(avg_freight_ratio) * 100, 1) AS avg_freight_pct_of_price,
  ROUND(AVG(avg_freight), 2)             AS avg_freight_brl,
  ROUND(AVG(avg_price), 2)               AS avg_price_brl
FROM olist_db.analytics.product_performance_metrics
WHERE order_count >= 10
GROUP BY category_english
ORDER BY avg_freight_pct_of_price DESC
LIMIT 10;
```

## Seller Scorecards (Satisfaction + Revenue)

```sql
SELECT
  seller_id,
  seller_state,
  SUM(total_units_sold)                  AS units,
  ROUND(SUM(total_revenue), 2)           AS revenue,
  ROUND(AVG(avg_review_score), 2)        AS avg_score,
  ROUND(AVG(satisfaction_rate) * 100, 1) AS satisfaction_pct,
  ROUND(AVG(avg_delivery_delay_days), 2) AS avg_delay
FROM olist_db.analytics.product_performance_metrics
GROUP BY seller_id, seller_state
HAVING SUM(total_units_sold) >= 50
ORDER BY satisfaction_pct DESC, units DESC
LIMIT 20;
```

## Monthly Revenue Trend

```sql
SELECT
  DATE_TRUNC('month', order_date)  AS month,
  SUM(total_orders)                AS orders,
  ROUND(SUM(total_revenue), 2)     AS revenue,
  ROUND(AVG(avg_review_score), 2)  AS avg_score
FROM olist_db.analytics.daily_sales_metrics
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;
```
