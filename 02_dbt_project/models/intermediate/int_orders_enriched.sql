-- ============================================================
-- Model       : int_orders_enriched
-- Layer       : Silver (Intermediate)
-- Description : Joins orders with customer and payment data.
--               Single grain = one row per order.
--               Feeds into fact_orders in Gold layer.
-- ============================================================

with orders as (

    select * from {{ ref('stg_orders') }}

),

customers as (

    select * from {{ ref('stg_customers') }}

),

payments as (

    -- aggregate payments to order level
    -- one order can have multiple payment rows (installments)
    select
        ORDER_ID,
        sum(PAYMENT_VALUE)                          as total_payment_value,
        max(PAYMENT_INSTALLMENTS)                   as max_installments,
        count(distinct PAYMENT_TYPE)                as payment_type_count,
        listagg(distinct PAYMENT_TYPE, ' | ')
            within group (order by PAYMENT_TYPE)    as payment_types_used,
        sum(case when IS_INSTALLMENT_PURCHASE
            then 1 else 0 end)                      as installment_payment_count
    from {{ ref('stg_payments') }}
    group by ORDER_ID

),

geolocation as (

    select * from {{ ref('stg_geolocation') }}

),

joined as (

    select
        -- order keys
        o.ORDER_ID,
        o.CUSTOMER_ID,

        -- customer details
        c.CUSTOMER_UNIQUE_ID,
        c.CUSTOMER_CITY,
        c.CUSTOMER_STATE,
        c.CUSTOMER_ZIP_CODE,

        -- customer geolocation
        g.LATITUDE                                  as customer_latitude,
        g.LONGITUDE                                 as customer_longitude,

        -- order details
        o.ORDER_STATUS,
        o.ORDER_PURCHASED_AT,
        o.ORDER_APPROVED_AT,
        o.ORDER_DELIVERED_CARRIER_AT,
        o.ORDER_DELIVERED_CUSTOMER_AT,
        o.ORDER_ESTIMATED_DELIVERY_AT,

        -- delivery metrics
        o.ACTUAL_DELIVERY_DAYS,
        o.ESTIMATED_DELIVERY_DAYS,
        o.DELIVERY_STATUS,

        -- payment details
        p.TOTAL_PAYMENT_VALUE,
        p.MAX_INSTALLMENTS,
        p.PAYMENT_TYPE_COUNT,
        p.PAYMENT_TYPES_USED,
        p.INSTALLMENT_PAYMENT_COUNT,

        -- metadata
        o._INGESTED_AT,
        o._PIPELINE_NAME

    from orders o
    left join customers c
        on o.CUSTOMER_ID = c.CUSTOMER_ID
    left join payments p
        on o.ORDER_ID = p.ORDER_ID
    left join geolocation g
        on c.CUSTOMER_ZIP_CODE = g.ZIP_CODE

)

select * from joined