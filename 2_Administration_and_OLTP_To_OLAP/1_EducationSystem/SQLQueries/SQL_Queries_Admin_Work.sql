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
    sortkey1, -- institute: institute_id_sk, applicant: applicant_id_sk
    skew_rows, -- institute: 1.20, applicant: NULL
    skew_sortkey1, -- 1 for both
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


-- De-duplication/Clean data starts:

-- 1) We will make sure only one name is associated with one ID. This was reason why CTEs were used on almost all the Business Statements.


SELECT COUNT(*) FROM aws_project.institute; -- 5,00,000 records


select DISTINCT institute_name from aws_project.institute; -- 83 names.
select DISTINCT institute_id_sk from aws_project.institute; -- 1,00,818 IDs
-- There is a huge variation b/w the above 2 numbers which itself proves that we have bad data. How is it even possible to have 400+ IDs for a single name?


CREATE TABLE aws_project.stg_institute AS
(
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY institute_id_sk ORDER BY institute_name) AS rnk
    FROM aws_project.institute
); -- Obviously we delete using other methods as well.


SELECT COUNT(*) FROM aws_project.stg_institute; -- We will have original count of 5,00,000 records.


TRUNCATE TABLE aws_project.institute; -- We will remove existing data before de-duplication.


INSERT INTO aws_project.institute
SELECT
    institute_id_sk,
    institute_name,
    institute_fee,
    institute_reputation,
    institute_campus_job_placement_pct,
    institute_campus_area,
    score_cut_off,
    total_no_of_students,
    applied_no_of_students,
    declined_no_of_student_pct,
    accepted_no_of_student_pct
FROM aws_project.stg_institute
WHERE rnk = 1; -- This number makes sure we have only one name for each ID.


SELECT COUNT(*) FROM aws_project.institute;--1,00,818. Now our institute table is clean.


DROP TABLE aws_project.stg_institute; -- This is no longer needed. Save space.


-- 2) We will work on applicant table.

-- We ran below queries on DuckDB which is local to my system, which also means data duplication, which we did in Redshift, has not happened here.
SELECT COUNT(*) FROM aws_project.applicant; -- 7,09,99,980

SELECT COUNT(*)-- Count of records in applicant table which have no corresponding match in institute table. Means bad data.
FROM aws_project.applicant AS a
LEFT OUTER JOIN aws_project.institute AS i
    ON i.institute_id_sk = a.institute_id_fk
WHERE i.institute_name IS NULL; -- 81,54,145

SELECT COUNT(*)-- Count of records in applicant table which have proper match in institute table.
FROM aws_project.applicant AS a
LEFT OUTER JOIN aws_project.institute AS i
    ON i.institute_id_sk = a.institute_id_fk
WHERE i.institute_name IS NOT NULL; -- 6,28,45,835
-- 81,54,145 + 6,28,45,835 = 7,09,99,980


-- Step 1: We will remove those records for which no match in institute table.

DELETE FROM aws_project.applicant
WHERE NOT EXISTS (
    SELECT 1
    FROM aws_project.institute
    WHERE institute_id_sk = TRIM(applicant.institute_id_fk) -- Seems Redshift is not allowing to delete unless I have a no-use function here.
    -- FYI: We have Foreign Key here and Redshift is assuming the data is good. Obviously we have to prove it wrong.
); -- Deleted records count: 81,54,145


SELECT COUNT(*) FROM aws_project.applicant; -- 6,28,45,835
-- We completed our first step. Now we will go after duplicates as we did this intentionally.

-- Step 2: Remove duplicates.

SELECT COUNT(DISTINCT applicant_id_sk) FROM aws_project.applicant; -- 1,18,64,129
SELECT COUNT(applicant_id_sk) FROM aws_project.applicant; -- 6,28,45,835 same as above


SELECT applicant_id_sk, applicant_name, applicant_gender, applicant_country, applicant_dob, COUNT(*)
FROM aws_project.applicant
GROUP BY applicant_id_sk, applicant_name, applicant_gender, applicant_country, applicant_dob
HAVING COUNT(*) > 1; -- It is showing 5 duplicate record for each record. Which is obviously as per our Python script.

