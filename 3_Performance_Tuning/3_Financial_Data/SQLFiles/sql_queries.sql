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
