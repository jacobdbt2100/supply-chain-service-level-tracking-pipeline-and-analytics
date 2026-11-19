
-- =============================================================================
-- dim_date.sql
-- Mart layer: calendar dimension for complete date-based analysis.
--
-- Grain: one row per calendar date
--
-- Generates every date between the first day of the month of the earliest
-- order placement date and the last day of the month of the latest agreed
-- or actual delivery date, including dates with no orders or deliveries.
-- =============================================================================

WITH date_range AS (

    -- Establish the boundaries of the available order and delivery period
    SELECT
        DATE_TRUNC('MONTH', MIN(order_placement_date))::DATE AS min_date,

        LAST_DAY(
            GREATEST_IGNORE_NULLS(
                MAX(agreed_delivery_date),
                MAX(actual_delivery_date)
            )
        ) AS max_date

    FROM {{ ref('stg_order_lines') }}

),

dates AS (

    -- Generate a continuous date range between the boundaries
    WITH RECURSIVE date_sequence (calendar_date, max_date) AS (

        -- Start with the earliest date
        SELECT
            min_date,
            max_date

        FROM date_range

        WHERE min_date IS NOT NULL
          AND max_date IS NOT NULL

        UNION ALL

        -- Generate the next calendar date until the maximum date is reached
        SELECT
            DATEADD(DAY, 1, calendar_date),
            max_date

        FROM date_sequence

        WHERE calendar_date < max_date

    )

    SELECT
        calendar_date

    FROM date_sequence

),

date_attributes AS (

    -- Derive calendar attributes for analysis
    SELECT
        calendar_date,
        YEAR(calendar_date) AS year,
        QUARTER(calendar_date) AS quarter,
        MONTH(calendar_date) AS month,
        TO_CHAR(calendar_date, 'MMMM') AS month_name,
        DAY(calendar_date) AS day,
        DAYOFWEEKISO(calendar_date) AS day_of_week,
        TO_CHAR(calendar_date, 'DY') AS day_name,
        CASE
            WHEN DAYOFWEEKISO(calendar_date) IN (6, 7) THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type,
        WEEKISO(calendar_date) AS week_of_year

    FROM dates

)

SELECT
    calendar_date,
    year,
    quarter,
    month,
    month_name,
    day,
    day_of_week,
    day_name,
    day_type,
    week_of_year

FROM date_attributes

ORDER BY calendar_date