CREATE TABLE aws_project.stg_applicant AS
(
    SELECT *, ROW_NUMBER() OVER (PARTITION BY applicant_id_sk, applicant_name, applicant_gender, applicant_country, applicant_dob ORDER BY applicant_id_sk) AS rnk
    FROM aws_project.applicant
); -- Took: 1m 4.3s

SELECT COUNT(*) FROM aws_project.stg_applicant; -- 6,28,45,835 same as above
SELECT * FROM aws_project.stg_applicant LIMIT 5;

TRUNCATE TABLE aws_project.applicant; -- Took: 230ms

INSERT INTO aws_project.applicant
SELECT
    applicant_id_sk,
    applicant_name,
    applicant_gender,
    applicant_dob,
    applicant_country,
    applicant_qual_test_score,
    applicant_high_school_GPA,
    scholarship_grade,
    scholarship_pct,
    interview_date,
    interview_score,
    admission_date,
    institute_id_fk,
    course_name
FROM aws_project.stg_applicant
WHERE rnk = 1; -- Took: 19.4s, 1,25,69,167

SELECT COUNT(DISTINCT applicant_id_sk) FROM aws_project.applicant; -- 1,18,64,129 same as earlier
SELECT COUNT(applicant_id_sk) FROM aws_project.applicant; -- 1,25,69,167 same as above
-- Finally the data we duplicated has been removed. We will check tables size after dropping stg table.

DROP TABLE aws_project.stg_applicant;-- Took: 221ms


SELECT
    database,
    schema AS table_schema,
    table_id,
    "table" AS table_name,
    encoded,
    diststyle,
    sortkey1, -- institute: institute_id_sk, applicant: applicant_id_sk
    skew_rows, -- institute: 1.16 (improvement), applicant: NULL (Same as earlier, expected since our DISSTYLE is EVEN)
    skew_sortkey1, -- 1 for both
    "size" as size_mb -- applicant: 4352 (improvement, size reduced), institute: 3584 (Seems same as earlier)
FROM svv_table_info
WHERE
table_schema = 'aws_project'
AND table_name IN ('applicant', 'institute')
ORDER BY skew_rows DESC;


SELECT
    schema AS table_schema,
    "table" AS table_name,
    diststyle, -- Same as previous
    unsorted, -- Same as previous
    stats_off, -- applicant: 100 (We are going to use ANALYZE), institute: 0
    empty
FROM svv_table_info
WHERE
table_schema = 'aws_project'
AND table_name IN ('applicant', 'institute')
ORDER BY skew_rows DESC;


ANALYZE aws_project.applicant;-- Took: 2.2s

-- Now stats too are fine.


-- Step 3: Re-run our SQL Queries as per given Business Statements. Further optimisation might be needed for P1s atleast.
-- We can check Final_SQL_Queries.sql. Execution times were fine. In cases where data is huge time was inflated because of network and queries are running fine in under seconds. We will check further what has to be done.


VACUUM DELETE ONLY aws_project.institute;-- Took: 1m 42.7s
-- Even after vacuum we have same size which means 1MB blocks are filled in such a way that we cannot recover that space.

VACUUM FULL aws_project.institute;-- Took: 336ms
ANALYZE aws_project.institute;-- Took: 110ms


-- We will check how many records were fit into 1MB block.
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
  AND "table" IN ('applicant', 'institute');
-- applicant: 2888.1357 (Size: 4352 MB)
-- institute: 28.13 (Size: 3584) It seems 1MB blocks do have empty space.


-- Step 4: We are going to some tests by changing DISSTYLE for applicant table.
-- Do remember we have EVEN as DISSTYLE for this table, where as institute has Primay Key as Key.
-- We will have 3 versions of applicant, with one having DISSTYLE = EVEN (present case) and 2nd will have DISSTYLE = KEY (institute_id_fk, both tables will have same. SORTKEY = institute_id_fk) and 3rd one DISSTYLE = KEY (institute_id_fk, with AUTO SORTKEY)


