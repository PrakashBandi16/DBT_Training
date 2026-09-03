{{
    config(
        materialized='table',
        schema='gold'
    )
}}

select
    {{ dbt_utils.generate_surrogate_key(['employee_id']) }} as employee_key,
    employee_id,
    full_name,
    role,
    work_location,
    hire_date,
    tenure_years,
    email,
    phone

from {{ ref('stg_employee') }}