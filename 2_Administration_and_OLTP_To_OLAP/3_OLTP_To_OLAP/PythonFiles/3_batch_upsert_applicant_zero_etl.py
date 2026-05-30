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

chunk_size = 20000

try:
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()

    # ==========================================
    # Session Overrides
    # ==========================================
    print("Applying session overrides to bypass deep locks...")

    # 1. Stop MySQL from placing shared locks on the Staging and Institute tables
    cursor.execute("SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;")

    # 2. Disable Foreign Key checks for this script (INNER JOIN handles the filtering)
    cursor.execute("SET SESSION foreign_key_checks = 0;")

    # 3. Increase the lock wait timeout strictly for this session just in case
    cursor.execute("SET SESSION innodb_lock_wait_timeout = 120;")
    # ==========================================

    print("Fetching min and max row_id from staging...")
    cursor.execute("SELECT MIN(row_id), MAX(row_id) FROM applicant_stg;")
    min_id, max_id = cursor.fetchone()

    if min_id is None:
        print("Staging table is empty. Exiting.")
        exit()

    print("==========================================")
    print("ORPHANED APPLICANTS (DLQ)...")
    print("==========================================")
    trap_query = """
        INSERT INTO aws_project.applicant_exceptions (
            applicant_id_sk,
            applicant_name,
            applicant_gender,
            applicant_dob,
            applicant_country,
            institute_id_fk,
            error_reason
        )
        SELECT
            a.applicant_id_sk,
            a.applicant_name,
            a.applicant_gender,
            a.applicant_dob,
            a.applicant_country,
            a.institute_id_fk,
            'Missing or Invalid Institute ID' AS error_reason
        FROM aws_project.applicant_stg a
        WHERE NOT EXISTS (
            SELECT 1
            FROM aws_project.institute i
            WHERE i.institute_id_sk = a.institute_id_fk
        );
    """
    cursor.execute(trap_query)
    conn.commit()
    print(f"SUCCESS: Trapped {cursor.rowcount} orphaned records into the Exception Table.\n")

    print(f"Starting batch UPSERT from row_id {min_id} to {max_id}...")
    start_time = time.time()

    current_min = min_id
    total_processed = 0

    while current_min <= max_id:
        current_max = current_min + chunk_size - 1

        print(f" -> Processing rows {current_min} to {current_max}...")

        upsert_query = """
            INSERT INTO aws_project.applicant (
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
                course_name
            )
            SELECT
                a.applicant_id_sk,
                a.applicant_name,
                a.applicant_gender,
                a.applicant_dob,
                a.applicant_country,
                a.applicant_qual_test_score,
                a.applicant_high_school_pct,
                a.scholarship_grade,
                a.scholarship_pct,
                a.interview_date,
                a.interview_score,
                a.admission_date,
                a.institute_id_fk,
                a.course_name
            FROM aws_project.applicant_stg a
            INNER JOIN aws_project.institute i ON a.institute_id_fk = i.institute_id_sk
            WHERE a.row_id BETWEEN %s AND %s
            ON DUPLICATE KEY UPDATE
                applicant_name = VALUES(applicant_name),
                applicant_gender = VALUES(applicant_gender),
                applicant_dob = VALUES(applicant_dob),
                applicant_country = VALUES(applicant_country),
                applicant_qual_test_score = VALUES(applicant_qual_test_score),
                applicant_high_school_pct = VALUES(applicant_high_school_pct),
                scholarship_grade = VALUES(scholarship_grade),
                scholarship_pct = VALUES(scholarship_pct),
                interview_date = VALUES(interview_date),
                interview_score = VALUES(interview_score),
                admission_date = VALUES(admission_date),
                institute_id_fk = VALUES(institute_id_fk),
                course_name = VALUES(course_name);
        """

        cursor.execute(upsert_query, (current_min, current_max))
        conn.commit()

        total_processed += cursor.rowcount
        current_min += chunk_size

    elapsed = round(time.time() - start_time, 2)
    print(f"\nSUCCESS: Batch UPSERT complete in {elapsed} seconds.")

except Exception as e:
    print(f"Error: {e}")
finally:
    if 'conn' in locals() and conn.is_connected():
        cursor.close()
        conn.close()
