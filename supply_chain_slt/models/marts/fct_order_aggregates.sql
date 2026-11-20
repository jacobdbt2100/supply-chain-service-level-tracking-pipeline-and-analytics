
-- =============================================================================
-- fct_order_aggregates.sql
-- Mart layer: order-level service performance
-- Grain: one row per order_id
-- Incremental strategy: MERGE
-- =============================================================================

{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='order_id',
    on_schema_change='append_new_columns'
) }}

WITH aggregated AS (

    SELECT
        order_id,
        customer_id,
        MIN(order_placement_date) AS order_placement_date,

        -- Aggregated flags (all lines must be TRUE)
        BOOLOR_AGG(late_delivery_flag) AS late_delivery_flag,
        BOOLAND_AGG(on_time_flag) AS on_time_flag,
        BOOLAND_AGG(in_full_flag) AS in_full_flag

    FROM {{ ref('fct_order_lines') }}
    GROUP BY order_id, customer_id

),

final AS (

    SELECT
        order_id,
        customer_id,
        order_placement_date,
        on_time_flag,
        in_full_flag,

        -- OTIF derived at order level
        CASE
            WHEN on_time_flag = TRUE AND in_full_flag = TRUE THEN TRUE
            ELSE FALSE
        END AS otif_flag

    FROM aggregated

)

SELECT
    order_id,
    customer_id,
    order_placement_date,
    on_time_flag,
    in_full_flag,
    otif_flag

FROM final

{% if is_incremental() %}

    WHERE order_placement_date > (
        SELECT COALESCE(
            MAX(order_placement_date),
            '1900-01-01'
        )
        FROM {{ this }}
    )

{% endif %}
