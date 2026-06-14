-- pct_used: Percentage of total storage used by this table
-- skew_rows: Ratio of rows on the most populated compute partition vs. the least populated.
    -- 1.00 -> Perfect distribution
    -- 1.20 -> Good distribution
    -- 5.00 or higher -> This means DISTKEY is flawed, and one invisible compute node is doing 5x the work of the others, creating a massive bottleneck.
-- diststyle: type of distribution key
-- skew_sortkey1: Ratio of the size of the un-sorted region to the sorted region
    -- 1.00 -> Perfectly sorted according to the SORT KEY.
    -- If this number starts growing high, it means you have loaded a lot of new data and Redshift hasn't sorted it yet. We would run a VACUUM command to fix this, though Serverless often auto-vacuums in the background.
SELECT
    database,
    schema AS table_schema,
    table_id,
    "table" AS table_name,
    encoded,
    diststyle,
    sortkey1,
    skew_rows,
    skew_sortkey1,
    "size" as size_mb,
    pct_used
FROM svv_table_info
WHERE
    table_name IN ('order_fulfillment_stg', 'order_shipment_stg'
    , 'order_transaction_stg')
ORDER BY
    skew_rows DESC;

/*
table_name              encoded                 diststyle       sortkey1        skew_rows   skew_sortkey1   size_mb     pct_used
order_shipment_stg      Y, AUTO(ENCODE)         EVEN            AUTO(SORTKEY)   NULL        NULL            13440       0.021
order_fulfillment_stg   Y, AUTO(ENCODE)         KEY(fc_id)      AUTO(SORTKEY)   1.16        NULL            16327       0.0255
order_transaction_stg   Y, AUTO(ENCODE)         KEY(order_id)   AUTO(SORTKEY)   1.01        NULL            17152       0.0268
*/


-- stats_off: db statistics, since it is 0 stats are fine i.e., they are up-to-date
-- unsorted: if we have any unsorted data or not, since 0 fine
-- empty: if we have empty blocks or not, since 0 fine
SELECT
    "table" AS table_name,
    unsorted,
    stats_off,
    empty
FROM svv_table_info
WHERE
    "table" IN ('order_fulfillment_stg', 'order_shipment_stg'
    , 'order_transaction_stg')
ORDER BY
    skew_rows DESC;


table_name	unsorted	stats_off	empty
order_shipment_stg	NULL	0	0
order_fulfillment_stg	NULL	0	0
order_transaction_stg	NULL	0	0



-- Check compression.
SET SEARCH_PATH TO 'aws_project';
SELECT
    tablename,
    "column",
    type,
    encoding
FROM pg_table_def
WHERE
    tablename IN ('order_fulfillment_stg', 'order_shipment_stg'
    , 'order_transaction_stg')
ORDER BY
    tablename, "column";



SELECT
    "table" AS table_name,
    tbl_rows AS total_records,
    size AS total_megabytes,
    -- Calculate how many records fit in 1 MB
    CASE
        WHEN size > 0 THEN (tbl_rows / size)
        ELSE 0
    END AS records_per_mb
FROM svv_table_info
WHERE "schema" = 'aws_project'
    AND "table" IN ('order_fulfillment_stg', 'order_shipment_stg'
    , 'order_transaction_stg');


/*
table_name	             total_records   total_megabytes    records_per_mb
order_fulfillment_stg    250000000       16327              15312.0597
order_transaction_stg    250000000       17152              14575.5597
order_shipment_stg       250000000       13440              18601.1904
*/


-- Column level metadata. Useful for column level metadata.
SET SEARCH_PATH TO 'aws_project';
SELECT
    *
FROM pg_table_def
WHERE
    schemaname = 'aws_project'
    AND tablename IN ('order_fulfillment_stg', 'order_shipment_stg'
    , 'order_transaction_stg')
ORDER BY
    tablename;


-- Using DuckDB to check how data is spread.

SELECT
    COUNT(DISTINCT customer_name)
FROM aws_project.order_transaction_stg;-- 2,18,593

SELECT
    COUNT(DISTINCT customer_id)
FROM aws_project.order_transaction_stg;--2,18,593


-- We have 2 Lakh 20 Thousand customers against 25,00,00,000 transactions. We will try to create new table with only customers data.

