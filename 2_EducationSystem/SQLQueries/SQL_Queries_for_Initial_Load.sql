-- Similar to FlightAnlyticsSystem, questions shall not be shared. The below queries are being run on dirty. Do remember we did intentionally duplicate applicant data. Institute table too has invalid data.

SET SEARCH_PATH TO aws_project;
SET enable_result_cache_for_session TO OFF;

-- 1)

WITH Clean_Institute_Data AS (
    SELECT
        institute_id_sk,
        institute_name,
        institute_reputation,
        ROW_NUMBER() OVER(PARTITION BY institute_id_sk ORDER BY institute_name ASC) as row_num
    FROM aws_project.institute
)
SELECT
    a.applicant_id_sk,
    a.applicant_name,
    a.course_name,
    a.admission_date,
    i.institute_name
FROM aws_project.applicant AS a
JOIN Clean_Institute_Data AS i
    ON i.institute_id_sk = a.institute_id_fk
WHERE
    i.row_num = 1
ORDER BY
    i.institute_name,
    a.applicant_name;

/*
-------------------------------------------------------------------------
Obversations:
Got this popup: The maximum size of result was reached. You can use UNLOAD commands instead.

-- Q1:
SELECT
    query_id,
    user_id,
    query_text,
    start_time,
    end_time,
    DATEDIFF(microsecond, start_time, end_time) / 1000000.0 AS duration_seconds,
    *
FROM sys_query_history
WHERE query_id IN (8467712, 8467897, 8467940)
ORDER BY start_time DESC;
-- R1: 8467712, R2: 8467897, R3: 8467940

QueryId: 8467940 (run 3)
Elapsed Time: 49002016
Duration Seconds: 49.002016 (49002016)
Returned Rows: 6,28,45,835
Returned Bytes: 5726433125
Compile Time: 344772
Planning Time: 13617
Lock Wait Time: 38
Actual Records shown in the output screen: 12,07,292

QueryId: 8467897 (run 2)
Elapsed Time: 57551329
Duration Seconds: 57.551329 (57551329)
Returned Rows: 6,28,45,835
Returned Bytes: 5726433125
Compile Time: 413541
Planning Time: 17048
Lock Wait Time: 52
Actual Records shown in the output screen: 12,07,292

QueryId: 8467712 (run 1)
Elapsed Time: 66584537
Duration Seconds: 66.584537 (66584537)
Returned Rows: 100
Returned Bytes: 9158
Compile Time: 620808
Planning Time: 135675
Lock Wait Time: 105
Actual Records shown in the output screen: 100
-------------------------------------------------------------------------
*/


--2)

WITH Clean_Institute_Data AS (
    SELECT
        institute_id_sk,
        institute_name,
        institute_fee,
        institute_reputation,
        ROW_NUMBER() OVER(PARTITION BY institute_id_sk ORDER BY institute_name ASC) as row_num
    FROM aws_project.institute
)
SELECT
    -- 1. Personal Details
    a.applicant_id_sk,
    a.applicant_name,
    a.applicant_gender,
    a.applicant_country,
    TRUNC(a.applicant_dob) AS date_of_birth,

    -- 2. Academic & Testing Performance
    a.applicant_high_school_GPA,
    a.applicant_qual_test_score,
    a.interview_score,

    -- 3. Financial Aid Info
    a.scholarship_grade,
    a.scholarship_pct,

    -- 4. Admission & College Info
    a.course_name,
    a.admission_date,
    i.institute_name,
    i.institute_fee,

    -- 5. Calculate Final Fee after Scholarship (Business Logic)
    (i.institute_fee - (i.institute_fee * (a.scholarship_pct / 100.0))) AS final_payable_fee

FROM aws_project.applicant AS a
LEFT JOIN Clean_Institute_Data AS i
    ON i.institute_id_sk = a.institute_id_fk
        AND i.row_num = 1
WHERE
    a.applicant_id_sk = 209700;

