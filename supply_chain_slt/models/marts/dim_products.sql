-- =============================================================================
-- dim_products.sql
-- Mart layer: product dimension for product-level analysis.
-- Grain: one row per product_id
-- =============================================================================

SELECT
    product_id,
    product_name,
    category

FROM {{ ref('stg_products') }}
