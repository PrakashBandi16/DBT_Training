{{
    config(
        materialized='table',
        schema='gold'
    )
}}

select
    {{ dbt_utils.generate_surrogate_key(['store_id']) }} as store_key,
    store_id,
    store_name,
    store_type,
    region,
    city,
    state,
    zip_code,
    opening_date,
    store_size_category,
    size_sq_ft,
    is_active

from {{ ref('stg_store') }}