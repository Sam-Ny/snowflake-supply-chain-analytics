-- ============================================================
-- Model    : stg_geolocation
-- Layer    : Silver (Staging)
-- Source   : BRONZE.RAW_GEOLOCATION
-- Description: Cleans geolocation data. Deduplicates by
--              zip code keeping average lat/long.
-- ============================================================

with source as (

    select * from {{ source('bronze', 'RAW_GEOLOCATION') }}

),

deduplicated as (

    select
        GEOLOCATION_ZIP_CODE_PREFIX             as zip_code,
        upper(trim(GEOLOCATION_STATE))          as state,
        initcap(lower(trim(GEOLOCATION_CITY)))  as city,
        round(avg(GEOLOCATION_LAT), 6)          as latitude,
        round(avg(GEOLOCATION_LNG), 6)          as longitude

    from source

    group by
        GEOLOCATION_ZIP_CODE_PREFIX,
        GEOLOCATION_STATE,
        GEOLOCATION_CITY

)

select * from deduplicated