/*
-------------------------------------------------------------------------
Obversations:

-- Q2:
SELECT
    query_id,
    user_id,
    query_text,
    start_time,
    end_time,
    DATEDIFF(microsecond, start_time, end_time) / 1000000.0 AS duration_seconds,
    *
FROM sys_query_history
WHERE query_id IN (8870660, 8871025, 8871056)
ORDER BY start_time DESC;
-- R1: 8870660, R2: 8871025, R3: 8871056

QueryId: 8871056 (run 3)
Elapsed Time: 98171
Duration Seconds: 0.098171 (98171)
Returned Rows: 5
Returned Bytes: 680
Compile Time: 257
Planning Time: 18435
Lock Wait Time: 48
Actual Records shown in the output screen: 5

QueryId: 8871025 (run 2)
Elapsed Time: 426868
Duration Seconds: 0.426868 (426868)
Returned Rows: 5
Returned Bytes: 680
Compile Time: 338997
Planning Time: 18431
Lock Wait Time: 55
Actual Records shown in the output screen: 5

QueryId: 8870660 (run 1)
Elapsed Time: 158127929
Duration Seconds: 158.127929 (158127929)
Returned Rows: 5
Returned Bytes: 680
Compile Time: 423137
Planning Time: 114747
Lock Wait Time: 136
Actual Records shown in the output screen: 5
-------------------------------------------------------------------------
*/


-- 3)

WITH Clean_Institute_Data AS (
    SELECT
        institute_id_sk,
        institute_name,
        institute_fee,
        institute_reputation,
        score_cut_off,
        ROW_NUMBER() OVER(PARTITION BY institute_id_sk ORDER BY institute_name ASC) as row_num
    FROM aws_project.institute
)
SELECT
    i.institute_name,
    COUNT(a.applicant_id_sk) AS students_cnt
FROM aws_project.applicant AS a
JOIN Clean_Institute_Data AS i
    ON i.institute_id_sk = a.institute_id_fk
        AND i.row_num = 1
WHERE
    a.interview_score > i.score_cut_off
GROUP BY
    i.institute_name
ORDER BY
    students_cnt DESC;

/*
-------------------------------------------------------------------------
Obversations:

-- Q3:
SELECT
    query_id,
    user_id,
    query_text,
    start_time,
    end_time,
    DATEDIFF(microsecond, start_time, end_time) / 1000000.0 AS duration_seconds,
    *
FROM sys_query_history
WHERE query_id IN (8871278, 8871314, 8871331)
ORDER BY start_time DESC;
-- R1: 8871278, R2: 8871314, R3: 8871331

QueryId: 8871331 (run 3)
Elapsed Time: 1808092
Duration Seconds: 0.098171 (1808092)
Returned Rows: 83
Returned Bytes: 4508
Compile Time: 328
Planning Time: 14735
Lock Wait Time: 46
Actual Records shown in the output screen: 83

QueryId: 8871314 (run 2)
Elapsed Time: 2476353
Duration Seconds: 0.426868 (2476353)
Returned Rows: 83
Returned Bytes: 4508
Compile Time: 438177
Planning Time: 15065
Lock Wait Time: 46
Actual Records shown in the output screen: 83

QueryId: 8871278 (run 1)
Elapsed Time: 2934799
Duration Seconds: 158.127929 (2934799)
Returned Rows: 83
Returned Bytes: 4508
Compile Time: 361803
Planning Time: 15305
Lock Wait Time: 52
Actual Records shown in the output screen: 83
-------------------------------------------------------------------------
*/


-- 4)

WITH Clean_Institute_Data AS (
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
        accepted_no_of_student_pct,
        ROW_NUMBER() OVER(PARTITION BY institute_id_sk ORDER BY institute_name ASC) as row_num
    FROM aws_project.institute
)
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
FROM Clean_Institute_Data
WHERE
    institute_id_sk = 'TISN707'
    AND row_num = 1;

