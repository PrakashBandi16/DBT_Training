{{
    config(
        materialized='view',
        schema='gold'
    )
}}

select
    dp.product_id,
    dp.product_name,
    dp.category,
    dp.brand,
    sum(fs.quantity_sold)          as total_units_sold,
    sum(fs.total_sales_amount)      as total_sales_amount,
    sum(fs.profit_amount)           as total_profit_amount,
    count(distinct fs.order_id)     as total_orders,
    rank() over (order by sum(fs.total_sales_amount) desc) as sales_rank

from {{ ref('fact_sales') }} fs
inner join {{ ref('dim_product') }} dp on fs.product_key = dp.product_key

group by dp.product_id, dp.product_name, dp.category, dp.brand
order by total_sales_amount desc

