import os
import pymysql
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

def setup_oltp_schema():
    connection = pymysql.connect(**DB_CONFIG)
    try:
        with connection.cursor() as cursor:
            print("Connected to MySQL. Initiating Schema Setup...")

            # --- TEAR DOWN PHASE ---
            print("Dropping existing tables...")
            # MUST drop the child table (applicant) before the parent table (institute)
            cursor.execute("DROP TABLE IF EXISTS applicant;")
            print(" - Dropped 'applicant'")

            cursor.execute("DROP TABLE IF EXISTS institute;")
            print(" - Dropped 'institute'")


            # --- BUILD PHASE ---
            print("Building new schema...")

            # 1. Create Institute Table
            institute_ddl = """
            CREATE TABLE institute (
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
            """
            cursor.execute(institute_ddl)
            print("'institute' table created.")

            # 2. Create Applicant Table (With Auto-Increment Primary Key)
            applicant_ddl = """
            CREATE TABLE applicant (
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
            """
            cursor.execute(applicant_ddl)
            print("'applicant' table created.")

            print("Schema setup complete!")

    except Exception as e:
        print(f"Error setting up schema: {e}")
    finally:
        connection.close()

if __name__ == "__main__":
    setup_oltp_schema()
