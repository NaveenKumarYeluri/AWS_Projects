# ✈️ Flight Analytics System: Data Warehouse Architecture

## 📖 Project Overview
This project focuses on building an analytical Data Warehouse (DWH) to process and analyze massive volumes of flight data from multiple CSV files. However, the journey from initial design to final implementation required a major architectural pivot based on real-world data profiling and compute constraints.

## 🏗️ Architectural Evolution: From Star Schema to OBT

### Phase 1: The Star Schema Bottleneck
Initially, the DWH was modeled using a traditional Star Schema based on the source columns. During the ETL pipeline execution, inserting data into the Fact table caused severe performance bottlenecks. Running on a 4 RPU AWS Serverless Redshift cluster, a single 2GB CSV payload took 20+ minutes and failed to complete. 

To conserve AWS free-tier credits and isolate the issue, testing was moved locally using **DuckDB**, a lightweight analytical database. Even with local compute, Fact table generation stalled, proving the issue was not the cloud infrastructure or the SQL syntax, but the data itself.

### Phase 2: Data Profiling & The "Aha!" Moment
A rigorous data profiling exercise revealed critical insights about the source files:
* **Source Disconnect:** The provided JSON files had virtually zero intersection with the 10 CSV files (only 2 matching records found out of gigabytes of data). The JSON data was intentionally excluded from the pipeline to maintain integrity.
* **The Synthetic Data Anomaly:** The CSV files contained highly randomized, synthetic data. Traditional dimensional fields (`aircraft_id`, `flight_id`, `itinerary_no`, `passenger_name`) had nearly 100% cardinality (uniqueness). 
* **The Problem:** Because the data lacked true 1-to-Many referential integrity, the Dimension tables were almost as large as the Fact table. This forced the database to perform massive, billion-row Hash Joins, completely crashing the execution plan.

### Phase 3: The Pivot to One Big Table (OBT)
Realizing a Star Schema was fundamentally incompatible with this specific dataset, the architecture was completely redesigned. All fragmented Dimension tables were dropped in favor of a highly denormalized **One Big Table (OBT)** approach, keeping only a `Dim_Date` table for time-series analytics. This dramatically optimized load times and query performance by eliminating expensive JOIN operations.

## 🧠 Key Learnings & Engineering Principles
Through trial, error, and hardware limitations, this project reinforced essential Data Engineering best practices:

1. **Profile Before You Build:** Always analyze the source data to understand cardinality, data quality, and relationships *before* finalizing the Data Model.
2. **Query-Driven Design:** Analyze the required business queries beforehand to determine optimal JOIN strategies and access patterns.
3. **Strategic Key Allocation:** Identify high-priority queries and optimize the physical database layout using appropriate `DISTKEY` and `SORTKEY` configurations.
4. **Accepting Trade-offs:** Low-priority queries that do not align with the primary `DISTKEY`/`SORTKEY` will naturally take longer to execute; this is an acceptable architectural trade-off.
5. **Leveraging Materialized Views (MVs):** For medium-priority queries that suffer from key misalignment, MVs are an excellent optimization strategy to bridge the gap.
6. **SLA Compliance:** Optimization isn't about making everything instantly fast; it’s about strictly meeting predefined Service Level Agreements (SLAs) for critical workloads.

## 🛠️ Tech Stack & Tools
* **Databases:** AWS Redshift (Serverless), DuckDB
* **Data Processing:** Python, SQL
* **Workflow:** Local to Cloud migration, AI-assisted code optimization
