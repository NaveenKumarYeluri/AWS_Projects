# AWS Cloud Engineering & Data Portfolio

### 🏢 Training Source
These projects were developed as part of a comprehensive AWS training and certification program at **[3 Aaayaam](https://www.3aayaam.in/)**. 

## 📝 Overview
This repository contains a collection of three distinct projects focused on different aspects of cloud engineering, data engineering, and database optimization. Together, they demonstrate end-to-end proficiency in AWS infrastructure, ETL pipelines, schema design, and query optimization.

---

## 🚀 Project Portfolio

### 1. Flight Analytics System ✈️
#### 📊 Data Architecture: Star Schema
To optimize the data for analytical querying, the raw JSON, CSV flight data was modeled into a robust Star Schema consisting of:

* **Fact Tables:**
  * `Fact_Flight`: Captures operational telemetry including fuel consumption, taxi duration, average speed, and turbulence.
  * `Fact_Ticket`: Stores transactional data related to bookings, including flight costs and ticket classes.
* **Dimension Tables:**
  * `Dim_Flight_Route`: Maps the origin and destination airports. The schema is designed so that each itinerary number uniquely identifies a single flight.
  * `Dim_Aircraft`: Contains aircraft specifications (model, tail number).
  * `Dim_Passenger`: Stores frequent flier status and demographic details.
  * `Dim_Date`: Enables time-series analysis across travel dates, quarters, and months.
#### ⚙️ The ETL Pipeline
This project leverages AWS Redshift to handle the heavy lifting for data transformation. The current ELT (Extract, Load, Transform) approach follows these stages:

* **Data Ingestion (S3):**
  * `1_upload_local_to_s3 (Heavy_lifting_from_Redshift).py`: A custom Python script utilizing the boto3 SDK to securely push the large local source files to Amazon S3. Sample files have been attached in the folder SourceFiles.

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
