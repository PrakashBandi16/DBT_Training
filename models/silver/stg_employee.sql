{{
    config(
        materialized='view',
        schema='silver'
    )
}}

with current_employees as (

    select
        raw_record,
        raw_record:employee_id::string as employee_id,
        raw_record:last_modified_date::date as last_modified_date,
        _loaded_at
    from {{ ref('bronze_employees') }}
    qualify row_number() over (
        partition by raw_record:employee_id::string
        order by raw_record:last_modified_date::date desc, _loaded_at desc
    ) = 1

),

cleaned as (

    select
        employee_id,
        initcap(trim(raw_record:first_name::string)) as first_name,
        initcap(trim(raw_record:last_name::string))  as last_name,
        initcap(trim(raw_record:first_name::string)) || ' ' ||
            initcap(trim(raw_record:last_name::string)) as full_name,

        -- Role standardization, per doc's stated examples
        case
            when lower(trim(raw_record:role::string)) = 'sales associate'  then 'Associate'
            when lower(trim(raw_record:role::string)) = 'senior manager'   then 'Senior Manager'
            when lower(trim(raw_record:role::string)) = 'store manager'   then 'Manager'
            else initcap(trim(raw_record:role::string))
        end as role,

        raw_record:work_location::string as work_location,
        try_to_date(raw_record:hire_date::string) as hire_date,

        case
            when raw_record:email::string regexp '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'
                then lower(trim(raw_record:email::string))
            else null
        end as email,

        case
            when length(regexp_replace(upper(raw_record:phone::string), '[^0-9X]', '')) >= 10
                then right(regexp_replace(upper(raw_record:phone::string), '[^0-9X]', ''), 10)
            else null
        end as phone,

        raw_record:sales_target::number(14,2)  as sales_target,
        raw_record:current_sales::number(14,2) as current_sales,
        last_modified_date

    from current_employees

),

order_aggregates as (

    select
        employee_id,
        count(distinct order_id) as orders_processed,
        sum(order_total_amount)  as total_sales_amount
    from {{ ref('stg_orders') }}
    group by employee_id

)

select
    c.employee_id,
    c.first_name,
    c.last_name,
    c.full_name,
    c.role,
    c.work_location,
    c.hire_date,
    c.email,
    c.phone,
    c.sales_target,
    c.current_sales,
    c.last_modified_date,

    -- Tenure in years, per doc
    datediff(year, c.hire_date, current_date()) as tenure_years,

    -- Target achievement %, per doc, guarded against divide-by-zero
    case
        when c.sales_target > 0
            then round(c.current_sales / c.sales_target * 100, 2)
        else null
    end as target_achievement_percentage,

    coalesce(oa.orders_processed, 0)   as orders_processed,
    coalesce(oa.total_sales_amount, 0) as total_sales_amount

from cleaned c
left join order_aggregates oa
    on c.employee_id = oa.employee_id