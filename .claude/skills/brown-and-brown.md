# Brown & Brown Customer Context

Load this skill when doing any Brown & Brown work: data modeling, project management, writing vibes for the modeling agent, or preparing deliverables.

## Company Overview

Brown & Brown (NYSE: BRO) is one of the largest insurance brokerages in the world. Founded 1939, HQ in Daytona Beach FL. $5.9B revenue, ~23K employees, 700+ offices in 19 countries. S&P 500 member. Growth through aggressive M&A. They are a broker (places insurance), not a carrier (does not underwrite).

Four segments: Property & Casualty, Employee Benefits, Personal Insurance, Consulting. Serves 21+ industries. Full company details are in the web research from the initial project setup.

## This Engagement: PillarRx (Pharmacy Benefits Management Consulting)

This project is **not** about B&B's general insurance brokerage. It focuses on **PillarRx**, B&B's pharmacy benefit management (PBM) consulting arm. PillarRx provides customized pharmacy solutions for employer-sponsored health plans -- analyzing pharmacy claims, optimizing costs, managing copay assistance programs, and auditing PBM performance.

The initiative is called **PillarRx 3.0** and is overseen by a Steering Committee. **eNobleon** owns the target architecture delivery scope. **Perficient** (Eric's firm) is engaged on data/Databricks work.

### Strategic Goal

"A governed data foundation to accelerate client onboarding, Member 360, affordability intelligence, workflow automation and AI."

### Priority Data Domains

1. Pharmacy claims & history
2. Member eligibility & benefits
3. Prior authorization data (FMH, Agadia, SureScripts)
4. Drug & reference data
5. Manufacturer programs (copay, rebates, coupons, 340B)
6. Medical claims & network data

### Key Consumption Use Cases

- **Member 360** -- unified member/patient view across pharmacy, medical, eligibility
- **Affordability intelligence** -- copay programs, manufacturer rebates, 340B optimization
- **Reporting** -- monthly consulting reports, audit reports for clients
- **AI/ML** -- AI-ready data for decisioning
- **Workflow automation**
- **APIs** -- external integration with PBMs, manufacturers, providers

---

## Current Architecture (As-Is)

### Platform: Azure SQL DB

- Database: `sqldb-dw-prd-eastus2-001` (Azure SQL DB PaaS)
- ETL: Azure Data Factory (ADF)
- BI: Qlik Sense (SaaS on AWS)
- ~300 clients (past and present): Audit, Copay, and Consulting

### Four DW Schemas

| Schema | Purpose | Style |
|--------|---------|-------|
| **dw_acq** (Acquisition) | Raw data, version history, one table per source format | Independent tables, Type-2 default |
| **dw_int** (Integration) | Staging when ETL is complex | 3NF clusters, limited use |
| **dw_pres** (Presentation) | Conformed dimensional model for apps/reports | Dimensional, Type-1 default |
| **dw_lake** (Lake) | Power user access to source-specific attributes | Views over dw_acq |

### ACQ Layer Design

- Multi-tenant hierarchy: **Company > Division > Client**
- Single schema `DW_ACQ`, naming: `ACQ_{domain}_{source}_{format}` (e.g., `ACQ_CLIENT_PHARMACY_CLAIM_CVS_4000`)
- Raw + Curated pattern: raw table captures every row as strings; curated table has typed columns
- Type-2 history tables use `_HISTORY` suffix
- Durable business keys for traceability from presentation back to raw record and source file

### Data Flow Pattern

Source (FTP) -> Azure Blob Storage -> ADF -> dw_acq -> (dw_int) -> dw_pres -> Business Apps / Qlik

### Business Applications

| System | Purpose |
|--------|---------|
| **PAX Web App** | Copay assistance program management |
| **MemberOps DB** | Member operations (SQL Server, legacy) |
| **AccuCast** | Auditing platform (multiple project DBs) |
| **TricastBenchmarksDB** | Benchmarking |
| **TricastMaster DB** | Master reference for auditing |

### Key Contacts

- **Jeff Trzebiatowski** -- ETL DWH Leader at B&B (Wauwatosa, WI)

---

## Target Architecture (PillarRx 3.0)

### Platform: Databricks Lakehouse

| Layer | Purpose |
|-------|---------|
| **Bronze** | Raw/ingested source files, immutable |
| **Silver** | Canonical data model, normalized and cleansed (this is where vibe modeling targets) |
| **Gold** | Business views: Member 360, Claim 360, benefit opportunities, analytics/ML features |

### Supporting Infrastructure

- **Lakebase PostgreSQL** -- operational/transactional DB (cases, tasks, workflows, member view, near-real-time)
- **ASP.NET Core / C# microservices** -- Member Service, Opportunity Service, Program Service, Rule Service, Workflow Orchestration, etc.
- **Care Team Portal (Web)** -- 360 member view, work queue, case management
- **Client/Partner Portal (future)** -- reporting, file status, self-service
- **AI Services** -- natural language rules (LLM), rules engine, benefit optimization (ML), decision explainability, GenAI assistant
- **AI-Driven Ingestion** -- LLM-based schema inference and mapping; goal is new source onboarding in hours/days vs. current manual process
- **Azure Foundation** -- AKS/App Service, ADLS Gen2, Entra ID, Key Vault, Service Bus, Event Grid

---

## Source Systems & Data Inventory

### PBM Sources (~10 PBMs, 17 source format variants)

| PBM | Format(s) | ACQ Table(s) | Raw Columns |
|-----|-----------|---------------|-------------|
| CVS Caremark | CVS 4000, CVS BMASS | ACQ_CLIENT_PHARMACY_CLAIM_CVS_4000 | 185 |
| Optum Rx | CHF7, BCKC | ACQ_CLIENT_PHARMACY_CLAIM_OPTUM_CHF7/BCKC | 165, 70 |
| Navitus | Standard | ACQ_CLIENT_PHARMACY_CLAIM_NAVITUS | 187 |
| Express Scripts (ESI) | ESI 2300, ESI HMRK, ESI BMASS | ACQ_CLIENT_PHARMACY_CLAIM_ESI_2300/HMRK | 256, 58 |
| EmpiRx Health | Standard, Reject | ACQ_CLIENT_PHARMACY_CLAIM_EMPIRX | 52, 106 |
| BCBS Michigan | Standard | acq_client_pharmacy_claim_bmich | 85 |
| Rightway | Standard | ACQ_CLIENT_PHARMACY_CLAIM_RIGHTWAY | 83 |
| Prime/Magellan | Standard | ACQ_CLIENT_PHARMACY_CLAIM_PRIME_MAGELLAN | 83 |
| ServeYou | Standard | ACQ_CLIENT_PHARMACY_CLAIM_SERVE_YOU | -- |
| Carelon | Standard | ACQ_CLIENT_PHARMACY_CLAIM_CARELON | -- |

Total unique raw column names across all formats: **891**, mapping into a canonical **~113-column PHARMACY_CLAIM_TRANSACTION** table.

### External Reference Data

| Source | Provider | Purpose |
|--------|----------|---------|
| Medi-Span | Wolters Kluwer | Drug pricing and classification |
| First DataBank (FDB) | FDB | Drug pricing and reference |
| NCPDP | NCPDP | Pharmacy reference/standards |
| NPPES | CMS | Provider NPI registry |
| NUCC | NUCC | Healthcare provider taxonomy |
| CMS.gov | CMS | LSHIST, MOMEMO, FIR, PDE, LEIE |

### Internal Data

PAX Web App data, Account Management data, CAP invoice schedules, cross-reference lists, client dimension master data.

---

## Existing Dimensional Model (Paid Pharmacy Claims)

### Fact Tables

| Fact | Grain | Notes |
|------|-------|-------|
| **Paid Pharmacy Claim Transaction** | One record per payment/reversal/adjustment per Company/Division/Client | Raw transaction-level; excludes rejected claims |
| **Paid Pharmacy Claim Adjusted Transaction** | One record per payment/reversal per Company/Division/Client | Adjustments netted into related payment |

### Active Dimensions (~18)

**Client:** Client (Company>Division>Client hierarchy), Client Benefit Group/History (Type-2), Client Fiscal Month, Claim Benefit (new)

**Member:** Member, Claim Member, Claim Subscriber

**Drug:** Drug/History (NDC-keyed, Type-2), Claim Drug

**Pharmacy:** Pharmacy/History (NCPDP-keyed, Type-2), Claim Pharmacy

**Provider:** Prescribing Provider (NPI-keyed)

**Other:** PBM, Pharmacy Claim Info (junk dim), Fill Date / Submit Date / Load Date (role-playing date dims)

**Deprecated:** Subscriber Dim, Primary Care Provider Dim, Copay Assistance Program Options Dim, Copay Assistance Invoice Date Dim

### Key Modeling Patterns

- Role-playing date dimensions (Fill, Submit, Load)
- Type-2 SCD history on Drug, Pharmacy, Client Benefit Group
- Master/reference dims vs. claim-specific dims (e.g., Drug Dim + Claim Drug Dim)
- Junk dimension for miscellaneous claim attributes
- Company/Division/Client hierarchy scoped throughout; members scoped to Company/Client (not Division)

---

## Canonical PHARMACY_CLAIM_TRANSACTION (PCT) Table

The PCT is the central fact table. Key column groups:

- **Keys:** surrogate IDs, Company/Division/Client hierarchy codes, claim grouping keys
- **Claim IDs:** claim_number, rx_number (zero-padded 12 digits), refill_number, claim status
- **Dates:** fill_date (date of service), submit_date (adjudication date)
- **Member:** external ID, name, gender (standardized), DOB, person/dependent code, relationship (standardized), address, phone, Medicare MBI
- **Subscriber:** external ID, name (often NOT PROVIDED from source)
- **Provider/Pharmacy:** pharmacy NPI, prescribing provider NPI, drug NDC (11-digit)
- **Financial:** total_cost, ingredient_cost, dispensing_fee, plan_paid, member_copay, member_coinsurance, deductible applied/remaining, OOP applied/remaining, other_payer
- **Benefit:** benefit_group_id (complex per-PBM derivation), client_benefit_group_ik
- **CAP (Copay Assistance):** drug_type_code, alternate_program_code, daily inclusion/exclusion flags, accumulator inclusion flags
- **Processing flags:** rx_count (PAID=1, REVERSED=-1, ADJUSTED/REJECTED=0), complete/orphaned reversal flags, inclusion/exclusion indicators
- **Lineage/Audit:** PBM_code, source type/name/format/file/line, record hash, insert/update timestamps, ETL run IDs


### Standard Transformations

- `COALESCE(value, 'NOT PROVIDED')` universal null replacement
- Gender: raw codes -> MALE/FEMALE/NOT PROVIDED/UNKNOWN
- Relationship: raw codes -> SUBSCRIBER/SPOUSE/CHILD/OTHER
- Rx number: zero-padded to 12 digits
- Phone: punctuation stripped, bogus numbers -> NOT PROVIDED
- ZIP: left 5 digits, '00000' -> NOT PROVIDED
- Several columns are placeholders populated by downstream stored procedures (member matching, benefit group assignment, reversal flags, inclusion indicators)

---

## Known Issues (from DLH error analysis, Jun-Aug 2026)

- **93% of logged errors are noise:** Optum no-file false positives (90% of FTP errors) and BMICH empty-file exceptions (83% of BLOB-to-ACQ errors)
- Real errors: FTP connection failures, late files, actual code/execution bugs
- Support is partly manual: missing file follow-ups, pipeline restarts, account manager coordination via Wrike
- PAX-to-DLH integration error handling was a known concern

---

## Terminology

| Term | Meaning |
|------|---------|
| PillarRx | B&B's pharmacy benefit consulting platform/brand |
| PBM | Pharmacy Benefit Manager (e.g., CVS, Optum, ESI) -- the intermediary B&B audits |
| PCT | PHARMACY_CLAIM_TRANSACTION -- the canonical claims table |
| ACQ | Acquisition layer (raw/bronze) |
| DLH | Data Lakehouse |
| PAX | Copay assistance program web application |
| CAP | Copay Assistance Program |
| NDC | National Drug Code (11-digit drug identifier) |
| NPI | National Provider Identifier |
| NCPDP ID | Pharmacy identifier from NCPDP |
| MBI | Medicare Beneficiary Identifier |
| 340B | Federal drug discount program for eligible healthcare organizations |
| MVM | Minimum Viable Model (vibe modeling agent scope) |
| ECM | Expanded Coverage Model (vibe modeling agent scope) |
| eNobleon | Vendor delivering the PillarRx 3.0 target architecture |
| Lakebase | Databricks' managed PostgreSQL for operational/transactional data |

---

## When Writing Vibes for the Modeling Agent

- This is **pharmacy benefit management consulting**, not general insurance brokerage
- B&B's clients are employers with health plans; B&B analyzes their pharmacy spend across PBMs
- The multi-tenant hierarchy is **Company > Division > Client** -- this is fundamental
- Key entities: pharmacy claims (the core), members/patients, drugs (NDC), pharmacies (NCPDP), providers (NPI), PBMs, benefit groups, copay assistance programs
- The Silver/canonical layer is the target for vibe modeling -- it should produce a normalized, cleansed model
- Financial grain: individual claim transactions with plan-paid, member-paid, and other-payer amounts
- Member 360 is a critical Gold-layer output -- unifying a member across PBMs, eligibility, medical claims
- Copay assistance / affordability intelligence is a key differentiator -- model manufacturer programs, rebates, 340B
- Expect to handle reversals and adjustments (paid/reversed/adjusted/rejected status)
- Multiple PBMs send the same conceptual data in wildly different formats (891 raw columns -> 113 canonical columns)
- Drug, pharmacy, and provider reference data comes from external standards bodies, not from B&B
