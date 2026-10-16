# DLH Errors & Support Summary

Source: Email from Jeff Trzebiatowski (ETL DWH Leader, Brown & Brown, Wauwatosa WI) to Varun Tottempudi and Ramana Telukutla, dated 2026-09-15. The attached .docx contains the same content as the email body.

## Context

A 10-week error sample from DLH (Data Lakehouse) processes, captured from 2026-06-14 to 2026-08-25. The discussion concerned error handling and integrations between DLH and PAX.

## Key Systems

- **DLH** — Data Lakehouse (the data platform)
- **PAX** — A downstream system integrated with DLH (likely a pharmacy/claims product)
- **ADF** — Azure Data Factory (ETL orchestration)
- **Azure Blob Storage** — Landing zone for raw files
- **ACQ schema** — Acquisition/raw layer in the lakehouse where source files are loaded
- **Optum** — PBM (Pharmacy Benefit Manager), a major external data source
- **BMICH** — Another data source (likely Blue Cross Blue Shield of Michigan or similar)
- **Wrike** — Project management tool used for support requests

## Error Breakdown

### FTP to BLOB failures (80%+ of all logged failures)
Retrieval of raw files from source systems and saving to Azure Blob Storage.

| Subset | % of FTP-to-BLOB | Root Cause | Action Required? |
|--------|-------------------|------------|------------------|
| Optum file-not-found | 90% | **False positive.** Optum doesn't send files on days with no eligible claims, but DLH checks daily. | No DLH action. PAX Product Owner manually verifies via Optum reporting portal. |
| Legitimate failures | 10% | FTP connections failing/timing out, files arriving late. | Yes — real errors needing attention. |

### BLOB to ACQ RAW failures (13% of all logged failures)
Source file successfully retrieved to Blob but failed to insert into the ACQ schema.

| Subset | % of BLOB-to-ACQ | Root Cause | Action Required? |
|--------|-------------------|------------|------------------|
| BMICH empty files | 83% | BMICH sends empty claim files with no records. Exception is logged unnecessarily. | No (enhancement to suppress this is in backlog, low priority). |
| Real execution/bugs | 17% | Actual code or execution failures. | Yes — resolved by DLH support team. |

### Remaining ~7% — Other ETL process failures
Not broken out in detail in the email.

## DLH Support Response Categories

1. **Missing Files (FTP to BLOB):** If a file is missing (excluding Optum), DLH team reports to PAX product owner for follow-up with the source. Combination of automated and manual support/communication. Daily file receipt is critical.

2. **Execution Failures (any ETL process):** Usually caused by Azure execution issues. Typically resolved by manually restarting the pipeline.

3. **Unexpected Failures:** Caused by source file issues or ADF problems. Source file issues — DLH coordinates with account manager of the affected client. Code issues — backlog item created to fix root cause.

4. **Manual Processes:** Some processes remain manual. Low frequency, low effort. Backlog items exist to automate them.

5. **Wrike Requests:** Frequent requests from account managers for client support, enhancements, new client implementations, and analytics support using the DLH.

## Patterns & Observations

- **Signal-to-noise ratio is poor.** ~93% of "FTP to BLOB" failures and ~83% of "BLOB to ACQ RAW" failures are false positives or known benign conditions. Only a small fraction of logged errors require human action.
- **Optum is the dominant noise source.** Daily no-file checks for numerous Optum clients generate the bulk of logged errors.
- **The ETL pipeline is Azure-based:** ADF orchestration, Blob storage landing zone, ACQ schema as raw/bronze layer.
- **Data flow pattern:** Source (FTP) -> Azure Blob -> ACQ RAW schema (in the lakehouse).
- **Support is partly manual and reactive.** Missing file detection, pipeline restarts, and account manager coordination all involve human intervention.
- **PAX integration is a key concern.** The email was prompted by a discussion about DLH-to-PAX error handling and integration.
