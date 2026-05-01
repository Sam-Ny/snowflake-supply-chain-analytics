-- ============================================================
-- Model    : stg_sellers
-- Layer    : Silver (Staging)
-- Source   : BRONZE.RAW_SELLERS
-- Description: Cleans seller data.
-- ============================================================

with source as (

    select * from {{ source('bronze', 'RAW_SELLERS') }}

),

cleaned as (

    select
        -- primary key
        SELLER_ID,

        -- location
        SELLER_ZIP_CODE_PREFIX                  as seller_zip_code,
        initcap(lower(trim(SELLER_CITY)))       as seller_city,
        upper(trim(SELLER_STATE))               as seller_state,

        -- metadata
        _INGESTED_AT,
        _SOURCE_FILE,
        _PIPELINE_NAME

    from source

    where SELLER_ID is not null

)

select * from cleaned