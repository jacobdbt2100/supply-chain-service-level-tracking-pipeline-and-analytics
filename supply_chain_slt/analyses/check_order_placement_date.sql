
-- =============================================================================
-- check_order_placement_date.sql
-- Analysis: order placement date consistency in fct_order_lines.
-- Grain: one row per order_id
-- Purpose: ensures all lines belonging to an order share the same placement date.
-- Expected output: No rows returned.
-- =============================================================================

SELECT
    order_id,
    COUNT(DISTINCT order_placement_date) AS date_count
FROM {{ ref('fct_order_lines') }}
GROUP BY order_id
HAVING COUNT(DISTINCT order_placement_date) > 1
