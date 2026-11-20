
-- =============================================================================
-- fct_order_lines.sql
-- Mart layer: enriched order line data with service level metrics
-- Grain: one row per order line (order_id + product_id)
-- Incremental strategy: MERGE
-- =============================================================================

{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['order_id', 'product_id'],
    on_schema_change='append_new_columns'
) }}

WITH base AS (

    SELECT
        order_id,
        customer_id,
        product_id,
        order_placement_date,
        order_qty,
        agreed_delivery_date,
        actual_delivery_date,
        delivery_qty,

        -- On-time flag
        CASE
            WHEN actual_delivery_date <= agreed_delivery_date THEN TRUE
            ELSE FALSE
        END AS on_time_flag,

        -- In-full flag
        CASE
            WHEN delivery_qty >= order_qty THEN TRUE
            ELSE FALSE
        END AS in_full_flag,

        -- OTIF flag
        CASE
            WHEN actual_delivery_date <= agreed_delivery_date
             AND delivery_qty >= order_qty
            THEN TRUE
            ELSE FALSE
        END AS otif_flag,

        -- Line fulfilled flag
        CASE
            WHEN delivery_qty >= order_qty THEN TRUE
            ELSE FALSE
        END AS line_fulfilled_flag,

        -- Volume fill rate (percentage)
        ROUND(
            CASE
                WHEN order_qty = 0 THEN NULL
                ELSE (delivery_qty * 100.0 / order_qty)
            END,
            2
        ) AS volume_fill_rate_pct,

        -- Delay in days
        DATEDIFF(
            DAY,
            agreed_delivery_date,
            actual_delivery_date
        ) AS delay_days,

        -- Late delivery flag
        CASE
            WHEN actual_delivery_date > agreed_delivery_date THEN TRUE
            ELSE FALSE
        END AS late_delivery_flag

    FROM {{ ref('stg_order_lines') }}

)

SELECT
    order_id,
    customer_id,
    product_id,
    order_placement_date,
    order_qty,
    agreed_delivery_date,
    actual_delivery_date,
    delivery_qty,
    on_time_flag,
    in_full_flag,
    otif_flag,
    line_fulfilled_flag,
    volume_fill_rate_pct,
    delay_days,
    late_delivery_flag

FROM base

{% if is_incremental() %}

    WHERE order_placement_date > (
        SELECT COALESCE(
            MAX(order_placement_date),
            '1900-01-01'
        )
        FROM {{ this }}
    )

{% endif %}
