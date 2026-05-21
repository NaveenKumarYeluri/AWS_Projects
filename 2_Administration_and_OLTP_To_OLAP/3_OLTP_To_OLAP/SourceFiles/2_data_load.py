import os
import csv
import pymysql
from dotenv import load_dotenv

# Load variables from the .env file
load_dotenv()

# Define Directories
BASE_DIR = os.getcwd()
SPLIT_FILES_DIR = os.path.join(BASE_DIR, 'SplitFiles')

# Build the config dynamically
DB_CONFIG = {
    'host': os.getenv('RDS_ENDPOINT'),
    'port': 3306,
    'user': os.getenv('PIPELINE_USER'),
    'password': os.getenv('PIPELINE_PASS'),
    'database': 'aws_project',
    'autocommit': True
}

def load_split_file(filepath, table_name, insert_query):
    print(f"Loading {filepath} into {table_name}...")
    batch_size = 1000 # Reduced to prevent AWS "Packet Too Large" network limits
    data_batch = []
    rows_loaded = 0

    connection = pymysql.connect(**DB_CONFIG)
    try:
        with connection.cursor() as cursor:
            with open(filepath, 'r', encoding='utf-8') as csvfile:
                reader = csv.reader(csvfile)
                next(reader) # Skip header

                for row in reader:
                    # Clean the row (convert empty strings to None for MySQL Nulls)
                    clean_row = tuple(None if val == '' else val for val in row)
                    data_batch.append(clean_row)

                    # When we hit 1,000 rows, push them to the database
                    if len(data_batch) >= batch_size:
                        try:
                            cursor.executemany(insert_query, data_batch)
                            rows_loaded += len(data_batch)
                        except Exception as e:
                            print(f"Batch Error in {filepath}: {e}")

                        data_batch = [] # Reset batch regardless of success or failure

                # Push any remaining rows in the final batch
                if data_batch:
                    try:
                        cursor.executemany(insert_query, data_batch)
                        rows_loaded += len(data_batch)
                    except Exception as e:
                        print(f"Final Batch Error in {filepath}: {e}")

            print(f"Finished {filepath}. Inserted ~{rows_loaded} rows.")
    except Exception as e:
        print(f"Critical Error opening {filepath}: {e}")
    finally:
        connection.close()

if __name__ == "__main__":
    # --- 1. LOAD INSTITUTE FIRST (Foreign Key Requirement) ---
    institute_dir = os.path.join(SPLIT_FILES_DIR, 'institute')
    if os.path.exists(institute_dir):
        # sorted() ensures split_1 is processed before split_2
        institute_files = sorted([f for f in os.listdir(institute_dir) if f.endswith('.csv')])

        # The insert query for the institute table
        institute_query = """
        INSERT INTO institute (
            institute_id_sk, institute_name, institute_fee, institute_reputation,
            institute_campus_job_placement_pct, institute_campus_area, score_cut_off,
            total_no_of_students, applied_no_of_students, declined_no_of_student_pct,
            accepted_no_of_student_pct
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
        """

        # Loop through ALL files in the directory
        for file in institute_files:
            filepath = os.path.join(institute_dir, file)
            load_split_file(filepath, 'institute', institute_query)

    print("\n--------------------------------------------------\n")

    # --- 2. LOAD APPLICANT SECOND ---
    applicant_dir = os.path.join(SPLIT_FILES_DIR, 'applicant')
    if os.path.exists(applicant_dir):
        # sorted() ensures split_1 is processed before split_2
        applicant_files = sorted([f for f in os.listdir(applicant_dir) if f.endswith('.csv')])

        # The insert query for the applicant table
        applicant_query = """
        INSERT INTO applicant (
            applicant_id_sk, applicant_name, applicant_gender, applicant_dob,
            applicant_country, applicant_qual_test_score, applicant_high_school_pct,
            scholarship_grade, scholarship_pct, interview_date, interview_score,
            admission_date, institute_id_fk, course_name
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
        """

        # Loop through ALL files in the directory
        for file in applicant_files:
            filepath = os.path.join(applicant_dir, file)
            load_split_file(filepath, 'applicant', applicant_query)
