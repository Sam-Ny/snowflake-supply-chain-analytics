-- ============================================================
-- Model    : stg_orders
-- Layer    : Silver (Staging)
-- Source   : BRONZE.RAW_ORDERS
-- Description: Cleans and standardises raw orders data.
--              Casts timestamps, filters invalid records,
--              adds derived columns.
-- ============================================================

with source as (

    select * from {{ source('bronze', 'RAW_ORDERS') }}

),

cleaned as (

    select
        -- primary key
        ORDER_ID,

        -- foreign keys
        CUSTOMER_ID,

        -- order status
        lower(trim(ORDER_STATUS))                                       as order_status,

        -- timestamps (stored as unix nanoseconds — divide by 1B to get seconds)
        to_timestamp(ORDER_PURCHASE_TIMESTAMP / 1000000000)             as order_purchased_at,
        to_timestamp(ORDER_APPROVED_AT / 1000000000)                    as order_approved_at,
        to_timestamp(ORDER_DELIVERED_CARRIER_DATE / 1000000000)         as order_delivered_carrier_at,
        to_timestamp(ORDER_DELIVERED_CUSTOMER_DATE / 1000000000)        as order_delivered_customer_at,
        to_timestamp(ORDER_ESTIMATED_DELIVERY_DATE / 1000000000)        as order_estimated_delivery_at,

        -- derived columns
        datediff(
            'day',
            to_timestamp(ORDER_PURCHASE_TIMESTAMP / 1000000000),
            to_timestamp(ORDER_DELIVERED_CUSTOMER_DATE / 1000000000)
        )                                                               as actual_delivery_days,

        datediff(
            'day',
            to_timestamp(ORDER_PURCHASE_TIMESTAMP / 1000000000),
            to_timestamp(ORDER_ESTIMATED_DELIVERY_DATE / 1000000000)
        )                                                               as estimated_delivery_days,

        case
            when to_timestamp(ORDER_DELIVERED_CUSTOMER_DATE / 1000000000)
                 <= to_timestamp(ORDER_ESTIMATED_DELIVERY_DATE / 1000000000)
            then 'on_time'
            when to_timestamp(ORDER_DELIVERED_CUSTOMER_DATE / 1000000000)
                 > to_timestamp(ORDER_ESTIMATED_DELIVERY_DATE / 1000000000)
            then 'late'
            else 'unknown'
        end                                                             as delivery_status,

        -- metadata
        _INGESTED_AT,
        _SOURCE_FILE,
        _PIPELINE_NAME

    from source

    where ORDER_ID is not null

)

select * from cleaned