-- ============================================================
-- 02_cortex_agent.sql
-- Cortex Agent backed by the semantic view.
-- Access in Snowsight: AI & ML → Snowflake Intelligence
-- ============================================================

USE ROLE      olist_role;
USE WAREHOUSE olist_wh;
USE DATABASE  olist_db;
USE SCHEMA    olist_db.analytics;

CREATE OR REPLACE CORTEX AGENT olist_db.analytics.olist_analytics_agent
  DISPLAY_NAME = 'Olist E-Commerce Analytics Agent'
  TOOLS (
    CORTEX ANALYST (
      SEMANTIC_MODEL = 'olist_db.analytics.olist_semantic_model'
    )
  )
  COMMENT = 'Natural language analytics agent over the Olist Dynamic Tables pipeline.';
