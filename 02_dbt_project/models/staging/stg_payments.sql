-- ============================================================
-- Model    : stg_payments
-- Layer    : Silver (Staging)
-- Source   : BRONZE.RAW_PAYMENTS
-- Description: Cleans payment data, standardises payment types.
-- ============================================================

with source as (

    select * from {{ source('bronze', 'RAW_PAYMENTS') }}

),

cleaned as (

    select
        -- keys
        ORDER_ID,
        PAYMENT_SEQUENTIAL,

        -- payment details
        lower(trim(PAYMENT_TYPE))               as payment_type,
        PAYMENT_INSTALLMENTS                    as payment_installments,
        round(PAYMENT_VALUE, 2)                 as payment_value,

        -- flag for installment purchases
        case
            when PAYMENT_INSTALLMENTS > 1
            then true
            else false
        end                                     as is_installment_purchase,

        -- metadata
        _INGESTED_AT,
        _SOURCE_FILE,
        _PIPELINE_NAME

    from source

    where ORDER_ID is not null

)

select * from cleaned