{% macro create_external_table(table_name, source_folder, file_prefix) %}

    {% set ddl %}
        CREATE OR REPLACE EXTERNAL TABLE bronze.ext_{{ table_name }} (
            file_row_number NUMBER  AS (METADATA$FILE_ROW_NUMBER),
            file_name       VARCHAR AS (METADATA$FILENAME)
        )
        LOCATION = @bronze.stg_adls_capstone/Capstone_Project_Data/{{ source_folder }}/
        PATTERN = '.*{{ file_prefix }}.*[.]json'
        FILE_FORMAT = bronze.ff_json
        AUTO_REFRESH = FALSE;
    {% endset %}

    {% do run_query(ddl) %}
    {% do log("✔ Created external table: bronze.ext_" ~ table_name, info=true) %}

    {% set refresh_ddl %}
        ALTER EXTERNAL TABLE bronze.ext_{{ table_name }} REFRESH;
    {% endset %}

    {% do run_query(refresh_ddl) %}
    {% do log("✔ Refreshed metadata for: bronze.ext_" ~ table_name, info=true) %}

{% endmacro %}