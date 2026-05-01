-- ============================================================
-- Model    : stg_category_translation
-- Layer    : Silver (Staging)
-- Source   : BRONZE.RAW_CATEGORY_TRANSLATION
-- Description: Portuguese to English product category mapping.
-- ============================================================

with source as (

    select * from {{ source('bronze', 'RAW_CATEGORY_TRANSLATION') }}

),

cleaned as (

    select
        lower(trim(PRODUCT_CATEGORY_NAME))             as category_name_portuguese,
        lower(trim(PRODUCT_CATEGORY_NAME_ENGLISH))             as category_name_english

    from source

    where PRODUCT_CATEGORY_NAME is not null

)

select * from cleaned