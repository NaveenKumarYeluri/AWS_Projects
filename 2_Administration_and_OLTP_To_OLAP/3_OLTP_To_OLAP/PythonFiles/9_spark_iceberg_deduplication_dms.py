import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.window import Window
from pyspark.sql.functions import col, row_number

# 1. Initialize Spark and Glue Contexts
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# === SET YOUR BUCKET HERE ===
bucket_name = "aws-project-dms-raw-zone"
# ============================

print("Starting Data Lakehouse Deduplication Job...")

# 2. Configure Iceberg Catalog for this session
spark.conf.set("spark.sql.catalog.glue_catalog", "org.apache.iceberg.spark.SparkCatalog")
spark.conf.set("spark.sql.catalog.glue_catalog.warehouse", f"s3://{bucket_name}/iceberg_warehouse/")
spark.conf.set("spark.sql.catalog.glue_catalog.catalog-impl", "org.apache.iceberg.aws.glue.GlueCatalog")
spark.conf.set("spark.sql.catalog.glue_catalog.io-impl", "org.apache.iceberg.aws.s3.S3FileIO")

# 3. Read Raw DMS Parquet Data from S3
print("Loading Raw S3 Data into Memory...")
applicant_df = spark.read.parquet(f"s3://{bucket_name}/aws_project/applicant_dms/")
institute_df = spark.read.parquet(f"s3://{bucket_name}/aws_project/institute_dms/")

# 4. Join First
print("Joining to filter Orphans...")
window_inst = Window.partitionBy("institute_id_sk").orderBy(col("row_id").desc())

# Drop both "rn" and the institute's "row_id" before the join
inst_clean = institute_df.withColumn("rn", row_number().over(window_inst)).filter(col("rn") == 1).drop("rn", "row_id")

# Perform the INNER JOIN. Since inst_clean no longer has a row_id, there is no ambiguity!
valid_applicants_df = applicant_df.join(inst_clean, applicant_df.institute_id_fk == inst_clean.institute_id_sk, "inner")

# 5. Deduplicate Second (Now we only deduplicate surviving, valid records)
print("Executing ROW_NUMBER() Deduplication on valid records...")
window_app = Window.partitionBy("applicant_id_sk").orderBy(col("row_id").desc())
gold_df = valid_applicants_df.withColumn("rn", row_number().over(window_app)).filter(col("rn") == 1).drop("rn")

# 6. Select Final Columns
final_gold_df = gold_df.select(
    # Applicant Columns
    col("applicant_id_sk"),
    col("applicant_name"),
    col("applicant_gender"),
    col("applicant_dob"),
    col("applicant_country"),
    col("applicant_qual_test_score"),
    col("applicant_high_school_pct"),
    col("scholarship_grade"),
    col("scholarship_pct"),
    col("interview_date"),
    col("interview_score"),
    col("admission_date"),
    col("course_name"),

    # Institute Columns
    col("institute_id_sk"),
    col("institute_name"),
    col("institute_fee"),
    col("institute_reputation"),
    col("institute_campus_job_placement_pct"),
    col("institute_campus_area"),
    col("score_cut_off"),
    col("total_no_of_students"),
    col("applied_no_of_students"),
    col("declined_no_of_student_pct"),
    col("accepted_no_of_student_pct")
)

# 7. Write to Apache Iceberg format
print("Writing Clean Data to Apache Iceberg...")
final_gold_df.writeTo("glue_catalog.lakehouse_gold.dms_applicant_institute_gold") \
    .tableProperty("format-version", "2") \
    .createOrReplace()

print("Job Complete! Iceberg table successfully registered in Glue Data Catalog.")
