-- First thing after creating ETL pipeline is find the integration_id.
-- We will run this in our preferred DB (I used dev).
SELECT
    integration_id
FROM svv_integration;-- 8886994f-2dc2-4583-803b-07f9fbeb0c62


-- Use below drop in initial setup phase where you might face error while Zero ETL is being constructed.
-- DROP DATABASE zero_etl_db FORCE; Can be used when DB is fresh to trigger Zero ETL. Never use when ETL is already active.

-- After getting your ID, create a DB which will be under control of AWS which means it is read only for us.
-- We will run this in our preferred DB (I used dev).
CREATE DATABASE zero_etl_db
FROM INTEGRATION '8886994f-2dc2-4583-803b-07f9fbeb0c62';-- Took: 306ms


-- We need these VIEWS as the DB, zero_etl_db, is not in our control means AWS manages it.
-- We will run this in our preferred DB (I used dev).
CREATE OR REPLACE VIEW institute_silver AS
SELECT
    institute_id_sk, institute_name, institute_fee, institute_reputation,
    institute_campus_job_placement_pct, institute_campus_area, score_cut_off,
    total_no_of_students, applied_no_of_students, declined_no_of_student_pct,
    accepted_no_of_student_pct
FROM (
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY institute_id_sk ORDER BY row_id DESC) as rank
    FROM zero_etl_db.aws_project.institute
)
WHERE
    rank = 1
WITH NO SCHEMA BINDING;-- Took: 179ms
-- Don't worry about locking the underlying table right now. Just save this SQL logic, and check if the data exists at the exact moment I run a SELECT query.


-- We need these VIEWS as the DB, zero_etl_db, is not in our control means AWS manages it.
-- We will run this in our preferred DB (I used dev).
CREATE OR REPLACE VIEW applicant_silver AS
SELECT
    applicant_id_sk, applicant_name, applicant_gender, applicant_dob,
    applicant_country, applicant_qual_test_score, applicant_high_school_pct,
    scholarship_grade, scholarship_pct, interview_date, interview_score,
    admission_date, institute_id_fk, course_name
FROM (
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY applicant_id_sk ORDER BY row_id DESC) as rank
    FROM zero_etl_db.aws_project.applicant
)
WHERE
    rank = 1
WITH NO SCHEMA BINDING;-- Took: 144ms
-- Don't worry about locking the underlying table right now. Just save this SQL logic, and check if the data exists at the exact moment I run a SELECT query.


-- We will run this in our preferred DB (I used dev).
-- Unless we have errors in ETL Pipeline, we will have data in this.
-- Do remember SCHEMA and TABLE NAMEs will be taken from OLTP. Not in our control.
SELECT
    schema_name,
    table_name
FROM svv_all_tables
WHERE
    database_name = 'zero_etl_db';


-- Check Integration activity.
SELECT *
FROM sys_integration_activity
ORDER BY
    last_commit_timestamp DESC
LIMIT 10;


SELECT
    COUNT(*)
FROM applicant_silver;-- 1,19,659
SELECT
    COUNT(*)
FROM institute_silver;-- 74,337

SELECT
    COUNT(DISTINCT applicant_id_sk)
FROM applicant_silver;-- 1,19,659
SELECT
    COUNT(DISTINCT institute_id_sk)
FROM institute_silver;-- 74,337


-- If we CREATE a table then it defeats the purpose of our project because TABLES do not have AUTO REFRESH unlike MVs.
-- We cannot use MVs as we have Window Function in our VIEW.
-- So how we proceed? We will keep table but with a Stored Procedure (SP).
CREATE TABLE applicant_institute_gold
DISTSTYLE KEY
DISTKEY (institute_id_sk)
INTERLEAVED SORTKEY (institute_id_sk, applicant_id_sk)
AS
SELECT
    -- All Applicant Columns
    a.applicant_id_sk,
    a.applicant_name,
    a.applicant_gender,
    a.applicant_dob,
    a.applicant_country,
    a.applicant_qual_test_score,
    a.applicant_high_school_pct AS applicant_high_school_GPA,
    a.scholarship_grade,
    a.scholarship_pct,
    a.interview_date,
    a.interview_score,
    a.admission_date,
    a.course_name,
    -- All Institute Columns
    i.institute_id_sk,
    i.institute_name,
    i.institute_fee,
    i.institute_reputation,
    i.institute_campus_job_placement_pct,
    i.institute_campus_area,
    i.score_cut_off,
    i.total_no_of_students,
    i.applied_no_of_students,
    i.declined_no_of_student_pct,
    i.accepted_no_of_student_pct
