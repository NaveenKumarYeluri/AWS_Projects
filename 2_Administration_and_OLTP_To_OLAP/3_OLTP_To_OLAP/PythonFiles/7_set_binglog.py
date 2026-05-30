import mysql.connector
import os
from dotenv import load_dotenv

load_dotenv()

db_config = {
    'host': os.getenv('RDS_ENDPOINT'),
    'port': 3306,
    'user': os.getenv('MASTER_USER'),
    'password': os.getenv('MASTER_PASS'),
    'database': 'aws_project'
}

try:
    conn = mysql.connector.connect(**db_config)
    conn.autocommit = True
    cursor = conn.cursor()

    print("Forcing binlog retention to 12 hours...")
    cursor.execute("CALL mysql.rds_set_configuration('binlog retention hours', 12);")
    print("Command executed successfully.\n")

    print("Verifying Current RDS Configuration:")
    cursor.execute("CALL mysql.rds_show_configuration;")

    # Fetch and print the results
    results = cursor.fetchall()
    for row in results:
        if row[0] == 'binlog retention hours':
            print(f" -> {row[0]}: {row[1]} hours")

except Exception as e:
    print(f"Error: {e}")
finally:
    if 'conn' in locals() and conn.is_connected():
        cursor.close()
        conn.close()
