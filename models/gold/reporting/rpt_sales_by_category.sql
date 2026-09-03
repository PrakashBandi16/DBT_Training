{{
    config(
        materialized='view',
        schema='gold'
    )
}}

select
    dp.category,
    dp.subcategory,
    count(distinct fs.order_id)      as total_orders,
    sum(fs.quantity_sold)             as total_units_sold,
    sum(fs.total_sales_amount)        as total_sales_amount,
    sum(fs.profit_amount)             as total_profit_amount,
    round(sum(fs.profit_amount) / nullif(sum(fs.total_sales_amount), 0) * 100, 2) as profit_margin_percentage

from {{ ref('fact_sales') }} fs
inner join {{ ref('dim_product') }} dp on fs.product_key = dp.product_key

group by dp.category, dp.subcategory
order by total_sales_amount desc