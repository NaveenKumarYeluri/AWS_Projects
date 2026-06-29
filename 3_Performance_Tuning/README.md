# 📖 Overview
This project demonstrates advanced cloud database administration and performance tuning within Amazon Redshift. Focusing on the physical storage layer of Massively Parallel Processing (MPP) architectures, this project optimizes over 75 crore rows of synthetic e-commerce data. It evaluates different Distribution Keys (`DISTKEY`) and Sort Keys (`SORTKEY`) to eliminate network bottlenecks, resolve high-cardinality data skew, manage columnar update anomalies, and establish production-grade Service Level Agreements (SLAs).

## 🚀 Part 1: Order Shipment & Transaction Optimization
This component focuses on diagnosing and eliminating network bottlenecks caused by heavy cross-table joins between two massive fact tables: `order_transaction` (25 crore rows) and `order_shipment` (25 crore rows).

* **Workflow & Architecture:**
    * **Massive-Scale Data Ingestion:** Orchestrated the movement of 750 million synthetic e-commerce rows. Built a Google Colab pipeline to mount Google Drive, convert raw CSV files into highly compressed Parquet format, and dynamically generate JSON manifest files with byte-level metadata. The processed data was synchronized to Amazon S3 via the AWS CLI and rapidly ingested into Redshift staging tables utilizing highly parallelized manifest-based COPY commands.

    * **The Collocated Join Victory:** Engineered an Optimized Schema using `DISTKEY(order_id)` on both tables. This forced Redshift to store matching records physically next to each other on the same compute slices. By analyzing `EXPLAIN` plans, we proved this shifted the query from a network-bound broadcast (`DS_DIST_INNER`) to a completely localized join (`DS_DIST_NONE`), dropping the estimated execution cost from 154 Billion to 8.2 Million.

    * **Deep Copy & The Update Anomaly:** Diagnosed storage bloat caused by Redshift's append-only columnar nature. Utilized a Deep Copy methodology (`CREATE TABLE AS SELECT`) to cleanly rewrite data blocks, eliminating "ghost rows" left behind by standard `UPDATE/DELETE` commands.

* **Database Administration & Optimization:**

    * **Concurrency Buffering:** Captured multi-day, warm-cache execution logs. Established strict production SLAs by applying a **2x Average Concurrency Buffer** to simulate peak business hours and "noisy neighbor" cluster effects.

    * **Query Tiering:** Categorized business logic into Priority 1 (Live Dashboards: < 15s), Priority 2 (Standard Reporting: < 3m), and Priority 3 (Heavy Audits: < 4m 15s).

## 🚀 Part 2: Order Fulfillment Pipeline
This component tackles the optimization of a 25-crore-row `order_fulfillment` staging table. The primary engineering challenge was balancing MPP parallel distribution against the hidden dangers of high-cardinality Data Skew.

* **Workflow & Architecture:**
    * **Data Ingestion Pipeline:** Replicated the Colab-to-S3 Python workflow to extract, convert (CSV to Parquet), and generate manifests for 250 million fulfillment records, syncing them to S3 for rapid Redshift COPY bulk ingestion.

    * **Schema Stress-Testing:** Engineered three distinct physical schemas:

        **1. Default:** `DISTKEY(fc_id)` - perfectly balanced, but lacked I/O pruning.

        **2. Optimized:** `DISTKEY(mfg_facility_id)` with a `SORTKEY` - eliminated network broadcasts but suffered severe processing bottlenecks.

        **3. Hybrid:** `DISTKEY(fc_id)` paired with a `SORTKEY` on the date.

    * **The Hybrid Schema Selection:** The Hybrid Schema was selected for production. It reverted to the balanced fulfillment center distribution key and paired it with a date-based sort key. This maintained perfectly balanced parallel processing while unlocking sub-second I/O pruning for date-filtered queries.

* **Database Administration & Optimization:**

    * **Data Skew Penalty:** Queried internal system tables (`svv_table_info`) to discover a massive 5.51 data skew on the Manufacturing ID column. This proved that a poor `DISTKEY` choice can cripple performance by forcing a single "straggler node" to process a disproportionate amount of data.

    * **Zone Map Dominance:** Proved that applying a `SORTKEY` allowed Redshift to skip 99% of physical disk blocks, dropping a 9.7-second full-table scan down to just 578 milliseconds.

## 🚀 Part 3: Financial Data Optimization (Upcoming)
This final component executes complex financial analytics on a multi-table financial dataset. Moving away from distributed MPP tuning, this module shifts to an in-memory, vectorized analytical engine to perform heavy SQL aggregations while dynamically handling severe referential integrity anomalies.

* **Workflow & Architecture:**

    * **Vectorized Engine Efficiency:** Initialized **DuckDB** within Google Colab to leverage its state-of-the-art columnar, vectorized execution engine. This allowed for blazing-fast analytical processing using local RAM/CPU, bypassing the need for cloud network distribution (`DISTKEY`) or disk sorting (SORTKEY).

    * **The Orphan Anomaly & Data Quality:** Discovered a massive data quality anomaly where millions of "Orphan Records" in the synthetic data lacked matching master records, which triggered strict `ConstraintException` errors. To avoid dropping data and altering analytical volume, strict DDL constraints were bypassed, and the staging (`_stg`) tables were queried directly.

* **Database Administration & Optimization:**

   * **Dynamic Data Quality Enforcement:** Enforced referential integrity dynamically at the SQL query execution level by adding strict `INNER JOIN` clauses to verified master tables. This successfully constructed a pristine analytical view layer directly over dirty data.

   * **Advanced Analytical SQL:** Engineered 10+ complex business statements utilizing advanced SQL patterns, including Common Table Expressions (CTEs) for demographic bucketing (`DATE_DIFF`), conditional aggregations (`CASE` inside `SUM()`), and Anti-Joins (`EXCEPT`, `NOT IN`) for precise data validation without relying on outer joins.

## ⚙️ Technologies Stack

**Cloud Data Warehouse:** Amazon Redshift Serverless (Massively Parallel Processing Architecture), DuckDB (In-Memory Vectorized Columnar Execution)

**Storage & Architecture Modeling:** Amazon S3, Columnar Storage, Parquet, JSON Manifests, Distribution Styles (`DISTSTYLE EVEN`, `DISTSTYLE KEY`), Sort Keys (`SORTKEY`), Data Skew Management

**Performance Diagnostics:** Query Execution Plans (`EXPLAIN`), Collocated Joins, Network Broadcast Elimination (`DS_DIST_NONE`, `DS_DIST_INNER`), I/O Zone Map Pruning

**System Monitoring & Auditing:** Redshift System Views (`SYS_QUERY_HISTORY`, `SYS_QUERY_DETAIL`, `svv_table_info`)

**Data Engineering Techniques:** Google Colab Pipelines, CSV-to-Parquet Conversion, Redshift `COPY` Ingestion, Deep Copy (`CREATE TABLE AS SELECT`), Update Anomaly Resolution

**Scripting & Querying:** Python (Boto3), AWS CLI, Advanced ANSI SQL, Time-Series Aggregations
