import mysql.connector
import time
import os
from dotenv import load_dotenv

# Load variables from the .env file
load_dotenv()

# Build the config dynamically
db_config = {
    'host': os.getenv('RDS_ENDPOINT'),
    'port': 3306,
    'user': os.getenv('PIPELINE_USER'),
    'password': os.getenv('PIPELINE_PASS'),
    'database': 'aws_project'
}

try:
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()

    print("==========================================")
    print("MOVING DATA TO DMS TRACK...")
    print("==========================================")

    start_time = time.time()
    print("Loading Institute data...")
    cursor.execute("""
        INSERT INTO aws_project.institute_dms
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
            row_id
        FROM aws_project.institute_stg;
    """)
    conn.commit()
    print(f" -> Inserted {cursor.rowcount} institute records in {round(time.time() - start_time, 2)}s.")

    start_time = time.time()
    print("Loading Applicant data...")
    cursor.execute("""
        INSERT INTO aws_project.applicant_dms
        SELECT
            applicant_id_sk,
            applicant_name,
            applicant_gender,
            applicant_dob,
            applicant_country,
            applicant_qual_test_score,
            applicant_high_school_pct,
            scholarship_grade,
            scholarship_pct,
            interview_date,
            interview_score,
            admission_date,
            institute_id_fk,
            course_name, row_id
        FROM aws_project.applicant_stg;
    """)
    conn.commit()
    print(f" -> Inserted {cursor.rowcount} applicant records in {round(time.time() - start_time, 2)}s.")

    print("\n==========================================")
    print("WIPING STAGING ENVIRONMENT...")
    print("==========================================")

    cursor.execute("TRUNCATE TABLE aws_project.institute_stg;")
    cursor.execute("TRUNCATE TABLE aws_project.applicant_stg;")
    print("SUCCESS: DMS load complete and staging area is clean.")

except Exception as e:
    print(f"Error: {e}")
finally:
    if 'conn' in locals() and conn.is_connected():
        cursor.close()
        conn.close()
