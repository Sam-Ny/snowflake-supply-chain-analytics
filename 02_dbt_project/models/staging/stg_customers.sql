-- ============================================================
-- Model    : stg_customers
-- Layer    : Silver (Staging)
-- Source   : BRONZE.RAW_CUSTOMERS
-- Description: Cleans customer data. This table is the target
--              for SCD Type 2 snapshot in next phase.
-- ============================================================

with source as (

    select * from {{ source('bronze', 'RAW_CUSTOMERS') }}

),

cleaned as (

    select
        -- primary key
        CUSTOMER_ID,

        -- unique customer identifier (one customer can have many orders)
        CUSTOMER_UNIQUE_ID,

        -- location
        CUSTOMER_ZIP_CODE_PREFIX                as customer_zip_code,
        initcap(lower(trim(CUSTOMER_CITY)))     as customer_city,
        upper(trim(CUSTOMER_STATE))             as customer_state,

        -- metadata
        _INGESTED_AT,
        _SOURCE_FILE,
        _PIPELINE_NAME

    from source

    where CUSTOMER_ID is not null

)

select * from cleaned