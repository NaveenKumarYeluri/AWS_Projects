# Massively Parallel S3 Data Migration & Redshift Ingestion Pipeline

This project documents an optimized, memory-safe data engineering pipeline designed to migrate, split, and ingest a massive compressed dataset (55GB+, containing 1.2 billion records) from Google Drive into Amazon Redshift Serverless using Google Colab and AWS cloud-native components.

---

## 🏗️ Architecture Overview

To overcome local disk space limitations in Google Colab and maximize data ingestion throughput, the pipeline bypasses local storage entirely. It leverages an external Massively Parallel Processing (MPP) workflow to balance data distribution across Redshift compute slices (RPUs).

```text
[Google Drive ZIP File] 
       │ (Stream via Python)
       ▼
[Amazon S3 Raw Bucket] 
       │ (AWS Glue Crawler Auto-Schema Discovery)
       ▼
[AWS Glue Data Catalog] 
       │ (Athena Presto MPP Split Engine)
       ▼
[Amazon S3 Partitions] (20 Balanced .gz Chunks)
       │ (Manifest-driven parallel load)
       ▼
[Amazon Redshift Cluster] (4 RPUs - 1.2 Billion Rows in ~12 mins)
```

---

## 📦 Prerequisites & Installation
Before running the workflow cells inside Google Colab environment, we must install and upgrade the necessary system and Python packages. 

* Instructions are available in SourceFile directory.


## 🛠️ Execution Pipeline Steps

### 1. Initial Google Drive to S3 Raw Staging
This contains a workflow for migrating large datasets from **Google Drive** to **Amazon S3** using **Google Colab**.

* Available in SourceFile directory.


### 2. Automated Schema Discovery (AWS Glue)
Because manually mapping data types for multiple 9.2GB text files is error-prone, an AWS Glue Crawler is pointed at the raw S3 directory.

* **Action:** Runs for ~1 minute to automatically infer column schemas and populate the AWS Glue Data Catalog database.
* **Result:** Generates an external table visible inside Amazon Athena without manual script definitions.


### 3. Serverless MPP Data Chunking (Amazon Athena)
To optimize Redshift Serverless performance across 4 RPUs, data must be divided into balanced files. We utilize Amazon Athena's serverless distributed Trino/Presto engine to hash rows into exactly 20 compressed, headerless files inside structured S3 subfolders.

* Run the CTAS statement from `athena_sql_queries.sql` file in the Amazon Athena Console.

Outputs exactly 20 directories (orders_group=1/ to orders_group=20/) holding highly-optimized .csv.gz compressed parts.


### 4. Cross-Partition Manifest Generation
Because Athena assigns random UUIDs to files across distributed partitions, we want a Python script that creates Redshift manifest configuration file.

* Available, as `manifest_file_generation.py`, in PythonFiles folder.


### 5. High-Throughput Cluster Ingestion (Amazon Redshift)
The target physical table is optimized using explicit Distribution and Sort keys to maximize query performance. Data loading utilizes the native GZIP and MANIFEST arguments.

* Run the CREATE statement before going for COPY, sql file is `redshift_sql_queries.sql`.