CREATE TABLE aws_project.applicant_optimized(
    applicant_id_sk BIGINT PRIMARY KEY,
    applicant_name VARCHAR,
    applicant_gender VARCHAR,
    applicant_dob TIMESTAMP,
    applicant_country VARCHAR,
    applicant_qual_test_score DOUBLE PRECISION,
    applicant_high_school_GPA DOUBLE PRECISION,
    scholarship_grade VARCHAR,
    scholarship_pct DOUBLE PRECISION,
    interview_date DATE,
    interview_score DOUBLE PRECISION,
    admission_date TIMESTAMP,
    institute_id_fk VARCHAR,
    course_name VARCHAR,
    FOREIGN KEY (institute_id_fk) REFERENCES aws_project.institute(institute_id_sk)
)
DISTSTYLE KEY
DISTKEY (institute_id_fk)
SORTKEY (institute_id_fk);-- Took: 12.15429700


INSERT INTO aws_project.applicant_optimized
SELECT * FROM aws_project.applicant;-- Took: 1m 23.3s


ANALYSE aws_project.applicant_optimized; --3.2s


CREATE TABLE aws_project.applicant_optimized_nosort(
    applicant_id_sk BIGINT PRIMARY KEY,
    applicant_name VARCHAR,
    applicant_gender VARCHAR,
    applicant_dob TIMESTAMP,
    applicant_country VARCHAR,
    applicant_qual_test_score DOUBLE PRECISION,
    applicant_high_school_GPA DOUBLE PRECISION,
    scholarship_grade VARCHAR,
    scholarship_pct DOUBLE PRECISION,
    interview_date DATE,
    interview_score DOUBLE PRECISION,
    admission_date TIMESTAMP,
    institute_id_fk VARCHAR,
    course_name VARCHAR,
    FOREIGN KEY (institute_id_fk) REFERENCES aws_project.institute(institute_id_sk)
)
DISTSTYLE KEY
DISTKEY (institute_id_fk); -- Let it be AUTO sort.

-- Load your clean data into it
INSERT INTO aws_project.applicant_optimized_nosort
SELECT * FROM aws_project.applicant;

ANALYSE aws_project.applicant_optimized_nosort;


table_name	                total_records	  total_megabytes	records_per_mb
applicant_optimized	        12569167	       4476	                2808.1248
applicant	                12569167	       4352	                2888.1357
applicant_optimized_nosort	12569167	       2176	                5776.2715
institute	                100818	           3584	                28.13


table_id	table_name	                   encoded	            diststyle	            sortkey1	        skew_rows	skew_sortkey1	size_mb	  pct_used
244138	    applicant	                   Y, AUTO(ENCODE)	    EVEN	                applicant_id_sk	    NULL	      1	             4352	  0.0068
297112	    applicant_optimized	           Y, AUTO(ENCODE)	    KEY(institute_id_fk)	institute_id_fk	    1.34	      0.67	         4476	  0.0069
305304	    applicant_optimized_nosort	   Y, AUTO(ENCODE)	    KEY(institute_id_fk)	AUTO(SORTKEY)	    1.34	      NULL	         2176	  0.0034
244134	    institute	                   Y, AUTO(ENCODE)	    KEY(institute_id_sk)	institute_id_sk	    1.16	      1	             3584	  0.0056


-- Results for 1st P1:


-- Drops the temp table if you are re-running it
DROP TABLE IF EXISTS test_baseline;-- 9.3s, 31ms, 21ms, 22ms, 19ms
CREATE TEMP TABLE test_baseline AS
SELECT
    a.applicant_id_sk,
    a.applicant_name,
    a.course_name,
    a.admission_date,
    i.institute_name
FROM aws_project.applicant AS a
INNER JOIN aws_project.institute AS i
    ON i.institute_id_sk = a.institute_id_fk
ORDER BY
    i.institute_name,
    a.applicant_name;-- R1: 2m 20.3s, R2: 5.1s, R3: 5.3s, R4: 4.4s, R5: 4.4s, r6: 4.4



