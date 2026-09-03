{{
    config(
        materialized='incremental',
        unique_key='order_id',
        schema='bronze'
    )
}}

with source_data as (

    select
        flattened.value                        as raw_record,
        flattened.value:order_id::string        as order_id,
        flattened.value:order_date::timestamp   as order_date,
        ext.file_name                           as _source_file,
        ext.file_row_number                     as _source_row_number,
        current_timestamp()                     as _loaded_at,
        '{{ invocation_id }}'                   as _batch_id

    from {{ source('bronze_ext', 'ext_orders') }} as ext,
         lateral flatten(input => ext.value:orders_data) as flattened

    {% if is_incremental() %}
    where flattened.value:order_date::timestamp >
          (select coalesce(max(order_date), '1900-01-01'::timestamp) from {{ this }})
    {% endif %}

)

select * from source_data