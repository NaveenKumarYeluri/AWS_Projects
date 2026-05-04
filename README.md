# AWS Cloud Engineering & Data Portfolio

### 🏢 Training Source
These projects were developed as part of a comprehensive AWS training and certification program at **[3 Aayaam](https://www.3aayaam.in/)**. 

## 📝 Overview
This repository contains a collection of three distinct projects focused on different aspects of cloud engineering, data engineering, and database optimization. Together, they demonstrate end-to-end proficiency in AWS infrastructure, ETL pipelines, schema design, and query optimization.

---

## 🚀 Project Portfolio

### 1. Flight Analytics System ✈️
#### 📊 Data Architecture: OBT
To optimize the data for analytical querying, the raw CSV flight data was modeled into One Big Table consisting of:

* **Fact Table:**
  * `Fact_Flight_Transactions`: Captures all metrics including traditional dimentional columns.
* **Dimension Table:**
  * `Dim_Date`: Enables time-series analysis across travel dates, quarters, and months.
  
#### ⚙️ The ETL Pipeline
This project leverages AWS Redshift to handle data transformation. The current ELT (Extract, Load, Transform) approach follows these stages:

* **Data Ingestion (S3):**
  * `1_upload_local_to_s3_Heavy_lifting_from_Redshift.py`: A custom Python script utilizing the boto3 SDK to securely push the large local source files to Amazon S3. Sample files has been attached.

---

## 🛠️ Core Technologies
| Category           | Tools & Services                              |
| :-------------------| :----------------------------------------------|
| **Cloud Provider** | AWS (Amazon Web Services)                     |
| **Languages**      | Python, SQL                                   |
| **Data Concepts**  | Data Modelling, JSON Parsing, OLAP, ETL       |
| **Optimization**   | Query Profiling, Indexing, Performance Tuning |

---

## 📂 Repository Structure
```text
├── FlightAnalyticsSystem/       # Python scripts, JSON, CSV parsers, and SQL DDL/DML
├── EducationSystem/       # Admin scripts and OLTP-to-OLAP migration logic
├── OrdersManagement/       # Performance tuning scripts, indexes, and optimized queries
└── README.md               # Portfolio documentation
