# AWS Cloud Engineering & Data Portfolio

### 🏢 Training Source
These projects were developed as part of a comprehensive AWS training at **[3 Aayaam](https://www.3aayaam.in/)**.

![AWS](https://img.shields.io/badge/Amazon_AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Apache Spark](https://img.shields.io/badge/Apache_Spark-FFFFFF?style=for-the-badge&logo=apachespark&logoColor=#E35A16)
![MySQL](https://img.shields.io/badge/MySQL-00000F?style=for-the-badge&logo=mysql&logoColor=white)

## 📝 Overview
This repository contains a collection of three distinct projects focused on different aspects of cloud engineering, data engineering, and database optimization. Together, they demonstrate end-to-end proficiency in AWS infrastructure, ETL pipelines, schema design, and query optimization.

---

## 🚀 Project Portfolio

### 1. Flight Analytics System ✈️
**Focus:** *Automated ELT Pipelines and OBT Data Modeling*

#### 📊 Data Modeling (OBT Architecture)
We use a modern OBT (One Big Table) approach. This means we combine all information into one massive, super-fast table instead of many small ones.

* **Fact Table:**
  * `Fact_Flight_Transactions`: Captures transactional metrics and denormalized dimensions in a single unified table for rapid data retrieval.
* **Dimension Table:**
  * `Dim_Date`: Provides a standardized calendar framework for time-series analysis and reporting.
  
#### ⚙️ The ETL Pipeline
This project leverages AWS Redshift to handle data transformation. The current ELT (Extract, Load, Transform) approach follows these stages:

* **Data Ingestion (S3):**

  * `1_upload_local_to_s3_Heavy_lifting_from_Redshift.py`: Automates secure local-to-S3 data uploads using Boto3.
  * `2_schema_setup.py`: One-time setup script to initialize Redshift tables via the Data API. Designed to minimize costs and security risks by removing the need for an Elastic IP.
  
* **Transformation & Loading (Redshift):**

  * `3_daily_etl_job.py`: The core engine of the pipeline that manages the flow of data inside Redshift.
  
    * **Staging:** Moves raw data from S3 into a temporary staging table for cleaning.
    * **Deduplication:** Uses SQL logic to identify and remove duplicate ticket records, ensuring only the latest information is kept.
    * **UPSERT Logic:** Performs a "Smart Update"—it updates existing flight details and inserts new records at the same time to prevent data gaps.
    * **OBT Modeling:** Finalizes the data into a One Big Table (OBT) format, making it ready for fast analytical queries without complex joins.
    
* **Post-Processing & Archival:**

    * **Automated Archiving:** Once the Redshift transaction is successfully committed, the script triggers a cleanup of the S3 bucket.
    * **File Migration:** Processed CSV files are moved from the Source folder to an Archive folder. This ensures that the same data is never processed twice and keeps the storage organized.
    * **Date Synchronization:** Automatically checks and generates new records for the Dim_Date table to ensure the calendar dimension stays up to date with new flight schedules.

    
### 2. Enterprise Administration & OLTP-to-OLAP Migration 🎓🛒
**Focus:** *Database Administration, Massive-Scale Ingestion, and Lakehouse Architectures*

This massive, multi-part project demonstrates enterprise-grade physical database tuning, parallel ingestion limits, and evaluates modern data migration patterns using datasets exceeding 1.2+ crore records.

* **Part 1: Education System (Performance Tuning):** Engineered rigorous A/B/C SLA benchmarking. Re-architected Redshift schemas using collocated joins (DISTKEY) and Zone Maps (SORTKEY), slashing steady-state query execution times by over 50% (from ~4.4s down to ~2.0s) and dropping point-lookups to ~8ms. Storage bloat and skew_rows were actively audited using system tables.

* **Part 2: 55GB Orders System (Parallel Ingestion & DLM):** Bypassed local ISP bandwidth by using Google Colab to migrate 55GB of raw data directly to S3. Engineered Python scripts to generate JSON manifest files, forcing Redshift compute slices to ingest chunked S3 split files in parallel. Implemented Redshift UNLOAD to selectively export historical data (>2 years old) back to S3, utilizing AWS Glue and Amazon Athena to query the "cold" S3 data via serverless analytics.

* **Part 3: Education System (OLTP-to-OLAP):** Benchmarked the physical Redshift warehouse against two automated live pipelines:

  * **Architecture A (Zero-ETL):** Real-time CDC replication from MySQL to Redshift using Materialized Views.

  * **Architecture B (Data Lakehouse):** AWS DMS extraction to S3, followed by distributed PySpark (AWS Glue) in-memory deduplication, writing to Apache Iceberg formats, and queried via Redshift Spectrum for zero-maintenance historical storage.
  

### 3. Performance Tuning 🛠️
In-progress

---

## 🛠️ Core Technologies
| Category           | Tools & Services                                               |
| :------------------| :--------------------------------------------------------------|
| **Cloud Provider** | AWS (Amazon Web Services)                                      |
| **AWS Resources**  | S3, Athena, Glue, Redshift(Serverless & Spectrum), RDS, DMS    |
| **Languages**      | Python (Boto3), PySpark, SQL                                   |
| **Data Concepts**  | CDC, Zero ETL, DMS, OBT Modeling, Hot/Cold Tiering             |
| **Table Formats**  | Apache Iceberg, Parquet, CSV                                   |
| **Others**         | Google Colab, DuckDB                                           |

---

**Note:** The project leverages AI capabilities.

## 📂 Repository Structure
```text
├── 1_FlightAnalyticsSystem/                # Python scripts, JSON, CSV parsers, and SQL DDL/DML
├── 2_Administration_and_OLTP_To_OLAP/      # Ed. System tuning, 55GB Orders tiering, and Lakehouse
├── 3_Performance_Tuning/                   # Performance tuning, optimized queries, Data Modeling
└── README.md                               # Root portfolio documentation
```
