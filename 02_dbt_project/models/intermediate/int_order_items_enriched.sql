-- ============================================================
-- Model       : int_order_items_enriched
-- Layer       : Silver (Intermediate)
-- Description : Joins order items with product, seller and
--               category translation data.
--               Single grain = one row per order line item.
--               Feeds into fact_orders in Gold layer.
-- ============================================================

with order_items as (

    select * from {{ ref('stg_order_items') }}

),

products as (

    select * from {{ ref('stg_products') }}

),

sellers as (

    select * from {{ ref('stg_sellers') }}

),

category_translation as (

    select * from {{ ref('stg_category_translation') }}

),

seller_geo as (

    select * from {{ ref('stg_geolocation') }}

),

joined as (

    select
        -- keys
        oi.ORDER_ID,
        oi.ORDER_ITEM_ID,
        oi.PRODUCT_ID,
        oi.SELLER_ID,

        -- product details
        p.PRODUCT_CATEGORY_NAME_PORTUGUESE,
        coalesce(ct.CATEGORY_NAME_ENGLISH,
            p.PRODUCT_CATEGORY_NAME_PORTUGUESE)     as product_category_english,
        p.PRODUCT_WEIGHT_G,
        p.PRODUCT_VOLUME_CM3,
        p.PRODUCT_PHOTOS_QTY,

        -- seller details
        s.SELLER_CITY,
        s.SELLER_STATE,
        s.SELLER_ZIP_CODE,

        -- seller geolocation
        sg.LATITUDE                                 as seller_latitude,
        sg.LONGITUDE                                as seller_longitude,

        -- financials
        oi.ITEM_PRICE,
        oi.FREIGHT_VALUE,
        oi.TOTAL_ITEM_VALUE,
        oi.SHIPPING_LIMIT_AT,

        -- freight ratio (useful metric)
        case
            when oi.TOTAL_ITEM_VALUE > 0
            then round(oi.FREIGHT_VALUE / oi.TOTAL_ITEM_VALUE, 4)
            else 0
        end                                         as freight_ratio,

        -- metadata
        oi._INGESTED_AT,
        oi._PIPELINE_NAME

    from order_items oi
    left join products p
        on oi.PRODUCT_ID = p.PRODUCT_ID
    left join sellers s
        on oi.SELLER_ID = s.SELLER_ID
    left join category_translation ct
        on p.PRODUCT_CATEGORY_NAME_PORTUGUESE = ct.CATEGORY_NAME_PORTUGUESE
    left join seller_geo sg
        on s.SELLER_ZIP_CODE = sg.ZIP_CODE

)

select * from joined