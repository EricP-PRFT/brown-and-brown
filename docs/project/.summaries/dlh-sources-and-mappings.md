# DLH Data Source Inventory & Pharmacy Claim Column Mappings

## Overview

The Data Lakehouse (DLH) ingests pharmacy claims and related data from multiple PBM (Pharmacy Benefit Manager) sources, external drug reference databases, and internal operational files. All data flows through a medallion architecture: files land in Azure Blob Storage, get ingested into ACQ (acquisition/bronze) tables, then transformed through to a canonical `PHARMACY_CLAIM_TRANSACTION` (PCT) table in the presentation/silver layer.

---

## Data Source Inventory (75 file ingestion entries)

### File Types Ingested

| Category | Description | Count |
|----------|-------------|-------|
| Rx Claims | Pharmacy claim files from PBMs | ~55 entries |
| Benefit | Client benefit/eligibility files | ~6 entries |
| Accumulator Response | Copay accumulator response files | 1 entry |
| MAC External | External drug reference data (FDB, Medispan, NCPDP, NPPES, NUCC) | 5 entries |
| MAC Internal | Internal operational files (account mgmt, client info, cross-references) | 6 entries |

### PBM Sources (Rx Claims)

| PBM Source Code | PBM Name | Clients Served | ACQ Table |
|-----------------|----------|----------------|-----------|
| CVS | CVS Caremark | Boston Children's Hospital, Franklin International, Getty Images, ModernaTX, Revvity, Weill Cornell Medicine, Waters Technologies, + multi-client | ACQ_CLIENT_PHARMACY_CLAIM_CVS_4000 |
| OPTUM | Optum Rx (CHF7 + BCKC formats) | ~20 clients including Advocate Aurora Health, Brown University, Columbia University, BJ's Wholesale, Rochester Institute of Technology, BCBS Kansas City, + more | ACQ_CLIENT_PHARMACY_CLAIM_OPTUM_CHF7, ACQ_CLIENT_PHARMACY_CLAIM_OPTUM_BCKC |
| NAV | Navitus | Best Home Furnishings, Centivo, Halifax Staffing, KY Rural Electric, Paulding Commissioners/Hospital, Rutland Regional MC, South Central Power, Saint Meinrad, TheraCare | ACQ_CLIENT_PHARMACY_CLAIM_NAVITUS |
| ESI | Express Scripts | Multi-client (ESI 2300 format), Highmark (ESI HMRK format) | ACQ_CLIENT_PHARMACY_CLAIM_ESI_2300, ACQ_CLIENT_PHARMACY_CLAIM_ESI_HMRK |
| EMPIRX | EmpiRx Health | Multi-client (standard + reject formats) | ACQ_CLIENT_PHARMACY_CLAIM_EMPIRX, ACQ_CLIENT_PHARMACY_CLAIM_EMPIRX_REJECT |
| BMICH | BCBS Michigan | BCBS Michigan (Meijer + Regular claims) | acq_client_pharmacy_claim_bmich |
| RIGHTWAY | Rightway Healthcare | EMD Millipore Corporation | ACQ_CLIENT_PHARMACY_CLAIM_RIGHTWAY |
| PRIME | Prime Therapeutics / Magellan | EverQuote, Inc. | ACQ_CLIENT_PHARMACY_CLAIM_PRIME_MAGELLAN |
| BCKC | BCBS Kansas City | BCBS Kansas City (Optum-sourced) | ACQ_CLIENT_PHARMACY_CLAIM_OPTUM_BCKC |

### External Drug Reference Sources

| Source | Provider | Purpose |
|--------|----------|---------|
| FIRSTDATABANK | First DataBank (FDB) | Drug pricing and reference data |
| MEDISPAN | Wolters Kluwer (Medispan) | Drug classification and pricing |
| NCPDP | NCPDP | Pharmacy standards data |
| NPPES | CMS NPPES | Provider NPI registry |
| NUCC | NUCC | Healthcare provider taxonomy |

### Internal Data Sources

| Source | Purpose |
|--------|---------|
| ACCTMGMT - Client Level Data History | Client-level operational data |
| ACCTMGMT - Client Benefit Group | Client benefit group definitions (Blob trigger) |
| ACCTMGMT - CAP Invoice Special Case | Copay assistance program special cases |
| MISC - CAP Invoice Schedule | Copay assistance program invoice schedules |
| MISC - Cross Reference List | Cross-reference lookups between systems |
| MISC - Client Info | Client dimension master data |

