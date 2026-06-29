# 📖 AWS Data Engineering & Architecture Portfolio

### 🏢 Training Source
These projects were developed as part of a comprehensive AWS training at **[3 Aayaam](https://www.3aayaam.in/)**.

![AWS](https://img.shields.io/badge/Amazon_AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Apache Spark](https://img.shields.io/badge/Apache_Spark-FFFFFF?style=for-the-badge&logo=apachespark&logoColor=#E35A16)
![MySQL](https://img.shields.io/badge/MySQL-00000F?style=for-the-badge&logo=mysql&logoColor=white)

## 📝 Overview
This repository demonstrates an enterprise-grade cloud data architecture spanning automated ingestion, physical query optimization, Data Lifecycle Management (DLM), and modern OLTP-to-OLAP integration patterns.

It is divided into three major architectural projects:

1. An automated ELT pipeline for an Education System with rigorous performance tuning.

2. A Data Lakehouse migration evaluating Zero-ETL versus distributed PySpark processing.

3. Advanced Massively Parallel Processing (MPP) tuning using Amazon Redshift and DuckDB to resolve network bottlenecks, data skew, and data integrity anomalies.

---

## 🚀 Project Portfolio

### 🚀 Project 1: Automated Pipeline & Performance Tuning (Education System)
This component establishes an automated Python pipeline to define schemas, load data, and programmatically analyze the resulting Redshift architecture to achieve strict Service Level Agreements (SLAs). This physical, batch-loaded architecture serves as the highly optimized performance baseline for the entire repository.

* **Workflow & Automation:** Python-driven ingestion scripts (`boto3`) to batch and push raw applicant and institute data into the cloud data warehouse.

* **Storage Auditing:** Queried internal system tables (`svv_table_info`) to measure `skew_rows` and identify physical storage inefficiencies.

* **Schema Setup:** Automated the execution of `DDL` statements to construct staging and production tables within Redshift seamlessly.

_(Navigate to the `1_FlightAnalyticsSystem` folder for detailed SQL scripts, architectures, and execution logs)._
    
### 🚀 Project 2: OLTP-to-OLAP Data Lakehouse Migration
This project evaluates traditional ETL pipelines against modern Zero-ETL and Data Lakehouse architectures (Apache Iceberg) for migrating operational data into a scalable analytical environment.

* **Live CDC Simulation:** Created targeted Python scripts to fire micro-transactions (Updates, Inserts, Bad Data) into a MySQL OLTP database, proving downstream pipelines successfully captured and propagated live web-app changes.

* **State Management & Data Parity:** Identified and resolved an "Order of Operations" bug by aligning PySpark's `ROW_NUMBER()` logic with MySQL's ON `DUPLICATE KEY UPDATE` behavior.

* **Dead Letter Queue (DLQ) Trapping:** Engineered exception-handling scripts to catch and reroute "orphan" records into designated error tables to protect operational data integrity.

* **Architectural Benchmarking:** Documented SLAs proving that while Physical Tables dominate needle-in-a-haystack lookups (~8ms), Lakehouse architectures provide an acceptable trade-off (~1.5s - 2.5s) for infinitely scalable, zero-maintenance historical storage.

_(Navigate to the `2_Administration_and_OLTP_To_OLAP` folder for the PySpark notebooks, CDC configurations, and Iceberg setups)._
  

### 🚀 Project 3: MPP Performance Tuning & Financial Analytics
This final project focuses strictly on the physical storage layer of analytical engines, optimizing over 1 Billion rows of synthetic e-commerce and financial data.

* **Part 1: Order Shipments (Network Optimization):** Eliminated MPP network broadcast bottlenecks by engineering an Optimized Schema (DISTKEY(order_id)). This achieved Collocated Joins (`DS_DIST_NONE`), dropping estimated execution costs from 154 Billion down to 8.2 Million.

* **Part 2: Order Fulfillment (Data Skew vs. Zone Maps):** Diagnosed a fatal 5.51 data skew caused by a poor distribution key. Engineered a Hybrid Schema (`DISTKEY(fc_id)`, `SORTKEY(date)`) that balanced parallel compute slices while unlocking sub-second Zone Map I/O pruning.

* **Part 3: Financial Analytics (DuckDB):** Shifted to an in-memory, vectorized analytical engine (DuckDB). Bypassed strict DDL constraints to handle synthetic "Orphan Records," enforcing referential integrity dynamically via advanced SQL (`INNER JOIN`, CTEs, Conditional Aggregations, Anti-Joins).

_(Navigate to the `3_Performance_Tuning` folder for the diagnostic Redshift benchmarking and DuckDB analytics)._

---

## 🛠️ Core Technologies
**Cloud Data Warehousing & Analytics:** Amazon Redshift Serverless (MPP), DuckDB (In-Memory Vectorized Engine), Amazon Athena, Redshift Spectrum

**OLTP & Data Lake Storage:** MySQL, Amazon S3, Apache Iceberg, Parquet

**Data Movement & CDC:** AWS Database Migration Service (DMS), AWS Zero-ETL, Google Colab Pipelines

**Data Engineering & Scripting:** Python (Boto3), PySpark, Advanced ANSI SQL, AWS CLI

**Performance Tuning Techniques:** Collocated Joins, I/O Zone Map Pruning, Hot/Cold Tiering, Data Skew Management, Deep Copy (CTAS), Dynamic Referential Integrity

---

**Note:** The project leveraged AI capabilities.

## 📂 Repository Structure
```text
├── 1_FlightAnalyticsSystem/                # Data Modeling
├── 2_Administration_and_OLTP_To_OLAP/      # Ed. System tuning, 55GB Orders tiering, and Lakehouse
├── 3_Performance_Tuning/                   # Financial Analytics, Query Optimization
└── README.md                               # Root portfolio documentation
```
