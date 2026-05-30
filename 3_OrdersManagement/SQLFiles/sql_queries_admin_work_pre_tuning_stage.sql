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
