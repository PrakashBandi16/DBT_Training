{{
    config(
        materialized='table',
        schema='gold'
    )
}}

select
    {{ dbt_utils.generate_surrogate_key(['product_id']) }} as product_key,
    product_id,
    product_name,
    category,
    subcategory,
    product_line,
    brand,
    color,
    size,
    unit_price,
    cost_price,
    supplier_id,
    profit_margin_percentage,
    is_low_stock,
    is_featured,
    launch_date

from {{ ref('stg_product') }}