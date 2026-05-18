CREATE TABLE default.split_orders_mpp
WITH (
    format = 'TEXTFILE',
    field_delimiter = ',',
    external_location = 's3://mybuck_name_is/Education_System/Orders_Files/split_data/',
    partitioned_by = ARRAY['orders_group']
) AS
SELECT
    t.*,
    CAST((ABS(MOD(t.order_id, 20)) + 1) AS VARCHAR) as orders_group
FROM default.orders t;
