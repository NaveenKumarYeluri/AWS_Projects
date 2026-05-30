import mysql.connector
import time
import os
from dotenv import load_dotenv

# Load variables from the .env file
load_dotenv()

# Build the config dynamically
DB_CONFIG = {
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
    print("EXECUTING INSTITUTE UPSERT...")
    print("==========================================")

    upsert_query = """
    INSERT INTO aws_project.institute (
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
    FROM aws_project.institute_stg
    ON DUPLICATE KEY UPDATE
        institute_name = VALUES(institute_name),
        institute_fee = VALUES(institute_fee),
        institute_reputation = VALUES(institute_reputation),
        institute_campus_job_placement_pct = VALUES(institute_campus_job_placement_pct),
        institute_campus_area = VALUES(institute_campus_area),
        score_cut_off = VALUES(score_cut_off),
        total_no_of_students = VALUES(total_no_of_students),
        applied_no_of_students = VALUES(applied_no_of_students),
        declined_no_of_student_pct = VALUES(declined_no_of_student_pct),
        accepted_no_of_student_pct = VALUES(accepted_no_of_student_pct);
    """

    start_time = time.time()
    cursor.execute(upsert_query)
    conn.commit()

    elapsed = round(time.time() - start_time, 2)
    print(f"SUCCESS: Processed {cursor.rowcount} institute rows in {elapsed} seconds.")

except Exception as e:
    print(f"Error: {e}")
    if 'conn' in locals() and conn.is_connected():
        conn.rollback()
finally:
    if 'conn' in locals() and conn.is_connected():
        cursor.close()
        conn.close()
