-- ============================================================
-- Model    : stg_products
-- Layer    : Silver (Staging)
-- Source   : BRONZE.RAW_PRODUCTS
-- Description: Cleans product catalog data.
-- ============================================================

with source as (

    select * from {{ source('bronze', 'RAW_PRODUCTS') }}

),

cleaned as (

    select
        -- primary key
        PRODUCT_ID,

        -- category (raw is in Portuguese — will join translation in intermediate)
        lower(trim(PRODUCT_CATEGORY_NAME))      as product_category_name_portuguese,

        -- product attributes
        PRODUCT_NAME_LENGHT                     as product_name_length,
        PRODUCT_DESCRIPTION_LENGHT              as product_description_length,
        PRODUCT_PHOTOS_QTY                      as product_photos_qty,

        -- dimensions
        PRODUCT_WEIGHT_G                        as product_weight_g,
        PRODUCT_LENGTH_CM                       as product_length_cm,
        PRODUCT_HEIGHT_CM                       as product_height_cm,
        PRODUCT_WIDTH_CM                        as product_width_cm,

        -- calculated volume
        round(
            PRODUCT_LENGTH_CM *
            PRODUCT_HEIGHT_CM *
            PRODUCT_WIDTH_CM, 2
        )                                       as product_volume_cm3,

        -- metadata
        _INGESTED_AT,
        _SOURCE_FILE,
        _PIPELINE_NAME

    from source

    where PRODUCT_ID is not null

)

select * from cleaned