# Google Drive to S3 Data Pipeline

This contains a workflow for migrating large datasets from **Google Drive** to **Amazon S3** using **Google Colab**. The process includes environment setup, unwanted files removal, and cloud synchronization.

## Step-by-Step Breakdown

### 1. Install required packages
We will install all the required packages.

* **Update gdown**: Ensures we have the latest version to handle Drive API changes.
  ```bash
  !pip install --upgrade gdown
  ```
  
* **Install AWS CLI**: Install the Amazon Web Services Command Line Interface (AWS CLI) 
  ```bash
  !pip install awscli
  ```
  
* **Install boto3**: Install specialized data engineering libraries for Python
  ```bash
  !pip install boto3
  ```

### 2. Google Drive to S3 Raw Staging
Instead of downloading and unzipping locally—which causes a critical "Disk Full" crash on a standard Colab runtime, the script mounts Google Drive and streams file buffers directly into an Amazon S3 bucket via `boto3`. Colab needs Gdrive full access while mounting.

*   **Prerequisite Setup:**
    ```python
    from google.colab import drive
    import boto3
    import zipfile
    import io

    drive.mount('/content/drive')
    
    s3_client = boto3.client('s3', aws_access_key_id='KEY', aws_secret_access_key='SECRET', region_name='REGION')

    with zipfile.ZipFile('/content/drive/MyDrive/Flight_Data.zip', 'r') as z:
      for file_info in z.infolist():
        if file_info.is_dir() or '/done/' in file_info.filename:
          continue

        with z.open(file_info) as file_stream:
          s3_client.upload_fileobj(file_stream, 'BUCKETNAME', f'Education_System/Orders_Files/{file_info.filename}')
          
    print("🎉 Migration complete!")
    ```

### 3. Modifications in S3:
Incase you want to move files to a different folder then make use of following command. We have a limit 5GB when done using Console.

* **Move file to a different directory:**
  ```bash
  !aws s3 mv source_path target_path
  ```
