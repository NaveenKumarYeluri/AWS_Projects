-- Similar to FlightAnlyticsSystem, questions shall not be shared. The below queries are being run before making changes in original data load. Do remember we did intentionally duplicate applicant data. Institute table has lot of invalid data.

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
    ON i.institute_id_sk = ai.institute_id_fk
        AND i.row_num = 1
WHERE
    a.applicant_id_sk = 209700;


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


-- 5)

WITH Clean_Institute_Data AS (
    SELECT
        institute_id_sk,
        institute_name,
        score_cut_off,
        ROW_NUMBER() OVER(PARTITION BY institute_id_sk ORDER BY institute_name ASC) as row_num
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
