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