SELECT
  DISTINCT customer_id
  , customer_name
  , customer_country
  , customer_city
  , customer_state
  , customer_credit_rating
  , customer_premium_flag
FROM aws_project.order_transaction_stg;
-- This query is crashing in Google Colab as DuckDB is using full memory.
-- Tried multiple ways to limit but thy are not working. Finally has to CREATE a table and see the count.


CREATE TABLE aws_project.customers_tmp AS
SELECT DISTINCT
    customer_id,
    customer_name,
    customer_country,
    customer_city,
    customer_state,
    customer_credit_rating,
    customer_premium_flag
FROM aws_project.order_transaction_stg;-- 25,00,00,000
-- Welcome!
-- You can guess what that count means.


-- We will check how Shipment table is.

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM aws_project.order_shipment_stg;

/*
total_rows  unique_orders
250000000   249999041
*/


CREATE TABLE aws_project.temp_counts AS (
    SELECT
        order_id,
        COUNT(*) AS row_count,
        COUNT(DISTINCT invoice_number) AS unique_invoices
    FROM aws_project.order_shipment_stg
    GROUP BY
        order_id
    HAVING
        COUNT(*) > 1
);



SELECT *
FROM aws_project.temp_counts
ORDER BY
    unique_invoices DESC;-- 959 records.
-- These 959 records have same order id and they are not related.
-- Eg:
SELECT
    *
FROM aws_project.order_shipment_stg
WHERE
    order_id = 'ORD#259286001953';

order_id            shipment_date               invoice_number  shipment_from_city  shipment_to_city    invoice_amount
ORD#259286001953    2024-01-20 10:06:41.698744  WWGU2014-821    Maywood             Tigard              4145.7305
ORD#259286001953    2023-08-01 03:19:18.920112  VUOL6949-371    Cocoa               Poplar Bluff        3959.0195
-- So as per that, we will be removing 959 records from order_shipment_stg, by keeping only latest shipment records.


CREATE TABLE aws_project.order_shipment_stg_clean AS
SELECT * FROM (
    SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY shipment_date DESC) as rn
    FROM aws_project.order_shipment_stg
) WHERE rn = 1;--Took: 6m 58s


SELECT COUNT(*) FROM aws_project.order_shipment_stg_clean;-- 24,99,99,041


-- Instead of taking rn = 1 from above table we will try another method and see how it takes.
CREATE TABLE aws_project.order_shipment_stg_clean_2 AS
(
    SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY shipment_date DESC) as rn
    FROM aws_project.order_shipment_stg
);--Took: 2m 55.1s

SELECT * FROM aws_project.order_shipment_stg_clean_2 WHERE rn = 2; -- 959 records


-- Taking a backup so I can have full data incase something goes wrong.
CREATE TABLE aws_project.order_shipment_stg_backup AS (
    SELECT *
    FROM aws_project.order_shipment_stg
);--Took: 2m 58.8s


SELECT
    *
FROM aws_project.order_shipment_stg_clean_2
WHERE
    rn = 2;-- 959 records


DELETE
FROM aws_project.order_shipment_stg
WHERE EXISTS (
    SELECT
        1
    FROM aws_project.order_shipment_stg_clean_2 AS c
    WHERE
        c.order_id = aws_project.order_shipment_stg.order_id
        AND c.invoice_number = aws_project.order_shipment_stg.invoice_number
        AND c.rn = 2
);--Took: 959 records (10s)


VACUUM DELETE ONLY aws_project.order_shipment_stg;--Took: 1.8s
VACUUM FULL aws_project.order_shipment_stg;--Took: 57.9s


SELECT
    COUNT(*)
FROM aws_project.order_shipment_stg_clean;-- 24,99,99,041
SELECT
    COUNT(*)
FROM aws_project.order_shipment_stg;-- 24,99,99,041
SELECT
    COUNT(*)
FROM aws_project.order_shipment_stg_backup;-- 25,00,00,000


/*
It seems like, table from RANK function + rn = 1 took ~7mins
Where as, backup + table from RANK function + DELETE took ~6 mins on top it we have clean data in our stg table itself.
We will drop unwanted tables now since _stg has proper data.
*/

-- Now our order_shipment_stg table is clean with no duplicate order_id's.
-- Our order_transaction_stg table has same 25 crore records and we cannot make use of snowflake, there is no use of creating customer table because the records are very much unique.
-- We will apply same logic as Education System Dataset i.e., Collocated Join



