-- =============================================================================
-- dim_target_orders.sql
-- Mart layer: customer targets dimension for target-based analysis
-- Grain: one row per customer_id
-- =============================================================================

SELECT
    customer_id           AS customer_id,
    ontime_target_pct     AS ontime_target_pct,
    infull_target_pct     AS infull_target_pct,
    otif_target_pct       AS otif_target_pct

FROM {{ ref('stg_target_orders') }}
