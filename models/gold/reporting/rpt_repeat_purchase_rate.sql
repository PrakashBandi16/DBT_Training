{{
    config(
        materialized='view',
        schema='gold'
    )
}}

with customer_order_counts as (

    select
        dc.customer_id,
        count(distinct fs.order_id) as total_orders
    from {{ ref('fact_sales') }} fs
    inner join {{ ref('dim_customer') }} dc on fs.customer_key = dc.customer_key
    group by dc.customer_id

)

select
    count(*)                                              as total_purchasing_customers,
    count(case when total_orders > 1 then 1 end)           as repeat_customers,
    count(case when total_orders = 1 then 1 end)           as one_time_customers,
    round(count(case when total_orders > 1 then 1 end) / nullif(count(*), 0) * 100, 2) as repeat_purchase_rate_percentage

from customer_order_counts