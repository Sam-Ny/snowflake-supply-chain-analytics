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

        -- timestamps
        try_to_timestamp(to_varchar(ORDER_PURCHASE_TIMESTAMP), 'YYYY-MM-DD HH24:MI:SS')        as order_purchased_at,
        try_to_timestamp(to_varchar(ORDER_APPROVED_AT), 'YYYY-MM-DD HH24:MI:SS')               as order_approved_at,
        try_to_timestamp(to_varchar(ORDER_DELIVERED_CARRIER_DATE), 'YYYY-MM-DD HH24:MI:SS')    as order_delivered_carrier_at,
        try_to_timestamp(to_varchar(ORDER_DELIVERED_CUSTOMER_DATE), 'YYYY-MM-DD HH24:MI:SS')   as order_delivered_customer_at,
        try_to_timestamp(to_varchar(ORDER_ESTIMATED_DELIVERY_DATE), 'YYYY-MM-DD HH24:MI:SS')   as order_estimated_delivery_at,

        -- derived columns
        datediff(
            'day',
            try_to_timestamp(to_varchar(ORDER_PURCHASE_TIMESTAMP), 'YYYY-MM-DD HH24:MI:SS'),
            try_to_timestamp(to_varchar(ORDER_DELIVERED_CUSTOMER_DATE), 'YYYY-MM-DD HH24:MI:SS')
        )                                                               as actual_delivery_days,

        datediff(
            'day',
            try_to_timestamp(to_varchar(ORDER_PURCHASE_TIMESTAMP), 'YYYY-MM-DD HH24:MI:SS'),
            try_to_timestamp(to_varchar(ORDER_ESTIMATED_DELIVERY_DATE), 'YYYY-MM-DD HH24:MI:SS')
        )                                                               as estimated_delivery_days,

        case
            when try_to_timestamp(to_varchar(ORDER_DELIVERED_CUSTOMER_DATE), 'YYYY-MM-DD HH24:MI:SS')
                 <= try_to_timestamp(to_varchar(ORDER_ESTIMATED_DELIVERY_DATE), 'YYYY-MM-DD HH24:MI:SS')
            then 'on_time'
            when try_to_timestamp(to_varchar(ORDER_DELIVERED_CUSTOMER_DATE), 'YYYY-MM-DD HH24:MI:SS')
                 > try_to_timestamp(to_varchar(ORDER_ESTIMATED_DELIVERY_DATE), 'YYYY-MM-DD HH24:MI:SS')
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