import os
import boto3
import time
import logging
from dotenv import load_dotenv
from concurrent.futures import ThreadPoolExecutor, as_completed

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

load_dotenv()

# Configs
AWS_REGION = os.getenv('AWS_DEFAULT_REGION')
WORKGROUP = os.getenv('REDSHIFT_WORKGROUP')
DB_NAME = os.getenv('REDSHIFT_DB')
IAM_ROLE = os.getenv('REDSHIFT_IAM_ROLE')
CSV_SOURCE = os.getenv('CSV_SOURCE')
S3_BUCKET = os.getenv('S3_BUCKET')

if not all([WORKGROUP, DB_NAME, AWS_REGION, IAM_ROLE, CSV_SOURCE, S3_BUCKET]):
    raise ValueError("Missing database or S3 configuration. Please check your .env file.")

redshift_client = boto3.client('redshift-data', region_name=AWS_REGION)


COPY_INSTITUTE_DATA = f"""
COPY aws_project.institute
FROM 's3://{S3_BUCKET}/{CSV_SOURCE}/Institute_Source_Files/'
IAM_ROLE '{IAM_ROLE}'
FORMAT csv QUOTE as '"'
delimiter as ','
ignoreheader 1
region '{AWS_REGION}';
"""

# 1. Prepare Staging Table, once full data is loaded to main table it will be dropped.
PREPARE_STAGING_TABLE = """
DROP TABLE IF EXISTS aws_project.applicant_staging;
CREATE TABLE aws_project.applicant_staging (LIKE aws_project.applicant);
"""

# 2. Modify individual copy to target STAGING table
def get_applicant_copy_query(file_number):
    return f"""
    COPY aws_project.applicant_staging
    FROM 's3://{S3_BUCKET}/{CSV_SOURCE}/Applicant_Source_Files/education_applicant_data_{file_number}.csv'
    IAM_ROLE '{IAM_ROLE}'
    FORMAT csv QUOTE as '"'
    delimiter as ','
    ignoreheader 1
    region '{AWS_REGION}';
    """

# 3. Modify bulk copy to target STAGING table
COPY_ALL_APPLICANTS_DATA = f"""
COPY aws_project.applicant_staging
FROM 's3://{S3_BUCKET}/{CSV_SOURCE}/Applicant_Source_Files/'
IAM_ROLE '{IAM_ROLE}'
FORMAT csv QUOTE as '"'
delimiter as ','
ignoreheader 1
region '{AWS_REGION}';
"""

# 4. Final Merge Query (Now drops the staging table upon success)
MERGE_STAGING_TO_FINAL = """
BEGIN;
INSERT INTO aws_project.applicant SELECT * FROM aws_project.applicant_staging;
DROP TABLE aws_project.applicant_staging;
COMMIT;
"""


def execute_and_wait(sql_query, description):
    logger.info(f"Starting: {description}...")
    try:
        response = redshift_client.execute_statement(
            WorkgroupName=WORKGROUP,
            Database=DB_NAME,
            Sql=sql_query
        )
        statement_id = response['Id']

        while True:
            desc_response = redshift_client.describe_statement(Id=statement_id)
            status = desc_response['Status']
            if status == 'FINISHED':
                logger.info(f"SUCCESS: {description}")
                return True
            elif status in ['FAILED', 'ABORTED']:
                error_msg = desc_response.get('Error', 'Unknown Error')
                logger.error(f"FAILED: {description}. Error: {error_msg}")
                raise Exception(f"Query failed: {error_msg}")

            time.sleep(1)
    except Exception as e:
        logger.error(f"Exception during '{description}': {str(e)}")
        raise


def load_individual_file(file_num, iteration):
    query = get_applicant_copy_query(file_num)
    description = f"Load Applicant File {file_num} to STAGING (Iteration {iteration}/4)"
    execute_and_wait(query, description)


def main():
    try:
        logger.info("--- Starting Data Load Process ---")

        # Step 1: Load Institute Data (Sequential)
        execute_and_wait(COPY_INSTITUTE_DATA, "Load Institute Data (Folder Level)")

        # Step 2: Prepare Staging
        logger.info("--- Preparing Staging Environment ---")
        execute_and_wait(PREPARE_STAGING_TABLE, "Create Fresh Staging Table")

        # Step 3: Concurrent Loads into STAGING
        logger.info("--- Starting Concurrent Individual File Loads to STAGING ---")

        with ThreadPoolExecutor(max_workers=10) as executor:
            futures = []
            for file_num in range(1, 15):
                for iteration in range(1, 5):
                    futures.append(
                        executor.submit(load_individual_file, file_num, iteration)
                    )

            for future in as_completed(futures):
                future.result()

        logger.info("--- Concurrent Individual Loads to STAGING Finished ---")

        # Step 4: Load remaining data into STAGING
        execute_and_wait(COPY_ALL_APPLICANTS_DATA, "Load All Applicant Data to STAGING (Folder Level)")

        # Step 5: The Final Merge & Cleanup
        logger.info("--- All staging loads successful. Pushing to Production Table ---")
        execute_and_wait(MERGE_STAGING_TO_FINAL, "Merge Data and Drop Staging Table")

        logger.info("--- All Data Loaded Successfully! ---")

    except Exception as e:
        logger.error(f"SCRIPT ABORTED. Main table was NOT updated. Fix the error and re-run. Reason: {e}")

if __name__ == "__main__":
    main()
