{{
    config(
        materialized='view',
        schema='silver'
    )
}}

with aggregated as (

    select
        order_id,
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

        count(product_id)               as total_items,
        sum(quantity)                   as total_quantity,
        sum(quantity * unit_price)       as gross_revenue,
        sum(line_revenue)                as net_line_revenue,
        sum(line_cost)                   as total_cost,
        sum(item_discount_amount)        as total_item_discount,
        max(item_discount_amount)        as _sample_item_discount -- diagnostic only, not used downstream

    from {{ ref('stg_order_items') }}

    group by order_id, customer_id, employee_id, store_id, campaign_id,
             order_date, shipping_date, delivery_date, estimated_delivery_date,
             order_source, order_status, payment_method, shipping_method, shipping_state

)

select
    a.*,

    -- Pull shipping_cost / tax_amount / order_discount_amount from the header (any single line-item row has them)
       -- Pull shipping_cost / tax_amount / order_discount_amount from the header (any single line-item row has them)
      -- Pull shipping_cost / tax_amount / order_discount_amount / order_total_amount from the header
    o.shipping_cost,
    o.tax_amount,
    o.order_discount_amount,
    o.order_total_amount,
    -- Order-level profitability: net line revenue minus cost minus shipping (tax excluded from profit, it's a passthrough)
    (a.net_line_revenue - a.total_cost - o.shipping_cost) as profit_amount,

    case
        when a.net_line_revenue > 0
            then round((a.net_line_revenue - a.total_cost - o.shipping_cost) / a.net_line_revenue * 100, 2)
        else null
    end as profit_margin_percentage,

    -- Order time-of-day, per the doc's half-open hour ranges
    hour(a.order_date) as order_hour,
    case
        when hour(a.order_date) >= 5  and hour(a.order_date) < 12 then 'Morning'
        when hour(a.order_date) >= 12 and hour(a.order_date) < 17 then 'Afternoon'
        when hour(a.order_date) >= 17 and hour(a.order_date) < 22 then 'Evening'
        else 'Night'
    end as order_time_of_day,

    -- Calendar breakdowns
    date_trunc('week', a.order_date)::date  as order_week,
    date_trunc('month', a.order_date)::date as order_month,
    quarter(a.order_date)                    as order_quarter,
    year(a.order_date)                       as order_year,

    -- Shipping efficiency metrics, per doc
    datediff(day, a.order_date, a.shipping_date)  as processing_days,
    datediff(day, a.shipping_date, a.delivery_date) as shipping_days,
    case
        when a.delivery_date is not null and a.delivery_date <= a.estimated_delivery_date then 'On Time'
        when a.delivery_date is not null and a.delivery_date >  a.estimated_delivery_date then 'Delayed'
        when a.delivery_date is null and current_date() > a.estimated_delivery_date then 'Potentially Delayed'
        else 'In Transit'
    end as delivery_status

from aggregated a
inner join {{ ref('stg_order_items') }} o
    on a.order_id = o.order_id
qualify row_number() over (partition by a.order_id order by o.product_id) = 1