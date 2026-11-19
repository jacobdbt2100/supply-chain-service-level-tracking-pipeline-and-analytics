
-- =============================================================================
-- dim_customer.sql
-- Mart layer: customer dimension for customer-level analysis.
-- Grain: one row per customer
-- =============================================================================

SELECT
    customer_id,
    customer_name,
    city

FROM {{ ref('stg_customers') }}