### Ingestion Infrastructure

- **Storage:** Azure Blob Storage containers (`pillarrx-copay`, `pillarrx-all`, `external`, `internal`)
- **FTP Sources:** ftp.pillarrx.com, webtransport.caremark.com, mft.optum.com, ftp.navitus.com, eft.express-scripts.com, sftp.rightwayhealthcare.com, mvt1.primetherapeutics.com, mft.hmhs.com, ftp.fdbhealth.com, sftp.na.wolterskluwer.com, dbfiles.ncpdp.org
- **Trigger Types:** Scheduled triggers (most), Blob triggers (some), Manual uploads (internal files)
- **File Formats:** .txt, .zip, .dat, .xlsx, XML (zipped+PGP encrypted), PGP encrypted .txt
- **ETL Naming Convention:** `Load_{Layer}_{Entity}_{Source}_{Division}_{Client}` (e.g., `Load_Pres_FactPharmacyClaim_CVS_4000_PRX_COPAY_MULTIPLE`)

---

## Pharmacy Claim Transaction (PCT) Column Mappings

### Target Table: PHARMACY_CLAIM_TRANSACTION

The PCT table is the canonical fact table for pharmacy claims. It has **~113 columns** that consolidate data from 17 different source formats (15 original PBMs + 2 newer BMASS formats for CVS and ESI).

### Source Format Variants (17 total)

| Format | ACQ Table | Raw Columns |
|--------|-----------|-------------|
| CVS 4000 | ACQ_CLIENT_PHARMACY_CLAIM_CVS_4000 | 185 |
| EMPIRX | ACQ_CLIENT_PHARMACY_CLAIM_EMPIRX | 52 |
| EMPIRX REJECT | ACQ_CLIENT_PHARMACY_CLAIM_EMPIRX_REJECT | 106 |
| BMICH | acq_client_pharmacy_claim_bmich | 85 |
| NAVITUS | ACQ_CLIENT_PHARMACY_CLAIM_NAVITUS | 187 |
| ESI HMRK | ACQ_CLIENT_PHARMACY_CLAIM_ESI_HMRK | 58 |
| ESI 2300 | ACQ_CLIENT_PHARMACY_CLAIM_ESI_2300 | 256 |
| ESI HEALTH PLAN | ACQ_CLIENT_PHARMACY_CLAIM_ESI_HEALTH_PLAN | — |
| OPTUM CHF7 | ACQ_CLIENT_PHARMACY_CLAIM_OPTUM_CHF7 | 165 |
| OPTUM BCKC | ACQ_CLIENT_PHARMACY_CLAIM_OPTUM_BCKC | 70 |
| RIGHTWAY | ACQ_CLIENT_PHARMACY_CLAIM_RIGHTWAY | 83 |
| PRIME MAGELLAN | ACQ_CLIENT_PHARMACY_CLAIM_PRIME_MAGELLAN | 83 |
| SERVE YOU | ACQ_CLIENT_PHARMACY_CLAIM_SERVE_YOU | — |
| CARELON | ACQ_CLIENT_PHARMACY_CLAIM_CARELON | — |
| CVS_BMASS | ACQ_CLIENT_PHARMACY_CLAIM_CVS_BMASS | — |
| ESI_BMASS | ACQ_CLIENT_PHARMACY_CLAIM_ESI_BMASS | — |
| CAP NAVITUS | ACQ_CLIENT_CAP_PHARMACY_CLAIM_NAVITUS_RAW | 36 |

Total unique raw column names across all formats: **891**

### PCT Column Categories

**Identity & Keys:**
- `PHARMACY_CLAIM_TRANSACTION_INTERNAL_ID` — surrogate key (passthrough from ACQ)
- `COMPANY_DIVISION_CLIENT_ID`, `COMPANY_CLIENT_ID`, `COMPANY_CODE`, `DIVISION_CODE`, `CLIENT_CODE` — organizational hierarchy
- `PHARMACY_CLAIM_NET_INTERNAL_ID`, `PHARMACY_CLAIM_FILL_INTERNAL_ID` — claim grouping keys

