# Architecture Summary

Consolidated from: ACQ_Data_Architecture_Overview.pdf, CurrentArchitecture.pdf, TargetArchitecture.pdf

---

## Current Architecture (as-is)

The current platform is called **PillarRx** and revolves around a **Data Warehouse / Lake** on **Azure SQL DB (PaaS)** with the database name `sqldb-dw-prd-eastus2-001`. The architecture is divided into five major zones:

### 1. Source Systems / Client Data
- ~300 total clients (past and present): Audit, Copay, and Consulting clients
- Client data files: Rx claims, eligibility, specialty, drug lists, MAC lists
- Delivery: FTP Server (client FTP preferred; otherwise PillarRx FTP on files.com), Secure Email
- **PillarRx ETL Team** manually copies files as well

### 2. External Data Sources
| Vendor | Data |
|--------|------|
| **Wolters Kluwer Medi-Span** | Drug reference files |
| **First DataBank (fdb)** | Drug reference files |
| **NCPDP** | Pharmacy reference files |
| **NPPES** | Provider reference files |
| **CMS.gov** | LSHIST (Low-Income Subsidy History), MOMEMO (Monthly Membership Detail), FIR (Financial Information Reporting), PDE (Prescription Drug Event), LEIE (OIG List of Excluded Individuals and Entities) |

### 3. Blob Storage (Azure Blob Storage)
- Landing zone for all incoming files
- Organization: by Company/Division, then Client, Source, and Data Type
- Multi-client files organized by sender/source (not split by client)
- External reference files organized by vendor

### 4. Data Warehouse / Lake Schemas
Four schemas inside Azure SQL DB:

| Schema | Purpose | Structure | History |
|--------|---------|-----------|---------|
| **dw_acq** (Acquisition) | Collect raw data and track version history on data changes | Independent tables, no relationships. Separate table per source data format | Type-2 default; may be Type-1 or insert-only |
| **dw_int** (Integration) | Limited use, only when ETL logic is complex enough for staging | Clusters of related tables, may be 3NF | Type-1 default; Type-2 where needed |
| **dw_pres** (Presentation) | Conformed, consistent, integrated data for apps, reports, analytics | Dimensional. Subject areas with harmonized formats | Type-1 default; Type-2 where needed |
| **dw_lake** (Lake) | Make raw data available to power users; format-specific attributes not in dw_pres | DB views or materialized views. Same org as dw_acq | Same as dw_acq |

### 5. Business Applications
| System | Purpose | Technology |
|--------|---------|------------|
| **MemberOps DB** | Member operations | SQL Server (no change from current state) |
| **PAX Web App** | Copay assistance program | Web app; reads Rx claims, eligibility; creates enrollments |
| **Accucast DataStore** (Project DB 1-N) | Audit data store | Multiple project DBs |
| **TricastBenchmarksDB** | Benchmarking data | SQL Server (no change from current state) |
| **TricastMaster DB** | Master reference for auditing | SQL Server (no change from current state) |
| **SQL Server instance: SourceDataDB01** | Source data | SQL Server |
| **SQL Server instance: AccucastDB** | AccuCast application DB | Azure SQL VM (IaaS) |

### 6. BI / Reporting
- **Qlik Sense** (SaaS): self-service in-memory analytics
- **Qlik Data Files (QDF)**: build in-memory data sets in QDF Container
- Reports: monthly consulting reports, audit reports, etc.
- Users: Copay Users, Audit Users, Audit/Copay/Consulting Users and Clients

### 7. ETL and Integration
- **Azure Data Factory (ADF)**: primary ETL tool throughout
- Data flows: Copy file, ETL, ADF pipelines connecting blob storage to DW schemas and then to business apps
- HITL (Human-in-the-loop) for schema translation
- Schema registry and agnostic ingestion patterns for new sources
- Line of Business extraction for downstream app databases

### 8. Cloud Infrastructure
- **Microsoft Azure** (primary): Azure Blob Storage, Azure SQL DB (PaaS), Azure SQL VM (IaaS), ADF
- **AWS**: Some presence (shown in diagram but role unclear)

---

## ACQ Layer Architecture (Data Acquisition)

