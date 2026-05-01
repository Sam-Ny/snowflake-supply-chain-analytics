-- ============================================================
-- Model    : stg_geolocation
-- Layer    : Silver (Staging)
-- Source   : BRONZE.RAW_GEOLOCATION
-- Description: Cleans geolocation data. Deduplicates by
--              zip code only — one row per zip code.
-- ============================================================

with source as (

    select * from {{ source('bronze', 'RAW_GEOLOCATION') }}

),

deduplicated as (

    select
        GEOLOCATION_ZIP_CODE_PREFIX             as zip_code,
        -- take the most common state and city per zip
        mode(GEOLOCATION_STATE)                 as state,
        mode(GEOLOCATION_CITY)                  as city,
        round(avg(GEOLOCATION_LAT), 6)          as latitude,
        round(avg(GEOLOCATION_LNG), 6)          as longitude

    from source

    group by GEOLOCATION_ZIP_CODE_PREFIX

)

select * from deduplicated