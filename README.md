# Sentinel Bank: Audit, Fraud & Early Warning Analytics

> **Status: in progress.** Built in public over November 2026. Checkboxes below show what is done.
> **All data is synthetic.** "Sentinel Bank" is a fictional institution. No real bank data, customer data or confidential information is used anywhere in this repository.

## Purpose

An end-to-end analytics project that mimics the workflow of an Intelligence & Data Analytics team inside a bank's Internal Control and Compliance function: take data from source systems, load it into a warehouse, run control tests and anomaly detection, score risk, and report findings to audit and senior management.

## What it covers

| Area | What is built |
|---|---|
| Data warehouse | SQL Server with `stg` (staging), `core` (star schema) and `mart` (reporting) schemas, loaded by Python |
| Risk and control tests | 10 T-SQL tests across credit, AML, digital payments and internal controls, all writing to one `audit.exceptions` table |
| Predictive models | Logistic regression baseline and gradient boosting for fraud detection |
| Early warning | Weighted indicator scorecard and watchlist for borrowers and branches |
| Dashboard | Four-page Power BI report: Executive, Audit & Compliance, AML & Fraud, EWS Watchlist |
| Automation | `run_pipeline.py` with logging, data-quality checks and an Excel exception pack for audit fieldwork |
| Reporting | Audit memo and a short board-style deck |

## Architecture

```
Synthetic source data (Python generator + planted anomalies + hidden label table)
        |
        v
   stg schema  ->  core schema (star)  ->  mart schema (reporting views)
        |                |                        |
   DQ + reconciliation   10 T-SQL control tests   Power BI dashboard
                         fraud models, EWS         Excel exception pack
                                |
                         audit.exceptions
```

## Synthetic data design

- Roughly 300-500K transactions across customers, accounts, branches, employees, loans, repayments, digital payments and system audit logs.
- Anomalies are planted at known rates: structuring, rapid in-and-out movement, dormant-account reactivation, maker-checker bypass, loan evergreening and fraud bursts.
- A hidden label table records the ground truth, so detection quality can be measured as precision, recall and false-positive rate.

## Control tests (planned set of 10)

- **Credit (3):** NPL ageing buckets, concentration, evergreening pattern
- **AML (3):** structuring below a configurable reporting threshold, rapid in-and-out movement, high-risk customer activity
- **Digital payments (2):** velocity, odd-hour or failed-then-successful attempts
- **Controls (2):** maker-checker bypass, dormant-account reactivation

Thresholds are configurable parameters and should be checked against current regulatory guidance before any real use.

## Tech stack

SQL Server (T-SQL), Python 3.11 (pandas, SQLAlchemy, pyodbc, Faker, scikit-learn), Power BI, Excel (openpyxl).

## Roadmap

- [ ] Data requirements document
- [ ] Synthetic data generator with planted anomalies and label table
- [ ] Warehouse schemas and Python loader
- [ ] Data-quality and reconciliation checks
- [ ] 10 T-SQL control tests and `audit.exceptions` table
- [ ] Fraud models (logistic regression, gradient boosting)
- [ ] Early-warning scorecard and watchlist
- [ ] Power BI dashboard (4 pages)
- [ ] Automated pipeline and Excel exception pack
- [ ] Audit memo and board deck

## Repository structure (target)

```
sentinel-bank-analytics/
├── data_generation/   # generator and anomaly injection
├── warehouse/         # DDL, ETL, data-quality checks
├── analytics/         # T-SQL control tests and Python scripts
├── models/            # fraud models and EWS scorecard
├── automation/        # pipeline runner, logging, Excel pack
├── dashboards/        # Power BI file and screenshots
├── reports/           # audit memo and board deck
└── docs/              # requirements, data dictionary, methodology
```

## How to run

Instructions will be added as each stage is completed. Requirements: SQL Server (local instance), Python 3.11, ODBC Driver 18 for SQL Server, Power BI Desktop.

## Limitations

- Detection results are measured against anomalies I planted myself. They show that the pipeline works, not how it would perform on real bank data.
- Stakeholder collaboration (IT, Finance, Compliance, Audit) is simulated through documentation, not real engagement.
- The enterprise data warehouse is represented by a local SQL Server database.
- AI assistance was used for scaffolding and code generation; I review, run and can explain every component.