-- 1. Default Transaction Table
CREATE TABLE aws_project.order_transaction_def (
    order_id CHARACTER VARYING(50) NOT NULL COLLATE case_sensitive DISTKEY,
    order_date TIMESTAMP WITHOUT TIME ZONE,
    customer_id BIGINT,
    total_order_amount DOUBLE PRECISION,
    order_discount_pct BIGINT,
    final_order_amount DOUBLE PRECISION,
    customer_name BIGINT,
    customer_country CHARACTER VARYING(100) COLLATE case_sensitive,
    customer_city CHARACTER VARYING(100) COLLATE case_sensitive,
    customer_state CHARACTER VARYING(100) COLLATE case_sensitive,
    customer_credit_rating DOUBLE PRECISION,
    customer_premium_flag BOOLEAN,
    PRIMARY KEY (order_id)
) DISTSTYLE KEY;

-- 2. Default Shipment Table (With Informational FK)
CREATE TABLE aws_project.order_shipment_def (
    order_id CHARACTER VARYING(50) NOT NULL COLLATE case_sensitive,
    shipment_date TIMESTAMP WITHOUT TIME ZONE,
    invoice_number CHARACTER VARYING(50) COLLATE case_sensitive,
    shipment_from_city CHARACTER VARYING(100) COLLATE case_sensitive,
    shipment_to_city CHARACTER VARYING(100) COLLATE case_sensitive,
    invoice_amount DOUBLE PRECISION,
    PRIMARY KEY (order_id),
    FOREIGN KEY (order_id) REFERENCES aws_project.order_transaction_def(order_id)
) DISTSTYLE EVEN;




-- 1. Optimized Transaction Table
CREATE TABLE aws_project.order_transaction_opt (
    order_id CHARACTER VARYING(50) NOT NULL COLLATE case_sensitive,
    order_date TIMESTAMP WITHOUT TIME ZONE,
    customer_id BIGINT,
    total_order_amount DOUBLE PRECISION,
    order_discount_pct BIGINT,
    final_order_amount DOUBLE PRECISION,
    customer_name BIGINT,
    customer_country CHARACTER VARYING(100) COLLATE case_sensitive,
    customer_city CHARACTER VARYING(100) COLLATE case_sensitive,
    customer_state CHARACTER VARYING(100) COLLATE case_sensitive,
    customer_credit_rating DOUBLE PRECISION,
    customer_premium_flag BOOLEAN,
    PRIMARY KEY (order_id)
)
DISTSTYLE KEY
DISTKEY (order_id)
SORTKEY (order_date);

-- 2. Optimized Shipment Table (Upgraded to Key Distribution)
CREATE TABLE aws_project.order_shipment_opt (
    order_id CHARACTER VARYING(50) NOT NULL COLLATE case_sensitive,
    shipment_date TIMESTAMP WITHOUT TIME ZONE,
    invoice_number CHARACTER VARYING(50) COLLATE case_sensitive,
    shipment_from_city CHARACTER VARYING(100) COLLATE case_sensitive,
    shipment_to_city CHARACTER VARYING(100) COLLATE case_sensitive,
    invoice_amount DOUBLE PRECISION,
    PRIMARY KEY (order_id),
    FOREIGN KEY (order_id) REFERENCES aws_project.order_transaction_opt(order_id)
)
DISTSTYLE KEY
DISTKEY (order_id)
SORTKEY (shipment_date);



-- Populate Default Version
INSERT INTO
    aws_project.order_transaction_def
SELECT
    *
FROM aws_project.order_transaction_stg;--Took: 3m 4.6s


INSERT INTO
    aws_project.order_shipment_def
SELECT
    *
FROM aws_project.order_shipment_stg;--Took:  1m 31.6s


-- Populate Optimized Version
INSERT INTO
    aws_project.order_transaction_opt
SELECT
    *
FROM aws_project.order_transaction_stg;--Took: 3m 27.2s


INSERT INTO
    aws_project.order_shipment_opt
SELECT
    *
FROM aws_project.order_shipment_stg;--Took: 2m 48.6s


-- We are creating two scenarios where the default (def) follows the given rules.
-- Optimised (Opt) solution follows our own optimised table structure.
-- Comparision of above queries shall be available in redshift_queries_comparision.sql
