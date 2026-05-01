-- ============================================================
-- Model       : dim_products
-- Layer       : Gold (Marts)
-- Description : Product dimension with English category names.
--               One row per product.
-- ============================================================

with products as (

    select * from {{ ref('stg_products') }}

),

category_translation as (

    select * from {{ ref('stg_category_translation') }}

),

joined as (

    select
        -- primary key
        p.PRODUCT_ID,

        -- category in both languages
        p.PRODUCT_CATEGORY_NAME_PORTUGUESE,
        coalesce(
            ct.CATEGORY_NAME_ENGLISH,
            p.PRODUCT_CATEGORY_NAME_PORTUGUESE
        )                                       as product_category_english,

        -- product attributes
        p.PRODUCT_NAME_LENGTH,
        p.PRODUCT_DESCRIPTION_LENGTH,
        p.PRODUCT_PHOTOS_QTY,

        -- dimensions
        p.PRODUCT_WEIGHT_G,
        p.PRODUCT_LENGTH_CM,
        p.PRODUCT_HEIGHT_CM,
        p.PRODUCT_WIDTH_CM,
        p.PRODUCT_VOLUME_CM3,

        -- size bucket
        case
            when p.PRODUCT_WEIGHT_G < 500    then 'small'
            when p.PRODUCT_WEIGHT_G < 5000   then 'medium'
            when p.PRODUCT_WEIGHT_G < 20000  then 'large'
            else 'extra_large'
        end                                     as weight_bucket

    from products p
    left join category_translation ct
        on p.PRODUCT_CATEGORY_NAME_PORTUGUESE = ct.CATEGORY_NAME_PORTUGUESE

)

select * from joined