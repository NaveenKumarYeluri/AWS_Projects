import os
import boto3
import time
from dotenv import load_dotenv


load_dotenv()


# Standard configuration from .env
WORKGROUP = os.getenv('REDSHIFT_WORKGROUP')
DB_NAME = os.getenv('REDSHIFT_DB')
REGION_NAME=os.getenv('AWS_DEFAULT_REGION')

# Initialize the Data API client globally
data_client = boto3.client('redshift-data', region_name=REGION_NAME)


def run_sql(sql_text):
    """
    Standard Helper: Executes SQL and waits for completion.
    This ensures tables are created in the correct order.
    """
    response = data_client.execute_statement(
        WorkgroupName=WORKGROUP,
        Database=DB_NAME,
        Sql=sql_text
    )
    query_id = response['Id']

    # We will not allow another API call from this script
    # until the previous call is completed.
    while True:
        status_resp = data_client.describe_statement(Id=query_id)
        status = status_resp['Status']

        if status == 'FINISHED':
            return query_id
        elif status in ['FAILED', 'ABORTED']:
            raise Exception(f"SQL Failed: {status_resp.get('Error')}\nQuery: {sql_text[:100]}")

        time.sleep(1)


def deploy_schema():
    print(f"🚀 Deploying Schema to Workgroup: {WORKGROUP}")

    try:

        # 2. Drop Old Tables (Order matters: Drop Fact before Dim)
        print("Cleaning up old tables...")
        drop_sql = """
            DROP TABLE IF EXISTS aws_project.Fact_Flight_Transactions CASCADE;
            DROP TABLE IF EXISTS aws_project.Dim_Date CASCADE;
            DROP TABLE IF EXISTS aws_project.stg_csv_raw CASCADE;
        """
        run_sql(drop_sql)

        # ==========================================
        # 2. STAGING TABLE
        # ==========================================
        print("Creating Staging Table...")
        run_sql("""
            CREATE TABLE IF NOT EXISTS aws_project.stg_csv_raw (
                departure_time VARCHAR(100), arrival_time VARCHAR(100), flight_id VARCHAR(100),
                aircraft_id VARCHAR(100), itinerary_no VARCHAR(100), ticket_no VARCHAR(100), flight_cost VARCHAR(100),
                origin_airport VARCHAR(100), destination_airport VARCHAR(100), frequent_flier VARCHAR(100),
                travel_date VARCHAR(100), airplane_model VARCHAR(100), frequent_flier_no VARCHAR(100),
                passenger_name VARCHAR(100), passenger_country VARCHAR(100), tail_no VARCHAR(100),
                distance VARCHAR(100), turbulance VARCHAR(100), temp_at_dept VARCHAR(100), fuel_consumed_litre VARCHAR(100),
                taxi_duration_mins VARCHAR(100), avg_flight_speed_kmps VARCHAR(100), engine_performance VARCHAR(100),
                passenger_dob VARCHAR(100), passenger_flight_class VARCHAR(100)
            );
        """)

        # ==========================================
        # 3. DATE DIMENSION
        # ==========================================
        print("Creating Dim_Date...")
        run_sql("""
            CREATE TABLE IF NOT EXISTS aws_project.Dim_Date (
                date_sk INT PRIMARY KEY,
                full_date DATE,
                calendar_year INT,
                calendar_month INT,
                calendar_day INT,
                calendar_quarter INT,
                day_of_week INT,
                day_name VARCHAR(20),
                month_name VARCHAR(20),
                is_weekend BOOLEAN
            );
        """)

        # ==========================================
        # 4. ONE BIG TABLE (OBT)
        # ==========================================
        print("Creating Fact_Flight_Transactions...")
        run_sql("""
            CREATE TABLE IF NOT EXISTS aws_project.Fact_Flight_Transactions (
                ticket_no VARCHAR(50) PRIMARY KEY,
                flight_id VARCHAR(50),
                itinerary_no BIGINT,
                date_fk INT REFERENCES aws_project.Dim_Date(date_sk),
                departure_time TIMESTAMP,
                arrival_time TIMESTAMP,
                aircraft_id VARCHAR(50),
                airplane_model VARCHAR(100),
                tail_no VARCHAR(50),
                origin_airport VARCHAR(100),
                destination_airport VARCHAR(100),
                passenger_name VARCHAR(100),
                passenger_country VARCHAR(100),
                passenger_dob DATE,
                frequent_flier_no VARCHAR(50),
                frequent_flier_status BOOLEAN,
                passenger_flight_class VARCHAR(50),
                flight_cost DECIMAL(10,2),
                distance DECIMAL(10,2),
                fuel_consumed_litre DECIMAL(10,2),
                taxi_duration_mins INT,
                avg_flight_speed_kmps DECIMAL(10,2),
                engine_performance INT,
                turbulence INT,
                temp_at_dept DECIMAL(5,2)
            );
        """)

        print("✅ Success: Schema and Tables are ready for the ETL!")

    except Exception as e:
        print(f"❌ Schema Deployment Failed: {e}")


if __name__ == "__main__":
    deploy_schema()
