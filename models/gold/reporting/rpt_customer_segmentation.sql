{{
    config(
        materialized='view',
        schema='gold'
    )
}}

select
    dc.loyalty_tier,
    dc.age_segment,
    dc.income_bracket,
    count(distinct dc.customer_id)     as customer_count,
    count(distinct fs.order_id)         as total_orders,
    sum(fs.total_sales_amount)          as total_sales_amount,
    round(avg(fs.total_sales_amount), 2) as avg_sale_amount,
    round(sum(fs.total_sales_amount) / nullif(count(distinct dc.customer_id), 0), 2) as sales_per_customer

from {{ ref('dim_customer') }} dc
left join {{ ref('fact_sales') }} fs on dc.customer_key = fs.customer_key

group by dc.loyalty_tier, dc.age_segment, dc.income_bracket
order by total_sales_amount desc