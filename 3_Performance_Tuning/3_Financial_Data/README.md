# Part 3: Financial Data Analytics & Integrity (DuckDB)

## 📌 Project Objective
The objective of this final module is to execute complex financial analytics on a multi-table financial dataset. Unlike Parts 1 and 2, which focused on distributed cloud MPP tuning (Redshift), this module shifts to an in-memory, vectorized analytical engine (**DuckDB**) running locally within Google Colab. The primary goal is to perform heavy SQL aggregations while dynamically handling severe data quality and referential integrity anomalies.

## 🏗️ Problem Statement & Architecture
In Amazon Redshift, `PRIMARY KEY` and `FOREIGN KEY` constraints are merely "hints" for the query planner; they are not strictly enforced. DuckDB, however, strictly enforces referential integrity.

When attempting to build the main financial schema, the database immediately threw a `ConstraintException`. Upon investigation, discovered a **massive Data Quality Anomaly** in the synthetic data: lakhs of "Orphan Records." There were lakhs of transactions, loans, and accounts tied to synthetic `customer_ids` that did not exist in the master customer table.

**The Solution:** Instead of dropping data during ingestion (which would alter analytical volume), bypassed strict DDL constraints, queried the _stg (staging) tables directly, and enforced data integrity dynamically at the SQL query execution level.

## 🛠️ Execution Steps
**Step 1: DuckDB & Colab Environment Setup**

* Initialized DuckDB within Google Colab to leverage its state-of-the-art columnar, vectorized execution engine.

* This allowed for blazing-fast analytical processing using local RAM/CPU, bypassing the need for cloud network distribution (`DISTKEY`s) or disk sorting (`SORTKEY`).

**Step 2: Diagnostic Math & The Orphan Anomaly**

* Executed diagnostic `COUNT` and `INNER JOIN` comparisons to mathematically isolate the constraint failures.

* **Discovery**: Out of 50 Lakhs registered customers, only 3,151 actually held valid loans. However, base queries against the loan/account tables were returning over 17 lakhs unique customer IDs, proving the existence of massive phantom data generation in the synthetic pipeline.

**Step 3: Query-Level Integrity & Advanced SQL**

* Enforced referential integrity dynamically by adding strict `INNER JOIN` clauses to the verified `finance_customer_data_stg` master table, successfully filtering out phantom synthetic records during execution.

* Engineered 10+ complex business statements using advanced SQL patterns, including:

   * **Common Table Expressions (CTEs)**: Used `WITH` clauses to build demographic age-group buckets (`DATE_DIFF`) before aggregating loan volumes.

   * **Conditional Aggregations**: Utilized `CASE` statements inside `SUM()` functions to pivot completed vs. failed transaction statuses by currency.

   * **Anti-Joins**: Leveraged DuckDB's `EXCEPT` and `NOT IN` clauses to isolate countries with absolute zero equity in the ledger. _(Note: This was used specifically for data validation and was not part of the main business queries)._

## 🚀 Key Discoveries & Results
**Vectorized Engine Efficiency**

Shifting to DuckDB demonstrated that modern embedded analytical databases can perform massive, multi-table hash joins entirely in-memory at incredible speeds, completely bypassing the network bottlenecks and data skew penalties previously engineered around in Redshift.

**Dynamic Data Quality Enforcement**

This phase successfully proved that when working with untrusted or highly anomalous raw staging data, referential integrity does not have to be forced at the storage layer. By mastering `INNER JOIN` logic and Anti-Joins, a pristine, highly accurate analytical view layer can be constructed directly over dirty data.
