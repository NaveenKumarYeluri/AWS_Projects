import os
import mysql.connector
from dotenv import load_dotenv

# Load variables from the .env file
load_dotenv()

# Build the config dynamically
DB_CONFIG = {
    'host': os.getenv('RDS_ENDPOINT'),
    'port': 3306,
    'user': os.getenv('PIPELINE_USER'),
    'password': os.getenv('PIPELINE_PASS'),
    'database': 'aws_project',
    'autocommit': True
}

try:
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()

    print("==========================================")
    print("1. TEARDOWN: Dropping existing tables...")
    print("==========================================")

    drops = [
        "DROP TABLE IF EXISTS aws_project.applicant_stg;",
        "DROP TABLE IF EXISTS aws_project.institute_stg;",
        "DROP TABLE IF EXISTS aws_project.applicant;",
        "DROP TABLE IF EXISTS aws_project.institute;",
        "DROP TABLE IF EXISTS aws_project.applicant_exceptions;",
        "DROP TABLE IF EXISTS aws_project.institute_dms;",
        "DROP TABLE IF EXISTS aws_project.applicant_dms;"
    ]
    for drop in drops:
        cursor.execute(drop)
        print(f"Executed: {drop}")

    print("\n==========================================")
    print("2. BUILDING MAIN PRODUCTION TABLES (Zero ETL)...")
    print("==========================================")

    cursor.execute("""
    CREATE TABLE aws_project.institute (
        institute_id_sk VARCHAR(50) PRIMARY KEY,
        institute_name VARCHAR(255),
        institute_fee DECIMAL(10,2),
        institute_reputation VARCHAR(255),
        institute_campus_job_placement_pct DECIMAL(5,2),
        institute_campus_area VARCHAR(255),
        score_cut_off DECIMAL(5,2),
        total_no_of_students INT,
        applied_no_of_students INT,
        declined_no_of_student_pct DECIMAL(5,2),
        accepted_no_of_student_pct DECIMAL(5,2)
    );
    """)
    print("Created: aws_project.institute")

    cursor.execute("""
    CREATE TABLE aws_project.applicant (
        applicant_id_sk INT PRIMARY KEY,
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
        CONSTRAINT fk_applicant_institute FOREIGN KEY (institute_id_fk) REFERENCES aws_project.institute(institute_id_sk)
    );
    """)
    print("Created: aws_project.applicant")

    print("\n==========================================")
    print("2. BUILDING EXCEPTION PRODUCTION TABLE (Zero ETL)...")
    print("==========================================")

    cursor.execute("""
    CREATE TABLE aws_project.applicant_exceptions (
        exception_id INT AUTO_INCREMENT PRIMARY KEY, -- Zero ETL must need PK.
        applicant_id_sk INT,
        applicant_name VARCHAR(255),
        applicant_gender VARCHAR(50),
        applicant_dob DATETIME,
        applicant_country VARCHAR(100),
        institute_id_fk VARCHAR(50),
        error_reason VARCHAR(255),
        logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)
    print("Created: aws_project.applicant_exceptions")

    print("\n==========================================")
    print("3. BUILDING STAGING TABLES...")
    print("==========================================")

    cursor.execute("""
    CREATE TABLE aws_project.institute_stg (
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
        row_id INT AUTO_INCREMENT PRIMARY KEY
    );
    """)
    print("Created: aws_project.institute_stg")

    cursor.execute("""
    CREATE TABLE aws_project.applicant_stg (
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
        row_id INT AUTO_INCREMENT PRIMARY KEY
    );
    """)
    print("Created: aws_project.applicant_stg")

    print("\n==========================================")
    print("2. BUILDING MAIN PRODUCTION TABLES (DMS)...")
    print("==========================================")

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
    print("\nSUCCESS: Database architecture rebuilt.")

except Exception as e:
    print(f"Error: {e}")
finally:
    if 'conn' in locals() and conn.is_connected():
        cursor.close()
        conn.close()
