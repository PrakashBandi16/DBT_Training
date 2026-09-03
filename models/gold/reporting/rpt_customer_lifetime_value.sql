{{
    config(
        materialized='view',
        schema='gold'
    )
}}

select
    dc.customer_id,
    dc.full_name,
    dc.loyalty_tier,
    dc.age_segment,
    count(distinct fs.order_id)     as total_orders,
    sum(fs.quantity_sold)             as total_units_purchased,
    sum(fs.total_sales_amount)        as lifetime_sales_amount,
    sum(fs.profit_amount)             as lifetime_profit_amount,
    round(sum(fs.total_sales_amount) / nullif(count(distinct fs.order_id), 0), 2) as avg_order_value,
    min(dd.full_date)                 as first_order_date,
    max(dd.full_date)                 as most_recent_order_date

from {{ ref('fact_sales') }} fs
inner join {{ ref('dim_customer') }} dc on fs.customer_key = dc.customer_key
inner join {{ ref('dim_date') }} dd     on fs.date_key      = dd.date_key

group by dc.customer_id, dc.full_name, dc.loyalty_tier, dc.age_segment
order by lifetime_sales_amount desc