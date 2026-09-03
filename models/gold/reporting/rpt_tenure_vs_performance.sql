{{
    config(
        materialized='view',
        schema='gold'
    )
}}

select
    de.employee_id,
    de.full_name,
    de.role,
    de.tenure_years,

    case
        when de.tenure_years <= 2  then '0-2 years'
        when de.tenure_years <= 5  then '3-5 years'
        when de.tenure_years <= 10 then '6-10 years'
        else '10+ years'
    end as tenure_bracket,

    count(distinct fs.order_id)  as total_orders,
    sum(fs.total_sales_amount)    as total_sales_amount,
    sum(fs.profit_amount)         as total_profit_amount,
    round(sum(fs.total_sales_amount) / nullif(count(distinct fs.order_id), 0), 2) as avg_order_value

from {{ ref('dim_employee') }} de
left join {{ ref('fact_sales') }} fs on de.employee_key = fs.employee_key

group by de.employee_id, de.full_name, de.role, de.tenure_years
order by de.tenure_years desc