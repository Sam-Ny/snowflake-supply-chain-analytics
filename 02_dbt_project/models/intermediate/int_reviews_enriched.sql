-- ============================================================
-- Model       : int_reviews_enriched
-- Layer       : Silver (Intermediate)
-- Description : Joins reviews with order timestamps to
--               calculate review response time and enrich
--               sentiment analysis.
--               Single grain = one row per review.
-- ============================================================

with reviews as (

    select * from {{ ref('stg_reviews') }}

),

orders as (

    select
        ORDER_ID,
        ORDER_DELIVERED_CUSTOMER_AT,
        ORDER_PURCHASED_AT
    from {{ ref('stg_orders') }}

),

joined as (

    select
        -- keys
        r.REVIEW_ID,
        r.ORDER_ID,

        -- review details
        r.REVIEW_SCORE,
        r.REVIEW_SENTIMENT,
        r.REVIEW_TITLE,
        r.REVIEW_MESSAGE,

        -- timestamps
        r.REVIEW_CREATED_AT,
        r.REVIEW_ANSWERED_AT,

        -- derived timing metrics
        datediff(
            'day',
            o.ORDER_DELIVERED_CUSTOMER_AT,
            r.REVIEW_CREATED_AT
        )                                           as days_to_review_after_delivery,

        datediff(
            'hour',
            r.REVIEW_CREATED_AT,
            r.REVIEW_ANSWERED_AT
        )                                           as review_response_hours,

        -- flag for reviews with comments
        case
            when r.REVIEW_MESSAGE is not null
            and length(trim(r.REVIEW_MESSAGE)) > 0
            then true
            else false
        end                                         as has_comment,

        -- metadata
        r._INGESTED_AT,
        r._PIPELINE_NAME

    from reviews r
    left join orders o
        on r.ORDER_ID = o.ORDER_ID

)

select * from joined