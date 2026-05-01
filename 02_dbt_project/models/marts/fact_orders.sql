-- ============================================================
-- Model       : fact_orders
-- Layer       : Gold (Marts)
-- Description : Central fact table. One row per order item.
--               Joins enriched orders with enriched items,
--               reviews and date dimension.
--               This is the primary table for analytics.
-- ============================================================

with orders as (

    select * from {{ ref('int_orders_enriched') }}

),

order_items as (

    select * from {{ ref('int_order_items_enriched') }}

),

reviews as (

    -- one review per order, aggregate to avoid fan-out
    select
        ORDER_ID,
        avg(REVIEW_SCORE)                       as avg_review_score,
        max(REVIEW_SENTIMENT)                   as review_sentiment,
        max(DAYS_TO_REVIEW_AFTER_DELIVERY)      as days_to_review,
        sum(case when HAS_COMMENT
            then 1 else 0 end)                  as review_comment_count
    from {{ ref('int_reviews_enriched') }}
    group by ORDER_ID

),

dim_date as (

    select * from {{ ref('dim_date') }}

),

joined as (

    select
        -- keys
        oi.ORDER_ID,
        oi.ORDER_ITEM_ID,
        oi.PRODUCT_ID,
        oi.SELLER_ID,
        o.CUSTOMER_ID,

        -- date foreign keys
        d.DATE_ID                               as order_date_id,

        -- order details
        o.ORDER_STATUS,
        o.DELIVERY_STATUS,
        o.ORDER_PURCHASED_AT,
        o.ORDER_DELIVERED_CUSTOMER_AT,
        o.ACTUAL_DELIVERY_DAYS,
        o.ESTIMATED_DELIVERY_DAYS,

        -- customer location
        o.CUSTOMER_CITY,
        o.CUSTOMER_STATE,
        o.CUSTOMER_LATITUDE,
        o.CUSTOMER_LONGITUDE,

        -- product details
        oi.PRODUCT_CATEGORY_ENGLISH,
        oi.PRODUCT_WEIGHT_G,
        oi.PRODUCT_VOLUME_CM3,

        -- seller details
        oi.SELLER_CITY,
        oi.SELLER_STATE,
        oi.SELLER_LATITUDE,
        oi.SELLER_LONGITUDE,

        -- payment details
        o.TOTAL_PAYMENT_VALUE,
        o.PAYMENT_TYPES_USED,
        o.MAX_INSTALLMENTS,

        -- financials
        oi.ITEM_PRICE,
        oi.FREIGHT_VALUE,
        oi.TOTAL_ITEM_VALUE,
        oi.FREIGHT_RATIO,

        -- review metrics
        r.AVG_REVIEW_SCORE,
        r.REVIEW_SENTIMENT,
        r.DAYS_TO_REVIEW,
        r.REVIEW_COMMENT_COUNT,

        -- metadata
        oi._INGESTED_AT,
        oi._PIPELINE_NAME

    from order_items oi
    left join orders o
        on oi.ORDER_ID = o.ORDER_ID
    left join reviews r
        on oi.ORDER_ID = r.ORDER_ID
    left join dim_date d
        on try_to_date(to_varchar(o.ORDER_PURCHASED_AT)) = d.DATE_DAY

)

select * from joined