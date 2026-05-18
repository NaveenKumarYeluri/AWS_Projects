import os
import boto3
import time
import logging
from dotenv import load_dotenv

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# --- Redshift Configs ---
WORKGROUP = os.getenv('REDSHIFT_WORKGROUP')
DB_NAME = os.getenv('REDSHIFT_DB')
REGION_NAME = os.getenv('AWS_DEFAULT_REGION')

if not all([WORKGROUP, DB_NAME, REGION_NAME]):
    raise ValueError("Missing database configuration. Please check your .env file.")

redshift_client = boto3.client('redshift-data', region_name=REGION_NAME)

# --- DDL Queries ---
CREATE_INSTITUTE_TABLE = """
CREATE TABLE aws_project.institute(
    institute_id_sk VARCHAR PRIMARY KEY,
    institute_name VARCHAR,
    institute_fee DOUBLE PRECISION,
    institute_reputation DOUBLE PRECISION,
    institute_campus_job_placement_pct DOUBLE PRECISION,
    institute_campus_area DOUBLE PRECISION,
    score_cut_off DOUBLE PRECISION,
    total_no_of_students BIGINT,
    applied_no_of_students BIGINT,
    declined_no_of_student_pct DOUBLE PRECISION,
    accepted_no_of_student_pct DOUBLE PRECISION
)
DISTSTYLE KEY
DISTKEY (institute_id_sk)
SORTKEY (institute_id_sk);
"""

CREATE_APPLICANT_TABLE = """
CREATE TABLE aws_project.applicant(
    applicant_id_sk BIGINT PRIMARY KEY,
    applicant_name VARCHAR,
    applicant_gender VARCHAR,
    applicant_dob TIMESTAMP,
    applicant_country VARCHAR,
    applicant_qual_test_score DOUBLE PRECISION,
    applicant_high_school_GPA DOUBLE PRECISION,
    scholarship_grade VARCHAR,
    scholarship_pct DOUBLE PRECISION,
    interview_date DATE,
    interview_score DOUBLE PRECISION,
    admission_date TIMESTAMP,
    institute_id_fk VARCHAR,
    course_name VARCHAR,
    FOREIGN KEY (institute_id_fk) REFERENCES aws_project.institute(institute_id_sk)
)
DISTSTYLE EVEN
SORTKEY (applicant_id_sk);
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
                logger.info(f"SUCCESS: {description}\n")
                break
            elif status in ['FAILED', 'ABORTED']:
                error_msg = desc_response.get('Error', 'Unknown Error')
                logger.error(f"FAILED: {description}. Error: {error_msg}\n")
                raise Exception(f"Query failed: {error_msg}")
            time.sleep(2)
    except Exception as e:
        logger.error(f"Exception during '{description}': {str(e)}")
        raise

def main():
    try:
        logger.info("--- Starting Table Creation ---")
        execute_and_wait(CREATE_INSTITUTE_TABLE, "Create Institute Table")
        execute_and_wait(CREATE_APPLICANT_TABLE, "Create Applicant Table")
        logger.info("--- Table Creation Completed Successfully! ---")
    except Exception:
        logger.error("Script execution stopped due to an error.")

if __name__ == "__main__":
    main()
