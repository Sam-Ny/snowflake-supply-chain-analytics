-- ============================================================
-- Model       : dim_sellers
-- Layer       : Gold (Marts)
-- Description : Seller dimension with geolocation.
--               One row per seller.
-- ============================================================

with sellers as (

    select * from {{ ref('stg_sellers') }}

),

geolocation as (

    select * from {{ ref('stg_geolocation') }}

),

joined as (

    select
        -- primary key
        s.SELLER_ID,

        -- location
        s.SELLER_ZIP_CODE,
        s.SELLER_CITY,
        s.SELLER_STATE,

        -- geolocation
        g.LATITUDE                              as seller_latitude,
        g.LONGITUDE                             as seller_longitude

    from sellers s
    left join geolocation g
        on s.SELLER_ZIP_CODE = g.ZIP_CODE

)

select * from joined