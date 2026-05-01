-- ============================================================
-- Model       : agg_seller_performance
-- Layer       : Gold (Marts)
-- Description : Aggregate mart for seller performance metrics.
--               One row per seller per month.
--               Ready for dashboarding.
-- ============================================================

with fact as (

    select * from {{ ref('fact_orders') }}

),

aggregated as (

    select
        -- dimensions
        SELLER_ID,
        SELLER_CITY,
        SELLER_STATE,
        to_char(ORDER_PURCHASED_AT, 'YYYY-MM')  as order_month,

        -- volume metrics
        count(distinct ORDER_ID)                as total_orders,
        count(ORDER_ITEM_ID)                    as total_items_sold,

        -- revenue metrics
        round(sum(ITEM_PRICE), 2)               as total_revenue,
        round(avg(ITEM_PRICE), 2)               as avg_item_price,
        round(sum(FREIGHT_VALUE), 2)            as total_freight_collected,

        -- delivery metrics
        round(avg(ACTUAL_DELIVERY_DAYS), 1)     as avg_delivery_days,
        sum(case when DELIVERY_STATUS = 'on_time'
            then 1 else 0 end)                  as on_time_deliveries,
        sum(case when DELIVERY_STATUS = 'late'
            then 1 else 0 end)                  as late_deliveries,

        -- review metrics
        round(avg(AVG_REVIEW_SCORE), 2)         as avg_review_score,
        sum(case when REVIEW_SENTIMENT = 'positive'
            then 1 else 0 end)                  as positive_reviews,
        sum(case when REVIEW_SENTIMENT = 'negative'
            then 1 else 0 end)                  as negative_reviews

    from fact
    where ORDER_STATUS = 'delivered'
    group by
        SELLER_ID,
        SELLER_CITY,
        SELLER_STATE,
        to_char(ORDER_PURCHASED_AT, 'YYYY-MM')

)

select * from aggregated