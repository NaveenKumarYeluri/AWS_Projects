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
    'database': 'aws_project'
}

def verify_data():
    connection = pymysql.connect(**DB_CONFIG)
    try:
        with connection.cursor() as cursor:
            print("🔍 Querying MySQL Database...\n")

            # --- 1. Check Institute Table ---
            cursor.execute("SELECT COUNT(*) FROM institute;")
            institute_count = cursor.fetchone()[0]
            print(f"🏢 Total Institutes Loaded: {institute_count}")

            if institute_count > 0:
                print("Sample Institute Data:")
                cursor.execute("SELECT * FROM institute LIMIT 2;")
                for row in cursor.fetchall():
                    print(f"  -> {row}")

            print("\n--------------------------------------------------\n")

            # --- 2. Check Applicant Table ---
            cursor.execute("SELECT COUNT(*) FROM applicant;")
            applicant_count = cursor.fetchone()[0]
            print(f"🎓 Total Applicants Loaded: {applicant_count}")

            if applicant_count > 0:
                print("Sample Applicant Data:")
                cursor.execute("SELECT * FROM applicant LIMIT 2;")
                for row in cursor.fetchall():
                    print(f"  -> {row}")

    except Exception as e:
        print(f"Error querying database: {e}")
    finally:
        connection.close()

if __name__ == "__main__":
    verify_data()