DROP TABLE IF EXISTS test_nosort;-- 11ms, 21ms, 21ms, 21ms, 20ms
CREATE TEMP TABLE test_nosort AS
SELECT
    a.applicant_id_sk,
    a.applicant_name,
    a.course_name,
    a.admission_date,
    i.institute_name
FROM aws_project.applicant_optimized_nosort AS a
INNER JOIN aws_project.institute AS i
    ON i.institute_id_sk = a.institute_id_fk
ORDER BY
    i.institute_name,
    a.applicant_name;-- R1: 6s, R2: 4.8s, R3: 4.7s, R4: 4.2s, R5: 4.2s, R6: 4.2s



DROP TABLE IF EXISTS test_optimized;-- 14ms, 26ms, 20ms, 20ms, 21ms
CREATE TEMP TABLE test_optimized AS
SELECT
    a.applicant_id_sk,
    a.applicant_name,
    a.course_name,
    a.admission_date,
    i.institute_name
FROM aws_project.applicant_optimized AS a
INNER JOIN aws_project.institute AS i
    ON i.institute_id_sk = a.institute_id_fk
ORDER BY
    i.institute_name,
    a.applicant_name;-- R1: 5.1s, R2: 4s, R3: 3.1s, R4: 3.2s, R5: 2.6s, R6: 2.9s

-- We can see results above
    -- default version went from 5 sec to 4 sec.
    -- AUTOSORT version went from 6 to 4 sec.
    -- Collocated Join version went from 5 to ~3 sec.

-- As of now for 1st Business Statement Collocated Joins is working fine. We will verify for other P1 and P2's as well.
-- I feel since this is serverless time will be inflated because at times, server will be idle, which is impacting. May be we will have to pay more attention to Execution time?


-- Drops the temp table if you are re-running it
DROP TABLE IF EXISTS test_baseline;--

-- Forces Redshift to do all the math and sorting, but writes to a local temp disk
CREATE TEMP TABLE test_baseline AS
SELECT
    a.applicant_id_sk,
    a.applicant_name,
    i.institute_name,
    a.interview_score,
    i.score_cut_off,
    ROUND((i.score_cut_off - a.interview_score), 2) AS pct_short_by
FROM aws_project.applicant AS a
JOIN aws_project.institute AS i
    ON i.institute_id_sk = a.institute_id_fk
WHERE
    a.interview_score < i.score_cut_off
ORDER BY
    i.institute_name,
    a.applicant_name;-- R1: 13.2s, R2: 3.7s, R3: 3.8s, R4: 3.3s, R5: 3.3s, R6: 3.6s


DROP TABLE IF EXISTS test_nosort;

CREATE TEMP TABLE test_nosort AS
SELECT
    a.applicant_id_sk,
    a.applicant_name,
    i.institute_name,
    a.interview_score,
    i.score_cut_off,
    ROUND((i.score_cut_off - a.interview_score), 2) AS pct_short_by
FROM aws_project.applicant_optimized_nosort AS a
JOIN aws_project.institute AS i
    ON i.institute_id_sk = a.institute_id_fk
WHERE
    a.interview_score < i.score_cut_off
ORDER BY
    i.institute_name,
    a.applicant_name;-- R1: 4.7s, R2: 3.2s, R3: 3s, R4: 3s, R5: 2.9s, R6: 3.1s


DROP TABLE IF EXISTS test_optimized;

CREATE TEMP TABLE test_optimized AS
SELECT
    a.applicant_id_sk,
    a.applicant_name,
    i.institute_name,
    a.interview_score,
    i.score_cut_off,
    ROUND((i.score_cut_off - a.interview_score), 2) AS pct_short_by
FROM aws_project.applicant_optimized AS a
JOIN aws_project.institute AS i
    ON i.institute_id_sk = a.institute_id_fk
WHERE
    a.interview_score < i.score_cut_off
ORDER BY
    i.institute_name,
    a.applicant_name;-- R1: 6.2s, R2: 3.2s, R3: 2s, R4: 2s, R5: 2s, R6: 2s


-- With the above runs it is obvious that Collocated Join + our Sort Key working fine and giving much better performance compared to the other two. So we will stick with this option and drop the other tables. With this our work on optimisation is completed.
