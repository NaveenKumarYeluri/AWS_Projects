# 📖 Overview
This project demonstrates an enterprise-grade cloud data architecture spanning automated ingestion, physical query optimization, and Data Lifecycle Management (DLM). It is divided into two major components: an automated ELT pipeline for an Education System with rigorous performance tuning, and a massive-scale Orders System demonstrating parallel ingestion, cold-data archival, and Serverless Data Lake querying.

## 🚀 Part 1: Automated Pipeline & Performance Tuning (EducationSystem)
This component establishes an automated Python pipeline to define schemas, load data, and programmatically analyze the resulting Redshift architecture to achieve strict Service Level Agreements (SLAs).

**Workflow & Scripts:**

* `1_schema_setup.py:` Automates the execution of DDL statements to construct the staging and production tables within Redshift.

* `2_load_data.py:` A ont time load Python-driven ingestion script that batches and pushes the raw applicant and institute data into the data warehouse.

* `SQLFiles/:` Contains the administrative queries used to audit and tune the database physical storage.

**Database Administration & Optimization:**

* **Storage Auditing:** Queried internal system tables (`svv_table_info`) to measure `skew_rows` and identify physical storage bloat across the 1MB compute blocks.

* **Serverless Benchmarking:** Engineered rigorous A/B/C testing methodologies using Temporary Tables to isolate pure database engine speed from network/UI latency. Successfully identified and bypassed Redshift Serverless "Cold Starts" (which temporarily inflated initial executions to >2 minutes) to measure true steady-state RAM-cached performance.

* **Collocated Joins:** Re-architected table schemas to utilize identical Distribution Keys (`DISTKEY`). This eliminated network shuffling (broadcasts) and allowed matching records to be processed entirely within local compute node memory.

* **Merge Joins & Zone Maps:** Implemented explicit `SORTKEYs` to enable Redshift's Zone Maps to skip irrelevant disk blocks.

* **Result:** Slashed steady-state query execution times by over 50% (from a ~4.4s baseline down to ~2.0 seconds flat) for massive multi-million row analytical statements.

## 🚀 Part 2: Massive-Scale Ingestion & Data Lake Archival (Orders System)
Handling a monolithic 55GB+ dataset requires bypassing traditional bandwidth limits and separating "hot" compute storage from "cold" archival storage.

**Key Engineering Accomplishments:**

* **Cloud-to-Cloud Transfer:** Utilized Google Colab to bypass local ISP bandwidth constraints, successfully migrating 55GB of raw source data directly from Google Drive into Amazon S3.

* **Serverless Data Lake (**`athena_sql_queries.sql`**):**

    * Integrated AWS Glue (Data Catalog) to crawl the unloaded historical data residing in S3.

    * Utilized Amazon Athena to perform serverless, pay-per-query SQL analytics directly on the archived "cold" S3 data, ensuring historical data remained fully queryable without taking up warehouse space.

* **Massively Parallel Ingestion:** * `manifest_file_generation.py`: Engineered a script to generate an explicit JSON manifest file mapping out smaller, chunked S3 splits.

    * Utilized the manifest with the Redshift `COPY` command, forcing the underlying compute slices to ingest the split files in parallel, maximizing network throughput.

* **Data Lifecycle Management (Hot/Cold Tiering):**

    * `redshift_sql_queries.sql`: Implemented the Redshift UNLOAD command to selectively export historical data (records older than 2 years) back out to Amazon S3 in an optimized format.

    * Reclaimed expensive Redshift compute-storage by purging the unloaded historical records from the active warehouse.

**⚙️ Technologies Stack**
* **Data Warehouse:** Amazon Redshift (Serverless)

* **Data Lake / Serverless Analytics:** AWS Glue, Amazon Athena

* **Storage:** Amazon S3

* **Scripting & Automation:** Python (Google Colab, Boto3)

* **Performance Techniques:** Parallel S3 Manifest Loads, Collocated Joins, Hot/Cold Data Tiering.
