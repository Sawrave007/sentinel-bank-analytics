-- Phase 1: audit-layer tables (exceptions, rule parameters, logs) and the hidden label table.
USE SentinelBank;
GO

DROP TABLE IF EXISTS audit.exceptions;
DROP TABLE IF EXISTS audit.dq_results;
DROP TABLE IF EXISTS audit.pipeline_run_log;
DROP TABLE IF EXISTS audit.rule_config;
DROP TABLE IF EXISTS label.anomaly_truth;
GO

-- Rule parameters live here, never hard-coded in queries.
-- Regulatory values must be verified against current guidance before real use.
CREATE TABLE audit.rule_config (
    rule_id         VARCHAR(10)   NOT NULL,
    parameter_name  VARCHAR(40)   NOT NULL,
    parameter_value DECIMAL(18,2) NOT NULL,
    unit            VARCHAR(20)   NULL,
    note            VARCHAR(200)  NULL,
    CONSTRAINT pk_rule_config PRIMARY KEY (rule_id, parameter_name)
);

-- Single table every control test writes to. Power BI reads from this.
CREATE TABLE audit.exceptions (
    exception_id   BIGINT IDENTITY(1,1) PRIMARY KEY,
    run_id         UNIQUEIDENTIFIER NULL,
    rule_id        VARCHAR(10)   NOT NULL,
    area           VARCHAR(20)   NOT NULL,           -- Credit / AML / Digital Payments / Controls
    entity_type    VARCHAR(20)   NOT NULL,           -- account / customer / loan / employee / payment
    entity_id      BIGINT        NOT NULL,
    branch_id      INT           NULL,
    amount_bdt     DECIMAL(18,2) NULL,
    risk_rating    VARCHAR(10)   NOT NULL,           -- High / Medium / Low
    detail         NVARCHAR(500) NULL,
    detected_at    DATETIME2(0)  NOT NULL DEFAULT SYSDATETIME(),
    [status]       VARCHAR(15)   NOT NULL DEFAULT 'Open'
);

CREATE TABLE audit.pipeline_run_log (
    log_id        BIGINT IDENTITY(1,1) PRIMARY KEY,
    run_id        UNIQUEIDENTIFIER NOT NULL,
    step_name     VARCHAR(60)   NOT NULL,
    [status]      VARCHAR(10)   NOT NULL,            -- Started / Success / Failed
    rows_affected BIGINT        NULL,
    message       NVARCHAR(500) NULL,
    logged_at     DATETIME2(0)  NOT NULL DEFAULT SYSDATETIME()
);

CREATE TABLE audit.dq_results (
    dq_id        BIGINT IDENTITY(1,1) PRIMARY KEY,
    run_id       UNIQUEIDENTIFIER NULL,
    check_name   VARCHAR(80)   NOT NULL,
    table_name   VARCHAR(60)   NOT NULL,
    expected_val DECIMAL(24,2) NULL,
    actual_val   DECIMAL(24,2) NULL,
    check_status VARCHAR(10)   NOT NULL,             -- Pass / Fail
    checked_at   DATETIME2(0)  NOT NULL DEFAULT SYSDATETIME()
);

-- Ground truth for planted anomalies. Used ONLY to score detection afterwards.
CREATE TABLE label.anomaly_truth (
    truth_id      BIGINT IDENTITY(1,1) PRIMARY KEY,
    anomaly_type  VARCHAR(30)  NOT NULL,             -- e.g. structuring, dormant_reactivation, maker_checker_bypass
    entity_type   VARCHAR(20)  NOT NULL,
    entity_id     BIGINT       NOT NULL
);
GO
