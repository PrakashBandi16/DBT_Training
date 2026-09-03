{{
    config(
        materialized='table',
        schema='gold'
    )
}}

with line_items as (

    select * from {{ ref('stg_order_items') }}

)

select
        {{ dbt_utils.generate_surrogate_key(['li.order_id', 'li.product_id', 'li.line_sequence']) }} as sales_key,

    li.order_id,

    dc.customer_key,
    dp.product_key,
    ds.store_key,
    dd.date_key,
    de.employee_key,

    li.quantity                as quantity_sold,
    li.unit_price,
    (li.quantity * li.unit_price)              as total_sales_amount,
    (li.quantity * li.cost_price)              as cost_amount,
    li.item_discount_amount    as discount_amount,
    li.shipping_cost,
    li.line_profit_amount      as profit_amount,

    ds.region,
    li.order_source            as sales_channel,
    dc.loyalty_tier            as customer_segment

from line_items li
left join {{ ref('dim_customer') }} dc on li.customer_id = dc.customer_id
left join {{ ref('dim_product') }} dp  on li.product_id  = dp.product_id
left join {{ ref('dim_store') }} ds    on li.store_id     = ds.store_id
left join {{ ref('dim_date') }} dd     on cast(li.order_date as date) = dd.full_date
left join {{ ref('dim_employee') }} de on li.employee_id  = de.employee_id