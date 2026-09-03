{{
    config(
        materialized='table',
        schema='gold'
    )
}}

with date_spine as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2024-04-01' as date)",
        end_date="cast('2024-09-28' as date)"
    ) }}

),

renamed as (

    select
        date_day::date as full_date
    from date_spine

),

enriched as (

    select
        full_date,

        -- Surrogate key, per doc
        {{ dbt_utils.generate_surrogate_key(['full_date']) }} as date_key,

        year(full_date)     as year,
        quarter(full_date)  as quarter,
        month(full_date)    as month,
        week(full_date)     as week,
        dayofweek(full_date) as day_of_week,
        dayname(full_date)   as day_name,

        -- US Holiday flag, per doc. Only observed federal holidays that fall inside our date window (Apr-Sep 2024) are relevant.
case
    when full_date in (
        '2024-05-27',  -- Memorial Day
        '2024-06-19',  -- Juneteenth
        '2024-07-04',  -- Independence Day
        '2024-09-02'   -- Labor Day
    ) then true
    else false
end as holiday_flag,

        -- Season, per standard meteorological definition
        case
            when month(full_date) in (3, 4, 5)   then 'Spring'
            when month(full_date) in (6, 7, 8)   then 'Summer'
            when month(full_date) in (9, 10, 11) then 'Fall'
            else 'Winter'
        end as season

    from renamed

)

select * from enriched