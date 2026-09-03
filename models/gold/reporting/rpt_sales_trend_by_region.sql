{{
    config(
        materialized='view',
        schema='gold'
    )
}}

select
    fs.region,
    dd.year,
    dd.month,
    dd.full_date,
    count(distinct fs.order_id)  as total_orders,
    sum(fs.total_sales_amount)    as total_sales_amount,
    sum(fs.profit_amount)         as total_profit_amount

from {{ ref('fact_sales') }} fs
inner join {{ ref('dim_date') }} dd on fs.date_key = dd.date_key

group by fs.region, dd.year, dd.month, dd.full_date
order by fs.region, dd.full_date