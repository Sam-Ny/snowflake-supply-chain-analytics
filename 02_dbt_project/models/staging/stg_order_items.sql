-- ============================================================
-- Model    : stg_order_items
-- Layer    : Silver (Staging)
-- Source   : BRONZE.RAW_ORDER_ITEMS
-- Description: Cleans order line items, calculates total
--              item value including freight.
-- ============================================================

with source as (

    select * from {{ source('bronze', 'RAW_ORDER_ITEMS') }}

),

cleaned as (

    select
        -- composite key (order_id + order_item_id)
        ORDER_ID,
        ORDER_ITEM_ID,

        -- foreign keys
        PRODUCT_ID,
        SELLER_ID,

        -- dates
        to_timestamp_ntz(to_varchar(SHIPPING_LIMIT_DATE)) as shipping_limit_at,

        -- financials
        round(PRICE, 2)                                   as item_price,
        round(FREIGHT_VALUE, 2)                           as freight_value,
        round(PRICE + FREIGHT_VALUE, 2)                   as total_item_value,

        -- metadata
        _INGESTED_AT,
        _SOURCE_FILE,
        _PIPELINE_NAME

    from source

    where ORDER_ID is not null
      and ORDER_ITEM_ID is not null

)

select * from cleaned