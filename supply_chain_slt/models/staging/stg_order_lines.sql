-- =============================================================================
-- stg_order_lines.sql
-- Staging layer: casts, cleans and standardises order lines fact table
-- Grain: one row per order line (order_id + product_id)
-- =============================================================================

WITH source_data AS (

    -- Standardise data types from raw source
    SELECT
        CAST(order_id AS TEXT)                                                             AS order_id,
        TO_DATE(REGEXP_REPLACE(order_placement_date, '^[A-Za-z]+, ', ''), 'MMMM DD, YYYY') AS order_placement_date,
        CAST(customer_id AS TEXT)                                                          AS customer_id,
        CAST(product_id AS TEXT)                                                           AS product_id,
        CAST(order_qty AS INTEGER)                                                         AS order_qty,
        TO_DATE(REGEXP_REPLACE(agreed_delivery_date, '^[A-Za-z]+, ', ''), 'MMMM DD, YYYY') AS agreed_delivery_date,
        TO_DATE(REGEXP_REPLACE(actual_delivery_date, '^[A-Za-z]+, ', ''), 'MMMM DD, YYYY') AS actual_delivery_date,
        CAST(delivery_qty AS INTEGER)                                                      AS delivery_qty

    FROM {{ source('supply_chain_raw', 'order_lines') }}

),

deduplicated AS (

    -- Remove duplicate order line records
    -- Grain enforced: order_id + product_id
    SELECT
        order_id,
        order_placement_date,
        customer_id,
        product_id,
        order_qty,
        agreed_delivery_date,
        actual_delivery_date,
        delivery_qty,

        ROW_NUMBER() OVER (
            PARTITION BY order_id, product_id
            ORDER BY order_placement_date
        ) AS row_num

    FROM source_data

),

cleaned AS (

    -- Keep unique order lines
    SELECT
        order_id,
        order_placement_date,
        customer_id,
        product_id,
        order_qty,
        agreed_delivery_date,
        actual_delivery_date,
        delivery_qty

    FROM deduplicated
    WHERE row_num = 1

)

SELECT
    order_id,
    order_placement_date,
    customer_id,
    product_id,
    order_qty,
    agreed_delivery_date,
    actual_delivery_date,
    delivery_qty
FROM cleaned
