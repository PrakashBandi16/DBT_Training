{% snapshot snp_customer %}

{{
    config(
        target_schema='silver',
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='last_modified_date'
    )
}}

select * from {{ ref('stg_customer') }}

{% endsnapshot %}