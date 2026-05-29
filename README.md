<div align="center">

# 🛒 Olist E-Commerce — Snowflake Dynamic Tables Pipeline

**A production-grade, three-tier declarative data pipeline using Snowflake Dynamic Tables**  
Built with the [Brazilian E-Commerce (Olist) dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)·

![Snowflake](https://img.shields.io/badge/Snowflake-Dynamic%20Tables-29B5E8?style=flat-square&logo=snowflake&logoColor=white)
![SQL](https://img.shields.io/badge/Language-SQL-orange?style=flat-square)
![Dataset](https://img.shields.io/badge/Dataset-Olist%20~100k%20orders-brightgreen?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square)

</div>

---

## Overview

This project demonstrates how to build an **autonomous, self-refreshing data pipeline** using Snowflake Dynamic Tables — without writing a single stored procedure, stream, or task to orchestrate the flow. You declare _what_ you want using SQL; Snowflake handles the rest.

Dynamic Tables let you declare what your pipeline should produce using SQL. Cortex Code lets you describe what you want in plain English and generates the SQL for you. Together, they represent a fully declarative approach to data engineering — from intent to production pipeline, no boilerplate required.

The pipeline ingests raw Olist e-commerce data (orders, products, sellers, reviews, payments) and transforms it through three layers into business-ready aggregated metrics — with **incremental refresh**, **dependency-graph management**, and a **Cortex AI Agent** for natural language querying on top.

---

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│  olist_db.raw  (source tables) - Bronze                             │
│                                                                     │
│  orders  order_items  order_payments  order_reviews                 │
│  customers  sellers  products  product_category_name_translation    │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  olist_db.analytics  —  Silver  (TARGET_LAG = DOWNSTREAM)           │
│                                                                     │
│  ┌─────────────────────────┐  ┌──────────────────────────────────┐  │
│  │   orders_enriched       │  │   order_items_enriched           │  │
│  │                         │  │                                  │  │
│  │  orders + customers     │  │  order_items + products          │  │
│  │  + temporal dims        │  │  + sellers + category names      │  │
│  │  + delivery delay       │  │  + freight_ratio                 │  │
│  └────────────┬────────────┘  └────────────────┬─────────────────┘  │
└───────────────┼────────────────────────────────┼────────────────────┘
                └──────────────┬─────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  olist_db.analytics  —  Silver  (TARGET_LAG = DOWNSTREAM)           │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │   order_fact                                                │    │
│  │                                                             │    │
│  │  Wide fact table · one row per order line item              │    │
│  │  + payment data + review score + delivery performance       │    │
│  └─────────────────────────────────────────────────────────────┘    │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  olist_db.analytics  —  Gold  (TARGET_LAG = 1 hour)              │
│                                                                     │
│  ┌──────────────────────────┐  ┌──────────────────────────────────┐ │
│  │  daily_sales_metrics     │  │  product_performance_metrics     │ │
│  │                          │  │                                  │ │
│  │  Revenue · orders ·      │  │  Revenue · units · review score  │ │
│  │  delivery KPIs · reviews │  │  · freight ratio · satisfaction  │ │
│  │  by date + customer state│  │  by product + seller state       │ │
│  └──────────────────────────┘  └──────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
                    ┌────────────────────────┐
                    │   Cortex AI Agent      │
                    │   Natural language     │
                    │   querying interface   │
                    └────────────────────────┘
```

---

## Key Concepts

| Concept                    | How it's used                                                                                                |
| -------------------------- | ------------------------------------------------------------------------------------------------------------ |
| **Cortex Code**            | Data engineering co-pilot in Snowsight                                                                       |
| `TARGET_LAG = DOWNSTREAM`  | Silver enriched,fact tables refresh only when requested by the next tier — no wasted compute                 |
| `TARGET_LAG = '1 hour'`    | Gold aggregates stay at most 1 hour behind source data                                                       |
| `INITIALIZE = ON_SCHEDULE` | All tables are created empty; the first load is triggered manually, separating _definition_ from _execution_ |
| **Incremental refresh**    | Snowflake processes only changed rows per cycle — not the full dataset                                       |
| **Dependency graph**       | Refreshing a Gold table automatically cascades through Silver fact → Silver enriched in the right order      |
| **Cortex Agent**           | A natural language interface powered by a semantic view over all 5 dynamic tables                            |

---

## Dataset

**[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)** on Kaggle

> Real orders from 2016–2018 across multiple Brazilian marketplaces. The multi-table structure (order headers, line items, products, sellers, reviews, payments) makes it a near-perfect structural mirror to the Tasty Bytes dataset used in the original Snowflake quickstart.

| CSV file                                | Raw table                               | Rows  |
| --------------------------------------- | --------------------------------------- | ----- |
| `olist_orders_dataset.csv`              | `raw.orders`                            | ~99k  |
| `olist_order_items_dataset.csv`         | `raw.order_items`                       | ~112k |
| `olist_order_payments_dataset.csv`      | `raw.order_payments`                    | ~104k |
| `olist_order_reviews_dataset.csv`       | `raw.order_reviews`                     | ~99k  |
| `olist_customers_dataset.csv`           | `raw.customers`                         | ~99k  |
| `olist_sellers_dataset.csv`             | `raw.sellers`                           | ~3k   |
| `olist_products_dataset.csv`            | `raw.products`                          | ~32k  |
| `product_category_name_translation.csv` | `raw.product_category_name_translation` | 71    |
| `olist_geolocation_dataset.csv`         | _(optional — not used in pipeline)_     | —     |

---

## Prerequisites

| Requirement            | Details                                                                                                                           |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| **Snowflake account**  | Enterprise edition · AWS US-West-2 preferred · `ACCOUNTADMIN` access required · [Free trial](https://signup.snowflake.com/) works |
| **Cortex Code (CoCo)** | Enable in Snowsight → Settings · Used to generate pipeline SQL from natural language                                              |
| **Kaggle account**     | Free · Accept dataset license before downloading                                                                                  |
| **Snowsight**          | Upload the bulk CSV files to the internal stage. "Data → Add Data" uploader                                                       |

---

## Quick Start

### 1 — Clone & download dataset

```bash
git clone https://github.com/subajothi980/snowflake-pipeline-using-cortex-code.git
cd snowflake-pipeline-using-cortex-code

## Download dataset manually from:
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
and place the CSV files in data/raw/
```

### 2 — Set up the Snowflake environment

Open **Snowsight → Cortex code** panel by clicking the Cortex Code icon in the lower-right corner of Snowsight.

You'll see a chat interface. You'll paste prompts from each section directly into CoCo. CoCo will generate the SQL, explain what it's doing, and execute it for you.

Copy "Prompt 00" from /cortex_prompts/00_environment_setup.md and paste it in the CoCo chat window and enter.

This creates:

- Role `olist_role` with necessary privileges
- Warehouse `olist_wh` (XL, 60s auto-suspend)
- Database `olist_db` with schemas `raw` and `analytics`
- All 8 raw source tables
- Internal stage `olist_db.raw.olist_stage` with CSV file format

### 3 — Upload and load CSVs

**Snowsight UI alternative:** Go to **Data → Add Data → Load files into a stage**, upload each CSV manually, then run only the `COPY INTO` blocks from `setup/02_upload_and_load.sql`.

### 4 — Deploy the pipeline

Paste Prompt 01 from /cortex_prompts/01_silver_enrichment.md into **Cortex Code (CoCo)** to build both Silver Layer enrichment Dynamic Tables(orders_enriched and order_items_enriched).

Both tables use `TARGET_LAG = DOWNSTREAM` and `INITIALIZE = ON_SCHEDULE` and return immediately — no waiting for an initial full scan.

Paste Prompt 02 from /cortex_prompts/02_silver_fact_table.md into **Cortex Code (CoCo)** to build the central wide fact table(order_fact).

`TARGET_LAG = DOWNSTREAM` — fact table only refreshes when Gold layer asks.

Paste Prompt 03 from /cortex_prompts/03_gold_metrics.md into **Cortex Code (CoCo)** to build both Gold layer aggregated metric tables.

Both gold layer tables use `TARGET_LAG = '1 hour'` (quoted string, not keyword) and `INITIALIZE = ON_SCHEDULE`.

### 5 — Trigger the initial load

Paste Prompt 04 from /cortex_prompts/04_trigger_initial_load.md into **Cortex Code (CoCo)** to kick off the first full data load across all five Dynamic Tables.

This refreshes only the two Gold layer tables. Snowflake automatically resolves the dependency graph and refreshes Silver enriched → Silver fact → Gold tables in the correct order.

Paste Prompt 05 from /cortex_prompts/05_generate_incremental_orders.md into **Cortex Code (CoCo)** to create a stored procedure that generates synthetic orders. Used to demonstrate incremental refresh without needing a live data stream. And follow the instructions to test the pipeline with incremental data.

Paste any of the prompt from /cortex_prompts/06_monitoring.md into **Cortex Code (CoCo)** to monitor pipeline health conversationally.

### 6 — Deploy the Cortex Agent

Paste the prompts from /cortex_prompts/07_semantic_view_and_agent.md into **Cortex Code (CoCo)** to create the semantic view and Cortex Agent that powers natural language querying over your pipeline.

## How to access your agent

1. In Snowsight, go to **AI & ML → Snowflake Intelligence**
2. Select **olist_analytics_agent** from the agent list
3. Start asking questions in plain English

---

## Sample questions to try

| Question                                                                     | What it demonstrates                         |
| ---------------------------------------------------------------------------- | -------------------------------------------- |
| "What are the top 10 product categories by revenue?"                         | Aggregation over product_performance_metrics |
| "Show me daily revenue trends for the past 30 days"                          | Time-series over daily_sales_metrics         |
| "Which customer states have the worst average delivery delays?"              | Filtering + grouping on delivery_delay_days  |
| "Compare weekend vs weekday order volumes"                                   | day_name dimension                           |
| "Which sellers have the highest satisfaction rate with at least 50 reviews?" | HAVING-style filter on product metrics       |
| "What payment types are most common for high-value orders?"                  | payment_type dimension + price fact          |
| "Show me categories where freight is more than 20% of the item price"        | Derived metric from avg_freight_ratio        |

---

## Repository Structure

```
snowflake-pipeline-using-cortex-code/
│
├── README.md
├── .gitignore
│
├── setup/
│   ├── 01_environment.sql              # Role, warehouse, database, schemas, all raw tables
│   └── 02_upload_and_load.sql          # PUT commands + COPY INTO for all 8 CSV files
│
├── pipeline/
│   ├── trigger_initial_load.sql        # Kicks off the Gold layer refresh (cascades upstream)
│   ├── Silver/
│   │   ├── 01_orders_enriched.sql      # Orders + customers + temporal dims + delivery delay
│   │   └── 02_order_items_enriched.sql # Items + products + sellers + category translation
│   │   └── 03_order_fact.sql           # Wide fact table — joins both Silver enriched tables + payments + reviews
│   └── Gold/
│       ├── 01_daily_sales_metrics.sql  # Aggregated by date + customer state (1 hour lag)
│       └── 02_product_performance_metrics.sql  # By product + seller state (1 hour lag)
│
├── procedures/
│   └── generate_incremental_orders.sql # Inserts synthetic orders to test incremental refresh
│
├── monitoring/
│   └── refresh_history.sql             # 4 observability queries: latest refresh, health, 24h history, row counts
│
├── agent/
│   ├── 01_semantic_view.sql            # Cortex semantic view — facts, dimensions, relationships
│   └── 02_cortex_agent.sql             # Cortex Agent for NL querying via Snowflake Intelligence
│
├── data/
│   └── raw/                            # ← Place Olist CSVs here (git-ignored)
│
└── docs/
    ├── pipeline_overview.md            # Concept deep-dive: lag types, incremental refresh notes
    └── sample_queries.md               # 6 ready-to-run analytical SQL queries
```

---

## Testing Incremental Refresh

The `generate_incremental_orders` stored procedure inserts synthetic orders derived from real data — useful for observing how Dynamic Tables handle new rows without needing a live data stream.

```sql
-- Insert 500 synthetic orders
CALL olist_db.raw.generate_incremental_orders(500);

-- Trigger refresh (only Tier 3 — Snowflake cascades upstream automatically)
ALTER DYNAMIC TABLE olist_db.analytics.daily_sales_metrics         REFRESH;
ALTER DYNAMIC TABLE olist_db.analytics.product_performance_metrics REFRESH;

-- Check refresh behaviour
SELECT name, refresh_action, state, refresh_trigger
FROM TABLE(olist_db.information_schema.dynamic_table_refresh_history())
WHERE schema_name = 'ANALYTICS'
ORDER BY refresh_start_time DESC
LIMIT 10;
```

**What to look for:**

- `refresh_action = INCREMENTAL` on `orders_enriched`, `order_items_enriched`, `order_fact`, and `daily_sales_metrics` — only new rows processed
- `refresh_action = FULL` on `product_performance_metrics` — existing product aggregate rows must be recalculated when new orders arrive for already-seen products (expected behaviour, identical to the original Tasty Bytes guide)

---

## Monitoring

Run `monitoring/refresh_history.sql` at any time for a full pipeline health check:

```sql
-- Most recent refresh per table (action, state, duration)
-- Pipeline scheduling state (target lag vs actual lag)
-- All refreshes in the last 24 hours
-- Row count validation across all 5 dynamic tables
```

You can also view the **dependency graph** visually in Snowsight:  
`Catalog → Database Explorer → olist_db → analytics → [any dynamic table] → Graph tab`

---

## Sample Agent Questions

Once the Cortex Agent is deployed, try these in **Snowflake Intelligence**:

- _"Which product categories have the worst average delivery delays?"_
- _"Top 10 sellers by total revenue — show satisfaction rate alongside"_
- _"What's the average review score by customer state?"_
- _"Compare weekend vs weekday order volumes over the last 3 months"_
- _"Which states have the highest freight-to-price ratios?"_
- _"Show me revenue trend by month with a breakdown by payment type"_

---

## Cleanup

```sql
-- Run as ACCOUNTADMIN to tear down all project resources
DROP DATABASE  IF EXISTS olist_db;
DROP WAREHOUSE IF EXISTS olist_wh;
DROP ROLE      IF EXISTS olist_role;
```

---

## Resources

- [Snowflake Dynamic Tables Documentation](https://docs.snowflake.com/en/user-guide/dynamic-tables-intro)
- [Dynamic Table Refresh Documentation](https://docs.snowflake.com/en/user-guide/dynamic-tables-refresh)
- [Cortex Code Documentation](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code-snowsight)
- [Cortex Analyst Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst)
- [Olist Dataset on Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

---

<div align="center">
<sub>Built as a learning project. Not affiliated with Olist or Snowflake.</sub>
</div>

---

## Using Cortex Code (CoCo) Prompts

The `cortex-prompts/` folder contains **copy-paste prompts** for Snowflake's AI co-pilot (Cortex Code / CoCo). Instead of running SQL files manually, you can describe what you want in natural language and CoCo generates and executes the SQL for you — exactly as in the original Snowflake quickstart.

### How it works

1. Open Snowsight → click the **Cortex Code icon** (lower-right corner)
2. Open the relevant prompt file from `cortex-prompts/`
3. Copy the text inside the code block and paste it into CoCo
4. Press **Shift+Tab** to switch to **Plan mode** before large DDL steps — review the SQL before it runs
5. Choose **Allow CREATE** when CoCo asks for execution approval

### Prompt sequence

| Prompt file                                    | Builds                                                |
| ---------------------------------------------- | ----------------------------------------------------- |
| `cortex-prompts/00_environment_setup.md`       | Role, warehouse, DB, schemas, 8 raw tables, stage     |
| `cortex-prompts/01_silver_enrichment.md`       | `orders_enriched` + `order_items_enriched`            |
| `cortex-prompts/02_silver_fact_table.md`       | `order_fact` wide fact table                          |
| `cortex-prompts/03_gold_metrics.md`            | `daily_sales_metrics` + `product_performance_metrics` |
| `cortex-prompts/04_trigger_initial_load.md`    | Triggers the first full pipeline refresh              |
| `cortex-prompts/05_generate_test_data.md`      | Stored procedure for synthetic order generation       |
| `cortex-prompts/06_monitoring.md`              | Refresh history + health check queries                |
| `cortex-prompts/07_semantic_view_and_agent.md` | Cortex semantic view + AI Agent                       |

> The SQL files in `pipeline/`, `procedures/`, and `agent/` are the exact DDL CoCo should produce — use them as a reference or run them directly as a fallback if needed.
