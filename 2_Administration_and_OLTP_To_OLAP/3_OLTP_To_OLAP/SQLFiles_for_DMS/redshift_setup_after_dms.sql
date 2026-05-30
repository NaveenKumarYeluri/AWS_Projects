CREATE EXTERNAL SCHEMA IF NOT EXISTS lakehouse
FROM DATA CATALOG
DATABASE 'lakehouse_gold'
IAM_ROLE 'arn:aws:iam::051741041272:role/Redshift-Spectrum-Role'
CREATE EXTERNAL DATABASE IF NOT EXISTS;


SELECT COUNT(*)
FROM lakehouse.dms_applicant_institute_gold;-- 1,18,64,129
