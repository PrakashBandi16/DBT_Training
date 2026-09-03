with 

source as (

    select * from {{ source('ecom', 'raw_products') }}

),

renamed as (

    select

    from source

)

select * from renamed