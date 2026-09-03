{{
    config(
        materialized='view',
        schema='gold'
    )
}}

with order_level as (

    select
        dc.customer_id,
        dc.full_name,
        fs.order_id,
        sum(fs.total_sales_amount)   as order_amount,
        sum(fs.quantity_sold)         as order_units,
        max(fs.sales_channel)         as sales_channel,
        max(so.order_time_of_day)     as order_time_of_day

    from {{ ref('fact_sales') }} fs
    inner join {{ ref('dim_customer') }} dc on fs.customer_key = dc.customer_key
    inner join {{ ref('stg_orders') }} so     on fs.order_id    = so.order_id

    group by dc.customer_id, dc.full_name, fs.order_id
)

select
    customer_id,
    full_name,
    count(distinct order_id)                    as total_orders,
    sum(order_units)                             as total_units_purchased,
    sum(order_amount)                            as total_sales_amount,
    round(avg(order_amount), 2)                  as avg_order_value,
    mode(sales_channel)                          as preferred_sales_channel,
    mode(order_time_of_day)                      as preferred_shopping_time

from order_level
group by customer_id, full_name
order by total_sales_amount desc
