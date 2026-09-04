{{
    config(
        materialized='view',
        schema='silver'
    )
}}

with current_customers as (

    select
        customer_id,
        raw_record,
        raw_record:last_modified_date::date as last_modified_date,
        _loaded_at
    from {{ ref('bronze_customers') }}
    qualify row_number() over (
        partition by customer_id
        order by raw_record:last_modified_date::date desc, _loaded_at desc
    ) = 1

),

cleaned as (

    select
        customer_id,

        -- Name cleanup: trim stray whitespace, standardize to Title Case
        initcap(trim(raw_record:first_name::string)) as first_name,
        initcap(trim(raw_record:last_name::string))  as last_name,
        initcap(trim(raw_record:first_name::string)) || ' ' ||
            initcap(trim(raw_record:last_name::string)) as full_name,

        -- Age calculation and segmentation
        raw_record:birth_date::string as birth_date_raw,
        case
            when try_to_date(raw_record:birth_date::string, 'YYYY-MM-DD') is not null
                then datediff(year, try_to_date(raw_record:birth_date::string, 'YYYY-MM-DD'), current_date())
            when try_to_date(raw_record:birth_date::string, 'MM/DD/YYYY') is not null
                then datediff(year, try_to_date(raw_record:birth_date::string, 'MM/DD/YYYY'), current_date())
            when try_to_date(raw_record:birth_date::string, 'MM-DD-YYYY') is not null
                then datediff(year, try_to_date(raw_record:birth_date::string, 'MM-DD-YYYY'), current_date())
            when try_to_date(raw_record:birth_date::string, 'DD-MM-YYYY') is not null
                then datediff(year, try_to_date(raw_record:birth_date::string, 'DD-MM-YYYY'), current_date())
            else null
        end as age,

        -- Email validation: keep only strings matching a basic valid pattern, else NULL
        case
            when raw_record:email::string regexp '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'
                then lower(trim(raw_record:email::string))
            else null
        end as email,
        (raw_record:email::string regexp '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') as is_email_valid,

        -- Phone normalization: strip punctuation but keep digits AND masked 'X' characters,
        -- since source data uses X to redact the final digit of some phone numbers
        case
            when length(regexp_replace(upper(raw_record:phone::string), '[^0-9X]', '')) >= 10
                then right(regexp_replace(upper(raw_record:phone::string), '[^0-9X]', ''), 10)
            else null
        end as phone,

        -- Address standardization
        initcap(trim(raw_record:address:city::string))    as city,
        upper(trim(raw_record:address:state::string))     as state,
        trim(raw_record:address:zip_code::string)          as zip_code,
        initcap(trim(raw_record:address:street::string))  as street,
        upper(trim(raw_record:address:country::string))   as country,

        -- Standardize loyalty_tier casing (source has BRONZE, bronze, Bronze inconsistently)
        upper(trim(raw_record:loyalty_tier::string)) as loyalty_tier,

        -- Pass through fields that don't need cleaning
        upper(trim(raw_record:income_bracket::string))         as income_bracket,
        raw_record:marketing_opt_in::boolean                    as marketing_opt_in,
        initcap(trim(raw_record:occupation::string))            as occupation,
        lower(trim(raw_record:preferred_communication::string)) as preferred_communication,
        lower(trim(raw_record:preferred_payment_method::string)) as preferred_payment_method,
        try_to_date(raw_record:registration_date::string)       as registration_date,
        try_to_date(raw_record:last_purchase_date::string)       as last_purchase_date,
        raw_record:total_purchases::number                      as total_purchases,
        raw_record:total_spend::number(12,2)                     as total_spend,

        last_modified_date

    from current_customers

)

select
    customer_id,
    first_name,
    last_name,
    full_name,
    age,
    case
        when age between 18 and 35 then 'Young'
        when age between 36 and 55 then 'Middle-aged'
        when age >= 56 then 'Senior'
        else null
    end as age_segment,
    email,
    is_email_valid,
    phone,
    street,
    city,
    state,
    zip_code,
    country,
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
    last_modified_date

from cleaned