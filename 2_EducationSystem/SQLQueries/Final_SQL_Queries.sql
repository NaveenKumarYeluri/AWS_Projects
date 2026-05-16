SET SEARCH_PATH TO aws_project;
SET enable_result_cache_for_session TO OFF;

-- 1)

SELECT
    applicant_id_sk,
    applicant_name,
    course_name,
    admission_date,
    institute_name
FROM aws_project.applicant AS a
INNER JOIN aws_project.institute AS i
    ON i.institute_id_sk = a.institute_id_fk
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
WHERE query_id IN (9878429, 9879046, 9879075)
ORDER BY start_time DESC;

QueryId: 9878429 (run 1)
Elapsed Time: 175833444
Duration Seconds: 175.83344400 (175833444) Before de-duplication: 66.584537 (1st run is not that good, time was inflated by large data to export.)
Returned Rows: 12569167
Returned Bytes: 1145286625
Compile Time: 186788
Planning Time: 18500
Lock Wait Time: 60
Actual Records shown in the output screen: 1288946

QueryId: 9879046 (run 2)
Elapsed Time: 24613467
Duration Seconds: 24.61346700 (24613467) Before de-duplication: 57.551329 (Lot of improvement, time was inflated by large data to export.)
Returned Rows: 12569167
Returned Bytes: 1145286625
Compile Time: 270
Planning Time: 9761
Lock Wait Time: 45
Actual Records shown in the output screen: 1288946

QueryId: 9879075 (run 3)
Elapsed Time: 20737437
Duration Seconds: 20.73743700 (20737437) Before de-duplication: 49.002016 (Lot of improvement, time was inflated by large data to export.)
Returned Rows: 12569167
Returned Bytes: 1145286625
Compile Time: 250
Planning Time: 9841
Lock Wait Time: 44
Actual Records shown in the output screen: 1288946
-------------------------------------------------------------------------
*/


-- 2)

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
LEFT JOIN aws_project.institute AS i
    ON i.institute_id_sk = a.institute_id_fk
WHERE
    a.applicant_id_sk = 200006;

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
WHERE query_id IN (9879247, 9879274, 9879290)
ORDER BY start_time DESC;

QueryId: 9879247 (run 1)
Elapsed Time: 299445
Duration Seconds: 0.29944500 (299445) Before de-duplication: 158.127929 (Good)
Returned Rows: 1
Returned Bytes: 193
Compile Time: 206043
Planning Time: 15239
Lock Wait Time: 55
Actual Records shown in the output screen: 1

QueryId: 9879274 (run 2)
Elapsed Time: 54491
Duration Seconds: 0.05449100 (54491) Before de-duplication: 0.426868 (Good)
Returned Rows: 1
Returned Bytes: 193
Compile Time: 253
Planning Time: 15047
Lock Wait Time: 49
Actual Records shown in the output screen: 1

QueryId: 9879290 (run 3)
Elapsed Time: 53294
Duration Seconds: 0.05329400 (53294) Before de-duplication: 0.098171 (Good)
Returned Rows: 1
Returned Bytes: 193
Compile Time: 235
Planning Time: 15021
Lock Wait Time: 47
Actual Records shown in the output screen: 1
-------------------------------------------------------------------------
*/


-- 3)

SELECT
    i.institute_name,
    COUNT(a.applicant_id_sk) AS students_cnt
FROM aws_project.applicant AS a
JOIN aws_project.institute AS i
    ON i.institute_id_sk = a.institute_id_fk
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
WHERE query_id IN (9879644, 9879812, 9879826)
ORDER BY start_time DESC;

QueryId: 9879644 (run 1)
Elapsed Time: 895889
Duration Seconds: 0.89588900 (895889) Before de-duplication: 158.127929 (Good)
Returned Rows: 83
Returned Bytes: 4508
Compile Time: 324947
Planning Time: 11462
Lock Wait Time: 59
Actual Records shown in the output screen: 83

QueryId: 9879812 (run 2)
Elapsed Time: 772837
Duration Seconds: 0.77283700 (772837) Before de-duplication: 0.426868 (good)
Returned Rows: 83
Returned Bytes: 4508
Compile Time: 292765
Planning Time: 10322
Lock Wait Time: 48
Actual Records shown in the output screen: 83