**Claim Identification:**
- `CLAIM_NUMBER` — source claim identifier (varies by PBM: transaction_id, claim_no, claim_id, rxclaim_number, etc.)
- `CLAIM_REFERENCE_NUMBER` — cross-reference/reversal claim ID (complex null-handling per source)
- `UNIQUE_CLAIM_NUMBER` — derived unique identifier (may combine claim number + status suffix)
- `UNIQUE_CLAIM_REFERENCE_NUMBER` — derived unique reference for reversals
- `RX_NUMBER` — prescription number (zero-padded to 12 digits, 'NOT PROVIDED' default)
- `REFILL_NUMBER` — refill count (coalesced to 0)
- `CLAIM_INTERNAL_STATUS_CODE` — internal claim status
- `CLAIM_INTERNAL_SORT_NUMBER` — ordering within claim groups

**Dates:**
- `FILL_DATE` — date of service/dispensing
- `SUBMIT_DATE` — adjudication/processing date
- `LEGACY_BENEFIT_MATCH_DATE` — populated by downstream stored procedure

**Member Demographics:**
- `CLAIM_MEMBER_EXTERNAL_ID` + `_LABEL_NAME` — member identifier (varies: cardholder_id, card_id, contract_number, etc.)
- `CLAIM_MEMBER_FIRST/MIDDLE/LAST_NAME` — patient name
- `CLAIM_MEMBER_GENDER_CODE` + `INTERNAL_GENDER_CODE` — raw + standardized gender (MALE/FEMALE/NOT PROVIDED/UNKNOWN)
- `CLAIM_MEMBER_BIRTH_DATE` — date of birth
- `CLAIM_MEMBER_PERSON_CODE` — person/dependent code
- `CLAIM_MEMBER_RELATIONSHIP_CODE` + `INTERNAL_RELATIONSHIP_CODE` — raw + standardized relationship (SUBSCRIBER/SPOUSE/CHILD/OTHER)
- `CLAIM_MEMBER_MEDICARE_MBI_ID` — Medicare beneficiary ID (mostly NOT PROVIDED)
- `CLAIM_MEMBER_ADDRESS_*` — address fields (1, 2, city, state, zip, zip+4)
- `CLAIM_MEMBER_PHONE_NUMBER` — phone (punctuation stripped)
- `CLAIM_MEMBER_CUSTOM_FIELD_*` — extensible fields (BMICH uses for MEME_CK)

**Subscriber (distinct from member/patient):**
- `CLAIM_SUBSCRIBER_EXTERNAL_ID` + `_LABEL_NAME` — subscriber identifier
- `CLAIM_SUBSCRIBER_FIRST/MIDDLE/LAST_NAME` — subscriber name (many sources provide NOT PROVIDED)

**Provider & Pharmacy:**
- `PHARMACY_NPI_ID` — pharmacy NPI
- `PRESCRIBING_PROVIDER_NPI_ID` — prescriber NPI
- `DRUG_NDC_ID` — National Drug Code (11-digit)

**Financial Amounts:**
- `TOTAL_COST_AMOUNT` — sum of plan + member + other payer (computed differently per source)
- `INGREDIENT_COST_AMOUNT` — drug ingredient cost (nulled for COPAY division when $0)
- `DISPENSING_FEE_AMOUNT` — pharmacy dispensing fee
- `PLAN_PAID_AMOUNT` — amount paid by plan/sponsor
- `MEMBER_REPORTED_PAID_AMOUNT` — total member responsibility
- `MEMBER_COPAY_AMOUNT` — copay portion (nulled for COPAY division)
- `MEMBER_COINSURANCE_AMOUNT` — coinsurance
- `MEMBER_DEDUCTIBLE_APPLIED/REMAINING_AMOUNT` — deductible amounts
- `MEMBER_OOP_APPLIED/REMAINING_AMOUNT` — out-of-pocket amounts
- `OTHER_PAYER_AMOUNT` — coordination of benefits / other payer

**Benefit Grouping:**
- `BENEFIT_GROUP_ID` — benefit group identifier (complex derivation varies by PBM: account_id-group_id concat, carrier/group lookups, etc.)
- `CLIENT_BENEFIT_GROUP_IK` — populated by downstream stored procedure
- `CLIENT_FISCAL_YEAR_BEGIN_MONTH_NUMBER` — from client level data history lookup
- `CLAIM_BENEFIT_ID` + `CLAIM_BENEFIT_FIELD_1-5` — extensible benefit metadata fields

