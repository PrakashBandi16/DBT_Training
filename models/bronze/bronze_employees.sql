{{
    config(
        materialized='incremental',
        unique_key='employee_id',
        schema='bronze'
    )
}}

with source_data as (

    select
        flattened.value                        as raw_record,
        flattened.value:employee_id::string     as employee_id,
        ext.file_name                           as _source_file,
        ext.file_row_number                     as _source_row_number,
        current_timestamp()                     as _loaded_at,
        '{{ invocation_id }}'                   as _batch_id

    from {{ source('bronze_ext', 'ext_employees') }} as ext,
         lateral flatten(input => ext.value:employees_data) as flattened

    {% if is_incremental() %}
    where flattened.value:last_modified_date::date >
          (select coalesce(max(raw_record:last_modified_date::date), '1900-01-01') from {{ this }})
    {% endif %}

)

select * from source_data