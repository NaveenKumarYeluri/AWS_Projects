# 📖 Overview
This project demonstrates an enterprise-grade cloud data architecture spanning automated ingestion, physical query optimization, Data Lifecycle Management (DLM), and modern OLTP-to-OLAP integration patterns. It is divided into three major components: an automated ELT pipeline for an Education System with rigorous performance tuning, a massive-scale Orders System demonstrating parallel ingestion and cold-data archival, and a Data Lakehouse migration evaluating Zero-ETL versus distributed Spark processing.

## 🚀 Part 1: Automated Pipeline & Performance Tuning (EducationSystem)
This component establishes an automated Python pipeline to define schemas, load data, and programmatically analyze the resulting Redshift architecture to achieve strict Service Level Agreements (SLAs). This physical, batch-loaded architecture serves as the highly optimized performance baseline for the entire project.

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
    
## 🚀 Part 3: OLTP to OLAP Migration & Data Lakehouse Architecture
This component evaluates the migration of a live operational database (1.2+ crore records) into an analytical environment. To find the optimal balance of speed, cost, and automation, the architecture compares two distinct modern data pipelines against the physical baseline established in Part 1.

**The Two Automated Architectures:**

* **Architecture A:** The Real-Time Pipeline (AWS Zero-ETL): Connected MySQL directly to Redshift. Leveraged Materialized Views (MVs) to automatically handle Change Data Capture (CDC) and flatten schemas for rapid dashboarding without complex ETL code.

* **Architecture B:** The Data Lakehouse (AWS DMS & Apache Iceberg): Extracted MySQL data via AWS DMS to an S3 landing zone. Utilized distributed AWS Glue (PySpark) clusters to deduplicate data in-memory and write it back to S3 in the Apache Iceberg open table format. Redshift Spectrum was used to query the external files, minimizing storage costs.

**Key Engineering Accomplishments::**

* **Data Deduplication & State Management:** Identified and resolved an "Order of Operations" bug by aligning PySpark's ROW_NUMBER() logic with MySQL's ON DUPLICATE KEY UPDATE behavior to ensure perfect data parity across pipelines.

* **Dead Letter Queue (DLQ) Trapping:** Engineered exception-handling scripts to catch and reroute "orphan" records (students applying to non-existent colleges) into designated error tables to protect operational data integrity.

* **Live CDC Simulation:** Created targeted Python scripts to fire micro-transactions (Updates, Inserts, Bad Data) into the OLTP database, proving the downstream pipelines successfully captured and propagated live web-app changes.

* **Architectural Benchmarking:** Documented specific SLAs, proving that while the Physical Tables (Part 1) dominate specific needle-in-a-haystack lookups (~8ms), Lakehouse architectures provide an acceptable trade-off (~1.5s - 2.5s) for infinitely scalable, zero-maintenance historical storage.

**⚙️ Technologies Stack**
* **Data Warehouse:** Amazon Redshift (OLAP Serverless), MySQL (OLTP)

* **Data Lake / Serverless Analytics:** AWS Glue, Amazon Athena, Redshift Spectrum

* **Data Movement & Integration:** AWS Database Migration Service (DMS), AWS Zero-ETL

* **Storage & Table Formats:** Amazon S3, Apache Iceberg, Parquet

* **Scripting & Automation:** Python (Google Colab, Boto3), PySpark

* **Performance Techniques:** Parallel S3 Manifest Loads, Collocated Joins, Hot/Cold Tiering, CDC, Materialized Views