/*
-------------------------------------------------------------------------
Obversations:

-- Q4:
SELECT
    query_id,
    user_id,
    query_text,
    start_time,
    end_time,
    DATEDIFF(microsecond, start_time, end_time) / 1000000.0 AS duration_seconds,
    *
FROM sys_query_history
WHERE query_id IN (8871551, 8871570, 8871608)
ORDER BY start_time DESC;
-- R1: 8871551, R2: 8871570, R3: 8871608

QueryId: 8871608 (run 3)
Elapsed Time: 33033
Duration Seconds: 0.033033 (33033)
Returned Rows: 1
Returned Bytes: 175
Compile Time: 142
Planning Time: 13505
Lock Wait Time: 28
Actual Records shown in the output screen: 1

QueryId: 8871570 (run 2)
Elapsed Time: 300095
Duration Seconds: 0.300095 (300095)
Returned Rows: 1
Returned Bytes: 175
Compile Time: 269072
Planning Time: 13150
Lock Wait Time: 22
Actual Records shown in the output screen: 1

QueryId: 8871551 (run 1)
Elapsed Time: 278607
Duration Seconds: 0.278607 (278607)
Returned Rows: 1
Returned Bytes: 175
Compile Time: 182687
Planning Time: 13377
Lock Wait Time: 32
Actual Records shown in the output screen: 1
-------------------------------------------------------------------------
*/


-- 5)

WITH Clean_Institute_Data AS (
    SELECT
        institute_id_sk,
        institute_name,
        score_cut_off,
        -- We have issue here. Rows were changing per each run.
        -- Non-Deterministic Sorting: Each run will have a new record with row_num = 1
        -- Seems previous queries were fine as we were passing many other fields and hence the records count stayed constand for 3 runs.
        -- We will add one more field to the order by to make it deterministic.
        ROW_NUMBER() OVER(PARTITION BY institute_id_sk ORDER BY institute_name ASC, score_cut_off DESC) as row_num
        -- ROW_NUMBER() OVER(PARTITION BY institute_id_sk ORDER BY institute_name ASC) as row_num
    FROM aws_project.institute
)
SELECT
    a.applicant_id_sk,
    a.applicant_name,
    i.institute_name,
    a.interview_score,
    i.score_cut_off,
    ROUND((i.score_cut_off - a.interview_score), 2) AS pct_short_by
FROM aws_project.applicant AS a
JOIN Clean_Institute_Data AS i
    ON i.institute_id_sk = a.institute_id_fk
WHERE
    i.row_num = 1
    AND a.interview_score < i.score_cut_off
ORDER BY
    i.institute_name,
    a.applicant_name;

/*
-------------------------------------------------------------------------
Obversations:
Got this popup: The maximum size of result was reached. You can use UNLOAD commands instead.

-- Q5:
SELECT
    query_id,
    user_id,
    query_text,
    start_time,
    end_time,
    DATEDIFF(microsecond, start_time, end_time) / 1000000.0 AS duration_seconds,
    *
FROM sys_query_history
WHERE query_id IN (8871836, 8871947, 8872027)
ORDER BY start_time DESC;
-- R1: 8871836, R2: 8871947, R3: 8872027

QueryId: 8872027 (run 3)
Elapsed Time: 45236654
Duration Seconds: 45.23665400 (45236654)
Returned Rows: 37885885
Returned Bytes: 3760233660
Compile Time: 253
Planning Time: 14442
Lock Wait Time: 49
Actual Records shown in the output screen: 15,61,637

QueryId: 8871947 (run 2)
Elapsed Time: 45721310
Duration Seconds: 45.72131000 (45721310)
Returned Rows: 37910795
Returned Bytes: 3762960265
Compile Time: 792269
Planning Time: 14673
Lock Wait Time: 47
Actual Records shown in the output screen: 15,61,646

QueryId: 8871836 (run 1)
Elapsed Time: 43843462
Duration Seconds: 43.84346200 (43843462)
Returned Rows: 37919015
Returned Bytes: 3763773315
Compile Time: 258012
Planning Time: 15012
Lock Wait Time: 51
Actual Records shown in the output screen: 15,61,618


NEW OBSERVATIONS:

SELECT
    query_id,
    user_id,
    query_text,
    start_time,
    end_time,
    DATEDIFF(microsecond, start_time, end_time) / 1000000.0 AS duration_seconds,
    *
FROM sys_query_history
WHERE query_id IN (9072197, 9072374, 9072425)
ORDER BY start_time DESC;
-- R1: 9072197, R2: 9072374, R3: 9072425


QueryId: 9072425 (run 3)
Elapsed Time: 40228373
Duration Seconds: 40.22837300 (40228373)
Returned Rows: 38152005
Returned Bytes: 3786901740
Compile Time: 248
Planning Time: 14908
Lock Wait Time: 51
Actual Records shown in the output screen: 1561658

QueryId: 9072374 (run 2)
Elapsed Time: 39329669
Duration Seconds: 39.32966900 (39329669)
Returned Rows: 38152005
Returned Bytes: 3786901740
Compile Time: 260970
Planning Time: 15261
Lock Wait Time: 45
Actual Records shown in the output screen: 1561658

QueryId: 9072197 (run 1)
Elapsed Time: 214369624
Duration Seconds: 214.36962400 (214369624)
Returned Rows: 38152005
Returned Bytes: 3786901740
Compile Time: 687001
Planning Time: 546301
Lock Wait Time: 142
Actual Records shown in the output screen: 1561658
-------------------------------------------------------------------------
*/


