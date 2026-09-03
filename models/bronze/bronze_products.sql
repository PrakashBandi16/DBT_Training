{{
    config(
        materialized='incremental',
        unique_key='product_id',
        schema='bronze'
    )
}}

with source_data as (

    select
        flattened.value                       as raw_record,
        flattened.value:product_id::string     as product_id,
        ext.file_name                          as _source_file,
        ext.file_row_number                    as _source_row_number,
        current_timestamp()                    as _loaded_at,
        '{{ invocation_id }}'                  as _batch_id

    from {{ source('bronze_ext', 'ext_products') }} as ext,
         lateral flatten(input => ext.value:products_data) as flattened

    {% if is_incremental() %}
    where flattened.value:last_modified_date::date >
          (select coalesce(max(raw_record:last_modified_date::date), '1900-01-01') from {{ this }})
    {% endif %}

)

select * from source_data