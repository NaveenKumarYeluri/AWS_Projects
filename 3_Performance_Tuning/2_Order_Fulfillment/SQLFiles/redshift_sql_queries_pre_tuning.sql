-- Table creation: order_fulfillment_stg
CREATE TABLE aws_project.order_fulfillment_stg (
    fc_id VARCHAR(50) PRIMARY KEY,
    fc_release_to_mfg_date TIMESTAMP,
    fc_release_to_mfg_count INTEGER,
    fc_arrival_from_mfg_date TIMESTAMP,
    fc_arrival_from_mfg_count INTEGER,
    fc_inspection_date TIMESTAMP,
    fc_mfg_facility_id VARCHAR(50),
    fc_release_to_shipment_date TIMESTAMP,
    mfg_facility_id VARCHAR(50),
    to_mfg_facility_arrival_date TIMESTAMP,
    from_mfg_facility_departure_date TIMESTAMP,
    mfg_facility_input_count INTEGER,
    mfg_facility_output_count INTEGER,
    mfg_facility_backlog_count INTEGER,
    mfg_facility_product_capability_count INTEGER
)
DISTSTYLE KEY
DISTKEY (fc_id);


-- Copying data from S3:
COPY aws_project.order_fulfillment_stg
FROM 's3://mybuck_name_is/Order_Management_System/'
IAM_ROLE 'IAM_ROLE_WITH_ATLEAST_READ_ACCESS_TO_S3'
FORMAT AS csv
DELIMITER ','
IGNOREHEADER 1;--Took: 15m 29.8s
-- Load into table 'order_fulfillment_stg' completed, 250000000 record(s) loaded successfully.


SELECT
    COUNT(*)
FROM aws_project.order_fulfillment_stg;-- 25,00,00,000


SELECT
    *
FROM aws_project.order_fulfillment_stg
LIMIT
    2;
