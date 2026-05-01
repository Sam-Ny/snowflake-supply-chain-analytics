-- ============================================================
-- Model       : dim_date
-- Layer       : Gold (Marts)
-- Description : Date dimension generated from order dates.
--               No source table needed — generated via SQL.
--               Covers full date range of Olist dataset.
-- ============================================================

with date_spine as (

    select
        dateadd(day, seq4(), '2016-01-01'::date) as date_day
    from table(generator(rowcount => 2000))

),

final as (

    select
        -- primary key
        to_number(to_char(date_day, 'YYYYMMDD'))    as date_id,
        date_day,

        -- date parts
        year(date_day)                              as year,
        month(date_day)                             as month,
        day(date_day)                               as day,
        quarter(date_day)                           as quarter,
        weekofyear(date_day)                        as week_of_year,
        dayofweek(date_day)                         as day_of_week,

        -- date labels
        to_char(date_day, 'MMMM')                  as month_name,
        to_char(date_day, 'DY')                     as day_name,
        to_char(date_day, 'YYYY-MM')               as year_month,

        -- flags
        case
            when dayofweek(date_day) in (0, 6)
            then true else false
        end                                         as is_weekend,

        case
            when month(date_day) in (11, 12, 1)
            then true else false
        end                                         as is_peak_season

    from date_spine
    where date_day <= '2022-12-31'

)

select * from final