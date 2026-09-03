{{
    config(
        materialized='view',
        schema='silver'
    )
}}

with current_stores as (

    select
        raw_record,
        raw_record:store_id::string as store_id,
        raw_record:last_modified_date::date as last_modified_date,
        _loaded_at
    from {{ ref('bronze_stores') }}
    qualify row_number() over (
        partition by raw_record:store_id::string
        order by raw_record:last_modified_date::date desc, _loaded_at desc
    ) = 1

),

cleaned as (

    select
        store_id,
        initcap(trim(raw_record:store_name::string)) as store_name,
        lower(trim(raw_record:store_type::string))   as store_type,
        lower(trim(raw_record:region::string))       as region,
        raw_record:manager_id::string                as manager_id,
        raw_record:employee_count::number            as employee_count,
        raw_record:is_active::boolean                as is_active,
        raw_record:size_sq_ft::number                as size_sq_ft,
        raw_record:current_sales::number(14,2)       as current_sales,
        raw_record:sales_target::number(14,2)         as sales_target,
        raw_record:monthly_rent::number(12,2)         as monthly_rent,
        try_to_date(raw_record:opening_date::string)   as opening_date,

        initcap(trim(raw_record:address:city::string))    as city,
        upper(trim(raw_record:address:state::string))      as state,
        trim(raw_record:address:zip_code::string)           as zip_code,
        initcap(trim(raw_record:address:street::string))   as street,

        raw_record:email::string        as email,
        raw_record:phone_number::string as phone_number,
        raw_record:services              as services,
        last_modified_date

    from current_stores

)

select
    store_id,
    store_name,
    store_type,
    region,
    manager_id,
    employee_count,
    is_active,
    size_sq_ft,
    current_sales,
    sales_target,
    monthly_rent,
    opening_date,
    city,
    state,
    zip_code,
    street,
    email,
    phone_number,
    services,
    last_modified_date,

    -- Store size category, per doc's exact thresholds
    case
        when size_sq_ft < 5000                       then 'Small'
        when size_sq_ft >= 5000 and size_sq_ft <= 10000 then 'Medium'
        when size_sq_ft > 10000                      then 'Large'
    end as store_size_category,

    -- Store age in years, per doc
    datediff(year, opening_date, current_date()) as store_age_years,

    -- Sales target achievement %, guarded against divide-by-zero
    case
        when sales_target > 0
            then round(current_sales / sales_target * 100, 2)
        else null
    end as sales_target_achievement_percentage,

    -- Revenue per square foot, guarded
    case
        when size_sq_ft > 0
            then round(current_sales / size_sq_ft, 2)
        else null
    end as revenue_per_sq_ft,

    -- Employee efficiency, guarded
    case
        when employee_count > 0
            then round(current_sales / employee_count, 2)
        else null
    end as employee_efficiency,

    -- Performance issue flag, per doc (achievement < 90%)
    case
        when sales_target > 0 and (current_sales / sales_target * 100) < 90 then true
        else false
    end as has_performance_issue

from cleaned