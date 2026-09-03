{% snapshot snp_customer %}

{{
    config(
        target_schema='silver',
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='last_modified_date'
    )
}}

select
    customer_id,
    raw_record,
    raw_record:last_modified_date::date as last_modified_date

from {{ ref('bronze_customers') }}

qualify row_number() over (
    partition by customer_id
    order by raw_record:last_modified_date::date desc, _loaded_at desc
) = 1

{% endsnapshot %}