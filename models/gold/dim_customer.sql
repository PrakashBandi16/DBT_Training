{{
    config(
        materialized='table',
        schema='gold'
    )
}}

with customer_attributes as (

    select * from {{ ref('stg_customer') }}

),

scd_tracking as (

    select
        customer_id,
        dbt_valid_from,
        dbt_valid_to
    from {{ ref('snp_customer') }}
    where dbt_valid_to is null

)

select
    {{ dbt_utils.generate_surrogate_key(['ca.customer_id']) }} as customer_key,
    ca.customer_id,
    ca.full_name,
    ca.email,
    ca.phone,
    ca.street,
    ca.city,
    ca.state,
    ca.zip_code,
    ca.country,
    ca.age,
    ca.age_segment,
    ca.loyalty_tier,
    ca.income_bracket,
    ca.registration_date,

    st.dbt_valid_from as valid_from,
    st.dbt_valid_to   as valid_to,
    case when st.dbt_valid_to is null then true else false end as is_current

from customer_attributes ca
inner join scd_tracking st
    on ca.customer_id = st.customer_id