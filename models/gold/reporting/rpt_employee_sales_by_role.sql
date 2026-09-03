{{
    config(
        materialized='view',
        schema='gold'
    )
}}

select
    de.role,
    count(distinct de.employee_id)   as employee_count,
    count(distinct fs.order_id)       as total_orders,
    sum(fs.quantity_sold)              as total_units_sold,
    sum(fs.total_sales_amount)         as total_sales_amount,
    sum(fs.profit_amount)              as total_profit_amount,
    round(sum(fs.total_sales_amount) / nullif(count(distinct de.employee_id), 0), 2) as avg_sales_per_employee

from {{ ref('dim_employee') }} de
left join {{ ref('fact_sales') }} fs on de.employee_key = fs.employee_key

group by de.role
order by total_sales_amount desc