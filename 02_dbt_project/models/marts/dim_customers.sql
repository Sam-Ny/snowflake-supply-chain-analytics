-- ============================================================
-- Model       : dim_customers
-- Layer       : Gold (Marts)
-- Description : Customer dimension table. Pulls current
--               record from SCD Type 2 snapshot.
--               One row per unique customer.
-- ============================================================

with snapshot as (

    select * from {{ ref('customers_snapshot') }}

),

current_customers as (

    select
        -- surrogate key
        DBT_SCD_ID                              as customer_surrogate_key,

        -- natural key
        CUSTOMER_ID,
        CUSTOMER_UNIQUE_ID,

        -- location
        CUSTOMER_ZIP_CODE,
        CUSTOMER_CITY,
        CUSTOMER_STATE,

        -- SCD tracking
        DBT_VALID_FROM                          as valid_from,
        DBT_VALID_TO                            as valid_to,

        -- current record flag
        case
            when DBT_VALID_TO = to_date('9999-12-31')
            then true
            else false
        end                                     as is_current

    from snapshot

)

select * from current_customers