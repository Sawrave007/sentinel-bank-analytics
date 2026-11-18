# Data Requirements: Sentinel Bank Audit & Compliance Analytics

**Requested by:** Intelligence & Data Analytics, Internal Control & Compliance Division
**Prepared by:** Sawrave | **Version:** 1.0 | **Data:** synthetic (fictional bank)
**Purpose:** Define the data needed from source-system owners to run continuous control tests, fraud and AML monitoring, and early-warning reporting, and to load it into the analytics warehouse (EDW simulation).

## 1. Stakeholders and what they provide or need

| Stakeholder | Role in this project | What they provide or need |
|---|---|---|
| IT / Data Warehouse | Owns source systems and the EDW feed | Extracts of the tables below, refresh schedule, field definitions, access approval |
| Finance | Owns the general ledger and provisioning | Balance and loan outstanding figures that must reconcile to the ledger |
| Compliance | Owns AML, KYC and regulatory reporting | Reporting thresholds, KYC risk ratings, review of AML alert logic |
| Audit (ICCD) | Primary user | Exception lists, control-effectiveness view, evidence for fieldwork |
| Head of Intelligence & Data Analytics | Approver of methodology | Findings that are accurate and defensible |
| Senior Management / Board Audit Committee | Report readers | Summary risk view, trends, required actions |

## 2. Data requested

| Table (core schema) | Source system | Owner | Refresh | Used by |
|---|---|---|---|---|
| dim_branch | Core banking | IT | Monthly | All branch-level reporting |
| dim_employee | HR / Core banking | IT | Monthly | Maker-checker bypass, EWS, segregation of duties |
| dim_customer | KYC / Core banking | Compliance, IT | Daily | AML high-risk activity, KYC checks |
| dim_account | Core banking | IT | Daily | Dormant-account reactivation, all transaction tests |
| fact_transaction | Core banking | IT, Finance | Daily | Structuring, rapid in-and-out, maker-checker, dormant accounts |
| fact_loan | Loan system | Finance, IT | Daily | NPL ageing, concentration, evergreening, EWS |
| fact_loan_repayment | Loan system | Finance, IT | Daily | NPL ageing, evergreening, EWS |
| fact_digital_payment | Card / MFS / internet banking | IT | Daily (near real time in production) | Velocity, odd-hour and failed-then-success, fraud model |
| fact_audit_log | Core banking system logs | IT | Daily | Override and after-hours activity, control testing |
| dim_date | Generated | Analytics | Static | Time analysis in dashboards |

## 3. Key fields and definitions

- **Amounts** are in BDT.
- **Transaction time vs posting time:** `txn_datetime` is when the customer acted; `posting_datetime` is when the bank booked it. A posting earlier than its transaction time is a backdating signal.
- **Maker and checker:** `maker_id` initiates, `checker_id` approves. They must be different employees, and the checker must hold the Checker role.
- **Days past due:** days between due date and paid date (or the extract date if unpaid). Loan classification follows regulatory ageing buckets, to be confirmed against current Bangladesh Bank guidance.
- **Cash reporting threshold:** stored in `audit.rule_config`, never hard-coded. Verify against current regulation before relying on it.

## 4. Data quality requirements

- No duplicate primary keys; every foreign key resolves.
- Source-to-warehouse row counts and total amounts reconcile per load.
- Mandatory fields not null: account, customer, amount, dates, maker.
- Each load is logged (run id, step, row counts, status) in `audit.pipeline_run_log`; each data-quality check result in `audit.dq_results`.

## 5. Access and security assumptions

- Read-only access to source extracts; analytics writes only to its own database.
- Customer identifiers are masked or synthetic. No real personal data is used in this project.

## 6. Open items (to confirm with data owners)

- Exact regulatory reporting thresholds and loan classification rules.
- Frequency and format of the production EDW feed.
- Retention period for transaction and audit-log history.
