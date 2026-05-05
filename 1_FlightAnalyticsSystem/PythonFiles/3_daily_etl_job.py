import os
import time
import boto3
from datetime import datetime, timedelta
from dotenv import load_dotenv

load_dotenv()

# --- CONFIGURATION ---
AWS_REGION = os.getenv('AWS_DEFAULT_REGION')
WORKGROUP = os.getenv('REDSHIFT_WORKGROUP')
DB_NAME = os.getenv('REDSHIFT_DB')
IAM_ROLE = os.getenv('REDSHIFT_IAM_ROLE')
CSV_SOURCE = os.getenv('CSV_SOURCE')
S3_BUCKET = os.getenv('S3_BUCKET')

# Initialize Clients
data_client = boto3.client('redshift-data', region_name=AWS_REGION)
s3_client = boto3.client('s3', region_name=AWS_REGION)

def run_sql(sql_text):
    """Executes SQL and waits for completion. Returns the Query ID string."""
    response = data_client.execute_statement(
        WorkgroupName=WORKGROUP,
        Database=DB_NAME,
        Sql=sql_text
    )
    query_id = response['Id'] # This is a string

    while True:
        status_resp = data_client.describe_statement(Id=query_id)
        status = status_resp['Status']

        if status == 'FINISHED':
            return query_id  # <--- CRITICAL: Return ONLY the string ID
        elif status in ['FAILED', 'ABORTED']:
            raise Exception(f"SQL Failed: {status_resp.get('Error')}")

        time.sleep(1)

def get_first_value(query_id, column_index=0):
    """Safely pulls one value, handling NULLs (which the API returns as {'isNull': True})."""
    result = data_client.get_statement_result(Id=query_id)
    records = result.get('Records')

    if not records or not records[0]:
        return None

    val_dict = records[0][column_index]

    # If the database returned NULL, the API gives us {'isNull': True}
    if val_dict.get('isNull'):
        return None

    # Otherwise, return the actual data (stringValue, longValue, etc.)
    # We grab the first value that isn't the 'isNull' key
    for key, value in val_dict.items():
        if key != 'isNull':
            return value
    return None

def get_results(query_id):
    """Fetches the actual rows from a finished query."""
    return data_client.get_statement_result(Id=query_id)['Records']

# --- HELPER: DATE GENERATION ---
def generate_date_records(start_date, end_date):
    delta = timedelta(days=1)
    date_records = []
    curr = start_date
    while curr <= end_date:
        day_of_week = curr.weekday() + 1
        # Format for SQL VALUES clause: (sk, 'date', yr, mon, day, qtr, dow, 'dname', 'mname', bool)
        record = (
            f"({curr.strftime('%Y%m%d')}, '{curr.isoformat()}', {curr.year}, {curr.month}, "
            f"{curr.day}, {(curr.month-1)//3+1}, {day_of_week}, '{curr.strftime('%A')}', "
            f"'{curr.strftime('%B')}', {'TRUE' if day_of_week in (6,7) else 'FALSE'})"
        )
        date_records.append(record)
        curr += delta
    return date_records

# --- S3 ARCHIVAL ---
def archive_s3_files():
    print("\n--- Archiving S3 Files ---")
    source_prefix = 'Flight_Analytics_System/CSV_Source_Files/'
    archive_prefix = 'Flight_Analytics_System/Archive_CSV_Files/'

    response = s3_client.list_objects_v2(Bucket=S3_BUCKET, Prefix=source_prefix)
    if 'Contents' not in response: return

    for obj in response['Contents']:
        old_key = obj['Key']
        if old_key.endswith('/'): continue
        filename = old_key.split('/')[-1]
        new_key = f"{archive_prefix}{filename}"

        s3_client.copy_object(CopySource={'Bucket': S3_BUCKET, 'Key': old_key}, Bucket=S3_BUCKET, Key=new_key)
        s3_client.delete_object(Bucket=S3_BUCKET, Key=old_key)
        print(f" Moved {filename} to Archive.")

