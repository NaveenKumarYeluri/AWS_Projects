# Google Drive to S3 Data Pipeline

This contains a workflow for migrating large datasets from **Google Drive** to **Amazon S3** using **Google Colab**. The process includes environment setup, unwanted files removal, and cloud synchronization.

## Step-by-Step Breakdown

### 1. Installation & Data Acquisition
We update `gdown` to ensure compatibility with Google Drive's API for large file downloads.

* **Update gdown**: Ensures we have the latest version to handle Drive API changes.
  ```bash
  !pip install --upgrade gdown
  ```
* **Download Data**: Fetches the zip file using its unique File ID. The -O flag specifies the output path.
  ```bash
  !gdown "https://drive.google.com/uc?id=SOME-ID-HERE" -O /content/EducationData.zip
  ```

### 2. File Extraction & Directory Management
Standard Linux commands are used to prepare the files before uploading them to the cloud.

* **Unzip**: Extracts the archive into a specific folder.
  ```bash
  !unzip /content/EducationData.zip -d /content/unzipped_data
  ```
* **List Files (ls)**: Used to verify the directory structure. -lah shows details (long format), hidden files (all), and sizes in MB/GB (human-readable)
  ```bash
  !ls -lah /content/unzipped_data/Project_Education
  ```

### 3. Data Cleaning
Before moving data to S3, we remove temporary folders and redundant schema files to save storage costs and maintain a clean data lake.

* **Recursive Remove (`rm -rf`)**: Deletes unwanted directory and all its contents forcefully.
  ```bash
  !rm -rf /content/unzipped_data/Project_Education/done
  ```
* **Specific File Removal**: Deletes individual file.
  ```bash
  !rm /content/unzipped_data/Project_Education/._i*
  ```

### 4. AWS Authentication & CLI Setup
To interact with AWS S3, we must configure credentials and install the command-line interface.

* **Environment Variables**: Sets credentials in the Colab session so the AWS CLI can authenticate.
  ```python
  import os
  os.environ['AWS_ACCESS_KEY_ID'] = 'YOUR-ACCESS-KEY'
  os.environ['AWS_SECRET_ACCESS_KEY'] = 'YOUR-SECRET-KEY'
  os.environ['AWS_DEFAULT_REGION'] = 'YOUR-REGION'
  ```
* **Install AWS CLI**: Installs the tool needed for S3 interactions.
  ```bash
  !pip install awscli
  ```

### 5. S3 Synchronization
The final step moves the csv files to the target cloud storage.

* **S3 Copy (`cp`)**: The `--recursive` flag ensures that the entire folder structure is copied to the S3 bucket.
  ```bash
  !aws s3 cp /content/unzipped_data/Project_Education s3://YOUR-S3-BUCKET_NAME/FOLDER1/ --recursive
  ```
