import mysql.connector
import glob
import os
from dotenv import load_dotenv
import time

# Load variables from the .env file
load_dotenv()

# Build the config dynamically
db_config = {
    'host': os.getenv('RDS_ENDPOINT'),
    'port': 3306,
    'user': os.getenv('PIPELINE_USER'),
    'password': os.getenv('PIPELINE_PASS'),
    'database': 'aws_project',
    'allow_local_infile': True
}


# Make sure these point to the correct folders where your files live
ingestion_tasks = {
    'institute_stg': os.getenv('INSTITUTE'),
    'applicant_stg': os.getenv('APPLICANT')
}

try:
    print("Connecting to database...")
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()

    for table_name, file_pattern in ingestion_tasks.items():
        files_to_load = sorted(glob.glob(file_pattern))

        if not files_to_load:
            print(f"Warning: No files found for table '{table_name}' at {file_pattern}")
            continue

        print(f"\n========================================")
        print(f"Starting ingestion for table: {table_name.upper()}")
        print(f"Found {len(files_to_load)} files to process.")
        print(f"========================================")

        total_rows_inserted = 0
        start_time = time.time()

        # Loop through and load the files
        for file_path in files_to_load:
            file_name = os.path.basename(file_path)
            print(f" -> Loading {file_name}...")

            # The native MySQL bulk load command
            load_query = f"""
                LOAD DATA LOCAL INFILE '{file_path}'
                INTO TABLE {table_name}
                FIELDS TERMINATED BY ','
                ENCLOSED BY '"'
                LINES TERMINATED BY '\\n'
                IGNORE 1 ROWS;
            """
            cursor.execute(load_query)
            conn.commit()

            rows = cursor.rowcount
            total_rows_inserted += rows
            print(f"    Success: Inserted {rows:,} rows.")

        elapsed = round(time.time() - start_time, 2)
        print(f"----------------------------------------")
        print(f"FINISHED {table_name.upper()}: {total_rows_inserted:,} total rows inserted in {elapsed} seconds.")

except mysql.connector.Error as err:
    print(f"\nDatabase Error: {err}")
except Exception as e:
    print(f"\nSystem Error: {e}")
finally:
    if 'conn' in locals() and conn.is_connected():
        cursor.close()
        conn.close()
        print("\nAll tasks completed. Database connection closed safely.")
