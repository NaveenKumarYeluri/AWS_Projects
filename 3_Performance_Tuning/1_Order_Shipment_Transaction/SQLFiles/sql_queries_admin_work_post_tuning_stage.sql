-- Q8: This requires updating shipment table.

-- Option 1:
UPDATE aws_project.order_shipment_def
SET shipment_to_city = t.customer_city
FROM aws_project.order_transaction_def
WHERE
    aws_project.order_shipment_def.order_id = t.order_id
    AND aws_project.order_shipment_def.shipment_to_city != t.customer_city;--Took: 7m 59s

VACUUM FULL aws_project.order_shipment_def;-- Took: 32.5s
ANALYZE aws_project.order_shipment_def;-- Took: 1.2s


-- Option 2:
-- CTAS alternative to UPDATE.
CREATE TABLE aws_project.order_shipment_def_fixed
DISTSTYLE EVEN AS
SELECT
    s.order_id,
    s.shipment_date,
    s.invoice_number,
    s.shipment_from_city,
    t.customer_city AS shipment_to_city,
    s.invoice_amount
FROM aws_project.order_shipment_stg s
JOIN aws_project.order_transaction_def t
    ON s.order_id = t.order_id;

-- 2. Swap it
DROP TABLE aws_project.order_shipment_def;
ALTER TABLE aws_project.order_shipment_def_fixed RENAME TO order_shipment_def;



-- Option 1:
UPDATE aws_project.order_shipment_opt
SET shipment_to_city = t.customer_city
FROM aws_project.order_transaction_opt t
WHERE
    aws_project.order_shipment_opt.order_id = t.order_id
    AND aws_project.order_shipment_opt.shipment_to_city != t.customer_city;--Took: 8m 10.1s

VACUUM FULL aws_project.order_shipment_opt;-- Took: 10m 52s
ANALYZE aws_project.order_shipment_opt;-- Took: 1.1s


-- Option 2:
-- CTAS alternative to UPDATE.
CREATE TABLE aws_project.order_shipment_opt_fixed
DISTSTYLE KEY DISTKEY (order_id) SORTKEY (shipment_date) AS
SELECT
    s.order_id,
    s.shipment_date,
    s.invoice_number,
    s.shipment_from_city,
    t.customer_city AS shipment_to_city,
    s.invoice_amount
FROM aws_project.order_shipment_stg s
JOIN aws_project.order_transaction_opt t
    ON s.order_id = t.order_id;

-- 2. Swap it
DROP TABLE aws_project.order_shipment_opt;
ALTER TABLE aws_project.order_shipment_opt_fixed RENAME TO order_shipment_opt;



-- Get Query ID
SELECT
    query_id,
    query_text,
    start_time,
    execution_time
FROM sys_query_history
WHERE
    query_text LIKE '%temp_avg_lead_time_opt%'
ORDER BY
    start_time DESC;



-- Check
SELECT
    query_id,
    stream_id,
    segment_id,
    step_id,
    step_name,
    duration, -- Execution time for this specific step in microseconds
    table_name
FROM sys_query_detail
WHERE
    query_id = 23585650
ORDER BY
    stream_id,
    segment_id,
    step_id;



-- Check
SELECT
    query_id,
    query_text,
    start_time,
    execution_time
FROM sys_query_history
WHERE
    query_id = 23585650
ORDER BY
    start_time DESC;



/*

-- Setting Priority
-- P1: I will keep Business Satatements that produce very small and concise result set into this category. Instant answers + Live.
-- P2: Statements that will be part of reports but needs massive processing and produces lots of data. These might be seen once or twice per day.
-- P3: Audit statements where Business users might not need on a minute-by-minute basis. These are multi purpose statements.


So accordingly we have following groups.

P1: Q2, Q3, Q4, Q10
P2: Q1, Q5, Q7, Q9
P3: Q6, Q8

*/



/*

-- Setting SLAs
-- As given in project, I will be keeping 2x of average runtime, while setting SLA.

Accordingly,

Q1 (Order History 2-8 Years): Average ~1m 02s (62s). 2x = 124s. Final SLA: < 2 Minutes 5 Seconds.

Q2 (Discount by Credit): Average ~4.5s. 2x = 9.0s. Final SLA: < 10 Seconds.

Q3 (Top Country): Average ~0.15s. 2x = 0.3s. Final SLA: < 1 Second.

Q4 (Avg Credit by Country): Average ~4.5s. 2x = 9.0s. Final SLA: < 10 Seconds.

Q5 (Premium Avg Ship Time): Average ~1m 01s (61s). 2x = 122s. Final SLA: < 2 Minutes 5 Seconds.

Q6 (City-to-City Matrix): Average ~1m 59s (119s). 2x = 238s. Final SLA: < 4 Minutes.

Q7 (Global Avg Lead Time): Average ~1m 14s (74s). 2x = 148s. Final SLA: < 2 Minutes 30 Seconds.

Q8 (Mismatch Audit): Average ~1m 52s (112s). 2x = 224s. Final SLA: < 3 Minutes 45 Seconds.

Q9 (Lead Time by Amount): Average ~1m 29s (89s). 2x = 178s. Final SLA: < 3 Minutes.

Q10 (Top Premium States): Average ~8.0s. 2x = 16.0s. Final SLA: < 20 Seconds.

*/
