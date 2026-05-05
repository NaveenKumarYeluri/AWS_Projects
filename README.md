# AWS Cloud Engineering & Data Portfolio

### 🏢 Training Source
These projects were developed as part of a comprehensive AWS training and certification program at **[3 Aayaam](https://www.3aayaam.in/)**. 

## 📝 Overview
This repository contains a collection of three distinct projects focused on different aspects of cloud engineering, data engineering, and database optimization. Together, they demonstrate end-to-end proficiency in AWS infrastructure, ETL pipelines, schema design, and query optimization.

---

## 🚀 Project Portfolio

### 1. Flight Analytics System ✈️
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

---

## 🛠️ Core Technologies
| Category           | Tools & Services                              |
| :-------------------| :----------------------------------------------|
| **Cloud Provider** | AWS (Amazon Web Services)                     |
| **Languages**      | Python, SQL                                   |
| **Data Concepts**  | Data Modelling, JSON Parsing, OLAP, ETL       |
| **Optimization**   | Query Profiling, Indexing, Performance Tuning |

---

**Note:** AI has been used in structuring all the README files.

## 📂 Repository Structure
```text
├── FlightAnalyticsSystem/       # Python scripts, JSON, CSV parsers, and SQL DDL/DML
├── EducationSystem/       # Admin scripts and OLTP-to-OLAP migration logic
├── OrdersManagement/       # Performance tuning scripts, indexes, and optimized queries
└── README.md               # Portfolio documentation
