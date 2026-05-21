-- Now we will validate data. We have developed the same dataset in a different approach as part 1 of this Project 2.
-- We have deafult LIMIT 100

-- OLD (Q1):

SELECT
    applicant_id_sk,
    applicant_name,
    course_name,
    admission_date,
    institute_name
FROM aws_project.applicant_optimized AS a
INNER JOIN aws_project.institute AS i
    ON i.institute_id_sk = a.institute_id_fk
ORDER BY
    i.institute_name,
    a.applicant_name;-- Took: 233 ms (after multiple runs)


-- NEW (Q1):

SELECT
    applicant_id_sk,
    applicant_name,
    course_name,
    admission_date,
    institute_name
FROM applicant_institute_gold
ORDER BY
    institute_name,
    applicant_name;-- Took: 8 ms (after multiple runs)



-- OLD (Q2):

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

FROM aws_project.applicant_optimized AS a
LEFT JOIN aws_project.institute AS i
    ON i.institute_id_sk = a.institute_id_fk
WHERE
    a.applicant_id_sk = 200006;-- Took: 11 ms



-- NEW (Q2):

SELECT
    -- 1. Personal Details
    applicant_id_sk,
    applicant_name,
    applicant_gender,
    applicant_country,
    TRUNC(applicant_dob) AS date_of_birth,

    -- 2. Academic & Testing Performance
    applicant_high_school_GPA,
    applicant_qual_test_score,
    interview_score,

    -- 3. Financial Aid Info
    scholarship_grade,
    scholarship_pct,

    -- 4. Admission & College Info
    course_name,
    admission_date,
    institute_name,
    institute_fee,

    -- 5. Calculate Final Fee after Scholarship
    (institute_fee - (institute_fee * (scholarship_pct / 100.0))) AS final_payable_fee

FROM applicant_institute_gold
WHERE
    applicant_id_sk = 200006;-- Took: 48 ms


-- OLD (Q3):

SELECT
    i.institute_name,
    COUNT(a.applicant_id_sk) AS students_cnt
FROM aws_project.applicant_optimized AS a
JOIN aws_project.institute AS i
    ON i.institute_id_sk = a.institute_id_fk
WHERE
    a.interview_score > i.score_cut_off
GROUP BY
    i.institute_name
ORDER BY
    students_cnt DESC;-- Took: 10 ms


-- NEW (Q3):

SELECT
    institute_name,
    COUNT(applicant_id_sk) AS students_cnt
FROM applicant_institute_gold
WHERE
    interview_score > score_cut_off
GROUP BY
    institute_name
ORDER BY
    students_cnt DESC;-- Took: 6 ms



-- OLD (Q4):

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
    institute_id_sk = 'TISN707';-- Took: 10 ms


-- NEW (Q4):

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
FROM applicant_institute_gold
WHERE
    institute_id_sk = 'TISN707';-- Took: 59 ms



-- OLD (Q5):

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
    a.applicant_name;-- Took: 8 ms


-- NEW (Q5):

SELECT
    applicant_id_sk,
    applicant_name,
    institute_name,
    interview_score,
    score_cut_off,
    ROUND((score_cut_off - interview_score), 2) AS pct_short_by
FROM applicant_institute_gold
WHERE
    interview_score < score_cut_off
ORDER BY
    institute_name,
    applicant_name;-- Took: 9 ms



-- OLD (Q6):

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
    applicant_id_sk = 200006;-- Took: 10 ms


-- NEW (Q6):

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
FROM applicant_institute_gold
WHERE
    applicant_id_sk = 200006;-- Took: 51 ms



-- OLD (Q7):

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
    institute_id_sk;-- Took: 10 ms


-- NEW (Q7):

SELECT DISTINCT
    institute_id_sk,
    institute_name,
    institute_reputation,
    score_cut_off
FROM applicant_institute_gold
WHERE
    institute_id_sk = 'TISN707'
ORDER BY
    institute_name,
    institute_id_sk;-- Took: 58 ms



-- OLD (Q8):

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
    applicant_name ASC;-- Took: 11 ms


-- NEW (Q8):

SELECT
    applicant_id_sk,
    applicant_name,
    applicant_country,
    interview_score
FROM applicant_institute_gold
WHERE
    interview_score > 90.00
ORDER BY
    interview_score DESC,
    applicant_name ASC;-- Took: 21 ms



-- OLD (Q9):

SELECT
    institute_name,
    declined_no_of_student_pct
FROM aws_project.institute
ORDER BY
    declined_no_of_student_pct DESC
LIMIT 5;-- Took: 279 ms


-- NEW (Q9):

SELECT DISTINCT
    institute_name,
    declined_no_of_student_pct
FROM applicant_institute_gold
ORDER BY
    declined_no_of_student_pct DESC
LIMIT 5;-- Took: 230 ms


-- Observation: As for today the old method is working better compared to today's.
-- We will again check after full data load, which will be done only after DMS is created.
-- Next step DMS creation.
