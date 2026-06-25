--- Table: aws_project.finance_account_data_stg ---
CREATE TABLE aws_project.finance_account_data_stg (
    account_id BIGINT
    , customer_id BIGINT
    , balance DOUBLE
    , currency_code VARCHAR
    , acc_opening_date TIMESTAMP
);

--- Table: aws_project.finance_customer_data_stg ---
CREATE TABLE aws_project.finance_customer_data_stg (
    customer_id BIGINT
    , first_name VARCHAR
    , last_name VARCHAR
    , email VARCHAR
    , phone_number VARCHAR
    , date_of_birth DATE
    , gender VARCHAR
    , national_id VARCHAR
    , address_line_1 VARCHAR
    , address_line_2 VARCHAR
    , city VARCHAR
    , country VARCHAR
    , postal_code VARCHAR
    , created_at TIMESTAMP
    , updated_at TIMESTAMP
);

--- Table: aws_project.finance_ledger_data_stg ---
CREATE TABLE aws_project.finance_ledger_data_stg (
    ledger_id BIGINT
    , transaction_id VARCHAR
    , account_id BIGINT
    , ledger_type VARCHAR
    , amount DOUBLE
    , entry_date TIMESTAMP
);

--- Table: aws_project.finance_loan_data_stg ---
CREATE TABLE aws_project.finance_loan_data_stg (
    loan_id BIGINT
    , customer_id BIGINT
    , loan_type VARCHAR
    , principal_amount DOUBLE
    , interest_rate DOUBLE
    , term_month BIGINT
    , start_date TIMESTAMP
    , end_date TIMESTAMP
);

--- Table: aws_project.finance_transaction_data_stg ---
CREATE TABLE aws_project.finance_transaction_data_stg (
    transaction_id VARCHAR
    , src_account_id BIGINT
    , dest_account_id BIGINT
    , amount DOUBLE
    , currency_code VARCHAR
    , transaction_date TIMESTAMP
    , tran_status VARCHAR
);
