-- ============================================================
-- generate_demo_orders.sql
-- Stored procedure to insert synthetic orders for testing
-- incremental refresh behaviour without real new data.
--
-- Usage:
--   CALL olist_db.raw.generate_demo_orders(500);
-- ============================================================

USE ROLE      olist_role;
USE WAREHOUSE olist_wh;
USE DATABASE  olist_db;

CREATE OR REPLACE PROCEDURE olist_db.raw.generate_demo_orders(num_rows INTEGER)
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
  orders_before  INTEGER;
  items_before   INTEGER;
  orders_after   INTEGER;
  items_after    INTEGER;
BEGIN
  SELECT COUNT(*) INTO :orders_before FROM olist_db.raw.orders;
  SELECT COUNT(*) INTO :items_before  FROM olist_db.raw.order_items;

  -- Sample random existing orders and assign new IDs
  CREATE OR REPLACE TEMPORARY TABLE tmp_new_orders AS
  SELECT
    UUID_STRING()       AS new_order_id,
    o.order_id          AS original_order_id,
    o.customer_id,
    o.order_status,
    -- Preserve time-of-day but shift date to today
    DATEADD(
      'second',
      DATEDIFF('second',
        DATE_TRUNC('day', o.order_purchase_timestamp),
        o.order_purchase_timestamp),
      CURRENT_DATE()
    )                   AS order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date
  FROM olist_db.raw.orders o
  SAMPLE (:num_rows ROWS);

  -- Insert new order headers
  INSERT INTO olist_db.raw.orders (
    order_id, customer_id, order_status, order_purchase_timestamp,
    order_approved_at, order_delivered_carrier_date,
    order_delivered_customer_date, order_estimated_delivery_date
  )
  SELECT
    new_order_id, customer_id, order_status, order_purchase_timestamp,
    order_approved_at, order_delivered_carrier_date,
    order_delivered_customer_date, order_estimated_delivery_date
  FROM tmp_new_orders;

  -- Copy corresponding items with +/- 20% price variation
  INSERT INTO olist_db.raw.order_items (
    order_id, order_item_id, product_id, seller_id,
    shipping_limit_date, price, freight_value
  )
  SELECT
    n.new_order_id,
    i.order_item_id,
    i.product_id,
    i.seller_id,
    i.shipping_limit_date,
    ROUND(i.price         * UNIFORM(0.8::FLOAT, 1.2::FLOAT, RANDOM()), 2),
    ROUND(i.freight_value * UNIFORM(0.8::FLOAT, 1.2::FLOAT, RANDOM()), 2)
  FROM tmp_new_orders          n
  JOIN olist_db.raw.order_items i ON n.original_order_id = i.order_id;

  SELECT COUNT(*) INTO :orders_after FROM olist_db.raw.orders;
  SELECT COUNT(*) INTO :items_after  FROM olist_db.raw.order_items;

  DROP TABLE IF EXISTS tmp_new_orders;

  RETURN 'Inserted ' || (:orders_after - :orders_before) || ' orders and '
      || (:items_after  - :items_before)  || ' order items.';
END;
$$;
