import boto3
import json
from dotenv import load_dotenv

load_dotenv()

BUCKET_NAME = os.getenv('S3_BUCKET')
SPLIT_PREFIX = 'Education_System/Orders_Files/split_data/'

s3_client = boto3.client(
    's3',
    aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
    aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'),
    region_name=os.getenv('AWS_DEFAULT_REGION')
)

# Scan the Athena output directory to find the compressed split files
res = s3_client.list_objects_v2(Bucket=BUCKET_NAME, Prefix=SPLIT_PREFIX)
manifest_entries = []

if 'Contents' in res:
    for obj in res['Contents']:
        if obj['Key'].endswith('.gz') and '$folder$' not in obj['Key']:
            s3_uri = f"s3://{BUCKET_NAME}/{obj['Key']}"
            manifest_entries.append({"url": s3_uri, "mandatory": True})

# Wrap into Redshift manifest JSON format
manifest_json = {"entries": manifest_entries}
manifest_key = 'Education_System/Orders_Files/split_data/athena_orders_manifest.json'

# Upload the final manifest back to S3
s3_client.put_object(
    Bucket=BUCKET_NAME,
    Key=manifest_key,
    Body=json.dumps(manifest_json, indent=4),
    ContentType='application/json'
)

print(f"✨ Manifest created successfully at: ")
print(f"s3://{BUCKET_NAME}/{manifest_key}")
