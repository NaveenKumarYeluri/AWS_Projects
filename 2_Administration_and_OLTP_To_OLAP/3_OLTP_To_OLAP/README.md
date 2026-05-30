# Education System Data Pipeline: OLTP to OLAP

## 📌 Project Overview
This project demonstrates how to migrate a large-scale university admissions dataset (1,41,99,996 records) from an operational database (OLTP) into a cloud data warehouse (OLAP) for fast analytics. 

To find the best balance of speed, cost, and automation, this project implements and compares **three different data engineering architectures** on AWS.

---

## 🏗️ The Three Architectures (Tracks)

### Track 1: The Physical Warehouse (Batch Load)
* **How it works:** Raw data is loaded from Amazon S3 directly into highly optimized physical tables in Amazon Redshift.
* **Key Concept:** Uses `DISTKEY` and `COMPOUND SORTKEY` to organize data on the physical hard drives.
* **Result:** Blazing fast performance (under 10 milliseconds) for finding specific students or colleges.

### Track 2: The Real-Time Pipeline (AWS Zero-ETL)
* **How it works:** Connects MySQL directly to Redshift using AWS Zero-ETL integration. Data changes in MySQL are replicated to Redshift almost instantly.
* **Key Concept:** Uses a Materialized View (MV) in Redshift to join student and college data together for quick dashboarding.
* **Result:** Completely automates data movement without writing complex ETL code, though wide views can slow down specific point-lookup queries.

### Track 3: The Data Lakehouse (AWS DMS & Apache Iceberg)
* **How it works:** AWS DMS extracts data from MySQL and saves it as Parquet files in Amazon S3. AWS Glue (PySpark) cleans the data, removes duplicates, and saves it in the Apache Iceberg open table format. Redshift Spectrum queries the data directly from S3.
* **Key Concept:** Separates storage (cheap S3) from compute (Redshift). 
* **Result:** Highly cost-effective for massive datasets. Queries take a bit longer (~1.5 to 2.5 seconds) but storage costs are kept to a bare minimum.

---

## 🛠️ Technology Stack
* **Database:** MySQL (Operational / OLTP)
* **Storage:** Amazon S3 (Data Lake)
* **Compute & Transformation:** AWS Glue, PySpark, Python (Boto3)
* **Data Movement:** AWS Database Migration Service (DMS), Zero-ETL
* **Data Warehouse:** Amazon Redshift (OLAP), Redshift Spectrum
* **Table Formats:** Apache Iceberg

---

## 🚀 Key Features & Solutions
1.  **Massive Scale:** Handled over 1.4 crore rows of application and college data.
2.  **Data Deduplication:** Resolved a complex "Order of Operations" bug between MySQL's `ON DUPLICATE KEY` and Apache Spark's `ROW_NUMBER()` logic to ensure 100% data accuracy.
3.  **Exception Handling (DLQ):** Built a Dead Letter Queue to catch "orphan" student records (students applying to colleges that do not exist in the system).
4.  **Change Data Capture (CDC):** Simulated live web app transactions to prove the pipelines can handle real-time inserts, updates, and deletes seamlessly.
5.  **Schema Evolution:** Used Apache Iceberg to easily add new columns to the data lake without breaking the existing pipeline.

---

## 📊 Performance Benchmark Summary
A core part of this project was benchmarking 9 analytical queries across all three tracks to establish SLAs (Service Level Agreements):
* **Physical Tables (Track 1)** easily won speed tests for specific lookups (~8ms).
* **Zero-ETL (Track 2)** was the easiest to maintain and performed well on broad aggregations (~25ms).
* **Data Lakehouse (Track 3)** was the most cost-effective for storage, trading speed (~2 seconds) for infinite scalability.
