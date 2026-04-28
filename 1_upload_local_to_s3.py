import logging
import boto3
from botocore.exceptions import ClientError
from pathlib import Path

def build_files_dictionary(directory_path):
    folder_path = Path(directory_path)

    # Creates a dictionary of {filename: full_path}
    files_dict = {
        file.name: str(file.resolve())
        for file in folder_path.iterdir()
        if file.is_file() and file.suffix in ['.csv', '.json']
    }

    return files_dict

def upload_file(file_name, bucket, object_name):
    """Upload a file to an S3 bucket

    :param file_name: File to upload
    :param bucket: Bucket to upload to
    :param object_name: S3 object name. If not specified then file_name is used
    :return: True if file was uploaded, else False
    """

    # region name
    target_region = 'ap-south-1'

    # upload file to specific bucket in specific region
    s3_client = boto3.client('s3', region_name=target_region)

    try:
        # boto3 expects 'Bucket' to be just the name, and 'Key' to be the full path
        response = s3_client.upload_file(file_name, bucket, object_name)
    except ClientError as e:
        logging.error(e)
        return False
    return True

def upload_local_to_s3():
    # bucket name
    bucket_name = '3aayaam-aws-projects'
    # base folder path to prepend to our object names
    base_prefix = 'Flight_Analytics_System/'
    # local system file path
    # kept sample files in GitHub for reference
    local_folder = '/home/naveen/Code/GitHub/AWS_Projects/1_FlightAnalyticsSystem/PythonFiles'

    # Files Dictionary to upload
    files = build_files_dictionary(local_folder)

    if not files:
        print("No .csv or .json files found in the directory.")
        return

    for s3_object_name, local_full_file_path in files.items():
        print(f"Uploading {s3_object_name} to S3..")

        if s3_object_name.endswith('.json'):
            # Combine the base folder, the dynamic subfolder, and the file name
            full_object_key = f"{base_prefix}JSON_Source_Files/{s3_object_name}"

            status = upload_file(
                file_name=local_full_file_path,
                bucket=bucket_name,
                object_name=full_object_key
            )
            print(f"Status: {status}")

        elif s3_object_name.endswith('.csv'):
            # Combine the base folder, the dynamic subfolder, and the file name
            full_object_key = f"{base_prefix}CSV_Source_Files/{s3_object_name}"

            status = upload_file(
                file_name=local_full_file_path,
                bucket=bucket_name,
                object_name=full_object_key
            )
            print(f"Status: {status}")

if __name__ == "__main__":
    upload_local_to_s3()