# --- MAIN ETL ---
def execute_obt_etl():
    print(f"Starting ETL for Workgroup: {WORKGROUP}")

    try:
        ## STEP 1: LOAD STAGING
        #print("1. Truncating and Copying Staging...")
        #copy_sql = f"""
        #    TRUNCATE TABLE aws_project.stg_csv_raw;
        #    COPY aws_project.stg_csv_raw FROM '{CSV_SOURCE}'
        #    IAM_ROLE '{IAM_ROLE}' FORMAT AS CSV IGNOREHEADER 1;
        #"""
        #run_sql(copy_sql)

        # STEP 2: DYNAMIC DATES
        print("2. Syncing Date Dimension...")

        qid_dim = run_sql("SELECT MAX(full_date) FROM aws_project.Dim_Date;")
        dim_max_str = get_first_value(qid_dim)

        qid_stg = run_sql("SELECT MIN(CAST(travel_date AS DATE)), MAX(CAST(travel_date AS DATE)) FROM aws_project.stg_csv_raw;")
        # Note: Since this query has TWO columns, we fetch them specifically
        stg_res = data_client.get_statement_result(Id=qid_stg)['Records'][0]

        # Helper to extract from a specific column index
        def extract_val(val_dict):
            if not val_dict or val_dict.get('isNull'): return None
            return list(val_dict.values())[0]

        stg_min_str = extract_val(stg_res[0])
        stg_max_str = extract_val(stg_res[1])

        # Only proceed if there is actually data in staging
        if stg_max_str:
            stg_max = datetime.strptime(stg_max_str, '%Y-%m-%d').date()
            stg_min = datetime.strptime(stg_min_str, '%Y-%m-%d').date()

            # Handle the case where Dim_Date is empty (None)
            dim_max_date = None
            if dim_max_str:
                dim_max_date = datetime.strptime(dim_max_str, '%Y-%m-%d').date()

            # Logic to decide if we need more dates
            if not dim_max_date or stg_max > dim_max_date:
                print(f"   Table needs updates. Generating dates...")
                start = (dim_max_date + timedelta(days=1)) if dim_max_date else stg_min
                end = stg_max + timedelta(days=730)

                date_vals = generate_date_records(start, end)
                if date_vals:
                    insert_dates_sql = f"INSERT INTO aws_project.Dim_Date VALUES {','.join(date_vals)};"
                    run_sql(insert_dates_sql)

        # STEP 3 & 4: DEDUPE & UPSERT (Fixed for Decimal-to-Integer casting)
        print("3 & 4. Deduplicating and Upserting OBT...")
        upsert_sql = """
            DROP TABLE IF EXISTS temp_obt_clean;
            CREATE TEMP TABLE temp_obt_clean AS
            WITH DeduplicatedData AS (
                SELECT *, ROW_NUMBER() OVER (PARTITION BY TRIM(ticket_no) ORDER BY travel_date DESC) as row_num
                FROM aws_project.stg_csv_raw WHERE ticket_no IS NOT NULL
            )
            SELECT
                TRIM(ticket_no) as ticket_no,
                TRIM(flight_id) as flight_id,
                -- Use DOUBLE CAST for BigInt/Int columns that might have decimals in CSV
                CAST(CAST(NULLIF(TRIM(itinerary_no), '') AS DECIMAL) AS BIGINT) as itinerary_no,
                CAST(TO_CHAR(CAST(NULLIF(TRIM(travel_date), '') AS DATE), 'YYYYMMDD') AS INT) as date_fk,
                CAST(NULLIF(TRIM(travel_date), '') || ' ' || NULLIF(TRIM(departure_time), '') AS TIMESTAMP) as departure_time,
                CAST(NULLIF(TRIM(travel_date), '') || ' ' || NULLIF(TRIM(arrival_time), '') AS TIMESTAMP) as arrival_time,
                TRIM(aircraft_id) as aircraft_id,
                TRIM(airplane_model) as airplane_model,
                TRIM(tail_no) as tail_no,
                TRIM(origin_airport) as origin_airport,
                TRIM(destination_airport) as destination_airport,
                TRIM(passenger_name) as passenger_name,
                TRIM(passenger_country) as passenger_country,
                CAST(NULLIF(TRIM(passenger_dob), '') AS DATE) as passenger_dob,
                TRIM(frequent_flier_no) as frequent_flier_no,
                CASE WHEN UPPER(TRIM(frequent_flier)) IN ('TRUE', '1', 'YES') THEN TRUE ELSE FALSE END as frequent_flier_status,
                TRIM(passenger_flight_class) as passenger_flight_class,
                CAST(NULLIF(TRIM(flight_cost), '') AS DECIMAL(10,2)) as flight_cost,
                CAST(NULLIF(TRIM(distance), '') AS DECIMAL(10,2)) as distance,
                CAST(NULLIF(TRIM(fuel_consumed_litre), '') AS DECIMAL(10,2)) as fuel_consumed_litre,

                -- CRITICAL FIXES HERE: Double-Cast to handle '.0' in CSVs
                CAST(CAST(NULLIF(TRIM(taxi_duration_mins), '') AS DECIMAL) AS INT) as taxi_duration_mins,
                CAST(CAST(NULLIF(TRIM(avg_flight_speed_kmps), '') AS DECIMAL) AS DECIMAL(10,2)) as avg_flight_speed_kmps,
                CAST(CAST(NULLIF(TRIM(engine_performance), '') AS DECIMAL) AS INT) as engine_performance,
                CAST(CAST(NULLIF(TRIM(turbulance), '') AS DECIMAL) AS INT) as turbulence,
                CAST(NULLIF(TRIM(temp_at_dept), '') AS DECIMAL(5,2)) as temp_at_dept
            FROM DeduplicatedData WHERE row_num = 1;

            DELETE FROM aws_project.Fact_Flight_Transactions
            USING temp_obt_clean WHERE aws_project.Fact_Flight_Transactions.ticket_no = temp_obt_clean.ticket_no;

            INSERT INTO aws_project.Fact_Flight_Transactions SELECT * FROM temp_obt_clean;
        """
        run_sql(upsert_sql)
        print("✅ Pipeline Success!")

        # STEP 5: S3 ARCHIVAL
        archive_s3_files()

    except Exception as e:
        print(f"❌ ETL Failed: {e}")

if __name__ == "__main__":
    execute_obt_etl()
