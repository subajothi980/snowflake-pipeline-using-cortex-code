-- ============================================================
-- 01_semantic_view.sql
-- Cortex semantic view over all 5 dynamic tables.
-- Powers the Cortex Agent for natural language querying.
-- ============================================================

USE ROLE      olist_role;
USE WAREHOUSE olist_wh;
USE DATABASE  olist_db;
USE SCHEMA    olist_db.analytics;

CREATE OR REPLACE SEMANTIC VIEW olist_db.analytics.olist_semantic_model
  TABLES (
    olist_db.analytics.orders_enriched             AS orders,
    olist_db.analytics.order_items_enriched        AS order_items,
    olist_db.analytics.order_fact                  AS fact,
    olist_db.analytics.daily_sales_metrics         AS daily_metrics,
    olist_db.analytics.product_performance_metrics AS product_metrics
  )
  RELATIONSHIPS (
    orders.order_id      = fact.order_id,
    order_items.order_id = fact.order_id
  )
  FACTS (
    fact.price                       AS "Item price (BRL)",
    fact.freight_value               AS "Freight value (BRL)",
    fact.total_item_value            AS "Total item value (BRL)",
    fact.delivery_delay_days         AS "Delivery delay (days)",
    fact.review_score                AS "Review score (1-5)",
    daily_metrics.total_revenue      AS "Daily total revenue (BRL)",
    daily_metrics.total_orders       AS "Daily total orders",
    daily_metrics.avg_review_score   AS "Daily avg review score",
    product_metrics.total_revenue    AS "Product total revenue (BRL)",
    product_metrics.satisfaction_rate AS "Product satisfaction rate"
  )
  DIMENSIONS (
    fact.order_date       AS "Order date",
    fact.day_name         AS "Day of week",
    fact.order_hour       AS "Order hour",
    fact.customer_state   AS "Customer state",
    fact.seller_state     AS "Seller state",
    fact.category_english AS "Product category",
    fact.order_status     AS "Order status",
    fact.payment_type     AS "Payment type",
    fact.is_delivered     AS "Is delivered",
    fact.has_review       AS "Has review"
  );
