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
    print("SIMULATING LIVE WEB APP TRANSACTIONS...")
    print("==========================================")

    # --- THE SETUP: Onboard the University ---
    print("Executing Setup: Inserting the Test University...")
    setup_query = """
        INSERT INTO aws_project.institute (
            institute_id_sk,
            institute_name,
            institute_fee
        ) VALUES (
            'TEST-UNI-1',
            'Cloud Computing Institute',
            15000.00
        )
        ON DUPLICATE KEY UPDATE
        institute_name = VALUES(institute_name);
    """
    cursor.execute(setup_query)
    conn.commit()
    print(" -> SUCCESS: Test University is live.\n")

    # --- CASE 1: The Update ---
    print("Executing Case 1: Updating an existing record...")
    update_query = """
        INSERT INTO aws_project.applicant (
            applicant_id_sk,
            applicant_name,
            institute_id_fk,
            interview_score
        ) VALUES (
            %s,
            'Direct Update Test',
            'TEST-UNI-1',
            99.99
        )
        ON DUPLICATE KEY UPDATE
            applicant_name = VALUES(applicant_name),
            institute_id_fk = VALUES(institute_id_fk),
            interview_score = VALUES(interview_score);
    """
    cursor.execute(update_query, (200012,))
    conn.commit()
    print(" -> SUCCESS: Updated existing student profile.\n")


    # --- CASE 2: The New Valid Record (The missing piece) ---
    print("Executing Case 2: Inserting a brand new valid student...")
    valid_insert_query = """
        INSERT INTO aws_project.applicant (
            applicant_id_sk,
            applicant_name,
            institute_id_fk,
            interview_score
        ) VALUES (
            %s,
            'Brand New Valid Student',
            'TEST-UNI-1',
            85.00
        );
    """
    cursor.execute(valid_insert_query, (9999997,))
    conn.commit()
    print(" -> SUCCESS: Inserted perfectly valid new student.\n")


    # --- CASE 3: The New Orphan ---
    print("Executing Case 3: Trapping a bad orphan record...")
    orphan_test_id = 99999999
    bad_college_id = 'BAD-COLLEGE-ID'

    cursor.execute("SELECT 1 FROM aws_project.institute WHERE institute_id_sk = %s;", (bad_college_id,))
    if not cursor.fetchone():
        print(f" -> WEB APP ALERT: College {bad_college_id} does not exist. Routing to DLQ...")
        dlq_query = """
            INSERT INTO aws_project.applicant_exceptions (
                applicant_id_sk,
                applicant_name,
                institute_id_fk,
                error_reason
            ) VALUES (
                %s,
                'Live Orphan Test',
                %s,
                'Caught by Web App Validation'
            );
        """
        cursor.execute(dlq_query, (orphan_test_id, bad_college_id))
        conn.commit()
        print(" -> SUCCESS: Orphan safely trapped in Exception table.\n")

    print("==========================================")
    print("Live transaction simulation complete.")

except Exception as e:
    print(f"Error: {e}")
finally:
    if 'conn' in locals() and conn.is_connected():
        cursor.close()
        conn.close()
