-- Phase 1: core star schema (dimensions and facts).
-- Safe to re-run: drops and recreates tables in dependency order.
USE SentinelBank;
GO

DROP TABLE IF EXISTS core.fact_audit_log;
DROP TABLE IF EXISTS core.fact_digital_payment;
DROP TABLE IF EXISTS core.fact_loan_repayment;
DROP TABLE IF EXISTS core.fact_loan;
DROP TABLE IF EXISTS core.fact_transaction;
DROP TABLE IF EXISTS core.dim_account;
DROP TABLE IF EXISTS core.dim_customer;
DROP TABLE IF EXISTS core.dim_employee;
DROP TABLE IF EXISTS core.dim_branch;
DROP TABLE IF EXISTS core.dim_date;
GO

-- ---------- Dimensions ----------

CREATE TABLE core.dim_date (
    date_key     INT         NOT NULL PRIMARY KEY,   -- yyyymmdd
    full_date    DATE        NOT NULL,
    [year]       SMALLINT    NOT NULL,
    [quarter]    TINYINT     NOT NULL,
    [month]      TINYINT     NOT NULL,
    month_name   VARCHAR(12) NOT NULL,
    day_of_week  TINYINT     NOT NULL,               -- 1 = Monday
    is_weekend   BIT         NOT NULL
);

CREATE TABLE core.dim_branch (
    branch_id    INT          NOT NULL PRIMARY KEY,
    branch_name  VARCHAR(80)  NOT NULL,
    division     VARCHAR(40)  NOT NULL,
    district     VARCHAR(40)  NOT NULL,
    branch_type  VARCHAR(20)  NOT NULL               -- Urban / Semi-urban / Rural
);

CREATE TABLE core.dim_employee (
    employee_id  INT          NOT NULL PRIMARY KEY,
    branch_id    INT          NOT NULL REFERENCES core.dim_branch(branch_id),
    full_name    VARCHAR(80)  NOT NULL,
    [role]       VARCHAR(30)  NOT NULL,              -- Teller / Maker / Checker / Relationship Manager / Branch Manager
    hire_date    DATE         NOT NULL,
    is_active    BIT          NOT NULL
);

CREATE TABLE core.dim_customer (
    customer_id        INT          NOT NULL PRIMARY KEY,
    full_name          VARCHAR(100) NOT NULL,
    date_of_birth      DATE         NULL,
    occupation         VARCHAR(60)  NULL,
    customer_segment   VARCHAR(20)  NOT NULL,        -- Retail / SME / Corporate
    risk_rating        VARCHAR(10)  NOT NULL,        -- Low / Medium / High (KYC)
    pep_flag           BIT          NOT NULL,        -- politically exposed person
    kyc_status         VARCHAR(20)  NOT NULL,        -- Complete / Incomplete / Expired
    kyc_last_review    DATE         NULL,
    onboard_date       DATE         NOT NULL,
    home_branch_id     INT          NOT NULL REFERENCES core.dim_branch(branch_id)
);

CREATE TABLE core.dim_account (
    account_id         BIGINT       NOT NULL PRIMARY KEY,
    customer_id        INT          NOT NULL REFERENCES core.dim_customer(customer_id),
    branch_id          INT          NOT NULL REFERENCES core.dim_branch(branch_id),
    account_type       VARCHAR(20)  NOT NULL,        -- Savings / Current / Fixed Deposit / Loan
    open_date          DATE         NOT NULL,
    account_status     VARCHAR(15)  NOT NULL,        -- Active / Dormant / Closed
    last_activity_date DATE         NULL,
    currency           CHAR(3)      NOT NULL DEFAULT 'BDT'
);

-- ---------- Facts ----------

