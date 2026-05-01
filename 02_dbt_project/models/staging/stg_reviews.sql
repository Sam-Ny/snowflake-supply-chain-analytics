-- ============================================================
-- Model    : stg_reviews
-- Layer    : Silver (Staging)
-- Source   : BRONZE.RAW_REVIEWS
-- Description: Cleans review data, adds sentiment bucket
--              based on review score.
-- ============================================================

with source as (

    select * from {{ source('bronze', 'RAW_REVIEWS') }}

),

cleaned as (

    select
        -- primary key
        REVIEW_ID,
        ORDER_ID,

        -- review details (cast to int — stored as TEXT in Bronze)
        try_to_number(REVIEW_SCORE)                                 as review_score,

        -- sentiment
        case
            when try_to_number(REVIEW_SCORE) >= 4 then 'positive'
            when try_to_number(REVIEW_SCORE) = 3  then 'neutral'
            when try_to_number(REVIEW_SCORE) <= 2 then 'negative'
            else 'unknown'
        end                                                         as review_sentiment,

        -- text fields
        REVIEW_COMMENT_TITLE                                        as review_title,
        REVIEW_COMMENT_MESSAGE                                      as review_message,

        -- timestamps (stored as VARCHAR)
        try_to_timestamp(REVIEW_CREATION_DATE, 'YYYY-MM-DD HH24:MI:SS')    as review_created_at,
        try_to_timestamp(REVIEW_ANSWER_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS') as review_answered_at,

        -- metadata
        _INGESTED_AT,
        _SOURCE_FILE,
        _PIPELINE_NAME

    from source

    where REVIEW_ID is not null
      and ORDER_ID is not null

)

select * from cleaned