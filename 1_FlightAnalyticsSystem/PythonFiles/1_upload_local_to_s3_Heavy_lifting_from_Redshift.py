import logging
import boto3
from botocore.exceptions import ClientError
from pathlib import Path
from dotenv import load_dotenv
import os

load_dotenv()
TARGET_REGION = os.getenv('AWS_DEFAULT_REGION')
BUCKET_NAME = os.getenv('S3_BUCKET')
BASE_PREFIX = os.getenv('BASE_PREFIX')
LOCAL_FOLDER = os.getenv('LOCAL_FOLDER')

def build_files_dictionary(directory_path):
    # .expanduser() fixes the "~/" problem
    # .resolve() turns relative paths into strict absolute paths
    folder_path = Path(directory_path).expanduser().resolve()

    if not folder_path.exists():
        print("ERROR: Python cannot find this folder path!")
        return {}

    # Creates a dictionary of {filename: full_path}
    files_dict = {
        file.name: str(file)
        for file in folder_path.rglob('*')
        # .lower() ensures we catch '.CSV', '.Csv', and '.csv'
        if file.is_file() and file.suffix.lower() == '.csv'
    }

    print(f"Found {len(files_dict)} CSV files.")
    return files_dict

def upload_file(file_name, bucket, object_name):
    """Upload a file to an S3 bucket

    :param file_name: File to upload
    :param bucket: Bucket to upload to
    :param object_name: S3 object name. If not specified then file_name is used
    :return: True if file was uploaded, else False
    """

    # region name
    target_region = TARGET_REGION

    # we will upload file to specific bucket in specific region
    s3_client = boto3.client('s3', region_name=target_region)

    try:
        # boto3 expects 'Bucket' to be just the name, object_name can include folders structure + filename
        response = s3_client.upload_file(
            file_name,
            bucket,
            object_name,
        )
        print() # Prints a clean newline when the file finishes hitting 100%
    except ClientError as e:
        logging.error(e)
        return False
    return True

def upload_local_to_s3():
    # bucket name
    bucket_name = BUCKET_NAME
    # base folder path to prepend to our object names
    base_prefix = BASE_PREFIX
    # local system file path
    # kept sample files in GitHub for reference
    local_folder = LOCAL_FOLDER

    # Files Dictionary to upload
    files = build_files_dictionary(local_folder)

    if not files:
        print("No .csv files found in the directory.")
        return

    for s3_object_name, local_full_file_path in files.items():
        print(f"\n--- Preparing to upload {s3_object_name} ---")

        if s3_object_name.endswith('.csv'):
            # Combine the base folder, the dynamic subfolder, and the file name
            full_object_key = f"{base_prefix}CSV_Source_Files/{s3_object_name}"

            status = upload_file(
                file_name=local_full_file_path,
                bucket=bucket_name,
                object_name=full_object_key
            )

        if status:
            print(f"Success! {s3_object_name} is uploaded to S3.")
        else:
            print(f"Failed to upload {s3_object_name}.")

if __name__ == "__main__":
    upload_local_to_s3()
