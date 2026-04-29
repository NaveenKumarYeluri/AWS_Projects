import os
import redshift_connector
from dotenv import load_dotenv

load_dotenv()

REDSHIFT_CONFIG = {
    'host': os.getenv('REDSHIFT_HOST'),
    'database': os.getenv('REDSHIFT_DB'),
    'user': os.getenv('REDSHIFT_USER'),
    'password': os.getenv('REDSHIFT_PASSWORD')
}

def create_schema():
    if not REDSHIFT_CONFIG['password']:
        raise ValueError("Missing Redshift credentials in .env file!")

    print("Connecting to Redshift to build schema...")
    try:
        conn = redshift_connector.connect(**REDSHIFT_CONFIG)
        cursor = conn.cursor()

        ddl_queries = """
        -- 0. CREATE THE SCHEMA
        CREATE SCHEMA IF NOT EXISTS aws_project;

        -- 1. STAGING TABLES
        DROP TABLE IF EXISTS aws_project.stg_csv_raw CASCADE;
        CREATE TABLE aws_project.stg_csv_raw (
            departure_time VARCHAR(50), arrival_time VARCHAR(50), flight_id VARCHAR(50),
            aircraft_id VARCHAR(50), itinerary_no VARCHAR(50), ticket_no VARCHAR(50),
            flight_cost NUMERIC(10,2), origin_airport VARCHAR(100), destination_airport VARCHAR(100),
            frequent_flier VARCHAR(10), travel_date VARCHAR(50), airplane_model VARCHAR(100),
            frequent_flier_no VARCHAR(50), passenger_name VARCHAR(255), passenger_country VARCHAR(100),
            tail_no VARCHAR(50), distance NUMERIC(10,2), turbulance NUMERIC(10,2),
            temp_at_dept NUMERIC(10,2), fuel_consumed_litre NUMERIC(10,2), taxi_duration_mins NUMERIC(10,2),
            avg_flight_speed_kmps NUMERIC(10,2), engine_performance NUMERIC(10,2),
            passenger_dob VARCHAR(50), passenger_flight_class VARCHAR(50)
        );

        DROP TABLE IF EXISTS aws_project.stg_json_raw CASCADE;
        CREATE TABLE aws_project.stg_json_raw (
            passenger_id VARCHAR(50), itinerary_no VARCHAR(50), passenger_address VARCHAR(500),
            passenger_country VARCHAR(100), aircraft_id VARCHAR(50), flight_id VARCHAR(50),
            dep_time VARCHAR(50), arrival_time VARCHAR(50), tickets VARCHAR(50)
        );

        -- 2. DIMENSION TABLES
        CREATE TABLE IF NOT EXISTS aws_project.Dim_Date (
            date_sk INT PRIMARY KEY, travel_date DATE, year INT, quarter INT, month INT, day_of_week INT
        ) DISTSTYLE ALL SORTKEY (date_sk);

        CREATE TABLE IF NOT EXISTS aws_project.Dim_Aircraft (
            aircraft_sk BIGINT IDENTITY(1,1) PRIMARY KEY, aircraft_id VARCHAR(50),
            airplane_model VARCHAR(100), tail_no VARCHAR(50)
        ) DISTSTYLE ALL SORTKEY (aircraft_sk);

        CREATE TABLE IF NOT EXISTS aws_project.Dim_Flight_Route (
            flight_sk BIGINT IDENTITY(1,1) PRIMARY KEY, flight_id VARCHAR(50), itinerary_no VARCHAR(50),
            origin_airport VARCHAR(100), destination_airport VARCHAR(100)
        ) DISTSTYLE KEY DISTKEY (flight_sk) SORTKEY (origin_airport, destination_airport);

        CREATE TABLE IF NOT EXISTS aws_project.Dim_Passenger (
            passenger_sk BIGINT IDENTITY(1,1) PRIMARY KEY, passenger_id VARCHAR(50),
            passenger_name VARCHAR(255), passenger_address VARCHAR(500), passenger_country VARCHAR(100),
            passenger_dob DATE, frequent_flier_no VARCHAR(50), frequent_flier_status VARCHAR(10)
        ) DISTSTYLE KEY DISTKEY (passenger_sk) SORTKEY (passenger_country);

        -- 3. FACT TABLES
        CREATE TABLE IF NOT EXISTS aws_project.Fact_Flight (
            flight_fk BIGINT, aircraft_fk BIGINT, date_fk INT, departure_time TIMESTAMP, arrival_time TIMESTAMP,
            distance NUMERIC(10,2), fuel_consumed_litre NUMERIC(10,2), taxi_duration_mins NUMERIC(10,2),
            avg_flight_speed_kmps NUMERIC(10,2), engine_performance NUMERIC(10,2), turbulence NUMERIC(10,2),
            temp_at_dept NUMERIC(10,2)
        ) DISTSTYLE KEY DISTKEY (flight_fk) SORTKEY (date_fk, flight_fk);

        CREATE TABLE IF NOT EXISTS aws_project.Fact_Ticket (
            ticket_no VARCHAR(50) PRIMARY KEY, passenger_fk BIGINT, flight_fk BIGINT, date_fk INT,
            passenger_flight_class VARCHAR(50), flight_cost NUMERIC(10,2)
        ) DISTSTYLE KEY DISTKEY (passenger_fk) SORTKEY (date_fk, flight_fk);
        """

        cursor.execute(ddl_queries)
        conn.commit()
        print("Success!")

    except Exception as e:
        print(f"Error: {e}")
        if 'conn' in locals(): conn.rollback()
    finally:
        if 'cursor' in locals(): cursor.close()
        if 'conn' in locals(): conn.close()

if __name__ == "__main__":
    create_schema()
