-- Coparing DMS, Zero ETL and physical tables performance. NOTE: Runs of 4 to 5 were made and then results were captured.
-- Q1:

-- 1. Part 1 (Physical Optimized Tables)
SELECT
    applicant_id_sk,
    applicant_name,
    course_name,
    admission_date,
    institute_name
FROM aws_project.applicant_optimized AS a
INNER JOIN aws_project.institute_optimized AS i
    ON i.institute_id_sk = a.institute_id_fk
ORDER BY
    i.institute_name,
    a.applicant_name;--Took: 269 ms

-- 2. Zero-ETL (Materialized View)
SELECT
    applicant_id_sk,
    applicant_name,
    course_name,
    admission_date,
    institute_name
FROM applicant_institute_gold_mv
ORDER BY
    institute_name,
    applicant_name;--Took: 25 ms

-- 3. DMS / Lakehouse (External S3 Table)
SELECT
    applicant_id_sk,
    applicant_name,
    course_name,
    admission_date,
    institute_name
FROM lakehouse.dms_applicant_institute_gold
ORDER BY
    institute_name,
    applicant_name;--Took: 1946 ms



-- Q2:

-- 1. Part 1 (Physical Optimized Tables)
SELECT
    a.applicant_id_sk,
    a.applicant_name,
    a.applicant_gender,
    a.applicant_country,
    TRUNC(a.applicant_dob) AS date_of_birth,
    a.applicant_high_school_GPA,
    a.applicant_qual_test_score,
    a.interview_score,
    a.scholarship_grade,
    a.scholarship_pct,
    a.course_name,
    a.admission_date,
    i.institute_name,
    i.institute_fee,
    (i.institute_fee - (i.institute_fee * (a.scholarship_pct / 100.0))) AS final_payable_fee
FROM aws_project.applicant_optimized AS a
LEFT JOIN aws_project.institute_optimized AS i
    ON i.institute_id_sk = a.institute_id_fk
WHERE
    a.applicant_id_sk = 200006;--Took: 9 ms

-- 2. Zero-ETL (Materialized View)
SELECT
    applicant_id_sk,
    applicant_name,
    applicant_gender,
    applicant_country,
    TRUNC(applicant_dob) AS date_of_birth,
    applicant_high_school_pct,
    applicant_qual_test_score,
    interview_score,
    scholarship_grade,
    scholarship_pct,
    course_name,
    admission_date,
    institute_name,
    institute_fee,
    (institute_fee - (institute_fee * (scholarship_pct / 100.0))) AS final_payable_fee
FROM applicant_institute_gold_mv
WHERE
    applicant_id_sk = 200006;--Took: 68 ms

-- 3. DMS / Lakehouse (External S3 Table)
SELECT
    applicant_id_sk,
    applicant_name,
    applicant_gender,
    applicant_country,
    TRUNC(applicant_dob) AS date_of_birth,
    applicant_high_school_GPA,
    applicant_qual_test_score,
    interview_score,
    scholarship_grade,
    scholarship_pct,
    course_name,
    admission_date,
    institute_name,
    institute_fee,
    (institute_fee - (institute_fee * (scholarship_pct / 100.0))) AS final_payable_fee
FROM lakehouse.dms_applicant_institute_gold
WHERE
    applicant_id_sk = 200006;--Took: 457 ms



-- Q3:

-- 1. Part 1 (Physical Optimized Tables)
SELECT
    i.institute_name,
    COUNT(a.applicant_id_sk) AS students_cnt
FROM aws_project.applicant_optimized AS a
JOIN aws_project.institute_optimized AS i
    ON i.institute_id_sk = a.institute_id_fk
WHERE
    a.interview_score > i.score_cut_off
GROUP BY
    i.institute_name
ORDER BY
    students_cnt DESC;--Took: 9 ms

-- 2. Zero-ETL (Materialized View)
SELECT
    institute_name,
    COUNT(applicant_id_sk) AS students_cnt
FROM applicant_institute_gold_mv
WHERE
    interview_score > score_cut_off
GROUP BY
    institute_name
ORDER BY
    students_cnt DESC;--Took: 32 ms

-- 3. DMS / Lakehouse (External S3 Table)
SELECT
    institute_name,
    COUNT(applicant_id_sk) AS students_cnt
FROM lakehouse.dms_applicant_institute_gold
WHERE
    interview_score > score_cut_off
GROUP BY
    institute_name
ORDER BY
    students_cnt DESC;--Took: 1290 ms



-- Q4:

-- 1. Part 1 (Physical Optimized Tables)
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
FROM aws_project.institute_optimized
WHERE
    institute_id_sk = 'TISN707';--Took: 8 ms

-- 2. Zero-ETL (Materialized View)
SELECT DISTINCT
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
FROM applicant_institute_gold_mv
WHERE
    institute_id_sk = 'TISN707';--Took: 68 ms

-- 3. DMS / Lakehouse (External S3 Table)
SELECT DISTINCT
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
FROM lakehouse.dms_applicant_institute_gold
WHERE
    institute_id_sk = 'TISN707';--Took: 614 ms



