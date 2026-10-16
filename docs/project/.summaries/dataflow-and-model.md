# DLH Data Flow: Copay & Logical Dimensional Model Summary

## 1. DLH Data Flow: Copay

### Overview
This is the data flow architecture for the "Copay" domain within the Data Lakehouse (DLH). The flow moves data from external sources through Azure cloud infrastructure into a multi-schema data warehouse, then out to business applications and BI/reporting.

### Source Systems & Data Inputs

**Client Data:**
- Client data files: Benefits, Rx claims, eligibility, specialty drug lists, MAC lists, etc.
- Delivered via FTP (client FTP preferred, else PillarRx FTP on files.com)
- Also received via Secure Email (emailed to 672 - DW Support, manual process)

**External Reference Data:**
- **Drug reference files** (from Wolters Kluwer Medi-Span) -> Azure Blob Storage -> ADF scheduled pull
- **Pharmacy reference files** (from NCPDP) -> Azure Blob Storage -> ADF scheduled pull
- **Provider reference files** (from NPPES - National Plan & Provider Enumeration System) -> Azure Blob Storage -> ADF scheduled pull
- **Provider taxonomy code set** (from NUCC - National Uniform Claim Committee) -> Azure Blob Storage

**Business Application Data (from PAX Web App):**
- Daily claims
- Member legacy ID
- Enrollments/exceptions
- IPC ETC Coding
- Drug lists
- Client, ClientPBM, PBM
- UserLog, ClientDetail
- OverrideCategory
- Pulled via ADF scheduled pull from SQL Server instance: SourceDataDB01
- Some data is BLOB-triggered (Navitus Daily Claim, Account Management handled Benefit)

**Legacy System Data:**
- NPCS Risk Strategies (Legacy Axia) -> SQL Axia Prod -> Copy Data (NCPDP format) -> ADF push -> Azure Blob Storage

### Cloud Infrastructure

**Microsoft Azure Cloud:**
- Azure Blob Storage (multiple containers for different source types)
- Azure Data Factory (ADF) - ETL orchestration tool
- Azure SQL DB (PaaS) - DB Name: `sqldb-dw-prd-eastus2-001`

**Amazon Web Services Cloud:**
- Qlik Sense BI tool (SaaS) - self-service, in-memory analytics
- Qlik Data File (QDF) Container

### Data Lakehouse Schema Architecture

The data lakehouse resides in Azure SQL DB and has four schemas:

#### Schema: `dw_acq` (Acquisition)
- **Purpose:** Collect raw data and track version history on data changes where applicable. Support prototyping efforts for dw_pres layer.
- **Structure:** Independent tables (no relationships)
- **Organization:** Separate table for each source data format
- **Version history:** Type-2 is the default, but may be Type-1 for some tables if source tracks version history, or is insert-only, or no version history is needed/desired.

#### Schema: `dw_int` (Integration)
- **Purpose:** Limited use (as needed) when ETL logic to load a dw_pres object is sufficiently complex to warrant additional steps and persisting of data.
- **Structure:** Clusters of related tables, may be 3NF or denormalized
- **Organization:** As needed
- **Version history:** Type-1 is the default, Type-2 where version history is needed/desired.

#### Schema: `dw_pres` (Presentation)
- **Purpose:** Present conformed, consistent, integrated data to downstream applications, reports, and analytics.
- **Structure:** Dimensional
- **Organization:** Conformed by subject area (source data formats harmonized into common target model)
- **Version history:** Type-1 is the default, Type-2 where version history is needed/desired.

#### Schema: `dw_lake` (Lake)
- **Purpose:** Make data available to power users who need to access source format-specific attributes not contained in the dw_pres layer.
- **Structure:** Same as source table
- **Organization:** Same as source table
- **Version history:** Same as source table
- **Access:** Via DB views or materialized views

### ETL Flow Pattern
1. External files land in Azure Blob Storage
2. ADF pulls/pushes data into `dw_acq` schema
3. ETL transforms data from `dw_acq` to `dw_int` (when needed) via Stored Procedures executed through ADF
4. ETL transforms data from `dw_int` (or `dw_acq`) to `dw_pres` via Stored Procedures executed through ADF
5. `dw_lake` is populated as views/materialized views over `dw_acq` data

### Business Applications

- **PAX Web App:** Used by Copay Users, Care Team, Ops Team. Interacts with MemberOps DB.
- **Member Matching Tool:** Create, update, merge, unmerge members. Create, update member alias records to link PCT (Pharmacy Claim Transaction) claims. Used by Ops Team. Triggers stored procedures via ADF (on-demand push).
- **MemberOps DB:** Stores member operations data. Updated via stored procedures.

### BI / Reporting
- **Qlik Sense (SaaS on AWS):** Reads QDF files, builds in-memory data sets for self-service analytics
- **Reports:** Monthly consulting reports, custom analyses sent to Copay Clients
- Data pushed via ADF to Qlik; Qlik also does scheduled pulls
- Account Management Team sources Qlik reports for Benefit updates

### Key User Groups
- **Copay Clients:** Receive reports, send data files
- **Copay Users / Care Team:** Interact with PAX Web App, view reports
- **Ops Team:** Interact with PAX Web App, use Member Matching Tool
- **DB Power Users (Analytics, Ops, ETL):** Query dw_lake and dw_pres directly
- **Account Management Team:** Source Qlik reports for Benefit updates

---

