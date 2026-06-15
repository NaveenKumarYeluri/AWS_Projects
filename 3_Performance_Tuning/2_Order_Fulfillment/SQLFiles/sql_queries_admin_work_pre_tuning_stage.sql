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
    table_name IN ('order_fulfillment_stg', 'order_fulfillment_def', 'order_fulfillment_opt')
ORDER BY
    skew_rows DESC;

/*
table_name              encoded             diststyle               sortkey1                skew_rows   skew_sortkey1   size_mb     pct_used
order_fulfillment_opt   Y, AUTO(ENCODE)     KEY(mfg_facility_id)    fc_release_to_mfg_date  5.51        0.76            17693       0.0276
order_fulfillment_def   Y, AUTO(ENCODE)     KEY(fc_id)              AUTO(SORTKEY)           1.16        NULL            16327       0.0255
order_fulfillment_stg   Y, AUTO(ENCODE)     KEY(fc_id)              AUTO(SORTKEY)           1.16        NULL            16327       0.0255
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
    "table" IN ('order_fulfillment_stg')
ORDER BY
    skew_rows DESC;


/*
table_name              unsorted    stats_off   empty
order_fulfillment_opt   0           0           0
order_fulfillment_stg   NULL        0           0
order_fulfillment_def   NULL        0           0
*/


-- Check compression.
SET SEARCH_PATH TO 'aws_project';
SELECT
    tablename,
    "column",
    type,
    encoding
FROM pg_table_def
WHERE
    tablename IN ('order_fulfillment_stg', 'order_fulfillment_def', 'order_fulfillment_opt')
ORDER BY
    tablename,
    "column";



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
    AND "table" IN ('order_fulfillment_stg', 'order_fulfillment_def', 'order_fulfillment_opt');


/*
table_name              total_records   total_megabytes     records_per_mb
order_fulfillment_opt   250000000       17693               14129.8818
order_fulfillment_def   250000000       16327               15312.0597
order_fulfillment_stg   250000000       16327               15312.0597
*/



-- Check column level info
SELECT
    *
FROM pg_table_def
WHERE
    schemaname = 'aws_project'
    AND tablename IN ('order_fulfillment_stg', 'order_fulfillment_def', 'order_fulfillment_opt')
ORDER BY
    tablename;



-- --- DEFAULT VERSION ---
DROP TABLE IF EXISTS aws_project.order_fulfillment_def;
CREATE TABLE aws_project.order_fulfillment_def
DISTSTYLE KEY
DISTKEY (fc_id) AS
SELECT
    *
FROM aws_project.order_fulfillment_stg;--Took: 3m 15.5s



-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS aws_project.order_fulfillment_opt;
CREATE TABLE aws_project.order_fulfillment_opt
DISTSTYLE KEY
DISTKEY (mfg_facility_id)
SORTKEY (fc_release_to_mfg_date) AS
SELECT
    *
FROM aws_project.order_fulfillment_stg;--Took: 4m 43.6s