-- 6)

SELECT
    applicant_id_sk,
    applicant_name,
    applicant_country AS country,
    DATEDIFF(year, applicant_dob, CURRENT_DATE) -
        CASE
            WHEN TO_CHAR(CURRENT_DATE, 'MMDD') < TO_CHAR(applicant_dob, 'MMDD')
                THEN 1
            ELSE 0
        END AS age,
    applicant_qual_test_score AS qualification_score
FROM aws_project.applicant
WHERE applicant_id_sk = 209700;

/*
-------------------------------------------------------------------------
Obversations:

-- Q6:
SELECT
    query_id,
    user_id,
    query_text,
    start_time,
    end_time,
    DATEDIFF(microsecond, start_time, end_time) / 1000000.0 AS duration_seconds,
    *
FROM sys_query_history
WHERE query_id IN (9072574, 9072649, 9072671)
ORDER BY start_time DESC;
-- R1: 9072574, R2: 9072649, R3: 9072671

QueryId: 9072671 (run 3)
Elapsed Time: 32081
Duration Seconds: 0.03208100 (32081)
Returned Rows: 5
Returned Bytes: 280
Compile Time: 87
Planning Time: 8175
Lock Wait Time: 22
Actual Records shown in the output screen: 5

QueryId: 9072649 (run 2)
Elapsed Time: 437888
Duration Seconds: 0.43788800 (437888)
Returned Rows: 5
Returned Bytes: 280
Compile Time: 402960
Planning Time: 8086
Lock Wait Time: 23
Actual Records shown in the output screen: 5

QueryId: 9072574 (run 1)
Elapsed Time: 300191
Duration Seconds: 0.30019100 (300191)
Returned Rows: 5
Returned Bytes: 280
Compile Time: 98871
Planning Time: 11265
Lock Wait Time: 22
Actual Records shown in the output screen: 5
-------------------------------------------------------------------------
*/


-- 7)

WITH Clean_Institute_Data AS (
    SELECT
        institute_id_sk,
        institute_name,
        institute_reputation,
        score_cut_off,
        ROW_NUMBER() OVER(PARTITION BY institute_id_sk ORDER BY institute_name ASC) as row_num
    FROM aws_project.institute
)
SELECT
    institute_id_sk,
    institute_name,
    institute_reputation,
    score_cut_off
FROM Clean_Institute_Data
WHERE
    row_num = 1
    AND institute_id_sk = 'TISN707'
ORDER BY
    institute_name;

/*
-------------------------------------------------------------------------
Obversations:

-- Q7:
SELECT
    query_id,
    user_id,
    query_text,
    start_time,
    end_time,
    DATEDIFF(microsecond, start_time, end_time) / 1000000.0 AS duration_seconds,
    *
FROM sys_query_history
WHERE query_id IN (9072856, 9072875, 9072897)
ORDER BY start_time DESC;
-- R1: 9072856, R2: 9072875, R3: 9072897

QueryId: 9072897 (run 3)
Elapsed Time: 29354
Duration Seconds: 0.02935400 (29354)
Returned Rows: 1
Returned Bytes: 91
Compile Time: 169
Planning Time: 10095
Lock Wait Time: 25
Actual Records shown in the output screen: 1

QueryId: 9072875 (run 2)
Elapsed Time: 466558
Duration Seconds: 0.46655800 (466558)
Returned Rows: 1
Returned Bytes: 91
Compile Time: 438336
Planning Time: 10283
Lock Wait Time: 25
Actual Records shown in the output screen: 1

QueryId: 9072856 (run 1)
Elapsed Time: 364107
Duration Seconds: 0.36410700 (364107)
Returned Rows: 1
Returned Bytes: 91
Compile Time: 241393
Planning Time: 10016
Lock Wait Time: 34
Actual Records shown in the output screen: 1
-------------------------------------------------------------------------
*/