The ACQ layer is the controlled acquisition and landing foundation. Key design decisions:

### Multi-tenant Organization
- Hierarchy: **Company -> Division -> Client**
- Same-format data co-located in common physical tables, partitioned by business keys
- Division-level sensitivity preserved; multi-division clients get separate division-specific copies

### Three Data Domains
1. **Client data**: claims, eligibility, enrollment
2. **External data**: Medi-Span, NCPDP, NPPES, First DataBank (shared vendor/reference)
3. **Internal data**: PAX, AccuCast, AMS360

### Schema and Naming
- Single schema: **DW_ACQ**
- Naming: uppercase with underscores, pattern = layer + data category + source + client format
  - Examples: `ACQ_CLIENT_PHARMACY_CLAIM_CVS`, `ACQ_EXTERNAL_MEDISPAN_AWP_PRICE`, `ACQ_INTERNAL_PAX_ENROLLMENT`

### History and Governance
- **Type-1 tables**: one ACQ record per source business key; or copy source-provided history as-is
- **Type-2 tables**: warehouse-managed historical versions; use `_HISTORY` suffix
- **Raw + Curated ACQ pattern**: raw table captures every file row as strings (including duplicates and file metadata); curated typed table retains selected active/master record
- **Traceability**: durable business key links duplicates and supports navigation from presentation back to raw record and source file
- Case-insensitive SQL collation; non-Unicode string types for performance

### Azure Storage Organization
- **Client**: Container by Company/Division; folders by Client, Source, Data Type
- **Multi-client file**: organized by sender/source (preserves original file integrity)
- **External reference**: folders by vendor

---

## Target Architecture (PillarRx 3.0)

The target is a modernized, AI-powered platform called **PillarRx 3.0** with these design principles:
- AI-powered
- Unified Member View
- Intelligent Decisioning
- Automated Workflows
- Scalable and Real-time

### Experience & Access Layer
1. **Care Team Portal (Web)**: 360-degree member view, work queue, recommended actions, case management
2. **Client / Partner Portal (future)**: reporting, file status, integration APIs, self-service
3. **External APIs**: PBMs/Clients, Manufacturers, Providers/Pharmacies

### Application & API Layer (ASP.NET Core / C#)
1. API Gateway & BFF
2. Member Service
3. Opportunity Service
4. Program Service
5. Rule Service
6. Workflow Orchestration
7. Case/Task & Outreach Service
8. Notification Service
9. Integration Service

### Data Sources & Integrations
| Source | Data |
|--------|------|
| PBMs / Clients | Claims, member, benefit data; plan data, formulary data |
| Manufacturers | Rebate programs, coupons |
| Pharmacies | Prescription data, dispensing data |
| Members | Demographics, eligibility, communications |
| External Data | 340B, ESI/coupons, drug information |

### AI-Driven Extraction/Ingestion (Databricks framework)
1. File/API detection
2. Schema inference
3. AI mapping (LLM)
4. Validation and quality
5. Mapping approval
6. Automated pipeline
7. Exception handling
- Goal: ingest new file types in hours/days (vs current manual process)

### Lakehouse Data Platform (Databricks)
| Layer | Name | Contents |
|-------|------|----------|
| **Bronze** | Raw / Ingested | Source files, raw claims and member data, immutable storage |
| **Silver** | Canonical | Normalized and cleansed, canonical pharmacy model, master data |
| **Gold** | Business Views | Member 360, Claim 360, benefit opportunities, analytics/reporting/ML features |

**Data & Analytics Services**: Delta Lake, Unity Catalog, ML/AI, SQL Analytics, Streaming

### Operational/Transaction DB
- **Lakebase PostgreSQL**: cases and tasks, workflow instances, rules and decisions, benefit opportunities, audit and logs, unified member view, pre-joined optimized data, near real-time updates

### Legacy (Phase-out)
- **Legacy MemberOps**: SQL Server DB, stored procedures, legacy UI
- **Legacy Integration Layer**: CDC/data sync, event bridge, capability routing

### Event & Messaging Layer
- **Azure Service Bus**: transactional messaging
- **Event Grid**: events and notifications