QueryId: 9879826 (run 3)
Elapsed Time: 506816
Duration Seconds: 0.50681600 (506816) Before de-duplication: 0.098171 (good)
Returned Rows: 83
Returned Bytes: 4508
Compile Time: 309
Planning Time: 10473
Lock Wait Time: 34
Actual Records shown in the output screen: 83
-------------------------------------------------------------------------
*/


-- 4)

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
FROM aws_project.institute
WHERE
    institute_id_sk = 'TISN707';

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
WHERE query_id IN (10281413, 10281450, 10281465)
ORDER BY start_time DESC;

QueryId: 10281413 (run 1)
Elapsed Time: 11902883
Duration Seconds: 11.90288300 (11902883) Before de-duplication: 0.278607 (good, it is because the server was idle)
Returned Rows: 1
Returned Bytes: 175
Compile Time: 353264
Planning Time: 447608
Lock Wait Time: 105
Actual Records shown in the output screen: 1

QueryId: 10281450 (run 2)
Elapsed Time: 2842
Duration Seconds: 0.00284200 (2842) Before de-duplication: 0.300095 (good)
Returned Rows: 1
Returned Bytes: 175
Compile Time: 0
Planning Time: 2196
Lock Wait Time: 5
Actual Records shown in the output screen: 1

QueryId: 10281465 (run 3)
Elapsed Time: 2641
Duration Seconds: 0.00264100 (2641) Before de-duplication: 0.033033 (good)
Returned Rows: 1
Returned Bytes: 175
Compile Time: 0
Planning Time: 2096
Lock Wait Time: 5
Actual Records shown in the output screen: 1

-------------------------------------------------------------------------
*/


-- 5)

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
WHERE query_id IN (10281593, 10281625, 10281691)
ORDER BY start_time DESC;

QueryId: 10281593 (run 1)
Elapsed Time: 31819352
Duration Seconds: 31.81935200 (31819352) Before de-duplication: 40.22837300 (good, time was inflated by large data to export.)
Returned Rows: 7581858
Returned Bytes: 752563634
Compile Time: 287653
Planning Time: 82780
Lock Wait Time: 77
Actual Records shown in the output screen: 7581858

QueryId: 10281625 (run 2)
Elapsed Time: 29125199
Duration Seconds: 29.12519900 (29125199) Before de-duplication: 39.32966900 (good, time was inflated by large data to export.)
Returned Rows: 7581858
Returned Bytes: 752563634
Compile Time: 529239
Planning Time: 10559
Lock Wait Time: 44
Actual Records shown in the output screen: 7581858

QueryId: 10281691 (run 3)
Elapsed Time: 25286760
Duration Seconds: 25.28676000 (25286760) Before de-duplication: 40.22837300 (good, time was inflated by large data to export.)
Returned Rows: 7581858
Returned Bytes: 752563634
Compile Time: 241
Planning Time: 10603
Lock Wait Time: 49
Actual Records shown in the output screen: 7581858
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
WHERE applicant_id_sk = 200006;

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
WHERE query_id IN (10281856, 10281875, 10281896)
ORDER BY start_time DESC;

QueryId: 10281856 (run 1)
Elapsed Time: 282868
Duration Seconds: 0.28286800 (282868) Before de-duplication: 0.30019100 (good)
Returned Rows: 1
Returned Bytes: 60
Compile Time: 256221
Planning Time: 7883
Lock Wait Time: 28
Actual Records shown in the output screen: 1

QueryId: 10281875 (run 2)
Elapsed Time: 3114
Duration Seconds: 0.00311400 (3114) Before de-duplication: 0.43788800 (good)
Returned Rows: 1
Returned Bytes: 60
Compile Time: 0
Planning Time: 2460
Lock Wait Time: 5
Actual Records shown in the output screen: 1

QueryId: 10281896 (run 3)
Elapsed Time: 2962
Duration Seconds: 0.00296200 (2962) Before de-duplication: 0.03208100 (good)
Returned Rows: 1
Returned Bytes: 60
Compile Time: 0
Planning Time: 2339
Lock Wait Time: 6
Actual Records shown in the output screen: 1
-------------------------------------------------------------------------
*/