-- 8) Question is ambiguous

SELECT
    applicant_id_sk,
    applicant_name,
    applicant_country,
    interview_score
FROM aws_project.applicant
WHERE
    interview_score > 90.00
ORDER BY
    interview_score DESC,
    applicant_name ASC;

/*
-------------------------------------------------------------------------
Obversations:
Got this popup: The maximum size of result was reached. You can use UNLOAD commands instead.

-- Q8:
SELECT
    query_id,
    user_id,
    query_text,
    start_time,
    end_time,
    DATEDIFF(microsecond, start_time, end_time) / 1000000.0 AS duration_seconds,
    *
FROM sys_query_history
WHERE query_id IN (9073014, 9073081, 9073120)
ORDER BY start_time DESC;
-- R1: 9073014, R2: 9073081, R3: 9073120

QueryId: 9073120 (run 3)
Elapsed Time: 44216841
Duration Seconds: 44.21684100 (44216841)
Returned Rows: 22019810
Returned Bytes: 1090947185
Compile Time: 129
Planning Time: 6819
Lock Wait Time: 26
Actual Records shown in the output screen: 3798186

QueryId: 9073081 (run 2)
Elapsed Time: 40521220
Duration Seconds: 40.52122000 (40521220)
Returned Rows: 22019810
Returned Bytes: 1090947185
Compile Time: 308645
Planning Time: 6856
Lock Wait Time: 22
Actual Records shown in the output screen: 3798186

QueryId: 9073014 (run 1)
Elapsed Time: 44300843
Duration Seconds: 44.30084300 (44300843)
Returned Rows: 22019810
Returned Bytes: 1090947185
Compile Time: 160500
Planning Time: 6744
Lock Wait Time: 22
Actual Records shown in the output screen: 3798186
-------------------------------------------------------------------------
*/


-- 9)

WITH Clean_Institute_Data AS (
    SELECT
        institute_name,
        declined_no_of_student_pct,
        ROW_NUMBER() OVER(PARTITION BY institute_name ORDER BY institute_id_sk ASC) as row_num
    FROM aws_project.institute
)
SELECT
    institute_name,
    declined_no_of_student_pct
FROM Clean_Institute_Data
WHERE
    row_num = 1
ORDER BY
    declined_no_of_student_pct DESC
LIMIT 5;

/*
-------------------------------------------------------------------------
Obversations:
Got this popup: The maximum size of result was reached. You can use UNLOAD commands instead.

-- Q9:
SELECT
    query_id,
    user_id,
    query_text,
    start_time,
    end_time,
    DATEDIFF(microsecond, start_time, end_time) / 1000000.0 AS duration_seconds,
    *
FROM sys_query_history
WHERE query_id IN (9073271, 9073312, 9073335)
ORDER BY start_time DESC;
-- R1: 9073271, R2: 9073312, R3: 9073335

QueryId: 9073335 (run 3)
Elapsed Time: 204016
Duration Seconds: 0.20401600 (204016)
Returned Rows: 5
Returned Bytes: 264
Compile Time: 199
Planning Time: 8797
Lock Wait Time: 21
Actual Records shown in the output screen: 5

QueryId: 9073312 (run 2)
Elapsed Time: 450252
Duration Seconds: 0.45025200 (450252)
Returned Rows: 5
Returned Bytes: 264
Compile Time: 340242
Planning Time: 8648
Lock Wait Time: 24
Actual Records shown in the output screen: 5

QueryId: 9073271 (run 1)
Elapsed Time: 458610
Duration Seconds: 0.45861000 (458610)
Returned Rows: 5
Returned Bytes: 264
Compile Time: 219521
Planning Time: 8698
Lock Wait Time: 25
Actual Records shown in the output screen: 5
-------------------------------------------------------------------------
*/