### AI & Decisioning Services
- Natural Language Rules (LLM + validation)
- Rules Engine (deterministic)
- Benefit Optimization (ML + heuristics)
- Decision Explainability (transparency and audit)
- GenAI Assistant (care team / member)

### Azure Platform Foundation
| Component | Technology |
|-----------|------------|
| Compute | AKS / App Service |
| Storage | ADLS Gen2 |
| Networking | VNet / Private Endpoints |
| Security | Entra ID, Key Vault, RBAC |
| Observability | App Insights, Log Analytics |
| DevOps | GitHub / Azure DevOps |

### Delivery Scope
All components within the target architecture dotted boundary are within **eNobleon's** delivery scope.

---

## Key Differences: Current vs Target

| Aspect | Current | Target |
|--------|---------|--------|
| Data platform | Azure SQL DB (PaaS) | Databricks Lakehouse (Bronze/Silver/Gold) |
| Transaction DB | SQL Server (multiple) | Lakebase PostgreSQL |
| ETL | Azure Data Factory + manual | AI-driven ingestion (Databricks + LLM) |
| BI/Reporting | Qlik Sense (SaaS) | SQL Analytics + built-in analytics |
| Application | Disparate apps (PAX, AccuCast, etc.) | Unified microservices (ASP.NET Core) |
| Portals | None/limited | Care Team Portal + Client Portal |
| AI/ML | None | Natural language rules, benefit optimization, GenAI assistant |
| Schema design | 4 DW schemas (acq/int/pres/lake) | Bronze/Silver/Gold medallion |
| Member view | Fragmented across apps | Unified Member 360 |
| New source onboarding | Manual HITL process | AI-assisted: hours/days |

---

## All Systems and Technologies Referenced

### Databases and Data Stores
- Azure SQL DB (PaaS) — `sqldb-dw-prd-eastus2-001`
- Azure SQL VM (IaaS) — AccucastDB
- SQL Server instances: SourceDataDB01, AccucastDB, MemberOps DB, TricastBenchmarksDB, TricastMaster DB
- Azure Blob Storage
- ADLS Gen2 (target)
- Databricks Lakehouse (target)
- Lakebase PostgreSQL (target)
- Qlik Data File (QDF) Container

### Applications
- PAX Web App (copay assistance)
- AccuCast (auditing platform)
- Insight (auditing web app)
- Pharmacast (auditing web app)
- MemberOps (member operations, legacy)
- PillarRx (overall platform name)

### ETL and Integration
- Azure Data Factory (ADF)
- Azure Service Bus (target)
- Event Grid (target)
- CDC / data sync (legacy integration)

### BI and Analytics
- Qlik Sense (SaaS)
- Databricks SQL Analytics (target)
- Delta Lake (target)
- Unity Catalog (target)

### External Data Vendors
- Wolters Kluwer Medi-Span
- First DataBank (fdb)
- NCPDP
- NPPES
- CMS.gov

### Cloud and Infrastructure
- Microsoft Azure (primary)
- AWS (some presence)
- AKS / App Service (target compute)
- Entra ID, Key Vault, RBAC (target security)
- VNet / Private Endpoints (target networking)
- App Insights, Log Analytics (target observability)
- GitHub / Azure DevOps (target DevOps)

### DW Schema Names
- `dw_acq` (Acquisition)
- `dw_int` (Integration)
- `dw_pres` (Presentation)
- `dw_lake` (Lake)
- `DW_ACQ` (single ACQ schema)

### Table Naming Examples
- `ACQ_CLIENT_PHARMACY_CLAIM_CVS`
- `ACQ_EXTERNAL_MEDISPAN_AWP_PRICE`
- `ACQ_INTERNAL_PAX_ENROLLMENT`

### Key Business Entities
- Company, Division, Client (multi-tenant hierarchy)
- Claims (Rx/pharmacy claims primary focus)
- Eligibility
- Enrollment
- Members (demographics, eligibility, communications)
- Benefit opportunities
- Programs (rebate, coupon)
- Cases/Tasks
- Rules/Decisions
- Workflows

### Vendors / Partners
- **eNobleon**: delivery scope for target architecture
- **PillarRx ETL Team**: current ETL operations team
