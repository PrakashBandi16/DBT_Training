{{
    config(
        materialized='view',
        schema='silver'
    )
}}

with orders_header as (

    select
        raw_record:order_id::string             as order_id,
        raw_record:customer_id::string           as customer_id,
        raw_record:employee_id::string           as employee_id,
        raw_record:store_id::string              as store_id,
        raw_record:campaign_id::string           as campaign_id,
        raw_record:order_date::timestamp         as order_date,
        raw_record:shipping_date::timestamp      as shipping_date,
        raw_record:delivery_date::timestamp      as delivery_date,
        raw_record:estimated_delivery_date::timestamp as estimated_delivery_date,
        raw_record:order_source::string          as order_source,
        raw_record:order_status::string          as order_status,
        raw_record:payment_method::string        as payment_method,
        raw_record:shipping_method::string       as shipping_method,
        raw_record:shipping_cost::number(10,2)   as shipping_cost,
        raw_record:tax_amount::number(10,2)      as tax_amount,
        raw_record:discount_amount::number(10,2) as order_discount_amount,
        raw_record:total_amount::number(12,2)    as order_total_amount,
        raw_record:shipping_address:state::string as shipping_state,
        raw_record:shipping_address:city::string  as shipping_city,
        raw_record:order_items                   as order_items
    from {{ ref('bronze_orders') }}

),

line_items as (

    select
        oh.order_id,
        oh.customer_id,
        oh.employee_id,
        oh.store_id,
        oh.campaign_id,
        oh.order_date,
        oh.shipping_date,
        oh.delivery_date,
        oh.estimated_delivery_date,
        oh.order_source,
        oh.order_status,
        oh.payment_method,
        oh.shipping_method,
        oh.shipping_cost,
        oh.tax_amount,
        oh.order_discount_amount,
         oh.shipping_state,
        oh.order_total_amount,
        item.value:product_id::string           as product_id,
        item.value:quantity::number               as quantity,
        item.value:unit_price::number(10,2)        as unit_price,
        item.value:cost_price::number(10,2)        as cost_price,
        item.value:discount_amount::number(10,2)   as item_discount_amount

    from orders_header oh,
         lateral flatten(input => oh.order_items) as item

)

select
    order_id,
    product_id,
    customer_id,
    employee_id,
    store_id,
    campaign_id,
    order_date,
    shipping_date,
    delivery_date,
    estimated_delivery_date,
    order_source,
    order_status,
    payment_method,
    shipping_method,
    shipping_state,
    shipping_cost,
    tax_amount,
    order_discount_amount,
    order_total_amount,
    quantity,
    unit_price,
    cost_price,   row_number() over (
        partition by order_id, product_id
        order by quantity
    ) as line_sequence,
    item_discount_amount,

    -- Line-level revenue and cost (discount applied as a dollar deduction, confirmed against total_amount math)
    (quantity * unit_price) - item_discount_amount as line_revenue,
    quantity * cost_price                          as line_cost,

    -- Line-level profit: revenue - cost. Shipping/tax are order-level, not allocated per line here.
    ((quantity * unit_price) - item_discount_amount) - (quantity * cost_price) as line_profit_amount,

    case
        when (quantity * unit_price) - item_discount_amount > 0
            then round((((quantity * unit_price) - item_discount_amount) - (quantity * cost_price))
                       / ((quantity * unit_price) - item_discount_amount) * 100, 2)
        else null
    end as line_profit_margin_percentage
     

from line_items