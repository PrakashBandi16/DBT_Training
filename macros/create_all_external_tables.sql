{% macro create_all_external_tables() %}

    {% set sources = [
        {'table_name': 'customers', 'folder': 'customer_data', 'prefix': 'customers_'},
        {'table_name': 'products',  'folder': 'product_data',  'prefix': 'products_'},
        {'table_name': 'orders',    'folder': 'orders_data',   'prefix': 'orders_'},
        {'table_name': 'stores',    'folder': 'store_data',    'prefix': 'stores_'},
        {'table_name': 'employees', 'folder': 'employee_data', 'prefix': 'employees_'},
        {'table_name': 'campaigns', 'folder': 'campaign_data', 'prefix': 'campaigns_'},
        {'table_name': 'suppliers', 'folder': 'supplier_data', 'prefix': 'suppliers_'}
    ] %}

    {% for src in sources %}
        {{ create_external_table(src.table_name, src.folder, src.prefix) }}
    {% endfor %}

{% endmacro %}