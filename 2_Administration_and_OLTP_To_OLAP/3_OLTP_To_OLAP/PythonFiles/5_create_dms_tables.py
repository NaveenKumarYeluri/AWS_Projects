import mysql.connector
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
    print("BUILDING DEDICATED DMS TABLES...")
    print("==========================================")

    cursor.execute("DROP TABLE IF EXISTS aws_project.applicant_dms;")
    cursor.execute("DROP TABLE IF EXISTS aws_project.institute_dms;")

    create_institute_dms = """
    CREATE TABLE aws_project.institute_dms (
        institute_id_sk VARCHAR(50),
        institute_name VARCHAR(255),
        institute_fee DECIMAL(10,2),
        institute_reputation VARCHAR(255),
        institute_campus_job_placement_pct DECIMAL(5,2),
        institute_campus_area VARCHAR(255),
        score_cut_off DECIMAL(5,2),
        total_no_of_students INT,
        applied_no_of_students INT,
        declined_no_of_student_pct DECIMAL(5,2),
        accepted_no_of_student_pct DECIMAL(5,2),
        row_id INT
    );
    """
    cursor.execute(create_institute_dms)
    print("Created: aws_project.institute_dms")

    create_applicant_dms = """
    CREATE TABLE aws_project.applicant_dms (
        applicant_id_sk INT,
        applicant_name VARCHAR(255),
        applicant_gender VARCHAR(50),
        applicant_dob DATETIME,
        applicant_country VARCHAR(100),
        applicant_qual_test_score DECIMAL(5,2),
        applicant_high_school_pct DECIMAL(5,2),
        scholarship_grade VARCHAR(50),
        scholarship_pct DECIMAL(5,2),
        interview_date DATE,
        interview_score DECIMAL(5,2),
        admission_date DATETIME,
        institute_id_fk VARCHAR(50),
        course_name VARCHAR(255),
        row_id INT
    );
    """
    cursor.execute(create_applicant_dms)
    print("Created: aws_project.applicant_dms")

    conn.commit()
    print("\nSUCCESS: DMS Infrastructure is ready.")

except Exception as e:
    print(f"Error: {e}")
finally:
    if 'conn' in locals() and conn.is_connected():
        cursor.close()
        conn.close()