CREATE TABLE core.fact_transaction (
    txn_id               BIGINT        NOT NULL PRIMARY KEY,
    account_id           BIGINT        NOT NULL REFERENCES core.dim_account(account_id),
    branch_id            INT           NOT NULL REFERENCES core.dim_branch(branch_id),
    txn_datetime         DATETIME2(0)  NOT NULL,     -- when the customer acted
    posting_datetime     DATETIME2(0)  NOT NULL,     -- when the bank booked it
    txn_type             VARCHAR(20)   NOT NULL,     -- CASH_DEPOSIT / CASH_WITHDRAWAL / TRANSFER_IN / TRANSFER_OUT
    channel              VARCHAR(15)   NOT NULL,     -- Branch / ATM / Internet / Mobile
    amount_bdt           DECIMAL(18,2) NOT NULL,
    counterparty_account BIGINT        NULL,
    maker_id             INT           NOT NULL REFERENCES core.dim_employee(employee_id),
    checker_id           INT           NULL REFERENCES core.dim_employee(employee_id),
    approval_status      VARCHAR(15)   NOT NULL      -- Approved / Pending / Auto
);

CREATE TABLE core.fact_loan (
    loan_id              INT           NOT NULL PRIMARY KEY,
    customer_id          INT           NOT NULL REFERENCES core.dim_customer(customer_id),
    branch_id            INT           NOT NULL REFERENCES core.dim_branch(branch_id),
    rm_employee_id       INT           NOT NULL REFERENCES core.dim_employee(employee_id),
    approved_by_id       INT           NOT NULL REFERENCES core.dim_employee(employee_id),
    product_type         VARCHAR(30)   NOT NULL,     -- SME Term / Retail Personal / Corporate / Working Capital
    sector               VARCHAR(40)   NOT NULL,
    sanction_date        DATE          NOT NULL,
    sanction_amount_bdt  DECIMAL(18,2) NOT NULL,
    outstanding_bdt      DECIMAL(18,2) NOT NULL,
    interest_rate_pct    DECIMAL(5,2)  NOT NULL,
    tenor_months         SMALLINT      NOT NULL,
    collateral_value_bdt DECIMAL(18,2) NULL,
    restructure_count    TINYINT       NOT NULL DEFAULT 0,
    last_restructure_date DATE         NULL,
    loan_status          VARCHAR(15)   NOT NULL      -- Active / Closed / Written-off
);

CREATE TABLE core.fact_loan_repayment (
    repayment_id   BIGINT        NOT NULL PRIMARY KEY,
    loan_id        INT           NOT NULL REFERENCES core.fact_loan(loan_id),
    due_date       DATE          NOT NULL,
    paid_date      DATE          NULL,               -- NULL = unpaid
    due_amount_bdt DECIMAL(18,2) NOT NULL,
    paid_amount_bdt DECIMAL(18,2) NOT NULL DEFAULT 0
);

CREATE TABLE core.fact_digital_payment (
    payment_id        BIGINT        NOT NULL PRIMARY KEY,
    account_id        BIGINT        NOT NULL REFERENCES core.dim_account(account_id),
    payment_datetime  DATETIME2(0)  NOT NULL,
    channel           VARCHAR(15)   NOT NULL,        -- Card / MFS / Internet
    merchant_category VARCHAR(30)   NULL,
    amount_bdt        DECIMAL(18,2) NOT NULL,
    device_id         VARCHAR(30)   NULL,
    city              VARCHAR(40)   NULL,
    payment_status    VARCHAR(10)   NOT NULL,        -- Success / Failed
    failure_reason    VARCHAR(40)   NULL
);

CREATE TABLE core.fact_audit_log (
    log_id          BIGINT        NOT NULL PRIMARY KEY,
    employee_id     INT           NOT NULL REFERENCES core.dim_employee(employee_id),
    event_datetime  DATETIME2(0)  NOT NULL,
    event_type      VARCHAR(25)   NOT NULL,          -- LOGIN / APPROVE / OVERRIDE / LIMIT_CHANGE
    entity_type     VARCHAR(20)   NULL,
    entity_id       BIGINT        NULL
);
GO

-- Indexes on the columns the control tests filter and join on most.
CREATE INDEX ix_txn_account_time ON core.fact_transaction (account_id, txn_datetime);
CREATE INDEX ix_txn_maker        ON core.fact_transaction (maker_id);
CREATE INDEX ix_pay_account_time ON core.fact_digital_payment (account_id, payment_datetime);
CREATE INDEX ix_repay_loan       ON core.fact_loan_repayment (loan_id, due_date);
GO
