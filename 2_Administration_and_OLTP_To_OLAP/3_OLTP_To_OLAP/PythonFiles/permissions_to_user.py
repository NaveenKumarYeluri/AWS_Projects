import pymysql
from dotenv import load_dotenv

# Load variables from the .env file
load_dotenv()

db_user = os.getenv("PIPELINE_USER")
db_password = os.getenv("PIPELINE_PASS")

# 1. Connect using your MASTER RDS credentials directly to the endpoint
connection = pymysql.connect(
    host=os.getenv('RDS_ENDPOINT'),
    port=3306,
    user=os.getenv('MASTER_USER'),  # e.g., 'admin'
    password=os.getenv('MASTER_PASS'),
    autocommit=True
)

try:
    with connection.cursor() as cursor:
        print("Connected to RDS Master. Executing Admin Setup...")

        # 2. Create the database
        cursor.execute("CREATE DATABASE IF NOT EXISTS aws_project;")
        print("- Database 'aws_project' verified.")

        # 3. Create the dedicated pipeline user
        query = f"CREATE USER IF NOT EXISTS '{db_user}'@'%' IDENTIFIED BY '{db_password}';"
        cursor.execute(query)
        print(f"- User '{db_user}' created.")

        # 4. Grant privileges strictly to the aws_project database
        query = f"GRANT ALL PRIVILEGES ON aws_project.* TO '{db_user}'@'%';"
        cursor.execute(query)
        print("- Privileges granted.")

        cursor.execute("FLUSH PRIVILEGES;")
        print("- Privileges flushed.")

        print(f"Setup Complete! You can now use '{db_user}' for your ETL pipeline.")

finally:
    connection.close()