-- Q5:

-- 1. Part 1 (Physical Optimized Tables)
SELECT
    a.applicant_id_sk,
    a.applicant_name,
    i.institute_name,
    a.interview_score,
    i.score_cut_off,
    ROUND((i.score_cut_off - a.interview_score), 2) AS pct_short_by
FROM aws_project.applicant_optimized AS a
JOIN aws_project.institute_optimized AS i
    ON i.institute_id_sk = a.institute_id_fk
WHERE
    a.interview_score < i.score_cut_off
ORDER BY
    i.institute_name,
    a.applicant_name;--Took: 7 ms

-- 2. Zero-ETL (Materialized View)
SELECT
    applicant_id_sk,
    applicant_name,
    institute_name,
    interview_score,
    score_cut_off,
    ROUND((score_cut_off - interview_score), 2) AS pct_short_by
FROM applicant_institute_gold_mv
WHERE
    interview_score < score_cut_off
ORDER BY
    institute_name,
    applicant_name;--Took: 25 ms

-- 3. DMS / Lakehouse (External S3 Table)
SELECT
    applicant_id_sk,
    applicant_name,
    institute_name,
    interview_score,
    score_cut_off,
    ROUND((score_cut_off - interview_score), 2) AS pct_short_by
FROM lakehouse.dms_applicant_institute_gold
WHERE
    interview_score < score_cut_off
ORDER BY
    institute_name,
    applicant_name;--Took: 1449 ms



-- Q6:

-- 1. Part 1 (Physical Optimized Tables)
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
FROM aws_project.applicant_optimized
WHERE
    applicant_id_sk = 200006;--Took: 9 ms

-- 2. Zero-ETL (Materialized View)
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
FROM applicant_institute_gold_mv
WHERE
    applicant_id_sk = 200006;--Took: 69 ms

-- 3. DMS / Lakehouse (External S3 Table)
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
FROM lakehouse.dms_applicant_institute_gold
WHERE
    applicant_id_sk = 200006;--Took: 487 ms



-- Q7:

-- 1. Part 1 (Physical Optimized Tables)
SELECT
    institute_id_sk,
    institute_name,
    institute_reputation,
    score_cut_off
FROM aws_project.institute_optimized
WHERE
    institute_id_sk = 'TISN707'
ORDER BY
    institute_name,
    institute_id_sk;--Took: 7 ms

-- 2. Zero-ETL (Materialized View)
SELECT DISTINCT
    institute_id_sk,
    institute_name,
    institute_reputation,
    score_cut_off
FROM applicant_institute_gold_mv
WHERE
    institute_id_sk = 'TISN707'
ORDER BY
    institute_name,
    institute_id_sk;--Took: 25 ms

-- 3. DMS / Lakehouse (External S3 Table)
SELECT DISTINCT
    institute_id_sk,
    institute_name,
    institute_reputation,
    score_cut_off
FROM lakehouse.dms_applicant_institute_gold
WHERE
    institute_id_sk = 'TISN707'
ORDER BY
    institute_name,
    institute_id_sk;--Took: 708 ms



-- Q8:

-- 1. Part 1 (Physical Optimized Tables)
SELECT
    applicant_id_sk,
    applicant_name,
    applicant_country,
    interview_score
FROM aws_project.applicant_optimized
WHERE
    interview_score > 90.00
ORDER BY
    interview_score DESC,
    applicant_name ASC;--Took: 6 ms

-- 2. Zero-ETL (Materialized View)
SELECT
    applicant_id_sk,
    applicant_name,
    applicant_country,
    interview_score
FROM applicant_institute_gold_mv
WHERE
    interview_score > 90.00
ORDER BY
    interview_score DESC,
    applicant_name ASC;--Took: 77 ms

-- 3. DMS / Lakehouse (External S3 Table)
SELECT
    applicant_id_sk,
    applicant_name,
    applicant_country,
    interview_score
FROM lakehouse.dms_applicant_institute_gold
WHERE
    interview_score > 90.00
ORDER BY
    interview_score DESC,
    applicant_name ASC;--Took: 1120 ms



-- Q9:

-- 1. Part 1 (Physical Optimized Tables)
SELECT
    institute_name,
    declined_no_of_student_pct
FROM aws_project.institute_optimized
ORDER BY
    declined_no_of_student_pct DESC
LIMIT
    5;--Took: 6 ms

-- 2. Zero-ETL (Materialized View)
SELECT DISTINCT
    institute_name,
    declined_no_of_student_pct
FROM applicant_institute_gold_mv
ORDER BY
    declined_no_of_student_pct DESC
LIMIT
    5;--Took: 24 ms

-- 3. DMS / Lakehouse (External S3 Table)
SELECT DISTINCT
    institute_name,
    declined_no_of_student_pct
FROM lakehouse.dms_applicant_institute_gold
ORDER BY
    declined_no_of_student_pct DESC
LIMIT
    5;--Took: 2503 ms


-- Clearly physical tables were outperforming the other two.
