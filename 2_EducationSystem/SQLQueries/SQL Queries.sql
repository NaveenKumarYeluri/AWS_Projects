-- These queries are for Serverless as our DWH is based on Serverless. Provisioned cluster might have different tables.

-- Total Records
SELECT COUNT(*) FROM aws_project.applicant;--7,09,99,980
SELECT COUNT(*) FROM aws_project.institute;--5,00,000

--
ANALYZE aws_project.applicant;
ANALYZE aws_project.institute;


-- Size of tables in mb, total rows
SELECT
    schema AS table_schema,
    "table" AS table_name,
    size AS size_in_mb,
    tbl_rows AS total_rows
FROM svv_table_info
WHERE
table_schema = 'aws_project'
AND table_name IN ('applicant', 'institute')-- 8607 MB (7,09,99,980), 3584 MB (5,00,000)
ORDER BY size DESC;



-- pct_used: Percentage of total storage used by this table
-- skew_rows: The ratio of the most populated slice to the least
-- diststyle: type of distribution key
SELECT
    database,
    schema AS table_schema,
    table_id,
    "table" AS table_name,
    encoded,
    diststyle,
    sortkey1,
    skew_rows,
    "size" as size_mb,
    pct_used
FROM svv_table_info
WHERE
table_schema = 'aws_project'
AND table_name IN ('applicant', 'institute')
ORDER BY skew_rows DESC;



-- stats_off: db statistics, since it is 0 stats are fine
-- unsorted: if we have any unsorted data, since 0 fine
-- empty: if we have empty blocks, since 0 fine
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
SELECT
    query_id,
    status,
    loaded_rows,
    loaded_bytes / 1024 / 1024 as loaded_mb,
    start_time,
    end_time
FROM sys_load_history
ORDER BY start_time DESC;