## 2. Logical Dimensional Model: Paid Pharmacy Claims Stars (Entity-Level)

**Last Modified:** October 2025
**Author:** PillarRx Consulting (Customized Pharmacy Solutions)

### Fact Tables

#### Paid Pharmacy Claim Transaction Fact
- **Grain:** One record per unique pharmacy claims payment, reversal, or adjustment transaction, per applicable Company/Division/Client.
- **Exclusions:** Rejected claims
- **Inclusions:** Complete reversals
- **Note:** This is the raw transaction-level fact

#### Paid Pharmacy Claim Adjusted Transaction Fact
- **Grain:** One record per unique pharmacy claims payment or reversal transaction, per applicable Company/Division/Client.
- **Key difference from Transaction Fact:** Adjustments are netted into the related payment transaction.
- **Exclusions:** Rejected claims
- **Inclusions:** Complete reversals

### Dimension Tables

#### Client-Related Dimensions
| Dimension | Description | Notes |
|-----------|-------------|-------|
| **Client Dimension** | Client info with rollups to Division and Company | Hierarchical: Company > Division > Client |
| **Client Benefit Group / History Dimensions** | Benefit groups for each Company/Client | Includes client line of business and generic benefit fields. Has Type-2 history variant. |
| **Client Fiscal Month Dimension** | Client's fiscal month/quarter/year | Based on Fill Date |
| **Claim Benefit Dimension (NEW)** | Unique claim benefit reporting data | Per Company/Division/Client |

#### Member-Related Dimensions
| Dimension | Description | Notes |
|-----------|-------------|-------|
| **Member Dimension** | Unique members (humans) per Company/Client | Not Division-specific |
| **Claim Member Dimension** | Unique member demographic profiles from claims | Per Company/Client; not Division-specific |
| **Claim Subscriber Dimension** | Unique subscriber demographic profiles from claims | Per Company/Client; not Division-specific |
| ~~Subscriber Dimension~~ | ~~Unique subscribers (humans) per Company/Client~~ | **DEPRECATED** |

#### Drug-Related Dimensions
| Dimension | Description | Notes |
|-----------|-------------|-------|
| **Drug / History Dimensions** | Master/reference drug data based on NDC | From external data providers + internal derived/conformed fields. Has Type-2 history variant. |
| **Claim Drug Dimension** | Drug attributes needed directly from the claim | Claim-specific drug attributes |

#### Pharmacy-Related Dimensions
| Dimension | Description | Notes |
|-----------|-------------|-------|
| **Pharmacy / History Dimensions** | Master/reference pharmacy data based on NCPDP ID | From external data providers + internal derived/conformed fields. Also contains NPI. Has Type-2 history variant. |
| **Claim Pharmacy Dimension** | Pharmacy attributes needed directly from the claim | Claim-specific pharmacy attributes |

#### Provider-Related Dimensions
| Dimension | Description | Notes |
|-----------|-------------|-------|
| **Prescribing Provider Dimension** | Master/reference provider data based on NPI | From external data providers + internal derived/conformed fields |
| ~~Primary Care Provider Dimension~~ | ~~Same underlying Provider as Prescribing Provider~~ | **DEPRECATED (struck through in diagram).** Was based on PCP NPI from claim when available. Role-playing dimension. |

#### Other Dimensions
| Dimension | Description | Notes |
|-----------|-------------|-------|
| **PBM Dimension** | Basic info on the PBM | Likely maintained internally |
| **Pharmacy Claim Info Dimension** | Junk dimension - required attributes from claim or derived | Contains attributes that don't fit neatly into other dimensions |
| ~~Copay Assistance Program Options Dimension~~ | ~~Program options such as billing type and fee percentage/amount~~ | **DEPRECATED (struck through in diagram)** |
| ~~Copay Assistance Invoice Date Dimension~~ | ~~Date dimension for copay assistance invoices~~ | **DEPRECATED (struck through in diagram)** |

#### Date Dimensions (Role-Playing)
| Dimension | Description |
|-----------|-------------|
| **Fill Date Dimension** | Date the prescription was filled |
| **Submit Date Dimension** | Date the claim was submitted |
| **Load Date Dimension** | Date the record was loaded into the warehouse |

### Key Modeling Patterns

1. **Role-playing dimensions:** Date dimensions are role-played (Fill Date, Submit Date, Load Date use the same base Date Dimension)
2. **History dimensions:** Several dimensions have Type-2 SCD (Slowly Changing Dimension) history variants (Drug, Pharmacy, Client Benefit Group)
3. **Junk dimension:** Pharmacy Claim Info Dimension collects miscellaneous claim attributes
4. **Claim-specific vs. Master dimensions:** Pattern of having both master/reference dimensions (Drug, Pharmacy, Provider) and claim-specific dimensions (Claim Drug, Claim Pharmacy) to separate reference data from claim-level attributes
5. **Company/Division/Client hierarchy:** Core organizational hierarchy used throughout the model; members and subscribers are scoped to Company/Client level (not Division-specific)
6. **Deprecated entities:** Subscriber Dimension, Primary Care Provider Dimension, Copay Assistance Program Options Dimension, and Copay Assistance Invoice Date Dimension are all deprecated (struck through)

### Key Business Identifiers
- **NDC (National Drug Code):** Key for drug dimensions
- **NCPDP ID:** Key for pharmacy dimensions
- **NPI (National Provider Identifier):** Key for provider dimensions
- **Company/Division/Client:** Organizational hierarchy keys
