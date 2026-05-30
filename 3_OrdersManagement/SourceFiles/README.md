# Google Drive to S3 Data Pipeline

This contains a workflow for migrating large datasets from **Google Drive** to **Amazon S3** using **Google Colab**. The process includes environment setup, unwanted files removal, csv to parquet file conversion, manifest file generation and cloud synchronization.

## Step-by-Step Breakdown

### 1. Install Required Packages
We will install all the required packages.

* **Update gdown**: Ensures we have the latest version to handle Drive API changes.
  ```bash
  !pip install --quiet --upgrade gdrive
  ```
  
* **Install AWS CLI**: Install the Amazon Web Services Command Line Interface (AWS CLI) 
  ```bash
  !pip install awscli
  ```
  
* **Install boto3**: Install specialized data engineering libraries for Python
  ```bash
  !pip install boto3
  ```

### 2. Gdrive Access
Instead of downloading ZIP files through a link, I will be mounting it for easy access. Google limits bandwidth for shared files, hence has to rely on this. Since I do not store any personal information, I need not worry about what permissions I am giving to Google Colab. Obviously to access drive you have to provide required permissions.

* **Mout Drive**: Mount you Google Drive for easy access. 
  ```bash
  from google.colab import drive
  drive.mount('/content/drive')
  ```
  
* **Verify**: Once after mount check if MyDrive is visible. If it is visible then you are free to access files else check if required permissions are given or not.
  ```bash
  !ls -lah /content/drive/MyDrive/
  ```
  
### 3. Changing File Format
Instead of uploading CSV files, format has been changed to `PARQUET` file so loading completes in quick time compared to `CSV`.

* **Unzip files**: As we have limit in Colab each zip file will be processed seperately.
  ```bash
  !unzip /content/drive/MyDrive/Data_Engg_Vol_1_2/OrderManagementSystem/order_fulfillment.zip -d /content/
  ```
  
* **Remove unwanted things**: Zip files contain some hidden files and unwanted folder, hence removing them.
  ```bash
  !rm -rf /content/__MACOSX/
  !rm -rf /content/order_fulfillment/._*
  ```

*   **Taking 5MB copy for GitHub**: We will be sharing only a portion of the files.
    ```python
    import os
    import pandas as pd
    
    input_file = '/content/order_fulfillment/order_fulfillment_data_1.csv'
    output_file = '/content/order_fulfillment/order_fulfillment_data_1_subset_5mb.csv'
    
    # Estimate rows for 5MB
    target_size_bytes = 5 * 1024 * 1024
    
    # Read a small sample to estimate average row size
    sample_df = pd.read_csv(input_file, nrows=1000)
    sample_size_bytes = sample_df.to_csv(index=False).encode('utf-8').__sizeof__()
    avg_row_size = sample_size_bytes / 1000
    
    estimated_rows = int(target_size_bytes / avg_row_size)
    
    # Extract the subset
    subset_df = pd.read_csv(input_file, nrows=estimated_rows)
    subset_df.to_csv(output_file, index=False)
    
    # Verify size
    actual_size = os.path.getsize(output_file) / (1024 * 1024)
    print(f'Subset saved to: {output_file}')
    print(f'Actual size: {actual_size:.2f} MB')
    display(subset_df.head())
    ```
    
*   **CSV to Parquet**: We know parquet files are optimised to the best hence using them. It is observed, the same CSV files took ~12min, in Redshift Serverless with 4 RPUs, to load order fulfilment table.
    ```python
    import os
    import pandas as pd
    import json
    import pyarrow as pa
    import pyarrow.parquet as pq

    # Define paths
    local_csv_dir = '/content/order_fulfillment/'
    local_parquet_dir = '/content/order_fulfillment_parquet/'
    s3_path = 's3://mybuck_name_is/Order_Management_System/order_fulfillment_parquet/'

    os.makedirs(local_parquet_dir, exist_ok=True)

    # Get list of CSV files (excluding subsets or hidden files)
    files = [f for f in os.listdir(local_csv_dir) if f.endswith('.csv') and not f.startswith('.') and 'subset' not in f]

    parquet_s3_urls = []
    chunk_size = 750000

    for file in files:
        print(f'Processing {file} in chunks...')
        csv_path = os.path.join(local_csv_dir, file)
        parquet_file = file.replace('.csv', '.parquet')
        local_path = os.path.join(local_parquet_dir, parquet_file)
        
        writer = None
        
        # Use chunking to read the CSV
        for chunk in pd.read_csv(csv_path, chunksize=chunk_size):
            # Convert columns containing 'date' to datetime
            for col in chunk.columns:
                if 'date' in col.lower():
                    chunk[col] = pd.to_datetime(chunk[col], format='%Y-%m-%d %H:%M:%S.%f')
            
            table = pa.Table.from_pandas(chunk)
            
            if writer is None:
                writer = pq.ParquetWriter(local_path, table.schema)
            
            writer.write_table(table)
        
        if writer:
            writer.close()
        
        parquet_s3_urls.append(s3_path + parquet_file)

      print('Conversion complete.')
    ```

### 4. Uploading to S3:
After file conversion, manifest file is generation, we can load files to S3.

* **Loading to S3:**
  ```python
    import os
    import json

    os.environ['AWS_ACCESS_KEY_ID'] = 'AWS_ACCESS_KEY_ID'
    os.environ['AWS_SECRET_ACCESS_KEY'] = 'AWS_SECRET_ACCESS_KEY'
    os.environ['AWS_DEFAULT_REGION'] = 'AWS_DEFAULT_REGION'

    # Re-check local parquet files to get sizes for manifest meta
    local_parquet_dir = '/content/order_fulfillment_parquet/'
    s3_path = 's3://mybuck_name_is/Order_Management_System/order_fulfillment_parquet/'

    if not os.path.exists(local_parquet_dir):
        print('Warning: local_parquet_dir not found. Please re-run the conversion cell.')

    manifest_entries = []
    for url in parquet_s3_urls:
        filename = url.split('/')[-1]
        local_file_path = os.path.join(local_parquet_dir, filename)
        
        # Get file size in bytes
        file_size = os.path.getsize(local_file_path)
        
        manifest_entries.append({
            "url": url,
            "mandatory": True,
            "meta": {
                "content_length": file_size
            }
        })

    # Create Manifest content with meta key
    manifest = {"entries": manifest_entries}

    manifest_local_path = '/content/order_fulfillment_manifest.json'
    with open(manifest_local_path, 'w') as f:
        json.dump(manifest, f, indent=4)

    # Upload Parquet files to S3
    !aws s3 cp {local_parquet_dir} {s3_path} --recursive

    # Upload Manifest to S3
    !aws s3 cp {manifest_local_path} s3://mybuck_name_is/Order_Management_System/order_fulfillment_manifest.json

    print('\nUploaded to S3.')
  ```