**Copay Assistance Program (CAP) Fields:**
- `COPAY_ASSISTANCE_PROGRAM_DRUG_TYPE_CODE` — N/A for non-COPAY, UNKNOWN placeholder for COPAY (updated downstream)
- `COPAY_ASSISTANCE_PROGRAM_ALTERNATE_PROGRAM_CODE` — alternate program tracking
- `COPAY_ASSISTANCE_PROGRAM_DAILY_CLAIM_INCLUSION_*` — inclusion/exclusion flags (downstream proc)
- `COPAY_ASSISTANCE_PROGRAM_ACCUMULATOR_INCLUSION_*` — accumulator inclusion flags

**Claim Processing Flags:**
- `CLAIM_TRANSACTION_COUNT` — always 1
- `RX_COUNT` — derived: PAID=1, REVERSED=-1, ADJUSTED/REJECTED=0
- `CLAIM_INTERNAL_COMPLETE_REVERSAL_FLAG` — '?' placeholder, updated downstream
- `CLAIM_INTERNAL_ORPHANED_REVERSAL_FLAG` — '?' placeholder, updated downstream
- `PAID_PHARMACY_CLAIM_INCLUSION_INDICATOR` — UNKNOWN placeholder, updated downstream
- `PAID_PHARMACY_CLAIM_EXCLUSION_REASON_TEXT` — UNKNOWN placeholder, updated downstream

**Metadata (DW housekeeping):**
- `PBM_CODE` — standardized PBM identifier (via cross_reference_list_value lookup)
- `DW_SOURCE_TYPE_CODE`, `DW_SOURCE_NAME`, `DW_SOURCE_FORMAT_NAME`, `DW_SOURCE_FILE_NAME`, `DW_SOURCE_FILE_LINE_NUMBER`, `DW_SOURCE_TABLE_NAME` — lineage tracking
- `DW_RECORD_DELETE_INDICATOR`, `DW_RECORD_HASH` — change tracking
- `DW_RECORD_INSERT/UPDATE_TIMESTAMP` + `_UTC_TIMESTAMP` — audit timestamps
- `DW_RECORD_INSERT/UPDATE_ETL_PROCESS_RUN_ID` + `_STEP_RUN_ID` — ETL run tracking

### Key Transformation Patterns

1. **Null Handling:** Nearly all fields use `COALESCE(value, 'NOT PROVIDED')` as a standard null-replacement pattern
2. **Gender Standardization:** Raw codes (0/1/2 or M/F) mapped to MALE/FEMALE/NOT PROVIDED/UNKNOWN
3. **Relationship Standardization:** Raw codes mapped to SUBSCRIBER/SPOUSE/CHILD/OTHER/NOT PROVIDED/UNKNOWN
4. **Claim Status Derivation:** RX_COUNT derived from claim_internal_status_code (PAID=1, REVERSED=-1, ADJUSTED/REJECTED=0)
5. **Rx Number Padding:** Prescription numbers zero-padded to 12 digits across all sources
6. **Phone Cleanup:** Punctuation stripped, bogus numbers (all-zeros, all-ones, all-nines) replaced with NOT PROVIDED
7. **Zip Code Handling:** Left 5 digits extracted; '00000' treated as NOT PROVIDED; zip+4 formatted when available
8. **Downstream Post-Processing:** Several columns set to placeholder values during initial load, then updated by downstream stored procedures:
   - `MEMBER_ALIAS_IK` — member matching
   - `CLIENT_BENEFIT_GROUP_IK` — benefit group assignment
   - `UNIQUE_CLAIM_NUMBER` / `UNIQUE_CLAIM_REFERENCE_NUMBER` — for BMASS formats
   - `LEGACY_BENEFIT_MATCH_DATE` — benefit date matching
   - All inclusion indicators and exclusion reasons
   - Complete/orphaned reversal flags
9. **COPAY Division Logic:** Several financial columns (ingredient cost, copay) are nulled when the division is COPAY and the amount is $0
10. **Benefit Group Derivation:** Complex per-PBM logic using cross-reference list values to determine how to concatenate account_id, group_id, carrier_id, plan_code etc.
