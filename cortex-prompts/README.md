# Cortex Code (CoCo) Prompts

These are the natural language prompts to paste into **Cortex Code (CoCo)** in Snowsight — Snowflake's AI co-pilot. Each file corresponds to one step of the pipeline build.

You do **not** need to write any SQL manually. CoCo generates, explains, and executes it for you.

## How to use

1. Open Snowsight and click the **Cortex Code icon** (lower-right corner)
2. Open the prompt file for the step you're on
3. Copy the text inside the ` ``` ` code block
4. Paste it into the CoCo chat and press Enter
5. Review the generated SQL — use **Shift+Tab** to switch to Plan mode first for large changes
6. Approve execution when prompted

## Prompt files in order

| File | Step | What it builds |
|---|---|---|
| `00_environment_setup.md` | Setup | Role, warehouse, database, schemas, all 8 raw tables, stage |
| `01_tier1_enrichment.md` | Tier 1 | `orders_enriched` + `order_items_enriched` dynamic tables |
| `02_tier2_fact_table.md` | Tier 2 | `order_fact` wide fact table |
| `03_tier3_metrics.md` | Tier 3 | `daily_sales_metrics` + `product_performance_metrics` |
| `04_trigger_initial_load.md` | Initial load | Triggers Tier 3 refresh (Snowflake cascades Tier 1 → 2 → 3) |
| `05_generate_test_data.md` | Testing | Stored procedure for synthetic order generation |
| `06_monitoring.md` | Monitoring | Refresh history + pipeline health queries |
| `07_semantic_view_and_agent.md` | Agent | Cortex semantic view + AI Agent for NL querying |

## CoCo tips

- **Plan mode** (`Shift+Tab`) — CoCo shows you the full SQL plan before executing. Use this before Tier 1, 2, and 3 DDL to review all tables at once.
- **Allow CREATE** — when CoCo asks for execution permission, choose "Allow CREATE" to approve all DDL for the session without per-statement prompts.
- **Re-run a prompt** — if a step fails, the SQL files in `pipeline/`, `procedures/`, and `agent/` contain the exact DDL CoCo should have generated. You can run those directly as a fallback.