FROM applicant_silver a
JOIN institute_silver i
  ON a.institute_id_fk = i.institute_id_sk;-- Took: 12.4s


-- Compare our tables.
SELECT
    database,
    schema AS table_schema,
    table_id,
    "table" AS table_name,
    encoded,
    diststyle,
    sortkey1,
    skew_rows,-- gold: 1.39
    skew_sortkey1,-- gold: NULL
    "size" as size_mb,-- gold: 3328
    pct_used
FROM svv_table_info
WHERE
    table_name IN ('applicant', 'institute'
    , 'applicant_optimized', 'applicant_optimized_nosort', 'applicant_institute_gold')
ORDER BY skew_rows DESC;


-- Our SP
CREATE OR REPLACE PROCEDURE sp_refresh_gold_layer()
LANGUAGE plpgsql
AS $$
BEGIN
    -- 1. Build the 'Green' table with EVERY column required for Q1 - Q9
    EXECUTE '
        CREATE TABLE applicant_institute_gold_new
        DISTSTYLE KEY
        DISTKEY (institute_id_sk)
        INTERLEAVED SORTKEY (institute_id_sk, applicant_id_sk)
        AS
        SELECT
            -- All Applicant Columns
            a.applicant_id_sk,
            a.applicant_name,
            a.applicant_gender,
            a.applicant_dob,
            a.applicant_country,
            a.applicant_qual_test_score,
            a.applicant_high_school_pct AS applicant_high_school_GPA,
            a.scholarship_grade,
            a.scholarship_pct,
            a.interview_date,
            a.interview_score,
            a.admission_date,
            a.course_name,

            -- All Institute Columns
            i.institute_id_sk,
            i.institute_name,
            i.institute_fee,
            i.institute_reputation,
            i.institute_campus_job_placement_pct,
            i.institute_campus_area,
            i.score_cut_off,
            i.total_no_of_students,
            i.applied_no_of_students,
            i.declined_no_of_student_pct,
            i.accepted_no_of_student_pct
        FROM applicant_silver a
        JOIN institute_silver i
          ON a.institute_id_fk = i.institute_id_sk;
    ';

    -- 2. The Atomic Swap (Zero-Downtime)
    EXECUTE 'DROP TABLE IF EXISTS applicant_institute_gold_backup;';

    EXECUTE 'ALTER TABLE applicant_institute_gold RENAME TO applicant_institute_gold_backup;';

    EXECUTE 'ALTER TABLE applicant_institute_gold_new RENAME TO applicant_institute_gold;';

    -- 3. Cleanup the backup
    EXECUTE 'DROP TABLE IF EXISTS applicant_institute_gold_backup;';

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Blue/Green deployment failed: %', SQLERRM;
END;
$$;


-- Count before update file.
SELECT
    COUNT(*)
FROM applicant_institute_gold;-- 82,719


-- Sent an update file.
CALL sp_refresh_gold_layer();


-- Count after 1st update.
SELECT
    COUNT(*)
FROM applicant_institute_gold;-- 1,42,574


-- Compare tables again.
SELECT
    database,
    schema AS table_schema,
    table_id,
    "table" AS table_name,
    encoded,
    diststyle,
    sortkey1,
    skew_rows,-- gold: 1.35 (reduction of 0.04, nice)
    skew_sortkey1,-- gold: NULL
    "size" as size_mb,-- gold: 3328 (Same as earlier)
    pct_used
FROM svv_table_info
WHERE
    table_name IN ('applicant', 'institute'
    , 'applicant_optimized', 'applicant_optimized_nosort', 'applicant_institute_gold')
ORDER BY skew_rows DESC;

