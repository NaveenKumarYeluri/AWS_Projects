-- These queries are for Serverless as our DWH is based on Serverless. Provisioned cluster might have different tables.

-- Total Records
SELECT COUNT(*) FROM aws_project.applicant;--7,09,99,980
SELECT COUNT(*) FROM aws_project.institute;--5,00,000

--
ANALYZE aws_project.applicant;
ANALYZE aws_project.institute;


-- Size: Size in MB (Effectively the number of 1MB blocks).
-- tbl_rows: no of rows in respective table.
SELECT
    schema AS table_schema,
    "table" AS table_name,
    size AS total_megabytes,
    tbl_rows AS total_rows
FROM svv_table_info
WHERE
table_schema = 'aws_project'
AND table_name IN ('applicant', 'institute')-- 8607 MB (7,09,99,980), 3584 MB (5,00,000)
ORDER BY size DESC;



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
table_schema = 'aws_project'
AND table_name IN ('applicant', 'institute')
ORDER BY skew_rows DESC;



-- stats_off: db statistics, since it is 0 stats are fine i.e., they are up-to-date
-- unsorted: if we have any unsorted data or not, since 0 fine
-- empty: if we have empty blocks or not, since 0 fine
SELECT
    schema AS table_schema,
    "table" AS table_name,
    diststyle,
    unsorted,
    stats_off,
    empty
FROM svv_table_info
WHERE
table_schema = 'aws_project'
AND table_name IN ('applicant', 'institute')
ORDER BY skew_rows DESC;



-- This view shows 'encoding' for every column
SET SEARCH_PATH TO '$user', 'public', 'aws_project';
SELECT
    schemaname,
    tablename,
    "column",
    type,
    encoding
FROM pg_table_def
WHERE
tablename IN ('applicant', 'institute')
ORDER BY tablename, "column";



-- load history, you need to pass QueryId
-- Query_id is must here unlike sys_query_history we cannot search with actual query we ran.
-- It shows data_source, status of operation, and lot of other info related to the file operation.
SELECT
    query_id,
    status,
    loaded_rows,
    loaded_bytes / 1024 / 1024 as loaded_mb,
    start_time,
    end_time
FROM sys_load_history
ORDER BY start_time DESC;



-- This shows info related to the Queries we run.
-- Almost required info will be available, from who has run to it status, time taken at different stages etc.
SELECT
    query_id,
    user_id,
    query_text,
    start_time,
    end_time,
    -- How long the query actually took
    DATEDIFF(microsecond, start_time, end_time) / 1000000.0 AS duration_seconds,
    *
FROM sys_query_history
WHERE query_text ILIKE '%COPY aws_project.applicant%'
ORDER BY start_time DESC
LIMIT 20;
