-- Q1:

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(t.transaction_id) AS total_transactions
FROM aws_project.finance_customer_data_stg AS c
JOIN aws_project.finance_account_data_stg AS a
    ON a.customer_id = c.customer_id
JOIN aws_project.finance_transaction_data_stg AS t
    ON t.src_account_id = a.account_id
WHERE
    t.transaction_date >= CURRENT_DATE - INTERVAL 5 YEAR
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    total_transactions DESC
LIMIT
    5;



-- Q2:

SELECT
    COUNT(DISTINCT l.customer_id) AS loan_and_account_customers
FROM aws_project.finance_loan_data_stg AS l
JOIN aws_project.finance_account_data_stg AS a
    ON l.customer_id = a.customer_id
JOIN aws_project.finance_customer_data_stg AS c-- We must have record here
    ON c.customer_id = l.customer_id
WHERE
    a.acc_opening_date <= l.start_date;



-- Q3:

SELECT DISTINCT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    a.acc_opening_date
FROM aws_project.finance_customer_data_stg AS c
JOIN aws_project.finance_account_data_stg AS a
    ON a.customer_id = c.customer_id
WHERE
    a.acc_opening_date <= CURRENT_DATE - INTERVAL 5 YEAR;



-- Q4:

SELECT
    currency_code,
    SUM(CASE WHEN tran_status = 'TranStatus.C' THEN 1 ELSE 0 END) AS completed_count,
    SUM(CASE WHEN tran_status = 'TranStatus.F' THEN 1 ELSE 0 END) AS failed_count
FROM aws_project.finance_transaction_data_stg
GROUP BY
    currency_code
ORDER BY
    completed_count DESC,
    failed_count DESC;



-- Q5:

SELECT
    t.transaction_id,
    t.amount,
    t.currency_code,
    c.city,
    c.country
FROM aws_project.finance_transaction_data_stg AS t
JOIN aws_project.finance_account_data_stg AS a
    ON a.account_id = t.src_account_id
JOIN aws_project.finance_customer_data_stg AS c
    ON c.customer_id = a.customer_id
ORDER BY
    t.amount DESC
LIMIT
    10;



-- Q6 (1):

SELECT
    c.country,
    SUM(l.amount) AS total_expenses
FROM aws_project.finance_ledger_data_stg AS l
JOIN aws_project.finance_account_data_stg AS a
    ON a.account_id = l.account_id
JOIN aws_project.finance_customer_data_stg AS c
    ON c.customer_id = a.customer_id
WHERE
    LOWER(l.ledger_type) = 'expense'
GROUP BY
    c.country
ORDER BY
    total_expenses DESC
LIMIT
    1;



-- Q6(2):


SELECT
    c.country,
    SUM(l.amount) AS total_income
FROM aws_project.finance_ledger_data_stg AS l
JOIN aws_project.finance_account_data_stg AS a
    ON a.account_id = l.account_id
JOIN aws_project.finance_customer_data_stg AS c
    ON c.customer_id = a.customer_id
GROUP BY
    c.country
ORDER BY
    total_income DESC
LIMIT
    25;



-- Q7:

SELECT
    c.country,
    COUNT(l.loan_id) AS total_loan_count,
    SUM(l.principal_amount) AS total_principal_distributed
FROM aws_project.finance_loan_data_stg AS l
JOIN aws_project.finance_customer_data_stg AS c
    ON c.customer_id = l.customer_id
GROUP BY
    c.country
ORDER BY
    total_principal_distributed DESC;



-- Q8:

SELECT
    c.country,
    COUNT(l.ledger_id) AS total_equity_count,
    SUM(l.amount) AS total_equity
FROM aws_project.finance_ledger_data_stg AS l
JOIN aws_project.finance_account_data_stg AS a
    ON a.account_id = l.account_id
JOIN aws_project.finance_customer_data_stg AS c
    ON c.customer_id = a.customer_id
WHERE
    l.ledger_type = 'Equity'
GROUP BY
    c.country
ORDER BY
    total_equity DESC;



-- Q9:

WITH age_group_loan_counts AS (
    SELECT
        l.loan_id
        , l.loan_type
        , l.principal_amount
        , CASE
            WHEN DATE_DIFF('year', c.date_of_birth, CURRENT_DATE) BETWEEN 18 AND 25 THEN '18-25'
            WHEN DATE_DIFF('year', c.date_of_birth, CURRENT_DATE) BETWEEN 26 AND 35 THEN '26-35'
            WHEN DATE_DIFF('year', c.date_of_birth, CURRENT_DATE) BETWEEN 36 AND 45 THEN '36-45'
            WHEN DATE_DIFF('year', c.date_of_birth, CURRENT_DATE) BETWEEN 46 AND 55 THEN '46-55'
            WHEN DATE_DIFF('year', c.date_of_birth, CURRENT_DATE) > 55 THEN '55+'
            ELSE 'Unknown/Other'
        END AS age_group
    FROM aws_project.finance_loan_data_stg AS l
    JOIN aws_project.finance_customer_data_stg AS c
        ON c.customer_id = l.customer_id
)
SELECT
    age_group
    , loan_type
    , COUNT(*) AS total_loans_taken
    , SUM(principal_amount) AS total_borrowed_volume
FROM age_group_loan_counts
GROUP BY
    age_group
    , loan_type
ORDER BY
    total_borrowed_volume DESC
LIMIT
    1;



-- Q10:

SELECT
    a.currency_code,
    c.country,
    COUNT(l.ledger_id) AS total_ledger_transactions,
    SUM(l.amount) AS total_ledger_volume
FROM aws_project.finance_ledger_data_stg AS l
JOIN aws_project.finance_account_data_stg AS a
    ON a.account_id = l.account_id
JOIN aws_project.finance_customer_data_stg AS c
    ON c.customer_id = a.customer_id
GROUP BY
    a.currency_code,
    c.country
ORDER BY
    total_ledger_transactions DESC
LIMIT
    1;