-- 7)

SELECT
    institute_id_sk,
    institute_name,
    institute_reputation,
    score_cut_off
FROM aws_project.institute
WHERE
    institute_id_sk = 'TISN707'
ORDER BY
    institute_name,
    institute_id_sk;

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
WHERE query_id IN (10282007, 10282029, 10282056)
ORDER BY start_time DESC;

QueryId: 10282007 (run 1)
Elapsed Time: 184532
Duration Seconds: 0.18453200 (184532) Before de-duplication: 0.36410700 (good)
Returned Rows: 1
Returned Bytes: 91
Compile Time: 83651
Planning Time: 6227
Lock Wait Time: 27
Actual Records shown in the output screen: 1

QueryId: 10282029 (run 2)
Elapsed Time: 2445
Duration Seconds: 0.00244500 (2445) Before de-duplication: 0.46655800 (good)
Returned Rows: 1
Returned Bytes: 91
Compile Time: 0
Planning Time: 1929
Lock Wait Time: 7
Actual Records shown in the output screen: 1

QueryId: 10282056 (run 3)
Elapsed Time: 2363
Duration Seconds: 0.00236300 (2363) Before de-duplication: 0.02935400 (good)
Returned Rows: 1
Returned Bytes: 91
Compile Time: 0
Planning Time: 1867
Lock Wait Time: 7
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
WHERE query_id IN (10282111, 10282150, 10282179)
ORDER BY start_time DESC;

QueryId: 10282111 (run 1)
Elapsed Time: 40250454
Duration Seconds: 40.25045400 (40250454) Before de-duplication: 44.30084300 (good, time was inflated by large data to export.)
Returned Rows: 3898424
Returned Bytes: 193142933
Compile Time: 165696
Planning Time: 7152
Lock Wait Time: 27
Actual Records shown in the output screen: 3898424

QueryId: 10282150 (run 2)
Elapsed Time: 34510070
Duration Seconds: 34.51007000 (34510070) Before de-duplication: 40.52122000 (good, time was inflated by large data to export.)
Returned Rows: 3898424
Returned Bytes: 193142933
Compile Time: 316292
Planning Time: 6621
Lock Wait Time: 26
Actual Records shown in the output screen: 3898424

QueryId: 10282179 (run 3)
Elapsed Time: 34756141
Duration Seconds: 34.75614100 (34756141) Before de-duplication: 44.21684100 (good, time was inflated by large data to export.)
Returned Rows: 3898424
Returned Bytes: 193142933
Compile Time: 153
Planning Time: 6767
Lock Wait Time: 31
Actual Records shown in the output screen: 3898424
-------------------------------------------------------------------------
*/


-- 9)

SELECT
    institute_name,
    declined_no_of_student_pct
FROM aws_project.institute
ORDER BY
    declined_no_of_student_pct DESC
LIMIT 5;

/*
-------------------------------------------------------------------------
Obversations:

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
WHERE query_id IN (10282306, 10282321, 10282336)
ORDER BY start_time DESC;

QueryId: 10282306 (run 1)
Elapsed Time: 261715
Duration Seconds: 0.26171500 (261715) Before de-duplication: 0.45861000 (good)
Returned Rows: 5
Returned Bytes: 312
Compile Time: 169703
Planning Time: 4552
Lock Wait Time: 27
Actual Records shown in the output screen: 5

QueryId: 10282321 (run 2)
Elapsed Time: 2130
Duration Seconds: 0.00213000 (2130) Before de-duplication: 0.45025200 (good)
Returned Rows: 5
Returned Bytes: 312
Compile Time: 0
Planning Time: 1641
Lock Wait Time: 5
Actual Records shown in the output screen: 5

QueryId: 10282336 (run 3)
Elapsed Time: 2094
Duration Seconds: 0.00209400 (2094) Before de-duplication: 0.20401600 (good)
Returned Rows: 5
Returned Bytes: 312
Compile Time: 0
Planning Time: 1634
Lock Wait Time: 4
Actual Records shown in the output screen: 5
-------------------------------------------------------------------------
*/
