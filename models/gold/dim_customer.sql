{{
    config(
        materialized='table',
        schema='gold'
    )
}}

select
    {{ dbt_utils.generate_surrogate_key(['customer_id', 'dbt_valid_from']) }} as customer_key,

    customer_id,
    full_name,
    email,
    is_email_valid,
    phone,
    street,
    city,
    state,
    zip_code,
    country,
    age,
    age_segment,
    loyalty_tier,
    income_bracket,
    marketing_opt_in,
    occupation,
    preferred_communication,
    preferred_payment_method,
    registration_date,
    last_purchase_date,
    total_purchases,
    total_spend,
    last_modified_date,

    dbt_valid_from as valid_from,
    dbt_valid_to   as valid_to,
    case when dbt_valid_to is null then true else false end as is_current

from {{ ref('snp_customer') }}