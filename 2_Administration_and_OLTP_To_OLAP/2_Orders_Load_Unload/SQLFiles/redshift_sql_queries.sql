-- Table creation:

CREATE TABLE aws_project.orders(
    order_id bigint,
    customer_id bigint,
    seller_id bigint,
    order_date date,
    payment_method varchar(50)
)
DISTSTYLE KEY
DISTKEY (order_id)
COMPOUND SORTKEY (order_date);


-- Copying data from S3:

COPY aws_project.orders
FROM 's3://mybuck_name_is/Education_System/Orders_Files/split_data/athena_orders_manifest.json'
IAM_ROLE 'IAM_ROLE_WITH_ATLEAST_READ_ACCESS_TO_S3'
FORMAT AS CSV
DELIMITER ','
GZIP
MANIFEST;


-- Before unloading check counts:

SELECT COUNT(*) FROM aws_project.orders;-- 1,20,00,00,000
SELECT MAX(order_date) FROM aws_project.orders;-- 2030-12-31

SELECT COUNT(*)
FROM aws_project.orders
WHERE order_date < DATEADD(month, -24, TRUNC(SYSDATE));-- 47,76,97,250

SELECT COUNT(*)
FROM aws_project.orders
WHERE order_date >= DATEADD(month, -24, TRUNC(SYSDATE));-- 72,23,02,750

SELECT 722302750 + 477697250;-- 1,20,00,00,000


-- Unloading to S3:

UNLOAD ('
  SELECT *
  FROM aws_project.orders
  WHERE order_date < DATEADD(month, -24, TRUNC(SYSDATE));
')
TO 's3://mybuck_name_is/Education_System/Unload_Files_From_Redshift/'
IAM_ROLE 'IAM_ROLE_WITH_PUT_ACCESS_TO_S3'
FORMAT AS PARQUET
MANIFEST
ALLOWOVERWRITE;-- UNLOAD completed, 477697250 record(s) unloaded successfully. Took: 1m 52.7s


-- Deteting records:

DELETE
FROM aws_project.orders
WHERE order_date < DATEADD(month, -24, TRUNC(SYSDATE));-- Affected rows: 477697250, Took: 44.8s

SELECT COUNT(*) FROM aws_project.orders;-- 72,23,02,750

-- Dropping table:

DROP TABLE aws_project.orders;-- Took: 2.8s
