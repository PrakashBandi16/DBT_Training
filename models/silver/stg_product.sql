{{
    config(
        materialized='view',
        schema='silver'
    )
}}

with current_products as (

    select
        raw_record,
        raw_record:product_id::string as product_id,
        raw_record:last_modified_date::date as last_modified_date,
        _loaded_at
    from {{ ref('bronze_products') }}
    qualify row_number() over (
        partition by raw_record:product_id::string
        order by raw_record:last_modified_date::date desc, _loaded_at desc
    ) = 1

),

cleaned as (

    select
        product_id,

        -- PascalCase name / category / subcategory / product_line (source is all lowercase)
        initcap(trim(raw_record:name::string))         as product_name,
        initcap(trim(raw_record:category::string))     as category,
        initcap(trim(raw_record:subcategory::string))  as subcategory,
        initcap(trim(raw_record:product_line::string)) as product_line,

        initcap(trim(raw_record:brand::string))  as brand,
        initcap(trim(raw_record:color::string))  as color,
        upper(trim(raw_record:size::string))     as size,

        raw_record:short_description::string as short_description,
        raw_record:technical_specs::string   as technical_specs,
        raw_record:dimensions::string        as dimensions,
        raw_record:weight::string            as weight,
        raw_record:warranty_period::string   as warranty_period,

        raw_record:unit_price::number(10,2)     as unit_price,
        raw_record:cost_price::number(10,2)     as cost_price,
        raw_record:stock_quantity::number       as stock_quantity,
        raw_record:reorder_level::number        as reorder_level,
        raw_record:is_featured::boolean         as is_featured,
        try_to_date(raw_record:launch_date::string) as launch_date,
        raw_record:supplier_id::string          as supplier_id,
        last_modified_date

    from current_products

)

select
    product_id,
    product_name,
    category,
    subcategory,
    product_line,
    brand,
    color,
    size,
    dimensions,
    weight,
    warranty_period,
    unit_price,
    cost_price,
    stock_quantity,
    reorder_level,
    is_featured,
    launch_date,
    supplier_id,
    last_modified_date,

    -- Full product description, per doc: name + short_description + technical_specs
    product_name || ' - ' || short_description || ' (' || technical_specs || ')' as full_description,

    -- Product hierarchy, per doc: category > subcategory > product_line
    category || ' > ' || subcategory || ' > ' || product_line as product_hierarchy,

    -- Profit margin percentage, guarded against divide-by-zero per doc's calc logic
    case
        when unit_price > 0
            then round((unit_price - cost_price) / unit_price * 100, 2)
        else null
    end as profit_margin_percentage,

    -- Low-stock flag, per doc
    case
        when stock_quantity < reorder_level then true
        else false
    end as is_low_stock

from cleaned