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
    fs.region,
    count(distinct fs.order_id)  as total_orders,
    sum(fs.total_sales_amount)    as total_sales_amount,
    sum(fs.profit_amount)         as total_profit_amount,
    rank() over (partition by fs.region order by sum(fs.total_sales_amount) desc) as region_sales_rank

from {{ ref('fact_sales') }} fs
inner join {{ ref('dim_employee') }} de on fs.employee_key = de.employee_key

group by de.employee_id, de.full_name, de.role, fs.region
order by fs.region, region_sales_rank