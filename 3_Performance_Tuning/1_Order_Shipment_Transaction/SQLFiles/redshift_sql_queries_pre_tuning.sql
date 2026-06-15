-- Table creation: order_shipment_stg
CREATE TABLE aws_project.order_shipment_stg (
    order_id VARCHAR(50) PRIMARY KEY,
    shipment_date TIMESTAMP,
    invoice_number VARCHAR(50),
    shipment_from_city VARCHAR(100),
    shipment_to_city VARCHAR(100),
    invoice_amount DOUBLE PRECISION
)
DISTSTYLE EVEN;


COPY aws_project.order_shipment_stg
FROM 's3://mybuck_name_is/Order_Management_System/order_shipment_manifest.json'
IAM_ROLE 'IAM_ROLE_WITH_ATLEAST_READ_ACCESS_TO_S3'
FORMAT AS PARQUET
MANIFEST;--Took: 3m 20.8s
-- Load into table 'order_shipment_stg' completed, 250000000 record(s) loaded successfully.



-- Table creation: order_transaction_stg
CREATE TABLE aws_project.order_transaction_stg (
    order_id VARCHAR(50) PRIMARY KEY,
    order_date TIMESTAMP,
    customer_id VARCHAR(50),
    total_order_amount DECIMAL(18,2),
    order_discount_pct DECIMAL(5,4),
    final_order_amount DECIMAL(18,2),
    customer_name VARCHAR(150),
    customer_country VARCHAR(100),
    customer_city VARCHAR(100),
    customer_state VARCHAR(100),
    customer_credit_rating VARCHAR(50),
    customer_premium_flag VARCHAR(10)
)
DISTSTYLE KEY
DISTKEY (order_id);


COPY aws_project.order_transaction_stg
FROM 's3://mybuck_name_is/Order_Management_System/order_transaction_manifest.json'
IAM_ROLE 'IAM_ROLE_WITH_ATLEAST_READ_ACCESS_TO_S3'
FORMAT AS PARQUET
MANIFEST;--Took: 7m 52s
-- Load into table 'order_transaction_stg' completed, 250000000 record(s) loaded successfully.


SELECT
    COUNT(*)
FROM aws_project.order_transaction_stg;-- 25,00,00,000

SELECT
    *
FROM aws_project.order_transaction_stg
LIMIT
    2;
