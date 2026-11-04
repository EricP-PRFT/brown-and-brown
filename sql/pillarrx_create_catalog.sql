-- pillarrx_create_catalog.sql
-- Standalone DDL to recreate all pillarrx business schemas, tables, PKs, FKs,
-- and unique constraints from the v40 metamodel.
--
-- Generated from pillarrx._metamodel (version 40) with type corrections applied.
-- Includes manually-applied FK constraints the vibe agent cannot create.
--
-- Run on Databricks SQL against the pillarrx catalog.

-- =============================================================================
-- SECTION 1: CREATE SCHEMAS
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS pillarrx.claim;
CREATE SCHEMA IF NOT EXISTS pillarrx.client;
CREATE SCHEMA IF NOT EXISTS pillarrx.company;
CREATE SCHEMA IF NOT EXISTS pillarrx.division;
CREATE SCHEMA IF NOT EXISTS pillarrx.drug;
CREATE SCHEMA IF NOT EXISTS pillarrx.program;
CREATE SCHEMA IF NOT EXISTS pillarrx.reference;

-- =============================================================================
-- SECTION 2: CREATE TABLES
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Schema: claim
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS pillarrx.claim.adjustment (
  adjustment_date DATE COMMENT 'The calendar date on which the adjustment or reversal transaction was processed or submitted by the PBM. Principal business event date for financial reconciliation.',
  adjustment_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the pharmacy claim adjustment or reversal record in the Pillarrx lakehouse silver layer.',
  adjustment_original_rx_claim_id BIGINT COMMENT 'FK to claim.rx_claim.rx_claim_id — Adjustment/reversal references the original adjudicated claim it modifies; required for lifecycle audit trail.',
  adjustment_rx_claim_id BIGINT COMMENT 'Reference to the original pharmacy claim transaction that this adjustment, reversal, or rebill modifies. Core linkage to the parent claim fact.',
  adjustment_status STRING COMMENT 'Current lifecycle state of the adjustment transaction: pending (received, not yet applied), processed (applied to financials), rejected (denied by PBM), or voided (cancelled before processing).',
  adjustment_type STRING COMMENT 'Classifies the nature of the transaction: reversal (claim cancellation), rebill (resubmission after reversal), correction (financial correction), or general adjustment.',
  awp_adj DECIMAL(12,2) COMMENT 'The delta change to the AWP-based pricing component resulting from this adjustment. Used in AWP discount guarantee auditing and PBM contract reconciliation.',
  claim_benefit_group_id BIGINT COMMENT 'Foreign key linking to claim.claim_benefit_group. Business justification: Adjustments are processed under a specific benefit group context (same as the original claim).',
  company_client_id BIGINT COMMENT 'Foreign key linking to company.company_client. Business justification: Adjustments must be attributed to specific clients for accurate financial reconciliation, audit reporting, and consulting analysis of claim corrections.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM (e.g., CVS Caremark, Optum Rx, Express Scripts) that processed the original claim and submitted this adjustment transaction.',
  daw_code STRING COMMENT 'The DAW code from the original claim indicating brand/generic dispensing instruction (0=no product selection, 1=substitution not allowed by prescriber, 2=substitution by patient, etc.).',
  days_supply INT COMMENT 'The number of days of medication supply dispensed on the original claim. Retained on the adjustment for PMPM/PMPY trend analysis and days-supply-based pricing reconciliation.',
  deductible_adj DECIMAL(10,2) COMMENT 'The delta change to the deductible amount applied on the original claim resulting from this adjustment. Critical for accurate member deductible accumulator reconciliation.',
  dir_fee_adj DECIMAL(10,2) COMMENT 'The delta change to the DIR fee component applied via this adjustment. DIR fees are post-adjudication pharmacy clawbacks; tracking adjustments is essential for PBM audit and spread analysis.',
  dispensing_fee_adj DECIMAL(10,2) COMMENT 'The delta change to the pharmacy dispensing fee resulting from this adjustment. Used in PBM dispensing-fee guarantee auditing and contract reconciliation.',
  fill_number INT COMMENT 'The sequential fill number (refill count) of the original prescription being adjusted. Fill 0 = new prescription; Fill 1+ = refills. Used to identify which dispensing event is impacted.',
  ingested_timestamp TIMESTAMP COMMENT 'The date and time this adjustment record was first loaded into the Pillarrx lakehouse silver layer from the PBM claims feed. Used for data freshness monitoring and ETL audit.',
  ingredient_cost_adj DECIMAL(12,2) COMMENT 'The delta change to ingredient cost resulting from this adjustment. Negative for reversals; positive for upward corrections. Core financial component for PBM audit and benchmarking.',
  is_rebill BOOLEAN COMMENT 'Indicates whether this adjustment record represents a rebill (resubmission of a previously reversed claim with corrected data). True = rebill transaction following a reversal.',
  is_reversal BOOLEAN COMMENT 'Indicates whether this adjustment record represents a full claim reversal (cancellation) as opposed to a partial financial correction or rebill. True = full reversal.',
  member_coinsurance_adj DECIMAL(10,2) COMMENT 'The delta change to the member coinsurance (percentage cost-share) resulting from this adjustment. Supports member OOP reconciliation and benefit design analysis.',
  member_copay_adj DECIMAL(10,2) COMMENT 'The delta change to the member copay (fixed cost-share) resulting from this adjustment. Used for member out-of-pocket reconciliation and copay assistance program (CAP) impact analysis.',
  member_id BIGINT COMMENT 'Reference to the member (patient) associated with the adjusted claim. Supports Member 360 cross-PBM analytics and member-level financial reconciliation.',
  oop_adj DECIMAL(10,2) COMMENT 'The delta change to the member out-of-pocket (OOP) accumulator applied on the original claim. Used to reconcile member MOOP and TrOOP accumulators after adjustment.',
  original_dos DATE COMMENT 'The date of service (DOS) from the original pharmacy claim being adjusted. Retained on the adjustment record for period-accurate financial reporting and audit trail.',
  original_fill_date DATE COMMENT 'The dispensing date of the original prescription fill that is being adjusted or reversed. Used to attribute the financial impact to the correct dispensing period.',
  other_payer_adj DECIMAL(10,2) COMMENT 'The delta change to the other payer amount (e.g., SPAP, manufacturer copay card, secondary insurance) resulting from this adjustment. Supports coordination of benefits reconciliation.',
  pbm_adjustment_number STRING COMMENT 'The externally-assigned transaction number or reference code assigned by the PBM to uniquely identify this adjustment or reversal event within the PBM system.',
  pbm_assignment_id BIGINT COMMENT 'Foreign key linking to client.pbm_assignment. Business justification: Adjustments (reversals, rebills, DIR fees) are PBM-specific and must be reconciled against the employer''s PBM assignment contract terms.',
  pbm_claim_number STRING COMMENT 'The PBM-assigned claim number of the original adjudicated claim being adjusted or reversed. Used to trace the adjustment back to the source transaction in PBM systems.',
  pbm_division_id BIGINT COMMENT 'Foreign key linking to division.division. Business justification: Adjustments must be tracked at division level for accurate PBM guarantee calculations (AWP discount, dispensing fee, rebate guarantees) and division-specific financial reconciliation.',
  pbm_feed_batch_id BIGINT COMMENT 'Foreign key linking to claim.pbm_feed_batch. Business justification: Adjustments are ingested via PBM feed batches. Every adjustment should be traceable to its ingestion batch for audit and reconciliation.',
  pbm_response_code STRING COMMENT 'The response or disposition code returned by the PBM upon processing the adjustment transaction (e.g., approved, rejected with reason). Used for adjustment reconciliation and exception management.',
  pbm_response_message STRING COMMENT 'Free-text message returned by the PBM alongside the response code, providing additional context on the adjustment outcome (e.g., rejection reason narrative).',
  plan_paid_adj DECIMAL(12,2) COMMENT 'The delta change to the plan-paid amount resulting from this adjustment. Negative for reversals recovering plan funds; positive for underpayment corrections. Key for client financial reporting.',
  primary_rx_claim_id BIGINT COMMENT 'FK to claim.rx_claim.rx_claim_id — Adjustment/reversal records reference the original rx_claim; the lifecycle audit trail is meaningless without this parent FK.',
  quantity_dispensed DECIMAL(10,3) COMMENT 'The quantity of drug dispensed on the original claim being adjusted, expressed in the drug''s billing unit (e.g., tablets, mL). Retained for unit-cost recalculation during adjustment analysis.',
  reason_code STRING COMMENT 'Standardized code provided by the PBM indicating the reason for the adjustment or reversal (e.g., pricing correction, eligibility change, duplicate claim, DIR fee). [ENUM-REF-CANDIDATE: promote to reference product]',
  reason_description STRING COMMENT 'Human-readable description of the adjustment reason, either sourced from the PBM feed or mapped from the adjustment_reason_code during normalization.',
  rebate_adj DECIMAL(10,2) COMMENT 'The delta change to the manufacturer rebate amount associated with the original claim resulting from this adjustment. Used in rebate reconciliation and pass-through PBM contract auditing.',
  rx_number STRING COMMENT 'The pharmacy-assigned prescription number from the original fill being adjusted. Provides a human-readable cross-reference to the dispensing pharmacy''s dispensing record.',
  timestamp TIMESTAMP COMMENT 'Precise date and time the adjustment transaction was processed by the PBM system. Provides sub-day precision for sequencing multiple adjustments on the same claim.',
  to_rx_claim_id BIGINT COMMENT 'FK to claim.rx_claim.rx_claim_id — Adjustment/reversal records reference an original rx_claim; FK needed for lifecycle audit trail and DIR reconciliation.',
  total_cost_adj DECIMAL(12,2) COMMENT 'The net total dollar change across all financial components (ingredient cost + dispensing fee + other fees) resulting from this adjustment. Used for client-level financial impact reporting.',
  updated_timestamp TIMESTAMP COMMENT 'The date and time this adjustment record was last modified in the lakehouse (e.g., due to a reprocessing or correction of the normalized record). Supports audit trail and change tracking.',
  CONSTRAINT pk_adjustment PRIMARY KEY (adjustment_id)
)
COMMENT 'Adjustment and reversal transaction record that modifies or cancels a previously adjudicated pharmacy claim. Captures the original rx_claim reference, adjustment type (reversal, rebill, correction), adjustment reason code, adjustment date, the financial'
;

CREATE TABLE IF NOT EXISTS pillarrx.claim.claim_benefit_group (
  awp_discount_mail_pct DECIMAL(5,4) COMMENT 'Contracted AWP discount percentage applied to mail-order pharmacy claims under this benefit group. Typically higher than retail. Used in PBM mail-order discount guarantee auditing.',
  awp_discount_retail_pct DECIMAL(5,4) COMMENT 'Contracted AWP discount percentage applied to retail pharmacy claims under this benefit group. Expressed as a decimal (e.g., 0.1600 = 16% off AWP). Used in PBM discount guarantee auditing.',
  benefit_group_code STRING COMMENT 'The externally-known alphanumeric code identifying this benefit group as assigned by the PBM or employer plan. Used for claims routing and eligibility matching. Maps to RxGroup in claim transactions.',
  benefit_group_name STRING COMMENT 'Human-readable name of the benefit group as defined by the employer plan or PBM (e.g., ''Active Employees'', ''Retirees'', ''COBRA Members'').',
  benefit_group_status STRING COMMENT 'Current lifecycle state of the benefit group record indicating whether it is actively in use for claims adjudication and member eligibility assignment.',
  benefit_type STRING COMMENT 'Classification of the pharmacy benefit design by coverage type, distinguishing commercial employer plans from Medicare Part D, Medicaid, retiree, COBRA, or ACA exchange coverage.',
  cap_eligible BOOLEAN COMMENT 'Indicates whether members in this benefit group are eligible to participate in copay assistance programs (CAP) managed via the PAX application. Drives CAP enrollment eligibility logic.',
  claim_benefit_group_id BIGINT NOT NULL COMMENT 'Unique surrogate primary key for the benefit group master record defining the pharmacy benefit design applied to a cohort of members under a specific client plan.',
  client_benefit_group_id BIGINT COMMENT 'Identifier referencing the related client benefit group id for the claim benefit group record in the claim domain.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM (e.g., CVS Caremark, Optum Rx, Express Scripts) that administers this benefit group and from whose claims feed this group definition was sourced.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this benefit group record was first created in the PillarRx data platform. Used for audit trail and data lineage tracking in the lakehouse silver layer.',
  deductible_applies BOOLEAN COMMENT 'Indicates whether a pharmacy deductible must be satisfied before plan cost-sharing begins for members in this benefit group. Drives deductible accumulator logic in claims analysis.',
  division_benefit_group_id BIGINT COMMENT 'The raw benefit group identifier as received from the PBM claims feed prior to normalization. Preserved for audit traceability and PBM reconciliation against source data.',
  division_formulary_id BIGINT COMMENT 'Identifier of the formulary (covered drug list) associated with this benefit group as assigned by the PBM. Drives tier-based cost-sharing and drug coverage determinations.',
  effective_date DATE COMMENT 'The date on which this benefit group design becomes binding and applicable to enrolled members for pharmacy claims adjudication. Aligns with plan year start.',
  employer_id BIGINT COMMENT 'Reference to the employer client whose plan this benefit group belongs to, within the Company > Division > Client hierarchy.',
  family_deductible_amount DECIMAL(12,2) COMMENT 'Annual pharmacy deductible amount in USD that applies at the family/subscriber unit level before plan benefits apply. Relevant for dependent cost-sharing analysis.',
  family_oop_max_amount DECIMAL(12,2) COMMENT 'Annual maximum out-of-pocket amount in USD for the family/subscriber unit under this benefit group. Drives family-level cost-sharing accumulator analysis.',
  generic_mandatory BOOLEAN COMMENT 'Indicates whether members are subject to a brand penalty (DAW cost differential) when a generic equivalent is available. Drives Generic Dispensing Rate (GDR) and DAW code analysis.',
  individual_deductible_amount DECIMAL(12,2) COMMENT 'Annual pharmacy deductible amount in USD that an individual member must satisfy before plan benefits apply. Used in member out-of-pocket and affordability analysis.',
  individual_oop_max_amount DECIMAL(12,2) COMMENT 'Annual maximum out-of-pocket amount in USD for an individual member under this benefit group. Once reached, the plan covers 100% of eligible pharmacy costs. Key for MOOP analysis.',
  integrated_deductible BOOLEAN COMMENT 'Indicates whether the pharmacy deductible is integrated with the medical deductible (combined accumulator) or is a separate pharmacy-only deductible. Affects total cost of care analysis.',
  integrated_oop BOOLEAN COMMENT 'Indicates whether the pharmacy out-of-pocket maximum is integrated with the medical out-of-pocket maximum (combined MOOP) or is pharmacy-only. Critical for total cost of care (TCOC) reporting.',
  mail_order_allowed BOOLEAN COMMENT 'Indicates whether mail-order pharmacy dispensing is an eligible benefit channel under this benefit group. Drives channel-based cost-sharing and dispensing fee analysis.',
  mail_order_mandatory BOOLEAN COMMENT 'Indicates whether mail-order dispensing is mandatory for maintenance medications after a defined number of retail fills. Affects member cost-sharing and GDR reporting.',
  member_count INT COMMENT 'Number of members currently enrolled in this benefit group as of the most recent eligibility file. Used for Per Member Per Month (PMPM) and Per Member Per Year (PMPY) denominator calculations.',
  pass_through_pricing BOOLEAN COMMENT 'Indicates whether this benefit group operates under a pass-through (transparent) PBM pricing model where the plan pays actual drug cost plus a dispensing fee, with no spread retained by the PBM.',
  pbm_source_group_name STRING COMMENT 'The raw benefit group name as received from the PBM claims feed prior to normalization. Preserved for audit traceability and cross-PBM benchmarking.',
  plan_year_end_date DATE COMMENT 'The last day of the benefit plan year associated with this benefit group. Marks the boundary for annual deductible and out-of-pocket maximum accumulation periods.',
  plan_year_start_date DATE COMMENT 'The first day of the benefit plan year associated with this benefit group. Drives deductible and out-of-pocket accumulator resets for member cost-sharing calculations.',
  prior_auth_required BOOLEAN COMMENT 'Indicates whether prior authorization (PA) is required for any drug classes under this benefit group. Flags benefit groups for PA utilization management analysis.',
  quantity_limit_applied BOOLEAN COMMENT 'Indicates whether quantity limits (QL) are enforced on covered drugs under this benefit group. Drives utilization management and quantity limit exception analysis.',
  rds_eligible BOOLEAN COMMENT 'Indicates whether this benefit group qualifies for the CMS Retiree Drug Subsidy (RDS) program, applicable to employer-sponsored retiree pharmacy benefits.',
  rebate_passthrough_pct DECIMAL(5,4) COMMENT 'Contractual percentage of manufacturer rebates passed through to the employer plan under this benefit group. Expressed as a decimal (e.g., 1.0000 = 100%). Used in PBM rebate guarantee auditing.',
  rx_bin STRING COMMENT 'Six-digit Bank Identification Number used to route pharmacy claims to the correct PBM processor. Printed on member ID cards and transmitted in NCPDP claim transactions.',
  rx_group STRING COMMENT 'The RxGroup identifier transmitted on pharmacy claim transactions for routing and adjudication by the PBM. Directly corresponds to the Group ID field in NCPDP claim transactions.',
  rx_pcn STRING COMMENT 'Processor Control Number used alongside RxBIN to route pharmacy claims to the correct PBM sub-processor or plan. Transmitted in NCPDP claim transactions and printed on member ID cards.',
  specialty_benefit_type STRING COMMENT 'Indicates how specialty medications are covered under this benefit group — included in standard formulary, excluded, or administered under a separate specialty benefit carve-out.',
  step_therapy_required BOOLEAN COMMENT 'Indicates whether step therapy (ST) protocols are enforced under this benefit group, requiring members to try lower-cost alternatives before coverage of preferred agents.',
  termination_date DATE COMMENT 'The date on which this benefit group design ceases to be binding. Null for open-ended active groups. Used for Type-2 SCD history tracking in the lakehouse.',
  three_forty_b_eligible BOOLEAN COMMENT 'Indicates whether claims under this benefit group may be subject to 340B federal drug discount pricing. Relevant for covered entity clients and manufacturer program analysis.',
  tier_count INT COMMENT 'Number of formulary cost-sharing tiers defined in this benefit group (e.g., 3 for generic/preferred brand/non-preferred, 4 for specialty tier). Drives tier-level copay analysis.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this benefit group record was last modified in the PillarRx data platform. Used for change detection, incremental ETL processing, and audit trail maintenance.',
  CONSTRAINT pk_claim_benefit_group PRIMARY KEY (claim_benefit_group_id)
)
COMMENT 'Benefit group (BG) master record defining the pharmacy benefit design applied to a cohort of members under a specific client plan. Primary key is benefit_group_id.'
;

CREATE TABLE IF NOT EXISTS pillarrx.claim.claim_pbm (
  awp_discount_brand DECIMAL(5,2) COMMENT 'Contracted AWP discount percentage applied to brand-name drug ingredient cost reimbursement for this PBM. Used as the baseline for PBM contract guarantee reconciliation and audit.',
  awp_discount_generic DECIMAL(5,2) COMMENT 'Contracted AWP discount percentage applied to generic drug ingredient cost reimbursement for this PBM. Used alongside MAC pricing in generic effective rate benchmarking and audit.',
  bin_number STRING COMMENT 'Six-digit Bank Identification Number (BIN) used to route pharmacy claims to the correct PBM processor at the point of sale. Required for claim adjudication routing validation and audit.',
  claim_pbm_id BIGINT NOT NULL COMMENT 'Unique surrogate primary key for the PBM master record in the Pillarrx lakehouse. Assigned by the Enterprise Data Warehouse upon ingestion.',
  claims_feed_format STRING COMMENT 'Technical format of the claims data feed delivered by this PBM to Pillarrx. Drives ETL pipeline selection and normalization logic in the PBM Claims Feed Ingestion Platform.',
  claims_feed_frequency STRING COMMENT 'Frequency at which the PBM delivers claims data files to Pillarrx. Determines SLA expectations for data freshness and drives scheduling of ETL ingestion jobs.',
  claims_feed_lag_days INT COMMENT 'Expected number of calendar days between the pharmacy claim date of service (DOS) and the date the claim appears in the Pillarrx data feed. Used to set data completeness expectations in reporting.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the PBM master record was first created in the Pillarrx Enterprise Data Warehouse. Supports audit trail, data lineage, and record lifecycle governance.',
  data_use_agreement_date DATE COMMENT 'Date on which the Data Use Agreement (DUA) or Business Associate Agreement (BAA) between Pillarrx and the PBM became effective. Required for HIPAA compliance and PHI data access governance.',
  data_use_agreement_expiry DATE COMMENT 'Date on which the Data Use Agreement (DUA) or Business Associate Agreement (BAA) with the PBM expires. Triggers renewal workflow to maintain uninterrupted HIPAA-compliant data access.',
  dir_reporting_supported BOOLEAN COMMENT 'Indicates whether the PBM provides Direct and Indirect Remuneration (DIR) fee data in its claims feed or as a separate reconciliation file. Critical for true net cost analysis and CMS compliance.',
  dispensing_fee_mail DECIMAL(8,2) COMMENT 'Contracted dispensing fee amount (in USD) paid to mail-order pharmacies by this PBM. Used in mail-order cost benchmarking and dispensing fee guarantee reconciliation.',
  dispensing_fee_retail DECIMAL(8,2) COMMENT 'Contracted dispensing fee amount (in USD) paid to retail network pharmacies by this PBM. Used as the benchmark value in dispensing fee guarantee reconciliation and PBM audit.',
  formulary_model STRING COMMENT 'Type of formulary structure offered by the PBM. Closed formularies restrict coverage to listed drugs; open formularies cover most drugs with varying cost-sharing. Affects drug tier analysis.',
  headquarters_state STRING COMMENT 'Two-letter US state code for the PBM headquarters location. Used for state PBM licensure compliance tracking and regulatory jurisdiction determination.',
  mac_list_name STRING COMMENT 'Name or identifier of the Maximum Allowable Cost (MAC) pricing list used by this PBM for generic drug reimbursement. Used in MAC pricing audit and generic effective rate benchmarking.',
  mail_order_supported BOOLEAN COMMENT 'Indicates whether the PBM supports mail-order pharmacy dispensing. Used to segment retail vs. mail-order claim volumes in trend analysis and benchmarking reports.',
  notes STRING COMMENT 'Free-text field for Pillarrx data operations and consulting staff to record known data quirks, feed anomalies, contractual nuances, or onboarding notes specific to this PBM.',
  npi STRING COMMENT 'Ten-digit National Provider Identifier (NPI) assigned to the PBM as a covered entity or business associate under HIPAA. Used in claim transaction validation and provider cross-reference.',
  onboarding_date DATE COMMENT 'Date on which the PBM was formally onboarded into the Pillarrx platform and began delivering claims data. Marks the start of the operational data relationship and feed history.',
  parent_company_name STRING COMMENT 'Name of the parent corporation that owns or controls the PBM (e.g., CVS Health for CVS Caremark, UnitedHealth Group for Optum Rx). Used in ownership conflict analysis and contract governance.',
  pbm_code STRING COMMENT 'Short, normalized internal code uniquely identifying the PBM (e.g., CVS_CAREMARK, OPTUM_RX, ESI, NAVITUS). Used as the stable business key across all claim feeds and reporting.',
  pbm_name STRING COMMENT 'Full legal or trade name of the PBM organization (e.g., CVS Caremark, Optum Rx, Express Scripts, Navitus Health Solutions). Used in client-facing reports and consulting deliverables.',
  pbm_status STRING COMMENT 'Current lifecycle status of the PBM record within Pillarrx. Controls whether new claim feeds are accepted and whether the PBM appears in active client reporting.',
  pbm_type STRING COMMENT 'Categorical classification of the PBM by market segment and ownership model. Drives benchmarking peer grouping and audit methodology selection in consulting engagements.',
  pcn STRING COMMENT 'Processor Control Number (PCN) used in conjunction with BIN to route pharmacy claims to the correct PBM sub-processor or benefit plan. Supports claim routing validation during PBM audits.',
  pricing_model STRING COMMENT 'Contractual pricing transparency model under which the PBM operates for Pillarrx clients. Pass-through means pharmacy reimbursement equals plan cost; spread means PBM retains the difference.',
  primary_contact_email STRING COMMENT 'Email address of the primary PBM account manager or relationship contact. Used for operational communications, data feed issue escalation, and contract correspondence.',
  primary_contact_name STRING COMMENT 'Full name of the primary account manager or relationship contact at the PBM. Used by Pillarrx consulting staff for escalation, data issue resolution, and contract negotiation.',
  primary_contact_phone STRING COMMENT 'Phone number of the primary PBM account manager or relationship contact. Used for urgent escalation of data feed failures, claim discrepancies, and audit inquiries.',
  rebate_file_supported BOOLEAN COMMENT 'Indicates whether the PBM delivers a separate manufacturer rebate reconciliation file to Pillarrx. When True, rebate data is available for guarantee reconciliation and DIR analysis.',
  rebate_model STRING COMMENT 'Describes how manufacturer rebates are handled by the PBM. Pass-through means rebates flow fully to the plan; retained means the PBM keeps a portion. Critical for DIR and rebate audit analysis.',
  rx_group STRING COMMENT 'Default or primary RxGroup identifier associated with this PBM. Identifies the pharmacy benefit group used for claim adjudication routing. May be overridden at the client benefit plan level.',
  sftp_directory_path STRING COMMENT 'Remote directory path on the PBM SFTP server where claims data files are deposited for Pillarrx ingestion. Used by the ETL pipeline to locate and retrieve incoming claim files.',
  sftp_host STRING COMMENT 'Hostname or IP address of the SFTP server used by the PBM to deliver claims data files to Pillarrx. Confidential infrastructure detail used by the ETL ingestion platform.',
  short_name STRING COMMENT 'Abbreviated display name for the PBM used in dashboards, trend reports, and benchmarking outputs where space is constrained (e.g., Caremark, OptumRx, ESI).',
  specialty_pharmacy_network BOOLEAN COMMENT 'Indicates whether the PBM operates a specialty pharmacy network or limited distribution drug (LDD) channel. True when specialty claims are routed through a dedicated specialty network.',
  supports_adjustments BOOLEAN COMMENT 'Indicates whether the PBM includes claim adjustment transactions in its data feed. True when adjustment records are provided; False when adjustments are delivered as net replacements.',
  supports_reversals BOOLEAN COMMENT 'Indicates whether the PBM includes claim reversal transactions in its data feed. True when reversal records are provided; False when reversals must be inferred from net claim activity.',
  tax_identification_number STRING COMMENT 'Federal Employer Identification Number (EIN) / Tax ID for the PBM entity. Used in financial reconciliation, 1099 reporting, and contract governance under SOX and Brown & Brown finance controls.',
  termination_date DATE COMMENT 'Date on which the PBM relationship with Pillarrx was terminated or the data feed was permanently discontinued. Null for active PBMs. Used in historical reporting and data retention governance.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when the PBM master record was most recently modified in the Pillarrx Enterprise Data Warehouse. Used for change detection, ETL delta processing, and audit trail maintenance.',
  CONSTRAINT pk_claim_pbm PRIMARY KEY (claim_pbm_id)
)
COMMENT 'Pharmacy Benefit Manager (PBM) master record representing each PBM from which PillarRx ingests claims data (CVS Caremark, Optum Rx, Express Scripts, Navitus, EmpiRx Health, BCBS Michigan, Rightway, Prime Therapeutics, ServeYou, Carelon).'
;

CREATE TABLE IF NOT EXISTS pillarrx.claim.claim_prescriber (
  claim_prescriber_id BIGINT NOT NULL COMMENT 'Unique surrogate primary key for the prescriber record in the Pillarrx claims domain lakehouse silver layer.',
  claim_prescriber_status STRING COMMENT 'Current lifecycle status of the prescriber record as maintained in the Pillarrx prescriber master. Drives claim validation rules and prescriber-level reporting eligibility.',
  claim_prescriber_type STRING COMMENT 'Categorical classification of the prescribing provider type used for PBM audit and benchmarking segmentation. Derived from NPPES taxonomy and normalized across PBM feeds.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this prescriber record was first created in the Pillarrx lakehouse silver layer. Used for data lineage, audit trail, and ingestion monitoring.',
  credential_suffix STRING COMMENT 'Professional credential suffix (e.g., MD, DO, NP, PA, PharmD) as sourced from NPPES. Indicates prescriber licensure type for specialty and audit analysis.',
  dea_number STRING COMMENT 'DEA registration number authorizing the prescriber to prescribe controlled substances. Required for Schedule II-V drug claim validation and controlled substance audit workflows.',
  dea_schedule_authority STRING COMMENT 'Highest DEA controlled substance schedule the prescriber is authorized to prescribe (II through V). Used for controlled substance claim validation and DUR audit workflows.',
  effective_date DATE COMMENT 'Date from which this prescriber record version is considered valid. Supports Type-2 slowly changing dimension (SCD) history tracking for the prescriber master in the lakehouse silver layer.',
  entity_type STRING COMMENT 'NPPES NPI entity type code: individual (Type 1 NPI for a person) or organization (Type 2 NPI for a group practice or facility). Drives prescriber analytics segmentation.',
  enumeration_date DATE COMMENT 'Date the NPI was assigned to the prescriber by NPPES. Used for prescriber tenure analysis and to validate NPI currency in PBM claim audit workflows.',
  expiration_date DATE COMMENT 'Date on which this prescriber record version expires and is superseded by a newer version. Null for the current active record. Supports Type-2 SCD history in the lakehouse silver layer.',
  fax STRING COMMENT 'Fax number for the prescribers practice location as sourced from NPPES. Used for prior authorization and electronic prescription routing in PBM workflows.',
  first_name STRING COMMENT 'Legal first (given) name of the prescribing provider as sourced from NPPES or PBM claim feed. Used for display, reporting, and prescriber-level analytics.',
  gender STRING COMMENT 'Gender of the prescribing provider as sourced from NPPES (M=Male, F=Female, U=Unknown). Used for demographic analysis and NPPES record matching.',
  group_practice_pac_number STRING COMMENT 'CMS Provider Associate-level Identifier (PAC ID) for the group practice or organization the prescriber is affiliated with, as sourced from NPPES or CMS data. Supports group-level prescribing analytics.',
  is_340b_prescriber BOOLEAN COMMENT 'Flag indicating whether the prescriber is associated with a HRSA 340B covered entity. Used to identify 340B-eligible claims for manufacturer program management and audit.',
  is_controlled_substance_authorized BOOLEAN COMMENT 'Flag indicating whether the prescriber holds an active DEA registration authorizing controlled substance prescribing. Used in DUR and PBM audit claim validation.',
  is_current BOOLEAN COMMENT 'Boolean flag indicating whether this row is the current active version of the prescriber record. True for the latest version; False for historical SCD Type-2 rows. Simplifies current-record queries.',
  is_erx_enabled BOOLEAN COMMENT 'Flag indicating whether the prescriber is enrolled and active for electronic prescribing (ERx). Used for e-prescribing adoption analysis and PBM workflow routing.',
  is_specialty_prescriber BOOLEAN COMMENT 'Flag indicating whether the prescriber is classified as a specialty prescriber based on their NUCC taxonomy code. Used to segment specialty drug spend and specialty pharmacy routing analysis.',
  last_name STRING COMMENT 'Legal last (family) name of the prescribing provider as sourced from NPPES or PBM claim feed. Used for display, reporting, and prescriber-level analytics.',
  license_state STRING COMMENT 'Two-letter US state code for the jurisdiction that issued the prescribers license. Used for state-level regulatory compliance and geographic prescribing analysis.',
  middle_name STRING COMMENT 'Middle name or initial of the prescribing provider as sourced from NPPES. Supports full-name matching and identity resolution across PBM feeds.',
  name_prefix STRING COMMENT 'Honorific or professional prefix (e.g., Dr.) for the prescribing provider as sourced from NPPES. Used in member-facing and client-facing reporting displays.',
  npi STRING COMMENT '10-digit National Provider Identifier assigned by CMS via NPPES. Primary business key for the prescriber across all PBM claim feeds and the authoritative cross-source join key.',
  npi_deactivation_date DATE COMMENT 'Date the NPI was deactivated in NPPES, if applicable. Null for active prescribers. Used to flag claims submitted under deactivated NPIs during PBM audit.',
  npi_reactivation_date DATE COMMENT 'Date the NPI was reactivated in NPPES after a prior deactivation. Null if never deactivated or not yet reactivated. Supports NPI lifecycle tracking in audit workflows.',
  nppes_last_update_date DATE COMMENT 'Date the prescribers NPPES record was last updated in the source NPPES registry. Used to assess data currency and trigger refresh cycles in the prescriber master.',
  organization_name STRING COMMENT 'Name of the practice group, hospital system, or organization the prescriber is affiliated with as sourced from NPPES. Used for group-level prescribing trend and network analysis.',
  pbm_prescriber_identifier STRING COMMENT 'Prescriber identifier as assigned by the source PBM in the claim feed (may differ from NPI). Used for cross-PBM normalization and identity resolution in the Pillarrx claims aggregation pipeline.',
  phone STRING COMMENT 'Primary phone number for the prescribers practice location as sourced from NPPES. Used for prior authorization outreach and prescriber contact in consulting workflows.',
  practice_address_line1 STRING COMMENT 'Primary street address line of the prescribers practice location as sourced from NPPES. Used for geographic analysis, specialty pharmacy routing, and client reporting.',
  practice_address_line2 STRING COMMENT 'Secondary street address line (suite, floor, unit) of the prescribers practice location as sourced from NPPES. Supplements primary address for mail and geographic analysis.',
  practice_city STRING COMMENT 'City of the prescribers primary practice location as sourced from NPPES. Used for geographic prescribing trend analysis and client-level benchmarking reports.',
  practice_state STRING COMMENT 'Two-letter US state code of the prescribers primary practice location. Used for state-level prescribing analysis, regulatory compliance, and geographic benchmarking.',
  practice_zip STRING COMMENT '5-digit or ZIP+4 postal code of the prescribers primary practice location. Used for geographic prescribing trend analysis and regional benchmarking.',
  record_source STRING COMMENT 'Identifies the authoritative source system from which this prescriber record was ingested or created (NPPES, PBM feed, manual entry, or MDM golden record). Supports data lineage and audit.',
  secondary_specialty_code STRING COMMENT 'Secondary NUCC taxonomy code for the prescriber when a second specialty is registered in NPPES. Supports multi-specialty prescriber segmentation in consulting analytics.',
  source_pbm STRING COMMENT 'Name of the PBM from which this prescriber record was first sourced or most recently updated. Used for data lineage tracking and cross-PBM prescriber identity resolution.',
  specialty_code STRING COMMENT 'Primary taxonomy or specialty code for the prescriber as sourced from NPPES or PBM claim feed (e.g., NUCC Health Care Provider Taxonomy Code). Used for specialty drug and formulary analysis.',
  specialty_description STRING COMMENT 'Human-readable description of the prescribers primary specialty (e.g., Internal Medicine, Oncology, Psychiatry). Sourced from NUCC taxonomy or PBM feed normalization.',
  state_license_number STRING COMMENT 'State-issued prescriber license number as sourced from NPPES or PBM claim feed. Used for state-level compliance validation and controlled substance audit workflows.',
  telehealth_indicator BOOLEAN COMMENT 'Flag indicating whether the prescriber primarily operates via telehealth channels. Used for telehealth prescribing trend analysis and PBM audit of telehealth-originated claims.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this prescriber record was last modified in the Pillarrx lakehouse silver layer. Used for change tracking, SCD Type-2 versioning, and data quality monitoring.',
  CONSTRAINT pk_claim_prescriber PRIMARY KEY (claim_prescriber_id)
)
COMMENT 'Prescribing provider master record keyed by NPI (National Provider Identifier) as sourced from NPPES and PBM claims feeds. Primary key is prescriber_id. Captures the prescriber''s NPI, DEA number, name (first, last), specialty code and description'
;

CREATE TABLE IF NOT EXISTS pillarrx.claim.cob (
  benefit_plan_id BIGINT COMMENT 'Foreign key linking to client.benefit_plan. Business justification: Coordination of benefits (COB) records track other payer coverage for members. Linking to benefit_plan enables accurate accumulator reconciliation, TROOP calculation for Medicare Part D',
  cap_applied_flag BOOLEAN COMMENT 'Indicates whether this COB segment represents a manufacturer copay assistance program (CAP) payment such as a copay card or coupon. Enables PAX application tracking and CAP program analytics.',
  cob_id BIGINT NOT NULL COMMENT 'Unique surrogate primary key for the coordination-of-benefits segment record. One row per other-payer occurrence on a pharmacy claim.',
  cob_status STRING COMMENT 'Processing status of this COB segment. Indicates whether the other-payer amount was successfully applied, rejected by the adjudicator, pending resolution, or reversed.',
  company_client_id BIGINT COMMENT 'Foreign key linking to company.company_client. Business justification: COB records must be attributed to clients for coordination of benefits analysis, other payer recovery audits, and CAP program coordination reporting. New FK needed.',
  coordination_period_end_date DATE COMMENT 'End date of the benefit period during which the other payer''s coverage is active and coordinating. Null if the other payer coverage is open-ended or ongoing.',
  coordination_period_start_date DATE COMMENT 'Start date of the benefit period during which the other payer''s coverage is active and coordinating. Used to validate COB eligibility and benefit year alignment.',
  ingestion_timestamp TIMESTAMP COMMENT 'Timestamp when this COB segment record was first loaded into the lakehouse Silver layer from the PBM claims feed. Supports data freshness monitoring and ETL audit.',
  other_payer_amount_qualifier STRING COMMENT 'NCPDP qualifier indicating what the other_payer_paid_amt represents. Values: 01=Ingredient Cost, 02=Dispensing Fee, 03=Total, 04=Copay, 05=Coinsurance, 06=Deductible.',
  other_payer_bin STRING COMMENT 'Six-digit Bank Identification Number (BIN/RxBIN) of the other payer used for pharmacy claim routing. Enables identification of the other payer''s adjudication network.',
  other_payer_coinsurance_amt DECIMAL(12,2) COMMENT 'Percentage-based coinsurance amount assessed by the other payer for this claim. Supports granular COB cost-sharing analysis separate from copay and deductible.',
  other_payer_company_pbm_id BIGINT COMMENT 'Identifier of the other payer (e.g., secondary insurer, SPAP, Medicare, Medicaid, manufacturer copay card). Interpreted in conjunction with other_payer_id_qualifier.',
  other_payer_copay_amt DECIMAL(12,2) COMMENT 'Fixed copay amount assessed by the other payer for this claim. Distinguishes the copay component of patient responsibility from coinsurance and deductible for COB analytics.',
  other_payer_coverage_type STRING COMMENT 'Type of coverage provided by the other payer. Distinguishes pharmacy-specific COB from medical or other benefit coordination, relevant for total cost of care analysis.',
  other_payer_date DATE COMMENT 'Date on which the other payer adjudicated or processed this claim. Used to sequence COB events and validate that the other payer processed the claim before the primary plan.',
  other_payer_deductible_amt DECIMAL(12,2) COMMENT 'Deductible amount applied by the other payer toward this claim. Used to determine how much of the patient responsibility is attributable to the other payer''s deductible accumulator.',
  other_payer_group STRING COMMENT 'Benefit group identifier (RxGroup) associated with the other payer''s plan. Used to identify the specific benefit design under the secondary or tertiary payer.',
  other_payer_id_qualifier STRING COMMENT 'Qualifier code indicating the type of identifier in other_payer_id. NCPDP values: 01=BIN, 02=NPI, 03=NCPDP, 04=Medicare, 99=Other. Required to correctly interpret the payer ID.',
  other_payer_name STRING COMMENT 'Human-readable name of the other payer (e.g., ''Medicare Part D'', ''Aetna'', ''Pfizer Copay Card''). Sourced from the PBM claims feed or enriched from payer reference data.',
  other_payer_paid_amt DECIMAL(12,2) COMMENT 'Dollar amount paid by the other payer toward this claim. Used in COB calculations to determine residual member liability and plan liability after all payers have contributed.',
  other_payer_patient_responsibility_amt DECIMAL(12,2) COMMENT 'Amount the other payer determined to be the patient''s responsibility (copay, coinsurance, deductible) under that payer''s benefit design. Feeds into primary plan COB adjudication.',
  other_payer_pcn STRING COMMENT 'Processor Control Number (RxPCN) of the other payer, used alongside BIN to route claims to the correct adjudication processor for the secondary or tertiary payer.',
  other_payer_type STRING COMMENT 'Classification of the other payer. Supports COB analytics and CAP program identification. [ENUM-REF-CANDIDATE: commercial|medicare|medicaid|spap|manufacturer_cap|tricare|other — promote to reference product]',
  payer_sequence STRING COMMENT 'Indicates the coordination order of this other payer relative to the primary plan: primary, secondary, or tertiary. Drives COB logic and member liability calculation.',
  pbm_claim_number STRING COMMENT 'The PBM-assigned claim reference number from the source adjudication system. Used to correlate the COB segment back to the raw PBM claims feed for audit and reconciliation.',
  pbm_division_id BIGINT COMMENT 'Foreign key linking to division.division. Business justification: COB records needed at division level for accurate accumulator tracking and PBM guarantee measurement when coordination of benefits rules vary by division.',
  reject_code STRING COMMENT 'NCPDP reject code returned when the COB segment was not accepted during adjudication. Used for claims audit and PBM performance analysis when COB coordination fails.',
  reject_description STRING COMMENT 'Human-readable description of the reject code for the COB segment. Supports claims audit workflows and PBM consulting deliverables when investigating COB adjudication failures.',
  rx_claim_id BIGINT COMMENT 'Foreign key to the parent pharmacy claim (rx_claim) to which this COB segment belongs. Links the other-payer record to its adjudicated fill transaction.',
  source_file_name STRING COMMENT 'Name of the raw PBM claims file from which this COB segment was extracted. Enables data lineage tracing back to the original ingestion artifact for audit and reconciliation.',
  troop_excluded_flag BOOLEAN COMMENT 'Indicates whether the other payer amount is excluded from the member''s True Out-of-Pocket (TrOOP) accumulator under Medicare Part D rules. Critical for 340B and manufacturer CAP compliance.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp of the most recent update to this COB segment record in the lakehouse. Tracks adjustments, reversals, or corrections applied after initial ingestion.',
  CONSTRAINT pk_cob PRIMARY KEY (cob_id)
)
COMMENT 'Coordination-of-benefits / other-payer segment for a pharmacy claim, capturing each other-payer amount, payer sequence (primary/secondary/tertiary), other payer ID and qualifier, other payer paid amount, other payer patient responsibility, and the'
;

CREATE TABLE IF NOT EXISTS pillarrx.claim.dur_event (
  adjudication_timestamp TIMESTAMP COMMENT 'Date and time the pharmacy claim was adjudicated by the PBM and this DUR event was generated. Represents the principal real-world event time for this record.',
  alert_category STRING COMMENT 'Broad clinical category of the DUR alert for analytics grouping (e.g., drug_interaction, duplicate_therapy, dosing, allergy, age_precaution, pregnancy, renal, hepatic).',
  alert_sequence_number INT COMMENT 'Sequential number identifying the order of this DUR alert within the claim adjudication transaction when multiple DUR events are generated for a single claim.',
  alert_status STRING COMMENT 'Current disposition of the DUR alert: triggered (alert fired, no action yet), overridden (pharmacist bypassed), resolved (clinical action taken), or not_filled (prescription rejected).',
  claim_prescriber_id BIGINT COMMENT 'Foreign key linking to claim.prescriber. Business justification: DUR events are triggered by prescriber actions at the point of adjudication. Currently dur_event has prescriber_npi as a string; adding prescriber_id FK allows joining to the full prescriber',
  clinical_significance_code STRING COMMENT 'Numeric code from the drug reference source (Medi-Span or FDB) indicating the clinical significance of the interaction or alert (1=most significant to 5=least significant).',
  coagent_id_qualifier STRING COMMENT 'Qualifier indicating the coding system used for the co-agent drug identifier (e.g., ND=NDC, UP=UPC, GC=GPI Code, HC=HCPCS). Identifies the type of the interacting drug.',
  coagent_ndc_code STRING COMMENT '11-digit NDC of the co-agent (interacting or duplicate) drug when the DUR service reason involves a second drug. Normalized from coagent_id when qualifier is ND.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM that adjudicated the claim and generated this DUR event (e.g., CVS Caremark, Optum Rx, Express Scripts).',
  days_supply INT COMMENT 'Number of days of drug therapy supplied on the claim that triggered this DUR event. Relevant for duplicate therapy and refill-too-soon DUR alerts.',
  dos DATE COMMENT 'Date the prescription was dispensed (date of service) for the claim that generated this DUR event. Used for temporal DUR trend analysis.',
  drug_name STRING COMMENT 'Brand or generic name of the dispensed drug that triggered the DUR event. Denormalized from drug reference for reporting convenience.',
  drug_reference_source STRING COMMENT 'The drug reference database used by the PBM to generate this DUR alert (e.g., medi_span=Wolters Kluwer Medi-Span, fdb=First DataBank, pbm_proprietary=PBM internal rules).',
  dur_event_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for each Drug Utilization Review (DUR) event record generated at the point of pharmacy claim adjudication.',
  dur_rx_claim_id BIGINT COMMENT 'Reference to the parent pharmacy claim transaction that triggered this DUR event. Links the DUR event to its originating fill, reversal, or adjustment.',
  employer_id BIGINT COMMENT 'Reference to the employer client whose plan member triggered this DUR event. Supports multi-tenant client-level DUR analytics within the Company > Division > Client hierarchy.',
  event_type STRING COMMENT 'Classification of when the DUR review occurred relative to dispensing: prospective (at point of sale), concurrent (during therapy), or retrospective (post-dispensing claims analysis).',
  formulary_tier STRING COMMENT 'The formulary tier of the dispensed drug at the time of the DUR event (e.g., Tier 1 generic, Tier 2 preferred brand). Relevant for DUR events involving formulary-based clinical edits.',
  ingestion_timestamp TIMESTAMP COMMENT 'Date and time this DUR event record was first loaded into the PillarRx data lakehouse from the PBM claims feed. Audit timestamp for data pipeline tracking.',
  is_high_risk BOOLEAN COMMENT 'Indicates whether this DUR event is classified as high-risk based on severity_code or clinical_significance_code thresholds. Used for clinical safety reporting and PBM audit.',
  is_overridden BOOLEAN COMMENT 'Indicates whether the pharmacist overrode the DUR alert and dispensed the prescription despite the clinical warning. True when override_code is present and alert was bypassed.',
  level_of_effort_code STRING COMMENT 'NCPDP code indicating the pharmacist''s professional effort required to resolve the DUR alert (1=lowest to 5=highest). Used for MTM billing and audit purposes.',
  member_id BIGINT COMMENT 'Reference to the member (patient) whose prescription triggered this DUR event. Supports Member 360 cross-PBM analysis.',
  ncpdp_id STRING COMMENT '7-digit NCPDP identifier of the pharmacy that dispensed the prescription and submitted the DUR event. Used for pharmacy-level DUR trend analysis.',
  ndc_id BIGINT COMMENT 'The ndc id of the dur event.',
  normalized_flag BOOLEAN COMMENT 'Indicates whether this DUR event record has been normalized and standardized by the PillarRx ETL pipeline from the raw PBM source feed into the Silver layer schema.',
  override_code STRING COMMENT 'Code submitted by the pharmacist to override a DUR alert and proceed with dispensing (e.g., prescriber authorization, patient acknowledgment). Populated when alert_status is overridden.',
  pbm_assignment_id BIGINT COMMENT 'Foreign key linking to client.pbm_assignment. Business justification: DUR events (drug utilization review alerts) are adjudicated by the PBM at point-of-sale.',
  pbm_claim_number STRING COMMENT 'The PBM-assigned claim number from the source adjudication system that this DUR event is associated with. Used for cross-referencing back to the originating PBM feed.',
  pbm_division_id BIGINT COMMENT 'Foreign key linking to division.division. Business justification: DUR events must be attributed to division for division-specific clinical program reporting, PBM contract compliance measurement (clinical intervention rates), and consulting deliverables.',
  pbm_feed_batch_id BIGINT COMMENT 'Foreign key linking to claim.pbm_feed_batch. Business justification: DUR events are ingested via PBM feed batches. Strong traceability requirement for audit and data quality validation.',
  pbm_member_identifier STRING COMMENT 'The PBM-assigned member identifier as received in the source claims feed. Retained for cross-PBM reconciliation and Member 360 identity resolution.',
  prior_auth_id BIGINT COMMENT 'Foreign key linking to claim.prior_auth. Business justification: DUR events may be triggered by prior authorization requirements or conflicts. Currently dur_event has prior_auth_number as a string; adding prior_auth_id FK allows joining to the full',
  professional_service_code STRING COMMENT 'NCPDP code for the professional service rendered by the pharmacist in response to the DUR alert (e.g., AS=patient assessment, CC=coordination of care, DE=dosing evaluation).',
  quantity_dispensed DECIMAL(10,3) COMMENT 'The quantity of the drug dispensed on the claim that triggered this DUR event. Used in dosing-related DUR analysis (e.g., high dose alerts, quantity limit edits).',
  result_code STRING COMMENT 'NCPDP-standard code indicating the pharmacist''s action taken in response to the DUR alert (e.g., 1A=filled as is, 1B=filled with prescriber approval, 1C=not filled).',
  result_description STRING COMMENT 'Human-readable description of the DUR result code (e.g., ''Filled Prescription As Is'', ''Filled With Prescriber Approval'', ''Prescription Not Filled'').',
  rx_claim_id BIGINT COMMENT 'FK to claim.rx_claim.rx_claim_id — Each DUR event is generated at adjudication of a specific claim; description states ''linked to a specific rx_claim'' but the FK must be guaranteed.',
  service_reason_code STRING COMMENT 'NCPDP-standard code identifying the clinical reason the DUR alert was triggered (e.g., DD=drug-drug interaction, TD=duplicate therapy, HD=high dose, PA=drug-age precaution).',
  service_reason_description STRING COMMENT 'Human-readable description of the DUR service reason code (e.g., ''Drug-Drug Interaction'', ''Duplicate Therapy'', ''High Dose Alert''). Sourced from NCPDP code set.',
  severity_code STRING COMMENT 'Clinical severity level of the DUR alert as assigned by the drug reference source (1=contraindicated, 2=severe, 3=moderate, 4=minor). Sourced from Medi-Span or FDB drug interaction database.',
  to_rx_claim_id BIGINT COMMENT 'FK to claim.rx_claim.rx_claim_id — Each DUR event is generated for a specific claim at adjudication; parent FK required for clinical safety analysis joins.',
  updated_timestamp TIMESTAMP COMMENT 'Date and time this DUR event record was last modified in the lakehouse (e.g., due to a claim adjustment or data correction from the PBM feed).',
  CONSTRAINT pk_dur_event PRIMARY KEY (dur_event_id)
)
COMMENT 'Drug Utilization Review (DUR) event record generated at the point of adjudication for a pharmacy claim. Captures the DUR service reason code (e.g., drug-drug interaction, duplicate therapy, high dose), DUR result code (e.g., dispensed as is, prescription'
;

CREATE TABLE IF NOT EXISTS pillarrx.claim.medical_claim (
  admit_date DATE COMMENT 'Date of inpatient admission for institutional claims. Null for professional/outpatient claims. Used for length-of-stay and inpatient cost analysis.',
  allowed_amount DECIMAL(18,2) COMMENT 'Maximum amount the payer will consider for reimbursement after applying contractual fee schedules. Basis for plan-paid and member cost-share calculations.',
  benefit_plan_id BIGINT COMMENT 'Reference to the employer benefit plan under which this medical claim was adjudicated. Links to plan design for cost-sharing rule context.',
  billed_amount DECIMAL(18,2) COMMENT 'Gross amount billed by the provider before any contractual adjustments, discounts, or member cost-sharing. Basis for discount analysis.',
  billing_provider_npi STRING COMMENT '10-digit NPI of the entity submitting the claim for payment (may differ from rendering provider for group practices or facilities).',
  claim_number STRING COMMENT 'Externally assigned claim number from the medical payer or clearinghouse. Primary business identifier used for audit, reconciliation, and TCOC analysis.',
  claim_source STRING COMMENT 'Name or code of the medical claims integration feed or payer source from which this claim was ingested (e.g., carrier name, clearinghouse identifier).',
  claim_status STRING COMMENT 'Current processing lifecycle status of the medical claim as received from the medical claims integration feed.',
  claim_type STRING COMMENT 'Classification of the medical claim by form type: professional (CMS-1500 / 837P) or institutional (UB-04 / 837I).',
  discharge_date DATE COMMENT 'Date of inpatient discharge for institutional claims. Used with admit_date to calculate length of stay for inpatient benchmarking.',
  discharge_status_code STRING COMMENT 'UB-04 patient discharge status code indicating disposition at discharge (e.g., 01=Home, 20=Expired, 30=Still Patient). Used for readmission and outcomes analysis.',
  drg_code STRING COMMENT 'CMS Diagnosis Related Group code assigned to inpatient institutional claims for prospective payment classification and benchmarking.',
  employer_id BIGINT COMMENT 'Reference to the employer client whose health plan covers this medical claim, supporting multi-tenant Company > Division > Client scoping.',
  ingested_timestamp TIMESTAMP COMMENT 'Timestamp when this medical claim record was first captured and loaded into the Pillarrx lakehouse silver layer from the medical claims integration feed.',
  is_specialty_claim BOOLEAN COMMENT 'Flag indicating whether this medical claim is associated with a specialty condition or high-cost specialty service. Supports specialty spend monitoring.',
  medical_claim_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the medical claim record in the Pillarrx lakehouse silver layer.',
  member_coinsurance_amount DECIMAL(18,2) COMMENT 'Percentage-based cost-share amount paid by the member after the deductible is met. Contributes to member out-of-pocket accumulation.',
  member_copay_amount DECIMAL(18,2) COMMENT 'Fixed dollar copay amount paid by the member at the point of service. Contributes to member out-of-pocket accumulation.',
  member_deductible_amount DECIMAL(18,2) COMMENT 'Amount applied to the member''s deductible accumulator for this claim. Tracks member spend toward annual deductible threshold.',
  member_id BIGINT COMMENT 'Reference to the member (patient) associated with this medical claim, linking to the unified Member 360 record.',
  member_oop_amount DECIMAL(18,2) COMMENT 'Total out-of-pocket amount paid by the member for this claim (copay + coinsurance + deductible). Used for MOOP tracking and affordability analysis.',
  network_indicator STRING COMMENT 'Indicates whether the rendering provider was in-network or out-of-network at the time of service. Drives cost-sharing tier and benchmarking segmentation.',
  not_covered_amount DECIMAL(18,2) COMMENT 'Portion of the billed amount not covered by the plan (non-covered services, benefit exclusions). Supports benefit gap and plan design analysis.',
  other_payer_amount DECIMAL(18,2) COMMENT 'Amount paid by a secondary or tertiary payer (e.g., Medicare, Medicaid, SPAP, COB payer). Used for coordination of benefits and TCOC reconciliation.',
  paid_date DATE COMMENT 'Date the medical payer adjudicated and issued payment for this claim. Used for cash-flow and TCOC period alignment.',
  payer_claim_number STRING COMMENT 'Unique claim identifier assigned by the medical payer upon adjudication. Used for cross-referencing with payer EOBs and audit reconciliation.',
  payer_name STRING COMMENT 'Name of the medical insurance carrier or payer that adjudicated this claim. Supports multi-payer TCOC aggregation for employer clients.',
  pbm_division_id BIGINT COMMENT 'Foreign key linking to division.division. Business justification: Medical claims required for total cost of care (TCOC) analysis at division level. Multi-division clients often have separate medical/pharmacy benefit designs.',
  place_of_service_code STRING COMMENT 'CMS two-digit code indicating the setting where the medical service was rendered (e.g., 11=Office, 21=Inpatient Hospital, 23=Emergency Room).',
  plan_paid_amount DECIMAL(18,2) COMMENT 'Amount paid by the employer health plan after member cost-sharing is applied. Core TCOC metric for employer spend analysis.',
  primary_diagnosis_code STRING COMMENT 'ICD-10-CM code for the primary diagnosis associated with this medical claim. Core clinical dimension for TCOC and disease-burden analysis.',
  procedure_code STRING COMMENT 'CPT or HCPCS Level II procedure code identifying the medical service or supply billed. Primary clinical service identifier for TCOC analysis.',
  procedure_modifier STRING COMMENT 'Two-character CPT/HCPCS modifier appended to the procedure code to indicate special circumstances (e.g., bilateral, assistant surgeon, telehealth).',
  received_date DATE COMMENT 'Date the medical claim was received by the payer or clearinghouse. Used for turnaround-time and audit lag analysis.',
  rendering_provider_name STRING COMMENT 'Name of the provider who rendered the medical service, as reported on the claim. Supports provider-level reporting without requiring NPI lookup.',
  rendering_provider_npi STRING COMMENT '10-digit NPI of the provider who rendered the medical service. Sourced from NPPES. Used for provider-level TCOC and specialty analysis.',
  rendering_provider_specialty STRING COMMENT 'Medical specialty taxonomy code or description for the rendering provider. Used for specialty-level TCOC segmentation and benchmarking.',
  revenue_code STRING COMMENT 'Four-digit UB-04 revenue code used on institutional claims to identify the type of service or accommodation billed by the facility.',
  secondary_diagnosis_code STRING COMMENT 'ICD-10-CM code for the secondary or comorbid diagnosis on this claim. Supports comorbidity analysis and total cost of care stratification.',
  service_category STRING COMMENT 'High-level category of the medical service for TCOC segmentation and reporting. [ENUM-REF-CANDIDATE: inpatient|outpatient|emergency|professional|mental_health|pharmacy|other — promote to reference product]',
  service_date DATE COMMENT 'The date on which the medical service was rendered. Primary event date used for TCOC trend analysis and period attribution.',
  service_end_date DATE COMMENT 'End date of the service period for institutional claims spanning multiple days (e.g., inpatient stays). Equals service_date for single-day professional claims.',
  units_of_service DECIMAL(10,2) COMMENT 'Quantity of services, procedures, or days billed on this claim line. Used for unit-cost normalization in benchmarking and TCOC analysis.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp of the most recent update to this medical claim record in the lakehouse, reflecting adjustments, status changes, or data corrections.',
  CONSTRAINT pk_medical_claim PRIMARY KEY (medical_claim_id)
)
COMMENT 'Integrated medical claim record ingested from the medical claims feed for total cost of care (TCOC) analysis. Captures the medical claim number, member identifier, date of service, diagnosis codes (ICD-10), procedure codes (CPT/HCPCS), place of service'
;

CREATE TABLE IF NOT EXISTS pillarrx.claim.member_oop_accumulator (
  accumulator_program_id BIGINT COMMENT 'Add column claim.member_oop_accumulator.accumulator_program_id (BIGINT) as a FK to program.accumulator_program.accumulator_program_id, linking OOP accumulator tracking to the accumulator/maximizer program rules. ADD column claim.member_oop_',
  accumulator_source_type STRING COMMENT 'Indicates how the accumulator balances were derived: directly reported by the PBM, calculated by PillarRx from claim-level data, or provided by the plan or member.',
  accumulator_status STRING COMMENT 'Current lifecycle state of this accumulator record. Active during the benefit year; closed after year-end or member disenrollment.',
  accumulator_type STRING COMMENT 'Indicates whether this accumulator record tracks individual or family-level deductible and OOP thresholds per the benefit plan design.',
  benefit_group_fk BIGINT COMMENT 'FK to claim.benefit_group.benefit_group_id — Accumulator is scoped to benefit group and benefit year; MOOP breach detection joins to benefit_group MOOP limits. Should be enforced.',
  benefit_plan_id BIGINT COMMENT 'Reference to the benefit plan under which the member''s accumulators are tracked. Determines deductible and OOP maximum thresholds.',
  benefit_year INT COMMENT 'The plan benefit year (e.g., 2024) for which this accumulator record applies. Accumulators reset at the start of each benefit year.',
  benefit_year_end_date DATE COMMENT 'The last date of the benefit year accumulation period. Defines when deductible and OOP accumulators close for this member.',
  benefit_year_start_date DATE COMMENT 'The first date of the benefit year accumulation period. Defines when deductible and OOP accumulators begin for this member.',
  cap_applied_amt DECIMAL(18,2) COMMENT 'Year-to-date dollar amount applied by copay assistance programs (manufacturer coupons, copay cards) on behalf of the member. Tracked for TrOOP exclusion analysis.',
  cap_excluded_from_troop_flag BOOLEAN COMMENT 'Indicates whether copay assistance amounts are excluded from TrOOP calculation per CMS rules. True for manufacturer-funded copay cards on Medicare Part D.',
  claim_benefit_group_id BIGINT COMMENT 'FK to claim.claim_benefit_group.claim_benefit_group_id — Accumulator is scoped to benefit group and tracks benefit-year OOP/deductible against the benefit design.',
  claim_count INT COMMENT 'Total number of paid pharmacy claims contributing to this accumulator record within the benefit year. Excludes reversals and adjustments.',
  coinsurance_applied_amt DECIMAL(18,2) COMMENT 'Year-to-date coinsurance amounts paid by the member across all pharmacy claims in the benefit year. Percentage-based member cost share component.',
  company_client_id BIGINT COMMENT 'Foreign key linking to company.company_client. Business justification: OOP accumulators must be scoped to client for CAP program eligibility determination, member cost-share reporting, and affordability analysis consulting deliverables.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM (e.g., CVS Caremark, Optum Rx, Express Scripts) that adjudicated the claims contributing to this accumulator.',
  copay_applied_amt DECIMAL(18,2) COMMENT 'Year-to-date fixed copay amounts paid by the member across all pharmacy claims in the benefit year. Component of total OOP accumulation.',
  coverage_type STRING COMMENT 'Indicates whether this accumulator applies to pharmacy-only, medical-only, or a combined pharmacy and medical deductible/OOP per the plan design.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this accumulator record was first created in the system, typically at the start of the benefit year or upon the member''s first claim.',
  data_source STRING COMMENT 'Identifies the originating PBM or system that provided the accumulator data (e.g., CVS Caremark, Optum Rx, Express Scripts). Supports multi-PBM reconciliation.',
  deductible_applied_amt DECIMAL(18,2) COMMENT 'Year-to-date dollar amount the member has applied toward their pharmacy deductible within the benefit year. Accumulates with each paid claim.',
  deductible_maximum_amt DECIMAL(18,2) COMMENT 'The plan-defined maximum deductible threshold for this member''s benefit plan and year. Sourced from the benefit plan configuration.',
  deductible_met_date DATE COMMENT 'The date on which the member''s pharmacy deductible was fully satisfied for the benefit year. Null if deductible has not yet been met.',
  deductible_met_flag BOOLEAN COMMENT 'Indicates whether the member has fully satisfied their pharmacy deductible for the benefit year. True when deductible applied equals or exceeds deductible maximum.',
  deductible_remaining_amt DECIMAL(18,2) COMMENT 'Dollar amount remaining before the member satisfies their pharmacy deductible for the benefit year. Equals deductible maximum minus deductible applied.',
  dir_adjustment_amt DECIMAL(18,2) COMMENT 'Year-to-date DIR fee adjustments applied post-adjudication that may affect the member''s effective OOP. Relevant for Medicare Part D DIR reconciliation.',
  last_claim_date DATE COMMENT 'The date of service of the most recent pharmacy claim that updated this accumulator record. Used to identify stale or inactive accumulator records.',
  last_updated_timestamp TIMESTAMP COMMENT 'Timestamp of the most recent update to this accumulator record, reflecting the latest claim adjudication or adjustment that modified accumulator balances.',
  mbi STRING COMMENT 'The CMS-assigned Medicare Beneficiary Identifier for the member. Required for Medicare Part D TrOOP reporting and CMS coordination of benefits.',
  medicare_part_d_flag BOOLEAN COMMENT 'Indicates whether this accumulator record applies to a Medicare Part D member, enabling TrOOP tracking and CMS catastrophic coverage threshold logic.',
  member_id BIGINT COMMENT 'Reference to the member whose out-of-pocket and deductible accumulators are tracked. Links to the member master record.',
  member_oop_accumulator_id BIGINT NOT NULL COMMENT 'Unique surrogate primary key for the member OOP accumulator record. One record per member per benefit year per plan.',
  oop_applied_amt DECIMAL(18,2) COMMENT 'Year-to-date dollar amount the member has applied toward their pharmacy out-of-pocket maximum. Includes copay, coinsurance, and deductible contributions.',
  oop_maximum_amt DECIMAL(18,2) COMMENT 'The plan-defined maximum out-of-pocket threshold for this member''s benefit plan and year. Once reached, the plan covers 100% of eligible costs.',
  oop_met_date DATE COMMENT 'The date on which the member reached their pharmacy out-of-pocket maximum for the benefit year. Null if OOP maximum has not yet been reached.',
  oop_met_flag BOOLEAN COMMENT 'Indicates whether the member has reached their pharmacy out-of-pocket maximum for the benefit year. True when OOP applied equals or exceeds OOP maximum.',
  oop_remaining_amt DECIMAL(18,2) COMMENT 'Dollar amount remaining before the member reaches their pharmacy out-of-pocket maximum for the benefit year. Equals OOP maximum minus OOP applied.',
  other_payer_applied_amt DECIMAL(18,2) COMMENT 'Year-to-date amounts paid by other payers (secondary insurance, SPAP, Medicaid) that reduce the member''s OOP liability. Relevant for coordination of benefits.',
  pbm_division_id BIGINT COMMENT 'Foreign key linking to division.division. Business justification: Accumulators are division-specific when clients have multiple divisions with distinct benefit designs.',
  pbm_member_identifier STRING COMMENT 'The member identifier as assigned by the PBM source system. Used for cross-PBM reconciliation and Member 360 identity resolution.',
  program_savings_program_id BIGINT COMMENT 'Reference to program.savings_program.savings_program_id.',
  rds_eligible_flag BOOLEAN COMMENT 'Indicates whether the member is enrolled in a Retiree Drug Subsidy plan. Affects accumulator reporting requirements and CMS subsidy calculations.',
  reconciliation_status STRING COMMENT 'Status of reconciliation between PBM-reported accumulator balances and PillarRx-calculated balances from claim-level data. Supports PBM audit workflows.',
  reconciliation_variance_amt DECIMAL(18,2) COMMENT 'Dollar difference between PBM-reported OOP accumulator balance and PillarRx-calculated balance. Non-zero values trigger PBM audit review.',
  spap_applied_amt DECIMAL(18,2) COMMENT 'Year-to-date dollar amount applied by a State Pharmaceutical Assistance Program on behalf of the member. Tracked separately for TrOOP and COB analysis.',
  to_benefit_group BIGINT COMMENT 'FK to claim.benefit_group.benefit_group_id — Accumulator is scoped to benefit group for MOOP/deductible rules; FK needed for breach detection.',
  troop_applied_amt DECIMAL(18,2) COMMENT 'Year-to-date True Out-of-Pocket amount for Medicare Part D members. Tracks qualifying spend toward the catastrophic coverage threshold per CMS TrOOP rules.',
  troop_remaining_amt DECIMAL(18,2) COMMENT 'Dollar amount remaining before the Medicare Part D member reaches the catastrophic coverage threshold. Null for non-Medicare members.',
  troop_threshold_amt DECIMAL(18,2) COMMENT 'The CMS-defined TrOOP threshold for the benefit year at which Medicare Part D catastrophic coverage begins. Updated annually by CMS.',
  CONSTRAINT pk_member_oop_accumulator PRIMARY KEY (member_oop_accumulator_id)
)
COMMENT 'Tracks each member''s running out-of-pocket (OOP) and deductible accumulation across all pharmacy claims within a benefit year. Maintains year-to-date deductible applied, deductible remaining, OOP applied, OOP remaining, and True Out-of-Pocket (TrOOP) for'
;

CREATE TABLE IF NOT EXISTS pillarrx.claim.pbm_feed_batch (
  actual_record_count BIGINT COMMENT 'Total number of claim records physically present in the received feed file as counted during ingestion. Compared against expected_record_count for completeness validation.',
  adjustment_count BIGINT COMMENT 'Number of claim adjustment transactions contained in this feed batch. Adjustments correct previously adjudicated fills and are tracked separately for audit purposes.',
  batch_status STRING COMMENT 'Current lifecycle state of the feed batch within the ingestion pipeline. Tracks progression from receipt through validation, processing, and completion or failure.',
  checksum_algorithm STRING COMMENT 'Algorithm used to compute the file_checksum (e.g., MD5, SHA-256, SHA-512). Required to correctly validate file integrity during reprocessing or audit.',
  claim_pbm_id BIGINT COMMENT 'FK to claim.claim_pbm.claim_pbm_id — Each ingestion batch is a delivery from a specific PBM source; batch captures PBM identifier.',
  client_scope STRING COMMENT 'Identifies the employer client(s) whose claims data is contained in this feed batch. May be a single client code or a comma-separated list for multi-client PBM feeds.',
  created_timestamp TIMESTAMP COMMENT 'Date and time this pbm_feed_batch record was first created in the PillarRx ingestion platform. Serves as the audit record creation timestamp.',
  delivery_method STRING COMMENT 'Mechanism by which the PBM transmitted the feed file to PillarRx (e.g., SFTP, API push, cloud storage drop). Informs ingestion routing and SLA tracking.',
  employer_id BIGINT COMMENT 'Foreign key linking to client.employer. Business justification: PBM feed batches are often employer-scoped when PBMs deliver client-specific extracts. Data onboarding, feed validation, and SLA monitoring require linking batches to the employer client for',
  expected_record_count BIGINT COMMENT 'Total number of claim records declared by the PBM in the feed file header or manifest. Used for reconciliation against actual_record_count to detect truncation or transmission errors.',
  extract_date DATE COMMENT 'The date on which the PBM generated and extracted this feed file from their adjudication system. May differ from the received_timestamp due to transmission delays.',
  feed_file_name STRING COMMENT 'Original file name of the PBM claims feed file as received from the source PBM, including extension. Used for traceability and audit of the ingestion pipeline.',
  feed_file_path STRING COMMENT 'Full storage path or URI of the received PBM feed file in the landing zone (e.g., ADLS, S3, SFTP drop). Enables reprocessing and audit trail.',
  feed_format STRING COMMENT 'Technical format of the PBM feed file (e.g., NCPDP D.0 flat file, pipe-delimited, CSV). Drives parser selection during ETL normalization.',
  feed_frequency STRING COMMENT 'Expected delivery cadence for this PBM feed as contracted (e.g., daily, weekly, monthly). Used to detect missing or late file deliveries and trigger SLA alerts.',
  feed_type STRING COMMENT 'Classification of the data content delivered in this batch. Distinguishes pharmacy claims feeds from eligibility, formulary, rebate, prior authorization, or medical claims feeds.',
  file_checksum STRING COMMENT 'Cryptographic hash (e.g., MD5 or SHA-256) of the received feed file used to verify file integrity and detect corruption or tampering during transmission.',
  file_size_bytes BIGINT COMMENT 'Size of the received PBM feed file in bytes. Used for transmission completeness checks and storage capacity planning in the ingestion platform.',
  fill_count BIGINT COMMENT 'Number of original prescription fill transactions (claim type = fill) contained in this feed batch. Used for volume trending and PBM audit reconciliation.',
  ingestion_environment STRING COMMENT 'Target environment into which this feed batch was ingested (Production, UAT, Dev, Sandbox). Prevents test data from contaminating production analytics.',
  is_incremental BOOLEAN COMMENT 'Indicates whether this batch is an incremental (delta) feed containing only new or changed records since the last delivery, as opposed to a full historical reload.',
  is_reprocessed BOOLEAN COMMENT 'Indicates whether this batch record represents a reprocessing of a previously received feed file (e.g., after a validation failure or data correction). Prevents duplicate loading.',
  notes STRING COMMENT 'Free-text operational notes entered by the PillarRx data engineering team regarding this feed batch (e.g., late delivery explanation, PBM communication, manual override reason).',
  original_batch_pbm_feed_batch_id BIGINT COMMENT 'For reprocessed batches (is_reprocessed = true), references the pbm_feed_batch_id of the original batch that this record supersedes. Null for first-time ingestions.',
  pbm_batch_company_pbm_id BIGINT COMMENT 'Reference to the PBM source that delivered this feed batch (e.g., CVS Caremark, Optum Rx, Express Scripts, Navitus, EmpiRx Health).',
  pbm_batch_reference STRING COMMENT 'The PBM-assigned batch or transmission reference number included in the feed file header. Used for cross-referencing with the PBM''s own transmission logs during audits.',
  pbm_code STRING COMMENT 'Standardized short code identifying the PBM that delivered this feed batch. Used for routing, normalization, and source attribution in the ingestion pipeline.',
  pbm_division_id BIGINT COMMENT 'Foreign key linking to division.division. Business justification: Feed batches are division-specific - each division receives separate PBM data feeds even within same employer.',
  pbm_feed_batch_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for each PBM feed batch ingestion record within the PillarRx PBM Claims Feed Ingestion Platform.',
  pbm_fk BIGINT COMMENT 'FK to claim.pbm.pbm_id — Each ingestion batch is delivered by a specific PBM; FK needed for feed-completeness monitoring per source.',
  pbm_sender_company_pbm_id BIGINT COMMENT 'The sender identifier declared in the PBM feed file header (e.g., NCPDP sender ID, BIN, or proprietary PBM system ID). Used for source authentication and routing.',
  processed_record_count BIGINT COMMENT 'Number of claim records successfully parsed, normalized, and loaded into the Silver layer during ETL processing of this batch.',
  processing_end_timestamp TIMESTAMP COMMENT 'Date and time when the ETL normalization pipeline completed processing this feed batch. Combined with processing_start_timestamp to compute pipeline duration.',
  processing_start_timestamp TIMESTAMP COMMENT 'Date and time when the ETL normalization pipeline began processing this feed batch. Used for ingestion SLA measurement and pipeline performance monitoring.',
  received_timestamp TIMESTAMP COMMENT 'Date and time the PBM feed file was received and landed in the PillarRx ingestion platform. Serves as the authoritative business event timestamp for SLA tracking.',
  rejected_record_count BIGINT COMMENT 'Number of claim records that failed validation or normalization rules and were rejected during ETL processing. Drives data quality alerting and reprocessing workflows.',
  reporting_period_end_date DATE COMMENT 'The latest date of service (DOS) covered by the claims data in this feed batch, as declared by the PBM. Defines the reporting window for client analytics.',
  reporting_period_start_date DATE COMMENT 'The earliest date of service (DOS) covered by the claims data in this feed batch, as declared by the PBM. Defines the reporting window for client analytics.',
  reversal_count BIGINT COMMENT 'Number of claim reversal transactions contained in this feed batch. Reversals cancel previously adjudicated fills and affect net plan spend calculations.',
  to_pbm BIGINT COMMENT 'FK to claim.pbm.pbm_id — Each ingestion batch is from one PBM source; FK needed for feed-completeness monitoring per PBM.',
  total_ingredient_cost_amount DECIMAL(18,2) COMMENT 'Sum of ingredient cost amounts across all claim records in this feed batch. Ingredient cost is the drug acquisition cost component used in AWP discount and MAC analysis.',
  total_member_cost_share_amount DECIMAL(18,2) COMMENT 'Sum of all member cost-share amounts (copay + coinsurance + deductible applied) across all claim records in this batch. Used for member OOP and MOOP reconciliation.',
  total_plan_paid_amount DECIMAL(18,2) COMMENT 'Sum of plan-paid amounts across all claim records in this feed batch (net of reversals). Used for high-level financial reconciliation against PBM invoices and client reporting.',
  updated_timestamp TIMESTAMP COMMENT 'Date and time this pbm_feed_batch record was last modified (e.g., status update, reprocessing flag change). Supports change tracking and audit.',
  validation_error_summary STRING COMMENT 'Human-readable summary of validation errors encountered during feed batch processing. Captures top error categories (e.g., missing NDC, invalid NPI) for triage and remediation.',
  validation_status STRING COMMENT 'Result of the automated data quality validation checks applied to this feed batch (e.g., record count match, required field presence, NDC format checks). Distinct from batch_status.',
  CONSTRAINT pk_pbm_feed_batch PRIMARY KEY (pbm_feed_batch_id)
)
COMMENT 'Ingestion batch record representing a single file delivery from a PBM source system into the PillarRx PBM Claims Feed Ingestion Platform. Captures the PBM identifier, feed file name, file receipt timestamp, reporting period start and end dates, record'
;

CREATE TABLE IF NOT EXISTS pillarrx.claim.prior_auth (
  appeal_number STRING COMMENT 'The reference number assigned to a PA appeal submission. Populated only when pa_type is appeal. Links the appeal to the original denied PA for audit tracking.',
  appeal_outcome STRING COMMENT 'The result of the PA appeal review. Upheld means the original denial stands; overturned means the drug is approved on appeal. Null when no appeal was filed.',
  approved_days_supply INT COMMENT 'The number of days supply of medication approved under this PA. Constrains the dispensing window and refill eligibility at the pharmacy.',
  approved_quantity DECIMAL(10,3) COMMENT 'The quantity of drug units (e.g., tablets, milliliters) approved under this PA. Claims exceeding this quantity will reject at adjudication.',
  approved_refills INT COMMENT 'The number of refills authorized under this PA approval. A value of zero indicates the initial fill only; null indicates no refill restriction was specified.',
  claim_prescriber_id BIGINT COMMENT 'Reference to the prescribing provider (NPI-keyed) who initiated or is associated with the prior authorization request.',
  clinical_criteria_met BOOLEAN COMMENT 'Indicates whether the submitted clinical documentation satisfied the PBM or plan clinical criteria for approval. Populated from the PA decision record.',
  company_client_id BIGINT COMMENT 'Foreign key linking to company.company_client. Business justification: Prior authorization analysis is a core consulting service requiring client attribution for PA approval rate reporting, turnaround time benchmarking, and denial reason analysis by',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM (e.g., CVS Caremark, Optum Rx, Express Scripts) that adjudicated or managed this prior authorization.',
  created_timestamp TIMESTAMP COMMENT 'The timestamp when this prior authorization record was first loaded into the PillarRx lakehouse. Used for data lineage, audit, and incremental ETL processing.',
  decision_date DATE COMMENT 'The date the PBM or plan issued the approval, denial, or other determination on the PA request. Used to calculate decision turnaround time.',
  denial_reason_code STRING COMMENT 'Standardized code indicating the reason a PA request was denied (e.g., not medically necessary, step therapy required, non-formulary). Null when status is not denied.',
  denial_reason_description STRING COMMENT 'Free-text or standardized narrative explanation of the denial reason provided by the PBM or plan. Supports member appeal and consulting audit workflows.',
  diagnosis_code STRING COMMENT 'The ICD-10-CM diagnosis code submitted with the PA request to support medical necessity. PHI — restricted access. Null if not provided by the PBM source.',
  effective_date DATE COMMENT 'The date on which the prior authorization approval becomes valid and claims may be adjudicated against it.',
  expiration_date DATE COMMENT 'The date on which the prior authorization approval expires. Claims submitted after this date will reject unless a renewal PA is obtained.',
  formulary_tier INT COMMENT 'The formulary cost-sharing tier of the drug subject to this PA at the time of the request. Used to assess whether PA is driven by tier placement or clinical criteria.',
  is_340b_eligible BOOLEAN COMMENT 'Indicates whether the drug and dispensing context associated with this PA may qualify under the federal 340B drug discount program. Supports 340B compliance monitoring.',
  is_specialty_drug BOOLEAN COMMENT 'Indicates whether the drug subject to this PA is classified as a specialty medication (SMN). Specialty PAs typically have distinct clinical criteria and turnaround requirements.',
  member_id BIGINT COMMENT 'Reference to the member (patient) for whom the prior authorization was requested. Supports Member 360 cross-PBM analysis.',
  ndc_code STRING COMMENT 'The 11-digit FDA National Drug Code identifying the specific drug product subject to this PA. Stored as the normalized 11-digit format (5-4-2 segments, no hyphens).',
  notes STRING COMMENT 'Free-text notes or supplemental information captured during PA review, appeal, or consulting analysis. May include clinical rationale or PBM communication details.',
  pa_number STRING COMMENT 'The externally-assigned prior authorization number issued by the PBM or health plan. Used for claim adjudication routing and audit reconciliation.',
  pa_source STRING COMMENT 'Indicates the entity that issued or manages the PA requirement: PBM-driven, health plan-driven, state mandate, federal program (e.g., Medicare Part D), or other.',
  pa_status STRING COMMENT 'Current lifecycle status of the prior authorization request. Drives claim adjudication eligibility and member cost-share outcomes.',
  pa_type STRING COMMENT 'Classification of the PA request by review pathway. Standard is routine; expedited is urgent; appeal is a reconsideration of a denial; renewal extends an existing approval.',
  pbm_assignment_id BIGINT COMMENT 'Foreign key linking to client.pbm_assignment. Business justification: Prior authorizations are adjudicated by specific PBM assignments (employer-PBM contract context).',
  pbm_division_id BIGINT COMMENT 'Foreign key linking to division.division. Business justification: Prior auths must be scoped to division for division-specific formulary enforcement, clinical program tracking, and PBM contract compliance measurement (PA turnaround times, approval rates).',
  pbm_name STRING COMMENT 'The name of the PBM that processed or manages this PA (e.g., CVS Caremark, Optum Rx, Express Scripts). Denormalized for reporting convenience across multi-PBM analysis.',
  pbm_pa_reference STRING COMMENT 'The PBM-assigned internal reference or tracking number for this PA request, distinct from the adjudication PA number. Used for PBM audit reconciliation.',
  prescriber_npi STRING COMMENT 'The 10-digit NPI of the prescribing provider who requested or is associated with this PA. Sourced from the PBM claim feed for audit traceability.',
  prior_auth_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the prior authorization record in the PillarRx lakehouse. Primary key for the prior_auth entity.',
  prior_rx_claim_id BIGINT COMMENT 'Reference to the pharmacy claim transaction this prior authorization is associated with. Links PA records to the adjudicated fill event.',
  quantity_limit_applied BOOLEAN COMMENT 'Indicates whether a quantity limit restriction is the basis for or a condition of this prior authorization. Supports formulary utilization management analysis.',
  request_date DATE COMMENT 'The date the prior authorization request was submitted to the PBM or health plan for review. Used to measure turnaround time and compliance with CMS timelines.',
  rx_claim_id BIGINT COMMENT 'FK to claim.rx_claim.rx_claim_id — PA is linked to the rx_claim when a PA number is present on the claim; required for denial-rate benchmarking tied to actual fills.',
  source_pa_number STRING COMMENT 'The native PA record identifier from the originating PBM or source system. Preserved for reconciliation back to the source feed during PBM audits.',
  step_therapy_required BOOLEAN COMMENT 'Indicates whether the PA denial or requirement is driven by a step therapy protocol, requiring the member to try a preferred drug before the requested drug is approved.',
  to_rx_claim_id BIGINT COMMENT 'FK to claim.rx_claim.rx_claim_id — PA records link to rx_claim when a PA number is present; FK needed for PA denial-rate benchmarking against claims.',
  turnaround_days INT COMMENT 'Number of calendar days between the PA request date and the decision date. Used to benchmark PBM PA processing speed against CMS and contractual SLA requirements.',
  updated_timestamp TIMESTAMP COMMENT 'The timestamp when this prior authorization record was last modified in the PillarRx lakehouse, reflecting status changes, decision updates, or appeal outcomes.',
  CONSTRAINT pk_prior_auth PRIMARY KEY (prior_auth_id)
)
COMMENT 'Prior authorization (PA) record associated with a pharmacy claim or a member-drug combination. Captures the PA number, PA type (standard, expedited, appeal), PA status (approved, denied, pending, expired), effective and expiration dates, approved quantity'
;

CREATE TABLE IF NOT EXISTS pillarrx.claim.rebate_record (
  adjustment_amount DECIMAL(18,2) COMMENT 'Dollar amount of any post-invoice adjustment applied to this rebate record (positive = upward adjustment, negative = clawback or reduction).',
  adjustment_reason STRING COMMENT 'Explanation for the rebate adjustment amount, such as claim restatement, eligibility correction, or DIR reconciliation. Required when adjustment_amount is non-zero.',
  admin_fee_amount DECIMAL(18,2) COMMENT 'Administrative fee retained by the PBM from the gross rebate before passing through to the plan. Key metric in pass-through vs. spread PBM model audits.',
  benefit_period_end_date DATE COMMENT 'End date of the benefit period to which this rebate record applies. Together with benefit_period_start_date defines the rebate measurement window.',
  benefit_period_start_date DATE COMMENT 'Start date of the benefit period (plan year quarter or contract period) to which this rebate record applies. Used for period-level rebate aggregation.',
  claim_count INT COMMENT 'Number of eligible pharmacy claims included in this rebate record for the benefit period. Used to validate rebate amounts against per-claim rates.',
  claim_pbm_id BIGINT COMMENT 'FK to claim.claim_pbm.claim_pbm_id — Rebate records reference the PBM rebate contract; FK to PBM master needed for guarantee reconciliation.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM through which the rebatable claims were adjudicated. Links to company.pbm.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this rebate record was first created in the PillarRx lakehouse. Audit trail for data lineage and ETL traceability.',
  currency_code STRING COMMENT 'ISO 4217 three-letter currency code for all monetary amounts on this rebate record. Typically USD for domestic PBM rebates.',
  dispute_reason STRING COMMENT 'Free-text or coded reason for a rebate dispute when rebate_status is ''disputed''. Captures the basis for challenging the invoiced or received amount.',
  drug_name STRING COMMENT 'Brand or generic name of the drug associated with this rebate record. Denormalized for readability in rebate reporting and consulting deliverables.',
  employer_id BIGINT COMMENT 'Reference to the employer client whose plan members generated the rebatable claims. Links to client.employer. Supports multi-tenant client scoping.',
  estimated_rebate_amount DECIMAL(18,2) COMMENT 'Projected rebate amount calculated at time of estimation, prior to PBM invoice or manufacturer confirmation. Used for accrual and client forecasting.',
  formulary_tier STRING COMMENT 'Formulary tier placement of the drug at the time the rebate was earned. Tier placement drives rebate eligibility and rate under most PBM contracts.',
  gpi_code STRING COMMENT '14-digit Medi-Span Generic Product Identifier representing the therapeutic class or drug group for class-level rebate records where a single NDC is not applicable.',
  invoice_date DATE COMMENT 'Date on which the rebate was invoiced to the manufacturer or PBM. Marks the formal billing event in the rebate lifecycle.',
  invoiced_rebate_amount DECIMAL(18,2) COMMENT 'Rebate amount formally invoiced to the manufacturer or PBM for the benefit period. Represents the billed gross rebate before any adjustments.',
  is_340b_excluded BOOLEAN COMMENT 'Indicates whether claims under the federal 340B drug discount program are excluded from this rebate record, as required by most manufacturer rebate contracts.',
  is_pass_through BOOLEAN COMMENT 'Indicates whether the rebate is fully passed through to the employer plan (true) or retained in whole or part by the PBM under a spread model (false).',
  manufacturer_name STRING COMMENT 'Name of the pharmaceutical manufacturer from whom the rebate is earned. Key party in the rebate contract relationship.',
  market_share_pct DECIMAL(7,4) COMMENT 'Drug market share percentage achieved within the therapeutic class for the benefit period. Determines tier qualification for market-share-based rebate contracts.',
  ndc_code STRING COMMENT 'Add column claim.rebate_record.ndc_code (STRING), the 11-digit normalized NDC code for the rebated drug, for drug-level attribution. ADD column claim.rebate_record.ndc_code (STRING). 11-digit normalized NDC code for the rebated drug.',
  net_rebate_amount DECIMAL(18,2) COMMENT 'Net rebate amount passed through to the employer plan after deducting PBM administrative fees. Core metric for plan sponsor rebate value reporting.',
  notes STRING COMMENT 'Free-text notes entered by PillarRx analysts regarding this rebate record, such as audit findings, reconciliation commentary, or client communication context.',
  pbm_assignment_id BIGINT COMMENT 'Foreign key linking to client.pbm_assignment. Business justification: Rebate records must be reconciled against the specific PBM assignment''s contracted rebate guarantees, passthrough percentages, and pricing model.',
  pbm_rebate_reference STRING COMMENT 'PBM-assigned reference number for this rebate record as reported in the PBM rebate remittance file. Used for cross-referencing PBM source data during audits.',
  performance_tier STRING COMMENT 'Performance tier achieved under the rebate contract for the benefit period (e.g., Tier 1, Tier 2, Gold). Determines the applicable rebate rate for performance-based contracts.',
  program_savings_program_id BIGINT COMMENT 'Reference to program.savings_program.savings_program_id.',
  rebate_basis STRING COMMENT 'Method used to calculate the rebate amount: per claim, per dispensed unit, percentage of AWP/WAC, flat fee, or market-share tier. Drives rate application logic.',
  rebate_contract_id BIGINT COMMENT 'Reference to the rebate contract under which this rebate record was earned. Links to the division.rebate_contract product.',
  rebate_payment_id BIGINT COMMENT 'Reference to the rebate payment record that settled this rebate amount. Links to the division.rebate_payment product. Nullable until payment is received.',
  rebate_rate DECIMAL(10,6) COMMENT 'Contractual rebate rate applied to calculate the rebate amount, expressed as a percentage of AWP or a per-unit dollar amount per the rebate contract terms.',
  rebate_record_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the manufacturer rebate record within the PillarRx lakehouse. Primary key for the rebate_record entity.',
  rebate_rx_claim_id BIGINT COMMENT 'FK to claim.rx_claim.rx_claim_id — Claim-level rebate rows reference the originating claim; for claim-grain rebates a guaranteed FK supports DIR and pass-through reconciliation. (Drug-class-level rebate rows may be null-FK.)',
  rebate_status STRING COMMENT 'Current lifecycle state of the rebate record, from initial estimation through receipt, dispute resolution, or voiding.',
  rebate_type STRING COMMENT 'Classification of the rebate by its contractual basis. [ENUM-REF-CANDIDATE: brand|specialty|performance|administrative|inflation|market_share|formulary_placement — promote to reference product]',
  received_date DATE COMMENT 'Date on which the rebate payment was actually received. Nullable until payment is confirmed. Used for cash-basis rebate accounting.',
  received_rebate_amount DECIMAL(18,2) COMMENT 'Actual rebate amount received from the manufacturer or PBM. May differ from invoiced amount due to disputes, adjustments, or partial payments.',
  record_number STRING COMMENT 'Externally-known business identifier for this rebate record, assigned by the PBM or manufacturer. Used for reconciliation and audit traceability.',
  source_pbm_name STRING COMMENT 'Name of the PBM that reported this rebate record (e.g., CVS Caremark, Optum Rx, Express Scripts). Denormalized for multi-PBM reporting without join.',
  therapeutic_class_code STRING COMMENT 'Drug therapeutic class code (e.g., Medi-Span GPI class prefix) used for class-level rebate aggregation and performance tier measurement.',
  to_rx_claim_id BIGINT COMMENT 'FK to claim.rx_claim.rx_claim_id — Rebate records track amounts at the claim or drug-class level; a claim-level FK is required for claim-grain rebate reconciliation.',
  unit_count DECIMAL(18,4) COMMENT 'Total dispensed units (tablets, milliliters, etc.) across all eligible claims in this rebate record. Used for unit-based rebate rate calculations.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp of the most recent update to this rebate record. Used to detect changes during reconciliation cycles and ETL incremental loads.',
  CONSTRAINT pk_rebate_record PRIMARY KEY (rebate_record_id)
)
COMMENT 'Manufacturer rebate record tracking rebate amounts earned and received at the claim or drug-class level for a given client and benefit period. Captures the rebate type (brand, specialty, performance, administrative), the drug NDC or GPI therapeutic class'
;

CREATE TABLE IF NOT EXISTS pillarrx.claim.rx_claim (
  awp_discount_pct DECIMAL(8,4) COMMENT 'The effective AWP discount percentage achieved on this claim as adjudicated. Core metric for PBM contract guarantee (GER/BER) audit and benchmarking against contracted rates.',
  awp_unit_price DECIMAL(18,4) COMMENT 'Average Wholesale Price per unit for the dispensed NDC at time of fill, sourced from Medi-Span or FDB. Used as the benchmark for AWP discount calculation and PBM contract audit.',
  benefit_group_fk BIGINT COMMENT 'FK to claim.benefit_group.benefit_group_id — rx_claim references a benefit group to determine cost-sharing rules at adjudication; required for VREQ-003 hierarchy scoping and benefit-design analytics.',
  brand_generic_indicator STRING COMMENT 'Indicates whether the dispensed drug is a brand, generic, specialty, or biosimilar product. Used for Generic Dispensing Rate (GDR) calculation and brand/generic spend analysis.',
  claim_benefit_group_id BIGINT COMMENT 'Foreign key linking to claim.claim_benefit_group. Business justification: Every pharmacy claim is adjudicated under a specific benefit group (benefit design).',
  claim_pbm_id BIGINT COMMENT 'FK to claim.claim_pbm.claim_pbm_id — Every claim must attribute to its source PBM; claim_pbm is referenced by rx_claim for source attribution.',
  claim_prescriber_id BIGINT COMMENT 'Foreign key linking to claim.prescriber. Business justification: Every pharmacy claim has a prescribing provider. Currently rx_claim has prescriber_npi as a string; adding prescriber_id FK allows joining to the full prescriber master record (specialty',
  claim_status STRING COMMENT 'Current lifecycle state of the pharmacy claim transaction. Distinguishes paid fills from reversals and adjustments for accurate financial reporting and PBM audit.',
  claim_type STRING COMMENT 'Identifies whether this record represents an original fill, a reversal (cancellation), or an adjustment (correction) of a prior claim. Core grain discriminator for the claim fact.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM that adjudicated this claim (e.g., CVS Caremark, Optum Rx, Express Scripts). Enables cross-PBM benchmarking and audit analysis.',
  compound_flag BOOLEAN COMMENT 'Indicates whether the dispensed prescription is a compounded drug. Compound claims require special audit scrutiny and are tracked separately for PBM audit and formulary compliance.',
  date_of_service DATE COMMENT 'The date the prescription was dispensed to the member at the pharmacy. Primary business event date used for trend analysis, PMPM/PMPY calculations, and benefit period attribution.',
  daw_code STRING COMMENT 'NCPDP DAW code (0–9) indicating whether the brand was dispensed as written or a generic was substituted. Key input for Generic Dispensing Rate (GDR) and brand/generic analysis. [ENUM-REF-CANDIDATE: 0|1|2|3|4|5|6|7|8|9 — promote to reference product]',
  days_supply INT COMMENT 'Number of days of medication supplied in this fill as adjudicated by the PBM. Used for adherence calculations, mail-order vs retail classification, and PMPM normalization.',
  deductible_applied DECIMAL(18,4) COMMENT 'Dollar amount of this claim applied toward the member''s deductible. Used to track deductible accumulation and determine when plan coverage begins for the benefit period.',
  deductible_remaining DECIMAL(18,4) COMMENT 'Member''s remaining deductible balance after this claim is applied. Sourced from PBM adjudication response; used for member affordability and benefit period analysis.',
  dispensing_fee DECIMAL(18,4) COMMENT 'The pharmacy service fee component paid to the dispensing pharmacy as adjudicated by the PBM. Used in dispensing fee guarantee auditing and total reimbursement analysis.',
  employer_id BIGINT COMMENT 'Reference to the employer client whose health plan member filled this prescription. Supports multi-tenant claim partitioning within the Company > Division > Client hierarchy.',
  fill_date DATE COMMENT 'The date the prescription was physically filled and dispensed by the pharmacy. May differ from date_of_service for mail-order or specialty fills with processing lag.',
  fill_number INT COMMENT 'Sequential fill count for this prescription (0 = new, 1 = first refill, etc.). Used to distinguish new prescriptions from refills in adherence and utilization analysis.',
  formulary_tier STRING COMMENT 'The formulary cost-sharing tier assigned to the dispensed drug (e.g., Tier 1 Generic, Tier 2 Preferred Brand). Used for formulary compliance analysis and benefit design reporting.',
  ingested_timestamp TIMESTAMP COMMENT 'Timestamp when this claim record was first ingested into the Pillarrx lakehouse silver layer from the PBM claims feed. Used for ETL lineage, data freshness monitoring, and audit trail.',
  ingredient_cost DECIMAL(18,4) COMMENT 'The drug acquisition cost component of the claim as adjudicated by the PBM. Basis for AWP discount analysis, MAC pricing review, and PBM contract guarantee auditing.',
  mail_order_flag BOOLEAN COMMENT 'Indicates whether the prescription was dispensed through a mail-order pharmacy channel. Used for retail vs. mail-order utilization analysis and channel-specific cost benchmarking.',
  member_coinsurance DECIMAL(18,4) COMMENT 'Percentage-based cost-share amount paid by the member for this claim. Distinct from copay; used in benefit design analysis and member out-of-pocket (OOP) accumulation tracking.',
  member_copay DECIMAL(18,4) COMMENT 'Fixed dollar amount paid by the member at point of sale as their cost-share obligation. Used for member affordability analysis, copay assistance program (CAP) eligibility, and OOP tracking.',
  member_id BIGINT COMMENT 'Reference to the unified member record in the Member 360 master data. Links the claim to the patient who filled the prescription, enabling cross-PBM member analytics.',
  ncpdp_id STRING COMMENT 'Reference to the pharmacy dimension record keyed by NCPDP ID. Links the claim to the dispensing pharmacy for network, specialty, and chain/independent analysis.',
  ndc_code STRING COMMENT 'Add ndc_code STRING(13) column to claim.rx_claim as an NDC natural-key column for joins to drug.ndc and reference.fdb_drug. 1. Add ndc_code STRING(13) to claim.rx_claim - the central claims fact has no
   NDC column.',
  network_indicator STRING COMMENT 'Indicates whether the dispensing pharmacy was in-network or out-of-network at the time of the fill. Used for network compliance monitoring and out-of-network cost impact analysis.',
  oop_applied DECIMAL(18,4) COMMENT 'Dollar amount of this claim applied toward the member''s annual out-of-pocket maximum (MOOP). Used for member affordability intelligence and True Out-of-Pocket (TrOOP) tracking.',
  oop_remaining DECIMAL(18,4) COMMENT 'Member''s remaining out-of-pocket maximum balance after this claim. Sourced from PBM adjudication; used for member affordability intelligence and MOOP breach detection.',
  other_payer_amount DECIMAL(18,4) COMMENT 'Amount paid by a secondary payer (e.g., SPAP, copay card, manufacturer coupon, Medicare) on this claim. Used for coordination of benefits analysis and CAP program reconciliation.',
  paid_date DATE COMMENT 'The date the PBM adjudicated and paid the claim. Used for cash-flow analysis, DIR reconciliation timing, and PBM guarantee period attribution.',
  pbm_claim_number STRING COMMENT 'The externally-assigned claim identifier issued by the adjudicating PBM. Used as the primary business key for claim reconciliation, audit, and dispute resolution with the PBM.',
  pbm_division_id BIGINT COMMENT 'Foreign key linking to division.division. Business justification: Claims must be scoped to division for division-specific PBM guarantee calculations, consulting deliverables, and multi-division client reporting.',
  pbm_fk BIGINT COMMENT 'FK to claim.pbm.pbm_id — VREQ-001 requires every claim to tie to a PBM for source attribution and multi-PBM benchmarking. rx_claim description asserts the reference but it must be a guaranteed FK.',
  pbm_member_identifier STRING COMMENT 'The member identifier assigned by the adjudicating PBM on this claim. Preserved as-sourced to support Member 360 identity resolution and cross-PBM member matching.',
  plan_paid_amount DECIMAL(18,4) COMMENT 'The dollar amount paid by the health plan (employer) for this claim after member cost-share. Primary metric for employer pharmacy spend reporting, PMPM, and PBM audit.',
  prescriber_fk BIGINT COMMENT 'FK to claim.prescriber.prescriber_id — VREQ-001 requires each claim to tie to a prescribing provider by NPI; prescriber is the in-domain SSOT, so this is an in-domain FK.',
  prior_auth_number STRING COMMENT 'The prior authorization approval number associated with this claim, if applicable. Used to link claims to PA records for utilization management compliance and PA analytics.',
  quantity_dispensed DECIMAL(18,4) COMMENT 'The quantity of drug units dispensed in this fill (e.g., tablets, milliliters). Used for unit-cost analysis, quantity limit (QL) compliance review, and drug utilization review.',
  rx_claim_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for each pharmacy claim transaction record in the Pillarrx lakehouse silver layer. Serves as the primary key for the rx_claim fact entity.',
  rx_number STRING COMMENT 'The pharmacy-assigned prescription number for this fill. Used to link multiple fills and refills of the same prescription and to support pharmacy audit reconciliation.',
  rx_pbm_feed_batch_id BIGINT COMMENT 'Foreign key linking to claim.pbm_feed_batch. Business justification: Every rx_claim is ingested via a PBM feed batch. Strong traceability requirement for audit, data quality validation, and reconciliation.',
  source_pbm_feed_batch_id BIGINT COMMENT 'FK to claim.pbm_feed_batch.pbm_feed_batch_id — Data lineage: each claim arrives in an ingestion batch. Linking claim to its source batch enables feed-completeness gap detection and SLA traceability.',
  specialty_drug_flag BOOLEAN COMMENT 'Indicates whether the dispensed drug is classified as a specialty medication (SMN). Used for specialty pharmacy spend monitoring, trend reporting, and limited distribution drug (LDD) analysis.',
  to_benefit_group BIGINT COMMENT 'FK to claim.benefit_group.benefit_group_id — Every claim references a benefit group for cost-sharing rules; master FK required per VREQ-003 hierarchy scoping.',
  to_pbm BIGINT COMMENT 'FK to claim.pbm.pbm_id — Every claim ties to a source PBM; master FK required per VREQ-001 for source attribution and benchmarking.',
  to_prescriber BIGINT COMMENT 'FK to claim.prescriber.prescriber_id — Every claim ties to a prescribing provider (NPI); master FK required per VREQ-001.',
  total_cost DECIMAL(18,4) COMMENT 'Total gross cost of the claim (ingredient cost + dispensing fee + applicable fees). Represents the full pharmacy transaction value before any cost-share allocation. Used for TCOC analysis.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this claim record was last modified in the lakehouse (e.g., due to an adjustment or data correction). Used for change tracking, audit, and incremental processing.',
  CONSTRAINT pk_rx_claim PRIMARY KEY (rx_claim_id)
)
COMMENT 'Central fact entity for every pharmacy claim transaction ingested and normalized across all PBMs (CVS Caremark, Optum Rx, Express Scripts, Navitus, EmpiRx Health, BCBS Michigan, Rightway, Prime Therapeutics, ServeYou, Carelon), at the atomic'
;

CREATE TABLE IF NOT EXISTS pillarrx.claim.rx_claim_line (
  bin_number STRING COMMENT '6-digit BIN (RxBIN) used to route the pharmacy claim to the correct PBM processor at point of sale. Essential for PBM identification and claims routing audit.',
  compound_code STRING COMMENT 'NCPDP compound code indicating whether the dispensed drug is a compound (0=not compound, 1=not specified, 2=compound). Compounds require special pricing and audit treatment.',
  dos DATE COMMENT 'Date the prescription was dispensed to the member. The primary business event date for pharmacy claim analytics, trending, and PBM audit reconciliation.',
  ingested_timestamp TIMESTAMP COMMENT 'Timestamp when this claim line record was first ingested into the Pillarrx lakehouse from the source PBM feed. Supports ETL audit, data lineage, and SLA monitoring.',
  line_amount DECIMAL(18,4) COMMENT 'Total monetary value of this specific claim line (the principal line-level fact). Represents the gross amount for this cost component before member cost-share allocation.',
  line_number INT COMMENT 'Sequential line number within the parent pharmacy claim header. Used to order and identify individual cost components within a multi-line adjudication.',
  line_type STRING COMMENT 'Classifies the cost component this line represents within the claim adjudication. Supports decomposed pricing basis per line: ingredient cost, dispensing fee, sales tax, vaccine admin fee, or other.',
  maintenance_drug_flag BOOLEAN COMMENT 'Indicates whether the dispensed drug is classified as a maintenance medication (chronic/long-term therapy). Used for mail-order conversion opportunity analysis and adherence programs.',
  other_amount DECIMAL(18,4) COMMENT 'Catch-all amount field for any additional cost components on this claim line not captured by ingredient cost, dispensing fee, sales tax, or vaccine admin fee.',
  paid_date DATE COMMENT 'Date the claim line was adjudicated and payment was processed by the PBM. May differ from date of service; used for cash-basis financial reporting and PBM guarantee reconciliation.',
  pbm_claim_number STRING COMMENT 'Externally-assigned claim identifier from the source PBM (CVS Caremark, Optum Rx, Express Scripts, etc.). Used for PBM audit reconciliation and cross-source claim matching.',
  pbm_source STRING COMMENT 'Name of the source PBM from which this claim line was ingested. Supports multi-PBM normalization and cross-PBM benchmarking. [ENUM-REF-CANDIDATE',
  pcn STRING COMMENT 'Processor Control Number (RxPCN) used alongside BIN to route pharmacy claims to the correct PBM plan or benefit group. Supports multi-PBM claims normalization.',
  primary_rx_claim_id BIGINT COMMENT 'Foreign key reference to the parent pharmacy claim header (rx_claim) that this line belongs to. Supports multi-line adjudication.',
  prior_auth_number STRING COMMENT 'Prior authorization approval number associated with this claim line when the drug required PA. Links to prior authorization analytics for utilization management reporting.',
  refill_authorized INT COMMENT 'Number of refills authorized by the prescriber on the original prescription. Used for adherence monitoring and prescription lifecycle management.',
  rx_claim_line_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for each pharmacy claim line record in the Pillarrx lakehouse silver layer.',
  rx_group STRING COMMENT 'Pharmacy benefit group identifier transmitted on the claim, identifying the employer plan group under which the claim was adjudicated. Maps to client benefit group hierarchy.',
  sales_tax DECIMAL(18,4) COMMENT 'Sales tax applied to this claim line where applicable by state law. Tracked separately for financial reconciliation and state tax compliance reporting.',
  specialty_drug_flag BOOLEAN COMMENT 'Indicates whether the dispensed drug is classified as a specialty medication (SMN). Specialty drugs require separate spend monitoring, trend reporting, and PBM channel management.',
  to_rx_claim_id BIGINT COMMENT 'FK to claim.rx_claim.rx_claim_id — Line-level pricing decomposition must FK to its parent header so line sums can reconcile to header rollup totals; asserted in prose only across 5 iterations.',
  transaction_type STRING COMMENT 'Identifies the nature of the claim transaction at the individual grain: a new fill (dispensing event), a reversal (cancellation), or an adjustment (correction to a prior claim).',
  vaccine_admin_fee DECIMAL(18,4) COMMENT 'Fee charged for vaccine administration services when the dispensed drug is a vaccine. Tracked as a distinct line component per NCPDP adjudication standards.',
  CONSTRAINT pk_rx_claim_line PRIMARY KEY (rx_claim_line_id)
)
COMMENT 'Line-level pricing and cost-component breakdown of a pharmacy claim, supporting multi-line adjudication and COB scenarios. Owns the DECOMPOSED pricing basis per line: ingredient cost, dispensing fee, sales tax, vaccine administration fee, other amounts'
;

-- ---------------------------------------------------------------------------
-- Schema: client
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS pillarrx.client.audit_finding (
  analysis_period_end_date DATE COMMENT 'End date of the claims or contract period analyzed to identify this finding.',
  analysis_period_start_date DATE COMMENT 'Start date of the claims or contract period analyzed to identify this finding. Defines the lookback window for the specific finding.',
  analyst_notes STRING COMMENT 'Internal PillarRx analyst commentary on the finding, including methodology notes, escalation rationale, or follow-up actions required.',
  assigned_analyst STRING COMMENT 'Name of the PillarRx analyst responsible for investigating and managing this audit finding through to resolution.',
  audit_client_consulting_engagement_id BIGINT COMMENT 'Reference to the consulting engagement under which this audit finding was identified. Links the finding to its parent audit scope.',
  audit_finding_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for each individual audit finding record within a PBM audit engagement.',
  audit_pbm_contract_id BIGINT COMMENT 'Foreign key linking to client.pbm_contract. Business justification: Audit findings are identified by comparing actual PBM performance against contractual terms. The finding references the specific contract being audited.',
  audit_type STRING COMMENT 'The type of PBM audit that produced this finding. [ENUM-REF-CANDIDATE: pricing|rebate|dispensing_fee|mac|dir|eligibility|formulary|comprehensive — promote to reference product]',
  awp_discount_actual_pct DECIMAL(8,4) COMMENT 'The actual AWP discount percentage applied by the PBM on the claims under review. Compared against the contracted rate to quantify pricing discrepancy.',
  awp_discount_contracted_pct DECIMAL(8,4) COMMENT 'The AWP discount percentage guaranteed in the PBM contract for the drug category in question. Used as the benchmark in pricing discrepancy findings.',
  claim_count INT COMMENT 'Number of individual pharmacy claims affected by this audit finding within the analysis period. Used to assess the breadth of the discrepancy.',
  client_engagement_deliverable_id BIGINT COMMENT 'Reference to the consulting deliverable (audit report) in which this finding was formally communicated to the client.',
  client_pbm_contract_id BIGINT COMMENT 'Foreign key linking to company.client_pbm_contract. Business justification: Audit findings validate PBM performance against contracted terms. client.pbm_contract is client-side operational view; company.client_pbm_contract is authoritative contract master',
  contract_provision_reference STRING COMMENT 'Specific section, clause, or exhibit of the PBM contract that was violated or not honored, as cited in the audit finding.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this audit finding record was first created in the system. Supports audit trail and record lineage tracking.',
  currency_code STRING COMMENT 'ISO 4217 three-letter currency code for all monetary amounts on this finding. Defaults to USD for domestic employer plans.',
  dispensing_channel STRING COMMENT 'The pharmacy dispensing channel (retail, mail order, specialty) to which this finding applies. Determines applicable contracted rates and guarantees.',
  dispensing_fee_actual DECIMAL(8,2) COMMENT 'The actual dispensing fee per claim charged by the PBM on the claims under review. Compared against the contracted fee to identify dispensing fee variance.',
  dispensing_fee_contracted DECIMAL(8,2) COMMENT 'The dispensing fee per claim guaranteed in the PBM contract for the applicable channel (retail, mail, specialty). Benchmark for dispensing fee variance findings.',
  disputed_amount DECIMAL(18,2) COMMENT 'Portion of the estimated impact amount that the PBM formally disputes. Represents the difference between estimated and acknowledged amounts under active contention.',
  drug_category STRING COMMENT 'Drug category applicable to this finding (brand, generic, specialty, biosimilar). Determines which contracted pricing tier or guarantee applies.',
  employer_id BIGINT COMMENT 'Reference to the employer client on whose behalf the PBM audit was conducted. Scopes the finding to the multi-tenant hierarchy.',
  estimated_impact_amount DECIMAL(18,2) COMMENT 'PillarRx-calculated estimated total dollar amount of the discrepancy or shortfall identified in the finding, prior to PBM acknowledgment.',
  finding_client_consulting_engagement_id BIGINT COMMENT 'FK to client.client_consulting_engagement.client_consulting_engagement_id — audit_finding is produced during a ''PBM audit engagement''. Findings must roll up to the parent consulting engagement for deliverable tracking, billing reconciliation, and SLA',
  finding_description STRING COMMENT 'Detailed narrative describing the nature of the discrepancy, the methodology used to identify it, and the specific contract or pricing provision violated.',
  finding_number STRING COMMENT 'Human-readable, externally referenceable identifier for the finding (e.g., AF-2024-000123). Used in client-facing audit reports and correspondence.',
  finding_status STRING COMMENT 'Current lifecycle state of the audit finding, tracking progression from identification through resolution or waiver by the client or PBM.',
  finding_title STRING COMMENT 'Short, descriptive title summarizing the nature of the audit finding as it appears in client-facing audit reports and deliverables.',
  finding_type STRING COMMENT 'Category of the audit finding. [ENUM-REF-CANDIDATE: pricing_discrepancy|rebate_shortfall|dispensing_fee_variance|mac_pricing_error|dir_fee_anomaly|eligibility_error|formulary_violation|other — promote to reference product]',
  identified_date DATE COMMENT 'Calendar date on which the audit finding was first identified by the PillarRx analyst during claims or contract review.',
  is_disputed BOOLEAN COMMENT 'Indicates whether the PBM has formally disputed this audit finding. True when the PBM contests the finding methodology or calculated impact amount.',
  is_recoverable BOOLEAN COMMENT 'Indicates whether the financial impact of this finding is recoverable from the PBM under the terms of the contract. False for findings that are informational only.',
  member_count INT COMMENT 'Number of distinct plan members whose claims are affected by this audit finding. Supports member-level impact assessment.',
  ncpdp_id STRING COMMENT '7-digit NCPDP identifier of the dispensing pharmacy involved in the finding, when the finding is attributable to a specific pharmacy.',
  ndc_code STRING COMMENT '11-digit National Drug Code of the specific drug involved in the finding, when the finding is attributable to a single NDC or drug product.',
  pbm_acknowledged_amount DECIMAL(18,2) COMMENT 'Dollar amount the PBM formally acknowledged as a valid discrepancy. May differ from the estimated impact amount due to PBM dispute or methodology differences.',
  pbm_assignment_id BIGINT COMMENT 'Reference to the specific PBM assignment being audited (e.g., CVS Caremark, Optum Rx, Express Scripts). Identifies which PBM contract the finding applies to.',
  pbm_contract_id BIGINT COMMENT 'FK to client.pbm_contract.pbm_contract_id — audit_finding stores ''expected value per contract terms'' vs ''actual value billed''. The contract baseline lives in pbm_contract (AWP guarantees, GER/BER, DIR, fee schedules). Without this FK the varian',
  pbm_name STRING COMMENT 'Name of the PBM against which the audit finding was raised (e.g., CVS Caremark, Optum Rx, Express Scripts). Denormalized for reporting convenience.',
  pbm_response_date DATE COMMENT 'Date on which the PBM provided a formal response to the audit finding, either acknowledging, disputing, or proposing resolution.',
  pbm_response_notes STRING COMMENT 'Free-text notes capturing the PBM''s formal response, rationale for dispute, or explanation of the discrepancy as communicated to PillarRx.',
  rebate_actual_amount DECIMAL(18,2) COMMENT 'The actual rebate amount passed through by the PBM for the claims in scope. Compared against the guarantee to quantify rebate shortfall.',
  rebate_guarantee_amount DECIMAL(18,2) COMMENT 'The contractually guaranteed rebate amount (per claim or aggregate) applicable to this finding. Used as the benchmark in rebate shortfall findings.',
  recovered_amount DECIMAL(18,2) COMMENT 'Actual dollar amount recovered or credited to the client as a result of this audit finding, following PBM remediation or settlement.',
  resolved_date DATE COMMENT 'Date the audit finding was fully resolved, including any financial recovery, contract correction, or formal closure agreed upon by all parties.',
  severity STRING COMMENT 'Risk-based severity rating assigned to the finding, indicating the urgency and financial or compliance impact level for prioritization.',
  submitted_to_pbm_date DATE COMMENT 'Date the audit finding was formally submitted to the PBM for review, acknowledgment, or remediation.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp of the most recent update to this audit finding record, capturing status changes, amount revisions, or analyst note additions.',
  CONSTRAINT pk_audit_finding PRIMARY KEY (audit_finding_id)
)
COMMENT 'Records individual findings identified during a PBM audit engagement conducted by PillarRx on behalf of an employer client. Captures finding type (pricing discrepancy, rebate shortfall, dispensing fee variance, MAC pricing error, DIR fee anomaly'
;

CREATE TABLE IF NOT EXISTS pillarrx.client.benefit_plan (
  accumulator_adjustment_program BOOLEAN COMMENT 'Indicates whether this plan uses an accumulator adjustment program that prevents manufacturer copay assistance from counting toward the member''s deductible or OOP maximum.',
  benefit_employer_id BIGINT COMMENT 'Reference to the employer client that sponsors this pharmacy benefit plan within the Company > Division > Client hierarchy.',
  benefit_pbm_assignment_id BIGINT COMMENT 'FK to client.pbm_assignment.pbm_assignment_id — benefit_plan description states it carries an associated PBM; the PBM relationship is owned by pbm_assignment. Links plan design to the adjudicating PBM.',
  benefit_plan_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the pharmacy benefit plan record within the PillarRx data platform.',
  brand_penalty_amount DECIMAL(8,2) COMMENT 'Additional dollar amount charged to the member when a brand drug is dispensed and a generic equivalent is available, per the plan''s DAW policy. Null if no penalty applies.',
  cap_eligible BOOLEAN COMMENT 'Indicates whether members enrolled in this benefit plan are eligible to participate in PillarRx-managed copay assistance programs (CAP) via the PAX application.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM (e.g., CVS Caremark, Optum Rx, Express Scripts) contracted to administer this benefit plan on behalf of the employer client.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this benefit plan record was first created in the PillarRx data platform. Used for audit trail and data lineage tracking.',
  daw_policy STRING COMMENT 'Plan-level policy governing how DAW codes are handled. Determines whether members pay a brand penalty when a generic equivalent is available and the prescriber or member requests brand.',
  division_formulary_id BIGINT COMMENT 'Reference to the formulary (covered drug list) associated with this benefit plan. Determines which drugs are covered and at which tier cost-sharing level.',
  effective_date DATE COMMENT 'Date on which this benefit plan design becomes active and members are eligible to receive benefits under its terms. Aligns with the plan year start.',
  employer_id BIGINT COMMENT 'FK to client.employer.employer_id — duplicate-safe reassertion of employer scoping for plan design.',
  family_deductible_amount DECIMAL(10,2) COMMENT 'Aggregate dollar amount a family unit must pay out-of-pocket for covered pharmacy benefits before the plan begins to pay on behalf of any family member.',
  family_oop_max DECIMAL(10,2) COMMENT 'Maximum aggregate dollar amount a family unit pays out-of-pocket for covered pharmacy benefits in a plan year before the plan pays 100% of covered costs.',
  individual_deductible_amount DECIMAL(10,2) COMMENT 'Dollar amount an individual member must pay out-of-pocket for covered pharmacy benefits before the plan begins to pay. Zero for plans with no deductible.',
  individual_oop_max DECIMAL(10,2) COMMENT 'Maximum dollar amount an individual member pays out-of-pocket for covered pharmacy benefits in a plan year. After this limit, the plan pays 100% of covered costs.',
  mail_days_supply_limit INT COMMENT 'Maximum days supply allowed per fill at a mail order pharmacy under this plan (e.g., 90 days). Standard mail order supply is 90 days for maintenance medications.',
  mail_order_required_days INT COMMENT 'Minimum days supply threshold at which the plan mandates or incentivizes mail order dispensing (e.g., 90). Claims above this threshold at retail may incur higher cost-sharing.',
  pa_required BOOLEAN COMMENT 'Indicates whether this benefit plan enforces prior authorization requirements for any drug classes. True = PA program is active; individual drug PA rules are in the formulary.',
  pbm_assignment_id BIGINT COMMENT 'FK to client.pbm_assignment.pbm_assignment_id — benefit_plan is ''Linked to the administering PBM (via pbm_assignment)''; realize the stated link as a physical FK.',
  plan_code STRING COMMENT 'Externally-known alphanumeric code that uniquely identifies this benefit plan within the client''s plan portfolio. Used in eligibility feeds and PBM routing.',
  plan_description STRING COMMENT 'Free-text description of the benefit plan design, including notable features, restrictions, or consulting notes relevant to PillarRx audit and benchmarking analysis.',
  plan_employer_id BIGINT COMMENT 'FK to client.employer.employer_id — A benefit plan is offered by an employer client to its covered members; must resolve to a parent employer.',
  plan_name STRING COMMENT 'Human-readable name of the pharmacy benefit plan as presented to members and used in client reporting (e.g., ''Standard Rx Plan 2024'', ''High Deductible Rx Option'').',
  plan_status STRING COMMENT 'Current lifecycle state of the benefit plan. Controls whether new eligibility enrollments and claims can be processed against this plan.',
  plan_type STRING COMMENT 'Classification of the pharmacy benefit plan by coverage category. Drives regulatory reporting obligations and cost-sharing rules. [ENUM-REF-CANDIDATE: commercial|medicare_part_d|medicaid|retiree|cobra|hdhp|other — promote to reference product]',
  plan_year INT COMMENT 'The calendar or fiscal year (e.g., 2024) for which this benefit plan design is effective. Used to scope claims analysis, benchmarking, and audit deliverables.',
  quantity_limit_enforced BOOLEAN COMMENT 'Indicates whether quantity limits are enforced at adjudication for this benefit plan. True = quantity limit edits are active; limits are defined at the drug/formulary level.',
  retail_days_supply_limit INT COMMENT 'Maximum days supply allowed per fill at a retail pharmacy under this plan (e.g., 30 or 34 days). Fills exceeding this limit may be rejected at adjudication.',
  rx_bin STRING COMMENT 'Six-digit Bank Identification Number used to route real-time pharmacy claims to the correct PBM processor. Required on the member''s prescription drug card.',
  rx_group STRING COMMENT 'RxGroup identifier used by the PBM to route pharmacy claims to the correct benefit plan. Printed on the member''s prescription drug card alongside BIN and PCN.',
  rx_pcn STRING COMMENT 'Processor Control Number used in conjunction with BIN to further route pharmacy claims to the correct plan within the PBM''s adjudication system.',
  specialty_coinsurance_pct DECIMAL(5,2) COMMENT 'Member coinsurance percentage applied to specialty drug claims (e.g., 20.00 = 20%). Used when specialty tier cost-sharing is coinsurance-based rather than a fixed copay.',
  specialty_oop_max DECIMAL(10,2) COMMENT 'Maximum annual out-of-pocket amount a member pays for specialty drugs under this plan. Provides a cap on specialty cost exposure for high-cost medication users.',
  specialty_pharmacy_required BOOLEAN COMMENT 'Indicates whether specialty drugs under this plan must be dispensed through a designated specialty pharmacy network. True = specialty pharmacy mandatory for specialty drug fills.',
  step_therapy_required BOOLEAN COMMENT 'Indicates whether this benefit plan enforces step therapy protocols requiring members to try lower-cost alternatives before higher-cost drugs are covered.',
  termination_date DATE COMMENT 'Date on which this benefit plan design expires or is terminated. Null for open-ended plans. Claims with a date of service after this date are not covered.',
  tier1_copay_mail DECIMAL(8,2) COMMENT 'Fixed member copay dollar amount for Tier 1 (generic) drugs dispensed via mail order pharmacy. Typically lower than retail to incentivize mail order utilization.',
  tier1_copay_retail DECIMAL(8,2) COMMENT 'Fixed member copay dollar amount for Tier 1 (typically generic) drugs dispensed at a retail pharmacy. Core cost-sharing parameter used in member benefit communications.',
  tier2_copay_mail DECIMAL(8,2) COMMENT 'Fixed member copay dollar amount for Tier 2 (preferred brand) drugs dispensed via mail order pharmacy.',
  tier2_copay_retail DECIMAL(8,2) COMMENT 'Fixed member copay dollar amount for Tier 2 (typically preferred brand) drugs dispensed at a retail pharmacy.',
  tier3_copay_mail DECIMAL(8,2) COMMENT 'Fixed member copay dollar amount for Tier 3 (non-preferred brand) drugs dispensed via mail order pharmacy.',
  tier3_copay_retail DECIMAL(8,2) COMMENT 'Fixed member copay dollar amount for Tier 3 (typically non-preferred brand) drugs dispensed at a retail pharmacy.',
  tier4_copay_retail DECIMAL(8,2) COMMENT 'Fixed member copay dollar amount for Tier 4 (typically specialty) drugs dispensed at a retail pharmacy. May be null if specialty is handled via coinsurance.',
  tier_count INT COMMENT 'Number of formulary tiers defined in this benefit plan''s cost-sharing structure (e.g., 3-tier: generic/preferred brand/non-preferred brand, or 4-tier including specialty).',
  troop_accumulator BOOLEAN COMMENT 'Indicates whether copay assistance payments (manufacturer coupons, CAP) accumulate toward the member''s True Out-of-Pocket (TrOOP) limit. Relevant for Medicare Part D plans.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this benefit plan record was last modified in the PillarRx data platform. Supports change detection and Silver layer incremental processing.',
  CONSTRAINT pk_benefit_plan PRIMARY KEY (benefit_plan_id)
)
COMMENT 'Defines the pharmacy benefit plan design offered by an employer client to its covered members. Captures plan year, formulary tier structure, deductible amounts, OOP and MOOP limits, copay and coinsurance schedules by tier, DAW policy, and specialty drug'
;

CREATE TABLE IF NOT EXISTS pillarrx.client.cap_program_enrollment (
  accumulator_adjustment_flag BOOLEAN COMMENT 'Indicates whether the employer plan applies an accumulator adjustment program (AAP) that prevents CAP assistance from counting toward the member''s deductible or OOP.',
  annual_benefit_max DECIMAL(12,2) COMMENT 'Maximum dollar amount of copay assistance the member may receive from this program within a plan year. Null if no annual cap is defined by the sponsor.',
  annual_benefit_remaining DECIMAL(12,2) COMMENT 'Remaining dollar amount of copay assistance available to the member for the current plan year (annual_benefit_max minus annual_benefit_used). Null if no annual cap.',
  annual_benefit_used DECIMAL(12,2) COMMENT 'Cumulative dollar amount of copay assistance applied to the member''s claims under this program in the current plan year. Updated as claims are reconciled in PAX.',
  benefit_plan_id BIGINT COMMENT 'Identifier of the employer benefit plan under which this CAP enrollment is scoped. Determines cost-sharing rules and accumulator behavior.',
  bin_number STRING COMMENT '6-digit BIN (RxBIN) on the copay card used to route the CAP claim at the pharmacy point of sale. Required for copay card program types.',
  cap_employer_id BIGINT COMMENT 'Identifier of the employer client whose benefit plan members are enrolled in this copay assistance program. Links to the client domain.',
  cap_enrollment_benefit_group_fk BIGINT COMMENT 'FK to client.benefit_group.benefit_group_id — CAP eligibility is scoped to eligible benefit group(s); required to target enrolled populations.',
  cap_program_enrollment_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for a CAP program enrollment record in the PAX application. Primary key for this entity.',
  client_consulting_engagement_id BIGINT COMMENT 'FK to client.client_consulting_engagement.client_consulting_engagement_id — CAP management is delivered under a consulting engagement; FK ties the enrollment to the engagement that bills for it.',
  consent_on_file_flag BOOLEAN COMMENT 'Indicates whether the member''s signed consent or authorization for CAP program participation and data sharing is on file in PAX, as required by HIPAA.',
  copay_card_number STRING COMMENT 'Unique identifier of the physical or virtual copay assistance card issued to the member for this program. Used for card tracking and reconciliation in PAX.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this CAP enrollment record was first created in the PAX application or the data lakehouse. ISO 8601 format with timezone offset.',
  drug_name STRING COMMENT 'Brand or generic name of the drug covered by this copay assistance enrollment, as recorded at time of enrollment for audit and reporting purposes.',
  effective_date DATE COMMENT 'Date on which the member''s CAP enrollment becomes active and copay assistance benefits may be applied to eligible claims.',
  enrolled_by STRING COMMENT 'Name or identifier of the PillarRx staff member, hub representative, or system process that initiated the CAP enrollment in PAX.',
  enrollment_channel STRING COMMENT 'Channel through which the member was enrolled in the CAP program (e.g., PAX portal, phone, hub services). Used for operational and engagement analytics.',
  enrollment_date DATE COMMENT 'Calendar date on which the member was enrolled in the CAP program. Represents the business event date, distinct from the record audit timestamp.',
  enrollment_status STRING COMMENT 'Current lifecycle state of the member''s enrollment in the copay assistance program within PAX.',
  hub_name STRING COMMENT 'Name of the manufacturer patient services hub (e.g., Lilly Cares, Pfizer RxPathways) associated with this CAP program, if applicable.',
  income_verification_required_flag BOOLEAN COMMENT 'Indicates whether the manufacturer program requires income verification or financial need attestation as a condition of CAP enrollment eligibility.',
  income_verified_flag BOOLEAN COMMENT 'Indicates whether income verification has been completed and confirmed for this member''s CAP enrollment, when required by the program.',
  limited_distribution_flag BOOLEAN COMMENT 'Indicates whether the drug is a Limited Distribution Drug (LDD), available only through select specialty pharmacies, affecting where the CAP benefit can be applied.',
  manufacturer_enrollment_code STRING COMMENT 'Enrollment identifier assigned by the manufacturer or their hub for this member''s participation in the copay assistance program. Used for cross-system reconciliation.',
  member_id BIGINT COMMENT 'Identifier of the member (patient) enrolled in this CAP program. Ties the enrollment to the Member 360 golden record.',
  member_id_on_card STRING COMMENT 'Member identifier printed on or associated with the copay assistance card issued to the member. May differ from the internal member_id. PHI/PII per HIPAA.',
  ndc_code STRING COMMENT '11-digit FDA National Drug Code identifying the specific drug covered by this CAP enrollment. Ties the enrollment to the drug reference dimension.',
  notes STRING COMMENT 'Free-text notes entered by PillarRx staff regarding this CAP enrollment, such as special handling instructions, escalation context, or program-specific conditions.',
  pa_approval_number STRING COMMENT 'Authorization number issued by the PBM or plan approving the drug for coverage, required for CAP benefit application when prior_auth_required_flag is true.',
  pax_enrollment_number STRING COMMENT 'External-facing enrollment reference number assigned by the PAX application. Used for member communications, hub coordination, and manufacturer reconciliation.',
  pcn STRING COMMENT 'Processor Control Number (RxPCN) on the copay card used alongside BIN for pharmacy claim routing for this CAP program.',
  per_fill_benefit_max DECIMAL(10,2) COMMENT 'Maximum dollar amount of copay assistance the member may receive per prescription fill under this program. Null if no per-fill cap is defined.',
  plan_year INT COMMENT 'Four-digit calendar year of the employer benefit plan year to which this CAP enrollment and its benefit accumulators apply (e.g., 2024).',
  primary_employer_id BIGINT COMMENT 'FK to client.employer.employer_id — CAP enrollment is scoped to an employer client population; must resolve to its parent employer.',
  prior_auth_required_flag BOOLEAN COMMENT 'Indicates whether a prior authorization (PA) is required by the plan or manufacturer program before CAP benefits can be applied for this enrollment.',
  program_code STRING COMMENT 'Short alphanumeric code uniquely identifying the CAP program within the PAX application. Used for reporting and cross-reference.',
  program_name STRING COMMENT 'Human-readable name of the copay assistance program as defined by the manufacturer or sponsor (e.g., ''Humira Complete Savings Card'').',
  program_sponsor_name STRING COMMENT 'Name of the manufacturer or organization sponsoring the copay assistance program (e.g., AbbVie, Pfizer, Janssen). Used for manufacturer program management reporting.',
  program_type STRING COMMENT 'Classification of the copay assistance mechanism. Determines how the benefit is applied and reconciled. [ENUM-REF-CANDIDATE: copay_card|coupon|rebate|patient_assistance|foundation_grant — promote to reference product]',
  rx_group STRING COMMENT 'Group identifier on the copay card used for pharmacy claim routing and benefit identification for this CAP program.',
  specialty_drug_flag BOOLEAN COMMENT 'Indicates whether the drug covered by this CAP enrollment is classified as a specialty medication (SMN), which may affect program eligibility and benefit limits.',
  termination_date DATE COMMENT 'Date on which the member''s CAP enrollment ends. Null for open-ended enrollments. May be set by program expiry, member disenrollment, or plan year end.',
  termination_reason STRING COMMENT 'Reason code explaining why the CAP enrollment was terminated. Populated when termination_date is set. [ENUM-REF-CANDIDATE: plan_year_end|member_disenrolled|benefit_exhausted|drug_discontinued|program_ended|member_request — promote to reference product]',
  troop_eligible_flag BOOLEAN COMMENT 'Indicates whether copay assistance amounts under this enrollment count toward the member''s True Out-of-Pocket (TrOOP) for Medicare Part D purposes.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp of the most recent update to this CAP enrollment record. Used for change tracking, incremental ETL processing, and audit trail compliance.',
  CONSTRAINT pk_cap_program_enrollment PRIMARY KEY (cap_program_enrollment_id)
)
COMMENT 'Records an employer client''s enrollment and eligibility configuration for a copay-assistance program (CAP) managed through PillarRx''s PAX application. Captures the program name/sponsor, enrollment effective and termination dates, eligible'
;

CREATE TABLE IF NOT EXISTS pillarrx.client.client_benefit_group (
  accumulator_adjustment_program BOOLEAN COMMENT 'Indicates whether this benefit group participates in an accumulator adjustment program, preventing manufacturer copay card payments from counting toward the member''s deductible or OOP max.',
  benefit_plan_id BIGINT COMMENT 'Reference to the parent pharmacy benefit plan under which this benefit group is defined. A plan may contain multiple benefit groups segmenting the member population.',
  bg_code STRING COMMENT 'The PBM-assigned or client-assigned alphanumeric code identifying this benefit group. Used in eligibility feeds and claim routing. Maps to the RxGroup or BG code in PBM systems.',
  bg_description STRING COMMENT 'Detailed narrative description of the benefit group''s purpose, eligibility criteria, or population segment. Supports consulting documentation and client onboarding context.',
  bg_name STRING COMMENT 'Human-readable name for the benefit group as defined by the client or PBM (e.g., ''Active Employees'', ''Retirees'', ''COBRA'', ''Part-Time''). Used in reporting and member eligibility displays.',
  bg_status STRING COMMENT 'Current lifecycle status of the benefit group. Controls whether members can be enrolled and claims can be adjudicated against this group.',
  bg_type STRING COMMENT 'Classification of the member population segment this benefit group covers. Drives cost-sharing rules and formulary assignment. [ENUM-REF-CANDIDATE: active_employee|retiree|cobra|dependent|part_time|medicare|medicaid|other — promote to reference product]',
  brand_penalty_amount DECIMAL(8,2) COMMENT 'Additional member cost-share applied when a brand drug is dispensed and a generic equivalent is available, per the DAW policy. Used in generic substitution savings analysis.',
  cap_eligible BOOLEAN COMMENT 'Indicates whether members in this benefit group are eligible to participate in copay assistance programs (CAP) managed via the PAX application. Drives CAP enrollment eligibility logic.',
  client_benefit_group_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for a benefit group record within a client''s pharmacy benefit plan. Primary key for the client_benefit_group entity.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM administering this benefit group. Enables multi-PBM scoping where a client may have different benefit groups serviced by different PBMs.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this benefit group record was first created in the PillarRx data platform. Supports audit trail and data lineage tracking.',
  daw_policy STRING COMMENT 'The benefit group''s policy governing brand vs. generic dispensing. Controls whether a brand penalty applies when a generic equivalent is available. Drives GDR analysis.',
  division_formulary_id BIGINT COMMENT 'Identifier of the drug formulary (covered drug list) assigned to this benefit group. Determines which drugs are covered, at what tier, and with what cost-sharing for members in this group.',
  effective_date DATE COMMENT 'The date on which this benefit group becomes active and members may begin using benefits. Aligns with the plan year start or mid-year enrollment event.',
  eligibility_feed_code STRING COMMENT 'The code used to identify this benefit group in inbound eligibility files from the client or PBM. Used during ETL normalization to map raw eligibility records to the correct benefit group.',
  employer_id BIGINT COMMENT 'Reference to the employer client that owns this benefit group. Scopes the benefit group within the Company > Division > Client hierarchy.',
  family_deductible_amount DECIMAL(12,2) COMMENT 'Annual aggregate deductible amount for a family unit before the plan begins paying pharmacy benefits. Applies when a subscriber and dependents are enrolled together under this benefit group.',
  family_oop_max DECIMAL(12,2) COMMENT 'Maximum annual out-of-pocket cost for a family unit under this benefit group. Aggregate cap across all covered family members. Used in MOOP and TrOOP analysis for consulting deliverables.',
  individual_deductible_amount DECIMAL(12,2) COMMENT 'Annual deductible amount an individual member must satisfy before the plan begins paying pharmacy benefits for this benefit group. Used in OOP accumulator tracking and audit analysis.',
  individual_oop_max DECIMAL(12,2) COMMENT 'Maximum annual out-of-pocket cost an individual member will pay for pharmacy benefits under this benefit group. After this limit is reached, the plan pays 100% of covered drug costs.',
  mac_list_id BIGINT COMMENT 'Foreign key linking to drug.mac_list. Business justification: Benefit groups may reference specific MAC lists for generic pricing configuration. Supports benefit design analysis, pricing validation, and multi-PBM benchmarking across client benefit',
  mail_days_supply_limit INT COMMENT 'Maximum days supply dispensed per fill via mail order pharmacy under this benefit group (e.g., 90 days). Used in mail order utilization and cost-efficiency analysis.',
  mail_order_required BOOLEAN COMMENT 'Indicates whether this benefit group mandates mail order dispensing for maintenance medications after a defined number of retail fills. Drives mail order compliance reporting.',
  pa_required BOOLEAN COMMENT 'Indicates whether prior authorization is required for certain drugs under this benefit group. Enables PA utilization analysis and audit of PA approval rates.',
  pbm_assignment_id BIGINT COMMENT 'Foreign key linking to client.pbm_assignment. Business justification: A client benefit group is scoped to a specific PBM assignment. The rx_group, rx_bin, and rx_pcn identifiers on client_benefit_group are PBM-specific routing codes that belong to the',
  pbm_bg_external_code STRING COMMENT 'The PBM''s own internal identifier for this benefit group as received in claims feeds or eligibility files. Enables reconciliation between PillarRx''s normalized BG record and the source PBM system.',
  plan_year INT COMMENT 'The four-digit calendar or fiscal plan year this benefit group is associated with (e.g., 2024). Used for annual deductible and out-of-pocket accumulator resets and year-over-year trend analysis.',
  quantity_limit_enforced BOOLEAN COMMENT 'Indicates whether quantity limits are enforced on drug dispensing for this benefit group. Drives QL exception and override analysis in PBM audit engagements.',
  retail_days_supply_limit INT COMMENT 'Maximum days supply dispensed per fill at a retail pharmacy under this benefit group (e.g., 30 days). Drives quantity limit enforcement and mail order mandate analysis.',
  specialty_coinsurance_pct DECIMAL(5,2) COMMENT 'Member coinsurance percentage applied to specialty drug claims under this benefit group (e.g., 20.00 = 20%). Used in specialty spend analysis and affordability intelligence reporting.',
  specialty_oop_max DECIMAL(12,2) COMMENT 'Annual out-of-pocket cap specific to specialty medications for members in this benefit group. Separate from the overall OOP max when the plan applies a specialty-specific limit.',
  specialty_pharmacy_required BOOLEAN COMMENT 'Indicates whether specialty medications must be dispensed through a designated specialty pharmacy network for this benefit group. Drives specialty channel compliance analysis.',
  step_therapy_required BOOLEAN COMMENT 'Indicates whether step therapy protocols are enforced for this benefit group, requiring members to try lower-cost alternatives before higher-cost drugs are covered.',
  termination_date DATE COMMENT 'The date on which this benefit group is no longer active. Null for open-ended groups. Used in eligibility validation and claims adjudication boundary checks.',
  tier1_copay_mail DECIMAL(8,2) COMMENT 'Fixed member copay for Tier 1 (generic) drugs dispensed via mail order pharmacy under this benefit group. Typically lower than retail to incentivize mail order utilization.',
  tier1_copay_retail DECIMAL(8,2) COMMENT 'Fixed member copay amount for Tier 1 (typically generic) drugs dispensed at a retail pharmacy under this benefit group. Core cost-sharing parameter for member OOP analysis.',
  tier2_copay_mail DECIMAL(8,2) COMMENT 'Fixed member copay for Tier 2 (preferred brand) drugs dispensed via mail order pharmacy under this benefit group.',
  tier2_copay_retail DECIMAL(8,2) COMMENT 'Fixed member copay amount for Tier 2 (typically preferred brand) drugs dispensed at a retail pharmacy under this benefit group.',
  tier3_copay_mail DECIMAL(8,2) COMMENT 'Fixed member copay for Tier 3 (non-preferred brand) drugs dispensed via mail order pharmacy under this benefit group.',
  tier3_copay_retail DECIMAL(8,2) COMMENT 'Fixed member copay amount for Tier 3 (typically non-preferred brand) drugs dispensed at a retail pharmacy under this benefit group.',
  tier4_copay_retail DECIMAL(8,2) COMMENT 'Fixed member copay amount for Tier 4 drugs (typically specialty or non-formulary) dispensed at a retail pharmacy under this benefit group. May be null if tier 4 uses coinsurance instead.',
  tier_count INT COMMENT 'Number of formulary cost-sharing tiers defined for this benefit group (e.g., 3 for generic/preferred brand/non-preferred, 4 for specialty tier). Drives copay and coinsurance structure analysis.',
  troop_accumulator BOOLEAN COMMENT 'Indicates whether this benefit group applies TrOOP accumulator logic, which excludes third-party copay assistance payments from counting toward the member''s OOP maximum.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this benefit group record was last modified in the PillarRx data platform. Used for change detection in downstream ETL processes and SCD Type-2 history management.',
  CONSTRAINT pk_client_benefit_group PRIMARY KEY (client_benefit_group_id)
)
COMMENT 'Defines a benefit group (BG) — the population-segmentation grain within an employer client''s pharmacy benefit, to which members and claims are scoped (VREQ-003).'
;

CREATE TABLE IF NOT EXISTS pillarrx.client.client_consulting_engagement (
  account_manager_name STRING COMMENT 'Full name of the PillarRx account manager responsible for the client relationship and commercial oversight of this engagement. Distinct from the lead consultant who manages delivery.',
  audit_type STRING COMMENT 'Specific audit methodology applied when engagement_type is ''pbm_audit''. Includes contract guarantee (GER/BER), DIR reconciliation, spread analysis, rebate audit, or MAC audit. Null for non-audit engagements.',
  billed_amount DECIMAL(18,2) COMMENT 'Cumulative consulting fees invoiced to the client against this engagement in USD as recorded in NetSuite. Compared to contract_value to track billing progress and revenue recognition.',
  claims_analysis_period_end DATE COMMENT 'End date of the pharmacy claims data window being analyzed in this engagement. Defines the Date of Service (DOS) upper bound for claims extraction and benchmarking.',
  claims_analysis_period_start DATE COMMENT 'Start date of the pharmacy claims data window being analyzed in this engagement. Defines the Date of Service (DOS) lower bound for claims extraction and benchmarking.',
  client_consulting_engagement_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for a consulting engagement record in the PillarRx enterprise data warehouse. Primary key for the client_consulting_engagement product.',
  client_contact_email STRING COMMENT 'Email address of the primary employer client contact for this engagement. Used for deliverable distribution and engagement correspondence. Classified as confidential PII.',
  client_contact_name STRING COMMENT 'Full name of the primary point of contact at the employer client organization for this engagement. Used for deliverable distribution and stakeholder communication.',
  client_employer_id BIGINT COMMENT 'Reference to the employer client (within the Company > Division > Client hierarchy) for whom this consulting engagement is being performed. Core scoping key for all analytics.',
  closed_date DATE COMMENT 'Date the engagement was formally closed (completed or cancelled) in Salesforce CRM. Distinct from end_date — reflects actual operational closure vs. contractual end.',
  contract_value DECIMAL(18,2) COMMENT 'Total contracted consulting fee value for the engagement in USD. Represents the gross billable amount agreed upon at engagement signing. Used for revenue forecasting and SOX reporting.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this consulting engagement record was first created in the enterprise data warehouse. Sourced from Salesforce CRM opportunity creation event. Used for audit and lineage.',
  currency_code STRING COMMENT 'ISO 4217 three-letter currency code for all monetary amounts on this engagement (e.g., USD). PillarRx operates primarily in USD; field supports multi-currency for future international clients.',
  data_onboarding_date DATE COMMENT 'Date on which client data onboarding was completed and claims feeds were validated as ready for analysis. Marks the operational readiness milestone for the engagement.',
  data_onboarding_status STRING COMMENT 'Current status of the client data onboarding process within the PBM Claims Feed Ingestion Platform. Tracks whether claims feeds have been configured, tested, and validated for this engagement.',
  deliverable_format STRING COMMENT 'Primary format in which consulting deliverables are produced and delivered to the client. Drives BI and Consulting Reporting Suite configuration and output templates.',
  delivery_frequency STRING COMMENT 'Cadence at which consulting deliverables or reports are produced and delivered to the client. Drives scheduling in the BI and Consulting Reporting Suite and billing cycle alignment.',
  employer_id BIGINT COMMENT 'FK to client.employer.employer_id — Each consulting engagement is scoped to an employer client; FK required for engagement-to-client attribution.',
  end_date DATE COMMENT 'The contractually agreed date on which the consulting engagement concludes. Nullable for open-ended engagements. Used for billing cutoff, deliverable scheduling, and renewal tracking.',
  engagement_code STRING COMMENT 'Short alphanumeric code uniquely identifying the engagement for internal reference, reporting, and billing. Assigned at engagement creation and used across PillarRx systems.',
  engagement_description STRING COMMENT 'Free-text narrative describing the scope, objectives, and key deliverables of the consulting engagement. Sourced from the Salesforce Opportunity description field. Used in client proposals and SOWs.',
  engagement_name STRING COMMENT 'Human-readable name or title of the consulting engagement as recorded in Salesforce CRM (e.g., ''Acme Corp 2024 PBM Audit''). Used in client-facing deliverables and reporting.',
  engagement_status STRING COMMENT 'Current lifecycle state of the consulting engagement. Controls workflow routing, billing eligibility, and reporting inclusion. Values: draft, active, on_hold, completed, cancelled.',
  engagement_type STRING COMMENT 'Classification of the consulting engagement by service type. Drives deliverable templates, billing rates, and analytics scope. [ENUM-REF-CANDIDATE: pbm_audit|benchmarking|trend_analysis|cap_management|formulary_review|tcoc_analysis|prior_auth_analysis —',
  fee_structure STRING COMMENT 'Billing model governing how PillarRx charges for this engagement. Drives invoicing logic in NetSuite. PMPM (Per Member Per Month) is common for ongoing CAP management engagements.',
  includes_cap_management BOOLEAN COMMENT 'Indicates whether this engagement includes Copay Assistance Program (CAP) management via the PAX application. When true, PAX enrollment and coupon reconciliation workflows are activated.',
  includes_formulary_review BOOLEAN COMMENT 'Indicates whether this engagement includes formulary tier analysis and drug coverage review using Medi-Span or FDB drug reference data. Drives formulary analytics scope.',
  includes_prior_auth_analysis BOOLEAN COMMENT 'Indicates whether this engagement includes Prior Authorization (PA) and Step Therapy (ST) analysis. When true, the Prior Authorization Analytics module is scoped for this client.',
  includes_tcoc BOOLEAN COMMENT 'Indicates whether this engagement includes integration of medical claims data for Total Cost of Care (TCOC) analysis. When true, the Medical Claims Integration feed is activated for this client.',
  is_renewal BOOLEAN COMMENT 'Indicates whether this engagement is a renewal of a prior engagement. When true, renewal_of_engagement_id should reference the predecessor record. Used for client retention and revenue trend analysis.',
  lead_consultant_name STRING COMMENT 'Full name of the PillarRx consultant who owns and is accountable for delivery of this engagement. Used for workload management, client communication, and performance reporting.',
  member_360_enabled BOOLEAN COMMENT 'Indicates whether the Member 360 cross-PBM identity resolution capability is activated for this engagement. When true, the MDM platform performs golden-record stewardship for the client''s members.',
  netsuite_project_code STRING COMMENT 'The NetSuite project or job record identifier used for consulting fee billing, GL posting, and AR tracking under Brown & Brown Finance. Links engagement to financial system of record.',
  pbm_scope STRING COMMENT 'Comma-separated list of PBM names in scope for this engagement (e.g., ''CVS Caremark, Optum Rx''). Defines which PBM data feeds are analyzed. Stored as free text due to multi-PBM combinations.',
  pmpm_rate DECIMAL(10,4) COMMENT 'The per-member-per-month consulting fee rate in USD applicable when fee_structure is ''pmpm''. Multiplied by eligible member count each month to derive the invoice amount.',
  priority_level STRING COMMENT 'Business priority assigned to this engagement by PillarRx management. Drives resource allocation, escalation thresholds, and delivery scheduling across the consulting portfolio.',
  renewal_of_engagement_id BIGINT COMMENT 'Self-referencing identifier pointing to the prior engagement that this record renews or extends. Enables engagement lineage tracking and year-over-year continuity analysis for recurring clients.',
  salesforce_opportunity_code STRING COMMENT 'The Salesforce CRM Opportunity record ID that originated or tracks this consulting engagement. Enables bi-directional traceability between the lakehouse and the CRM system of record.',
  scope_notes STRING COMMENT 'Supplemental free-text notes capturing scope inclusions, exclusions, assumptions, or constraints agreed upon with the client. Complements engagement_description with operational detail.',
  signed_date DATE COMMENT 'Date the consulting engagement agreement was formally executed (signed) by both PillarRx and the employer client. Marks the binding commitment point for revenue recognition.',
  start_date DATE COMMENT 'The contractually agreed date on which the consulting engagement becomes effective and work may commence. Used for SLA tracking, billing period calculation, and timeline reporting.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp of the most recent update to this consulting engagement record in the enterprise data warehouse. Tracks the last synchronization from Salesforce CRM or NetSuite source systems.',
  CONSTRAINT pk_client_consulting_engagement PRIMARY KEY (client_consulting_engagement_id)
)
COMMENT 'Represents a formal consulting engagement between PillarRx and an employer client, as managed in Salesforce CRM and billed through NetSuite. Captures engagement type (PBM audit, benchmarking, trend analysis, CAP management, formulary review, TCOC'
;

CREATE TABLE IF NOT EXISTS pillarrx.client.client_engagement_deliverable (
  analysis_period_end_date DATE COMMENT 'End date of the claims or data analysis window covered by this deliverable. Defines the upper bound of the measurement period.',
  analysis_period_start_date DATE COMMENT 'Start date of the claims or data analysis window covered by this deliverable (e.g., beginning of the measurement period for a PBM audit or trend report).',
  assigned_analyst STRING COMMENT 'Name of the PillarRx consulting analyst primarily responsible for producing this deliverable. Used for workload management and accountability tracking.',
  audit_finding_count INT COMMENT 'Number of discrete audit findings or exceptions identified in this deliverable. Applicable to PBM audit deliverable types; null for non-audit deliverables.',
  billable_hours DECIMAL(8,2) COMMENT 'Number of consulting hours billed to the client for producing this deliverable. Used for fee-based billing reconciliation in NetSuite.',
  billing_milestone_flag BOOLEAN COMMENT 'Indicates whether delivery or acceptance of this deliverable triggers a consulting fee billing milestone in NetSuite. Supports revenue recognition.',
  claims_record_count BIGINT COMMENT 'Total number of pharmacy claim records included in the analysis underlying this deliverable. Provides data volume context for audit and benchmarking.',
  client_accepted_date DATE COMMENT 'Date on which the client formally acknowledged or accepted the deliverable. Triggers billing milestone or consulting fee recognition in NetSuite.',
  client_consulting_engagement_id BIGINT COMMENT 'FK to client.client_consulting_engagement.client_consulting_engagement_id — Header->line relationship. Each deliverable is produced within exactly one consulting engagement; the description states ''Linked to the parent consulting engagement.'' Must be a',
  client_engagement_deliverable_description STRING COMMENT 'Narrative description of the deliverable scope, methodology, and key findings summary. Used for internal documentation and client-facing SOW alignment.',
  client_engagement_deliverable_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for a consulting deliverable produced within a client engagement. Primary key for this entity.',
  completed_date DATE COMMENT 'Actual date on which the deliverable was finalized and marked complete by the PillarRx consulting team prior to delivery.',
  confidentiality_level STRING COMMENT 'Data classification level assigned to this deliverable governing distribution and handling. Aligns with HIPAA PHI and PillarRx data governance policy.',
  contains_phi_flag BOOLEAN COMMENT 'Indicates whether this deliverable contains Protected Health Information as defined under HIPAA. Governs distribution controls and BAA requirements.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this deliverable record was first created in the system. Audit trail for record provenance.',
  data_refresh_date DATE COMMENT 'Date through which the underlying claims or eligibility data was refreshed for this deliverable. Indicates data currency and lag relative to analysis period end.',
  deliverable_format STRING COMMENT 'Format in which the deliverable is produced and delivered to the client (e.g., Excel workbook, PDF report, PowerPoint deck, interactive dashboard).',
  deliverable_number STRING COMMENT 'Externally-known business identifier for this deliverable, used in client communications, SOW references, and billing. Format: DEL-YYYY-NNNNNN.',
  deliverable_status STRING COMMENT 'Current lifecycle state of the deliverable from initial draft through client acceptance or cancellation.',
  deliverable_type STRING COMMENT 'Classification of the consulting deliverable by analytical category. [ENUM-REF-CANDIDATE: pbm_audit|benchmarking|trend_analysis|formulary_gap|cap_performance|prior_auth_analysis|tcoc_report|custom — promote to reference product]',
  delivered_date DATE COMMENT 'Date on which the deliverable was formally transmitted or presented to the client. Used for SLA compliance measurement and billing milestone tracking.',
  delivery_method STRING COMMENT 'Channel through which the deliverable is transmitted to the client (e.g., secure portal upload, email, live presentation, SFTP).',
  due_date DATE COMMENT 'Contractual or agreed-upon date by which the deliverable must be completed and delivered to the client per the engagement SOW.',
  employer_id BIGINT COMMENT 'Reference to the employer client for whom this deliverable was produced. Scopes the deliverable within the Company > Division > Client hierarchy.',
  estimated_savings_amount DECIMAL(14,2) COMMENT 'Dollar value of estimated client savings or recoveries identified in this deliverable (e.g., PBM audit recovery, formulary optimization savings). In USD.',
  fee_amount DECIMAL(12,2) COMMENT 'Consulting fee amount associated with this deliverable in USD. Represents the billable value tied to this specific output per the engagement SOW.',
  is_final_version BOOLEAN COMMENT 'Indicates whether this record represents the final approved version of the deliverable. False for draft or superseded versions.',
  member_count INT COMMENT 'Number of distinct plan members included in the analysis scope of this deliverable. Used for PMPM and PMPY metric context.',
  netsuite_invoice_code STRING COMMENT 'Reference to the NetSuite invoice record generated when this deliverable triggers a billing milestone. Supports AR reconciliation.',
  notes STRING COMMENT 'Free-text field for internal consulting team notes, caveats, or client communication context related to this deliverable. Not included in client-facing output.',
  pbm_scope STRING COMMENT 'Comma-delimited list of PBMs whose claims data is included in this deliverable (e.g., ''CVS Caremark, Optum Rx''). Drives data extraction scope for the analysis.',
  primary_client_consulting_engagement_id BIGINT COMMENT 'Reference to the parent consulting engagement under which this deliverable was produced. Links deliverable to its engagement context.',
  report_template_code STRING COMMENT 'Internal code identifying the standardized report template used to generate this deliverable. Links to the BI reporting suite template library.',
  requested_date DATE COMMENT 'Date on which the client or internal engagement team formally requested this deliverable. Used for SLA tracking and workload planning.',
  reviewed_by STRING COMMENT 'Name of the PillarRx senior consultant or manager who reviewed and approved this deliverable before client delivery. Quality control record.',
  revision_reason STRING COMMENT 'Narrative explanation for why a revised version was produced (e.g., data correction, client feedback, scope change). Populated only for version > 1.0.',
  salesforce_opportunity_code STRING COMMENT 'Identifier of the associated Salesforce CRM opportunity or engagement record. Enables cross-system traceability between the data warehouse and CRM.',
  sla_met_flag BOOLEAN COMMENT 'Indicates whether the deliverable was completed and delivered within the SLA target days. Supports consulting performance benchmarking.',
  sla_target_days INT COMMENT 'Number of business days from request date to delivery date as defined in the engagement SLA. Used to measure on-time delivery performance.',
  title STRING COMMENT 'Human-readable title of the consulting deliverable as presented to the client (e.g., ''Q3 2024 PBM Audit Report — CVS Caremark'').',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp of the most recent modification to this deliverable record. Supports change tracking and audit compliance.',
  version_number STRING COMMENT 'Version identifier for the deliverable (e.g., 1.0, 1.1, 2.0). Incremented when a revised version is produced following client feedback or data corrections.',
  CONSTRAINT pk_client_engagement_deliverable PRIMARY KEY (client_engagement_deliverable_id)
)
COMMENT 'Tracks individual consulting deliverables produced within a consulting engagement — such as PBM audit reports, benchmarking analyses, trend summaries, formulary gap analyses, and CAP performance reports.'
;

CREATE TABLE IF NOT EXISTS pillarrx.client.consulting_fee_invoice (
  adjustment_amount DECIMAL(18,2) COMMENT 'Dollar amount of any credits, discounts, or corrections applied to the gross invoice amount. Negative values represent credits; positive values represent surcharges.',
  billed_claim_count INT COMMENT 'Number of pharmacy claims processed during the billing period used as the basis for per-claim fee calculation. Sourced from the claims aggregation platform.',
  billed_member_count INT COMMENT 'Number of eligible members used as the basis for PMPM fee calculation during the billing period. Sourced from the eligibility management system.',
  billing_contact_email STRING COMMENT 'Email address of the client billing contact for invoice delivery. Sourced from the client contact record. Used for electronic invoice transmission and payment follow-up.',
  billing_contact_name STRING COMMENT 'Name of the client-side billing contact to whom this invoice is addressed. Used for invoice delivery and collections correspondence.',
  billing_frequency STRING COMMENT 'Frequency at which consulting fees are invoiced per the engagement contract. Determines the cadence of invoice generation and revenue recognition.',
  billing_period_end_date DATE COMMENT 'End date of the service period covered by this invoice. Together with billing_period_start_date, defines the performance obligation period for revenue recognition.',
  billing_period_start_date DATE COMMENT 'Start date of the service period covered by this invoice. Defines the claims or engagement activity window for which consulting fees are being charged.',
  client_consulting_engagement_id BIGINT COMMENT 'FK to client.client_consulting_engagement.client_consulting_engagement_id — consulting_fee_invoice is the SSOT for consulting revenue recognition and must reconcile billed fees against contracted engagement terms — requires a FK to the engagement.',
  client_engagement_deliverable_id BIGINT COMMENT 'Foreign key linking to client.client_engagement_deliverable. Business justification: Consulting fee invoices can be tied to specific deliverable milestones (billing_milestone_flag exists on deliverable table).',
  consulting_fee_invoice_id BIGINT NOT NULL COMMENT 'Unique surrogate key for the consulting fee invoice record in the PillarRx data lakehouse. Primary key for this entity.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this invoice record was first created in the PillarRx data lakehouse. Sourced from NetSuite feed ingestion. Used for audit trail and data lineage.',
  currency_code STRING COMMENT 'ISO 4217 three-letter currency code for all monetary amounts on this invoice. PillarRx operates primarily in USD; retained for multi-currency compliance.',
  dispute_flag BOOLEAN COMMENT 'Indicates whether the client has formally disputed this invoice. When true, triggers collections hold and escalation workflow in NetSuite.',
  dispute_reason STRING COMMENT 'Free-text description of the client''s stated reason for disputing the invoice. Null when dispute_flag is false. Used for collections resolution and engagement management.',
  due_date DATE COMMENT 'Date by which payment is due from the client per the consulting agreement payment terms. Used for AR aging, collections, and cash flow forecasting.',
  employer_id BIGINT COMMENT 'Reference to the employer client to whom this consulting fee invoice is issued. Links to the employer/client entity in the organizational hierarchy.',
  fee_type STRING COMMENT 'Classification of the consulting fee structure for this invoice. Drives how the invoice amount is calculated and reconciled against the engagement contract.',
  gl_account_code STRING COMMENT 'NetSuite GL account code to which this invoice''s revenue is posted. Used for financial reporting, SOX controls, and Brown & Brown parent company consolidation.',
  invoice_amount DECIMAL(18,2) COMMENT 'Gross consulting fee amount billed to the client before any adjustments or credits. Represents the base billable amount as stated on the invoice.',
  invoice_date DATE COMMENT 'The date the invoice was formally issued to the client. Represents the principal business event timestamp for this transaction. Used for revenue recognition and aging analysis.',
  invoice_description STRING COMMENT 'Free-text description of the consulting services rendered, as it appears on the client-facing invoice. Provides context for client billing inquiries and dispute resolution.',
  invoice_number STRING COMMENT 'Externally-facing invoice number as assigned by NetSuite / Brown & Brown Finance. Used for client billing correspondence, AR tracking, and payment matching.',
  invoice_sequence_number INT COMMENT 'Sequential invoice number within the engagement, indicating which billing cycle this invoice represents (e.g., invoice 3 of 12 for an annual engagement).',
  invoice_status STRING COMMENT 'Current lifecycle state of the consulting fee invoice. Drives AR workflow in NetSuite. [ENUM-REF-CANDIDATE: draft|issued|sent|paid|partially_paid|voided|disputed — promote to reference product]',
  is_renewal_invoice BOOLEAN COMMENT 'Indicates whether this invoice is associated with a renewed consulting engagement rather than an original engagement. Used for revenue trend and retention reporting.',
  net_amount DECIMAL(18,2) COMMENT 'Final net amount due from the client after applying all adjustments and credits. Equals invoice_amount plus adjustment_amount. Used for AR and cash application.',
  netsuite_invoice_code STRING COMMENT 'Internal record identifier assigned by NetSuite / Brown & Brown Finance for this invoice. Used for cross-system reconciliation between the data lakehouse and the financial system of record.',
  paid_amount DECIMAL(18,2) COMMENT 'Total amount received from the client against this invoice to date. Used to compute outstanding balance and determine if the invoice is fully or partially paid.',
  paid_date DATE COMMENT 'Date on which full or final payment was received from the client. Null if invoice is unpaid or partially paid. Used for DSO and cash flow reporting.',
  payment_method STRING COMMENT 'Method by which the client remitted payment for this invoice. Used for cash application, treasury reconciliation, and audit trail in NetSuite.',
  payment_terms STRING COMMENT 'Contractual payment terms governing when the client must remit payment. Sourced from the consulting engagement agreement and NetSuite customer record.',
  per_claim_rate DECIMAL(10,4) COMMENT 'The per-claim consulting fee rate applied when fee_type is ''per_claim''. Multiplied by the claim count in the billing period to derive invoice amount.',
  performance_metric_type STRING COMMENT 'Type of performance outcome metric used as the basis for performance-based fee calculation. Defines what was measured to determine the fee.',
  performance_metric_value DECIMAL(18,4) COMMENT 'Quantitative outcome metric (e.g., savings achieved, GDR improvement) used to calculate performance-based fees when fee_type is ''performance_based''.',
  pmpm_rate DECIMAL(10,4) COMMENT 'The PMPM consulting fee rate applied when fee_type is ''pmpm''. Multiplied by eligible member count and months in billing period to derive invoice amount.',
  primary_client_consulting_engagement_id BIGINT COMMENT 'Reference to the consulting engagement under which this invoice was generated. Links invoice to the specific scoped engagement for audit and billing reconciliation.',
  salesforce_opportunity_code STRING COMMENT 'Salesforce CRM opportunity record ID linked to this invoice. Enables reconciliation between consulting revenue recognized in NetSuite and pipeline/opportunity data in Salesforce.',
  sent_date DATE COMMENT 'Date the invoice was transmitted to the client. Distinct from invoice_date (issuance). Used to track delivery confirmation and calculate effective payment terms start.',
  service_type STRING COMMENT 'Category of PillarRx consulting service being invoiced. Drives GL coding and revenue reporting by service line. [ENUM-REF-CANDIDATE: promote to reference product if values expand]',
  tax_amount DECIMAL(18,2) COMMENT 'Applicable tax amount included in or added to the invoice, where required by state or local tax regulations. Zero for most consulting engagements; retained for compliance.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this invoice record was last modified in the PillarRx data lakehouse. Tracks status changes, payment postings, and dispute updates for audit trail.',
  void_reason STRING COMMENT 'Reason code explaining why the invoice was voided. Null for non-voided invoices. Required for SOX controls and audit trail documentation.',
  voided_date DATE COMMENT 'Date the invoice was voided or cancelled. Null for active invoices. Required for SOX audit trail and AR reconciliation when invoices are reversed.',
  CONSTRAINT pk_consulting_fee_invoice PRIMARY KEY (consulting_fee_invoice_id)
)
COMMENT 'Records consulting fee invoices issued to employer clients for PillarRx services, as originated in NetSuite / Brown & Brown Finance. Captures invoice number, invoice date, billing period, fee type (fixed, PMPM, per-claim, performance-based), invoice'
;

CREATE TABLE IF NOT EXISTS pillarrx.client.contact (
  account_manager STRING COMMENT 'Name of the PillarRx account manager responsible for managing the relationship with this contact. Aligns with the account manager field on the consulting engagement.',
  assistant_name STRING COMMENT 'Name of the contact''s executive assistant or administrative support person. Used to coordinate meeting scheduling and deliverable routing for senior client contacts.',
  assistant_phone STRING COMMENT 'Phone number for the contact''s executive assistant. Used when direct contact is unavailable for time-sensitive consulting engagement coordination.',
  city STRING COMMENT 'City component of the contact''s mailing address.',
  contact_employer_id BIGINT COMMENT 'Reference to the employer client organization this contact is associated with, scoped within the Company > Division > Client hierarchy.',
  contact_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the contact record in the PillarRx data platform. Primary key for the client.contact product.',
  contact_status STRING COMMENT 'Current lifecycle status of the contact record. Inactive contacts are retained for historical engagement tracking. Do-not-contact respects opt-out preferences.',
  contact_type STRING COMMENT 'Classification of the contact''s role in the PillarRx consulting relationship. Determines routing of deliverables, invoices, and communications.',
  country_code STRING COMMENT 'ISO 3166-1 alpha-3 three-letter country code for the contact''s mailing address. Defaults to USA for domestic employer clients.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this contact record was first created in the PillarRx data platform. Populated on initial load from Salesforce CRM.',
  department STRING COMMENT 'Organizational department or functional area the contact belongs to at the employer client (e.g., Human Resources, Finance, Benefits Administration).',
  do_not_contact_reason STRING COMMENT 'Reason code explaining why this contact has been flagged as do-not-contact. Required when contact_status is do_not_contact to ensure compliance with opt-out and privacy obligations.',
  effective_date DATE COMMENT 'Date on which this contact became active and associated with the employer client in PillarRx''s Salesforce CRM. Marks the start of the contact relationship.',
  email STRING COMMENT 'Primary business email address for the contact. Used for consulting deliverable distribution, engagement communications, and Salesforce CRM correspondence.',
  employer_id BIGINT COMMENT 'FK to client.employer.employer_id — contact is a named individual at an employer client organization; must FK to the employer it is affiliated with.',
  engagement_role STRING COMMENT 'The contact''s functional role within the PillarRx consulting engagement lifecycle. Determines involvement in deliverable review, approval workflows, and PBM audit activities.',
  fax STRING COMMENT 'Fax number for the contact at the employer client organization. Retained for legacy document transmission where required by client.',
  first_name STRING COMMENT 'Given (first) name of the employer client contact individual as recorded in Salesforce CRM.',
  is_decision_maker BOOLEAN COMMENT 'Indicates whether this contact has authority to approve consulting engagement scope, contract renewals, or PBM strategy decisions on behalf of the employer client.',
  is_primary BOOLEAN COMMENT 'Indicates whether this contact is the designated primary point of contact for the employer client''s PillarRx consulting engagement. Only one contact per employer should be flagged as primary.',
  last_contacted_date DATE COMMENT 'Most recent date on which PillarRx staff had a documented interaction with this contact (call, email, meeting). Tracked in Salesforce CRM for relationship management.',
  last_name STRING COMMENT 'Family (last) name of the employer client contact individual as recorded in Salesforce CRM.',
  lead_consultant STRING COMMENT 'Name of the PillarRx lead consultant assigned to the client engagement associated with this contact. Primary technical point of contact for pharmacy benefit analysis.',
  linkedin_url STRING COMMENT 'LinkedIn profile URL for the contact. Used by PillarRx account managers for relationship intelligence and engagement preparation in Salesforce CRM.',
  mailing_address_line1 STRING COMMENT 'Primary street address line for mailing consulting deliverables or correspondence to the contact at the employer client organization.',
  mailing_address_line2 STRING COMMENT 'Secondary address line (suite, floor, mail stop) for the contact''s mailing address at the employer client organization.',
  mobile_phone STRING COMMENT 'Mobile phone number for the contact. Used for urgent consulting communications and time-sensitive engagement coordination.',
  next_followup_date DATE COMMENT 'Scheduled date for the next planned outreach or follow-up action with this contact by PillarRx account management or consulting staff.',
  notes STRING COMMENT 'Free-text notes captured by PillarRx account managers or consultants regarding this contact''s preferences, relationship context, or engagement history. Sourced from Salesforce CRM.',
  phone STRING COMMENT 'Primary business phone number for the contact, including direct dial or main office line. Used for consulting engagement coordination.',
  preferred_contact_method STRING COMMENT 'The contact''s stated preference for how PillarRx consulting staff should reach them. Guides outreach for deliverable distribution and engagement updates.',
  receives_cap_communications BOOLEAN COMMENT 'Indicates whether this contact receives communications related to the Copay Assistance Program (CAP) managed via the PAX application on behalf of the employer client.',
  receives_deliverables BOOLEAN COMMENT 'Indicates whether this contact is on the distribution list for PillarRx consulting deliverables (reports, benchmarking, audit findings). True = included in deliverable distribution.',
  receives_invoices BOOLEAN COMMENT 'Indicates whether this contact receives consulting fee invoices from PillarRx via NetSuite/Brown & Brown Finance. True = billing distribution list.',
  reports_to_name STRING COMMENT 'Name of the individual this contact reports to within the employer client organization. Provides organizational hierarchy context for consulting engagement escalation paths.',
  salesforce_contact_id BIGINT COMMENT 'Unique identifier for this contact record in Salesforce CRM, the system of record for client contact management at PillarRx. Used for CRM synchronization.',
  state_code STRING COMMENT 'Two-letter USPS state abbreviation for the contact''s mailing address. Used for geographic segmentation of consulting client contacts.',
  termination_date DATE COMMENT 'Date on which this contact was deactivated or disassociated from the employer client (e.g., employee departure, role change). Null if contact is currently active.',
  title STRING COMMENT 'Professional job title of the contact at the employer client organization (e.g., Benefits Manager, VP of Human Resources, CFO).',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp of the most recent update to this contact record in the PillarRx data platform. Reflects the latest synchronization from Salesforce CRM.',
  zip_code STRING COMMENT 'US ZIP or ZIP+4 postal code for the contact''s mailing address.',
  CONSTRAINT pk_contact PRIMARY KEY (contact_id)
)
COMMENT 'Master record for named individuals at employer client organizations who are the primary points of contact for PillarRx consulting engagements, as managed in Salesforce CRM.'
;

CREATE TABLE IF NOT EXISTS pillarrx.client.data_feed_config (
  api_authentication_method STRING COMMENT 'Authentication mechanism for API access (OAuth2, API key, basic auth, bearer token, certificate, none).',
  api_endpoint_url STRING COMMENT 'API endpoint URL for real-time or on-demand data retrieval.',
  character_encoding STRING COMMENT 'Character encoding standard used in the data files (UTF-8, UTF-16, ASCII, ISO-8859-1, Windows-1252).',
  company_pbm_id BIGINT COMMENT 'PBM source system providing the data feed (CVS Caremark, Optum Rx, Express Scripts, Navitus, etc.).',
  compression_format STRING COMMENT 'Compression format applied to data files (none, zip, gzip, tar, 7z).',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this feed configuration record was first created in the system.',
  data_assignment_fk BIGINT COMMENT 'FK to client.pbm_assignment.pbm_assignment_id — Each PBM data feed config corresponds to an employer-PBM relationship. Required for correct feed-to-PBM mapping.',
  data_employer_id BIGINT COMMENT 'Employer client for whom this PBM data feed is configured.',
  data_feed_config_id BIGINT NOT NULL COMMENT 'Unique identifier for the PBM data feed configuration record. Primary key.',
  data_pbm_assignment_id BIGINT COMMENT 'FK to client.pbm_assignment.pbm_assignment_id — Each data feed config is per employer-PBM pipeline; the employer-PBM relationship is owned by pbm_assignment, making it the natural scoping parent for the feed.',
  data_retention_days INT COMMENT 'Number of days raw feed files are retained in the ingestion platform before archival or deletion.',
  date_format STRING COMMENT 'Date format convention used in the data files (e.g., YYYY-MM-DD, MM/DD/YYYY, YYYYMMDD).',
  delimiter_character STRING COMMENT 'Character used to delimit fields in flat files (e.g., pipe |, comma, tab, semicolon).',
  delivery_frequency STRING COMMENT 'How often the PBM delivers data files (daily, weekly, biweekly, monthly, quarterly, on-demand, real-time). [ENUM-REF-CANDIDATE: daily|weekly|biweekly|monthly|quarterly|on_demand|real_time — 7 candidates stripped; promote to reference product]',
  delivery_method STRING COMMENT 'Mechanism by which the PBM delivers data files (SFTP, FTPS, API, S3 bucket, Azure Blob, email, manual upload). [ENUM-REF-CANDIDATE: sftp|ftps|api|s3_bucket|azure_blob|email|manual_upload — 7 candidates stripped; promote to reference product]',
  delivery_schedule STRING COMMENT 'Specific schedule or time window when files are expected (e.g., daily at 2:00 AM EST, first business day of month).',
  effective_date DATE COMMENT 'Date when this feed configuration became active and operational.',
  employer_id BIGINT COMMENT 'FK to client.employer.employer_id — Each PBM data feed is configured on behalf of a specific employer client.',
  encryption_method STRING COMMENT 'Encryption method applied to data files in transit or at rest (none, PGP, AES-256, TLS, SSL).',
  error_threshold_pct DECIMAL(5,2) COMMENT 'Maximum acceptable percentage of records with validation errors before the entire file is rejected.',
  feed_code STRING COMMENT 'Unique alphanumeric code identifying this feed configuration within the PBM Claims Feed Ingestion Platform.',
  feed_name STRING COMMENT 'Business-friendly name for this data feed configuration (e.g., CVS Caremark Claims Feed - Client ABC).',
  feed_status STRING COMMENT 'Current operational status of the data feed configuration.',
  feed_type STRING COMMENT 'Category of data delivered by this feed (pharmacy claims, eligibility, formulary, prior authorization, rebate, medical claims).',
  file_extension STRING COMMENT 'Expected file extension for incoming data files (e.g., .txt, .csv, .dat, .xml, .json).',
  file_format STRING COMMENT 'Format of the data files delivered by the PBM (EDI 835, flat file, CSV, pipe-delimited, tab-delimited, fixed-width, XML, JSON, proprietary). [ENUM-REF-CANDIDATE: edi_835|flat_file|csv|pipe_delimited|tab_delimited|fixed_width|xml|json|proprietary — 9',
  file_naming_pattern STRING COMMENT 'Expected file naming convention or regex pattern for incoming files (e.g., CLAIMS_YYYYMMDD_*.txt).',
  footer_row_present BOOLEAN COMMENT 'Indicates whether the data file contains a footer row with summary or control totals.',
  header_row_present BOOLEAN COMMENT 'Indicates whether the data file contains a header row with column names.',
  last_successful_load_date DATE COMMENT 'Date of the most recent successful data file ingestion for this feed.',
  next_expected_delivery_date DATE COMMENT 'Date when the next data file delivery is expected based on the delivery schedule.',
  notification_email_list STRING COMMENT 'Comma-separated list of email addresses to notify on feed success, failure, or anomaly detection.',
  pbm_assignment_id BIGINT COMMENT 'FK to client.pbm_assignment.pbm_assignment_id — Each PBM data feed is configured per employer-PBM pipeline; the feed config should resolve to the pbm_assignment (which owns the employer-PBM relationship and routing) rather than to a bare employer.',
  pbm_contact_email STRING COMMENT 'Email address of the primary PBM contact for feed-related issues and coordination.',
  pbm_contact_name STRING COMMENT 'Name of the primary contact at the PBM responsible for this data feed.',
  pbm_contact_phone STRING COMMENT 'Phone number of the primary PBM contact for urgent feed-related escalations.',
  primary_pbm_assignment_id BIGINT COMMENT 'FK to client.pbm_assignment.pbm_assignment_id — A data feed config ingests a specific employer-PBM pipeline; FK to the PBM assignment resolves which relationship the feed serves.',
  sftp_directory_path STRING COMMENT 'Directory path on the SFTP server where files are deposited.',
  sftp_host STRING COMMENT 'SFTP server hostname or IP address for file retrieval.',
  sftp_port INT COMMENT 'SFTP server port number (typically 22 for SFTP).',
  sftp_username STRING COMMENT 'Username credential for SFTP authentication.',
  sla_delivery_hours INT COMMENT 'Maximum number of hours allowed for file delivery per the SLA with the PBM.',
  termination_date DATE COMMENT 'Date when this feed configuration was terminated or decommissioned.',
  text_qualifier STRING COMMENT 'Character used to qualify text fields in flat files (e.g., double quote, single quote, none).',
  timestamp_format STRING COMMENT 'Timestamp format convention used in the data files (e.g., YYYY-MM-DD HH:MM:SS, ISO 8601).',
  timezone STRING COMMENT 'Timezone in which date and timestamp values are expressed (e.g., EST, UTC, America/New_York).',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this feed configuration record was last modified.',
  validation_rules_applied STRING COMMENT 'Summary of data quality and validation rules applied during ingestion (e.g., NDC format check, date range validation).',
  CONSTRAINT pk_data_feed_config PRIMARY KEY (data_feed_config_id)
)
COMMENT 'Stores the configuration parameters for each PBM data feed ingested on behalf of an employer client via the PBM Claims Feed Ingestion Platform. Captures PBM source system identifier, file format (EDI 835, flat file, proprietary), delivery method (SFTP'
;

CREATE TABLE IF NOT EXISTS pillarrx.client.document (
  amendment_number STRING COMMENT 'Sequential amendment identifier for contract_amendment document types, e.g., ''Amendment No. 3''. Nullable for original contracts and non-amendment document types.',
  checksum_hash STRING COMMENT 'Cryptographic hash (e.g., SHA-256) of the document file used to verify integrity and detect unauthorized modification. Supports SOC 2 and HIPAA audit trail requirements.',
  client_consulting_engagement_id BIGINT COMMENT 'Reference to the consulting engagement this document supports, such as a PBM audit SOW or benchmarking engagement. Nullable for documents not tied to a specific engagement.',
  client_signed_date DATE COMMENT 'Date on which the employer client countersigned the document. Nullable until the client signature is obtained. Used to confirm full execution status.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM counterparty associated with this document, e.g., CVS Caremark or Optum Rx for a PBM contract or audit workpaper. Nullable for documents not PBM-specific.',
  confidentiality_level STRING COMMENT 'Data classification level assigned to the document artifact per PillarRx data governance policy. Drives access control, sharing restrictions, and retention rules.',
  contains_phi BOOLEAN COMMENT 'Indicates whether the document artifact contains Protected Health Information as defined under HIPAA. Drives PHI handling, access logging, and breach notification obligations.',
  contains_pii BOOLEAN COMMENT 'Indicates whether the document artifact contains Personally Identifiable Information. Used to enforce data minimization and access controls per HIPAA and HITECH requirements.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this document record was first created in the PillarRx lakehouse. Supports audit trail and SOC 2 access logging requirements.',
  document_category STRING COMMENT 'Broad grouping of the document for folder-level organization and access control. Supports role-based filtering in the consulting reporting suite.',
  document_description STRING COMMENT 'Free-text narrative describing the purpose, scope, and key provisions of the document. Used by consulting analysts to understand document context without opening the artifact.',
  document_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for each compliance and engagement evidence artifact retained on behalf of an employer client in the PillarRx lakehouse.',
  document_number STRING COMMENT 'Externally-known or internally-assigned unique reference number for the document, such as a contract number, SOW number, or audit workpaper reference code.',
  document_status STRING COMMENT 'Current lifecycle state of the document artifact. Tracks progression from draft through execution, and flags superseded or voided documents for audit trail integrity.',
  document_type STRING COMMENT 'Classification of the document artifact. [ENUM-REF-CANDIDATE: pbm_contract|contract_amendment|engagement_sow|audit_workpaper|pbm_response_letter|invoice_support|data_use_agreement — promote to reference product]',
  effective_date DATE COMMENT 'Date on which the document becomes legally or operationally binding. For PBM contracts, this is the contract start date. For SOWs, the engagement commencement date.',
  employer_id BIGINT COMMENT 'Reference to the employer client on whose behalf this document is retained. Scopes the document within the Company > Division > Client hierarchy.',
  executed_date DATE COMMENT 'Date on which all required parties signed and fully executed the document. Distinct from effective_date; a document may be executed after its stated effective date.',
  expiration_date DATE COMMENT 'Date on which the document ceases to be binding or valid. Nullable for open-ended agreements. Used to trigger renewal workflows and audit expiry alerts.',
  file_format STRING COMMENT 'File format of the stored document artifact. Drives rendering and processing logic in the consulting reporting suite. [ENUM-REF-CANDIDATE: pdf|docx|xlsx|csv|msg|zip|other — 7 candidates stripped; promote to reference product]',
  file_name STRING COMMENT 'Original file name of the uploaded document artifact including extension, e.g., ''CVS_Caremark_PBM_Agreement_2024.pdf''. Used for retrieval and display in the consulting portal.',
  file_size_bytes BIGINT COMMENT 'Size of the document artifact file in bytes at time of upload. Used for storage capacity planning and to detect truncated or corrupt uploads.',
  is_current_version BOOLEAN COMMENT 'Indicates whether this record represents the most current version of the document. Set to FALSE when a newer version supersedes this record, supporting Type-2 version history.',
  legal_hold_flag BOOLEAN COMMENT 'Indicates the document is subject to a legal hold and must not be purged regardless of retention_expiry_date. Set by legal or compliance teams during litigation or regulatory inquiry.',
  netsuite_attachment_code STRING COMMENT 'Identifier of the corresponding document attachment in NetSuite, linking invoice support packages and billing artifacts to the Brown & Brown Finance GL and AR records.',
  notes STRING COMMENT 'Free-text field for analyst annotations, escalation notes, or contextual commentary about the document that does not fit structured fields. Not surfaced in client-facing deliverables.',
  pbm_contract_id BIGINT COMMENT 'Foreign key linking to client.pbm_contract. Business justification: Client documents include contract artifacts, amendments, and related legal documents. When document_type indicates a contract or amendment, the document should reference the pbm_contract',
  pillarrx_signed_date DATE COMMENT 'Date on which PillarRx executed its signature on the document, e.g., for engagement SOWs or data-use agreements. Nullable for documents not requiring PillarRx signature.',
  received_date DATE COMMENT 'Date PillarRx received or ingested the document into its document management system. Used for intake tracking and SLA compliance on document processing.',
  requires_countersignature BOOLEAN COMMENT 'Indicates whether the document requires a countersignature from the employer client or PBM counterparty before it is considered fully executed. Drives signature workflow routing.',
  retention_expiry_date DATE COMMENT 'Calculated date after which the document may be purged per retention policy. Derived from received_date plus retention_period_years; stored explicitly to support purge scheduling.',
  retention_period_years INT COMMENT 'Number of years this document must be retained per applicable regulatory or contractual requirements. Drives automated retention policy enforcement and legal hold workflows.',
  review_date DATE COMMENT 'Date on which the document was last reviewed by a PillarRx analyst. Used to track review currency and flag documents requiring re-review after a defined interval.',
  reviewed_by STRING COMMENT 'Username or display name of the PillarRx analyst or consultant who reviewed and approved the document for use in consulting deliverables or audit workpapers.',
  salesforce_document_code STRING COMMENT 'Identifier of the corresponding document record in Salesforce CRM, enabling cross-system traceability between the lakehouse document registry and the CRM engagement record.',
  signatory_name STRING COMMENT 'Full name of the primary authorized signatory who executed the document on behalf of the employer client or counterparty. Retained for contract enforcement and audit purposes.',
  signatory_title STRING COMMENT 'Job title of the authorized signatory, e.g., ''VP of Human Resources'' or ''Chief Financial Officer''. Used to verify signing authority for contract validity.',
  storage_location STRING COMMENT 'Path or URI to the document artifact in the enterprise document store or lakehouse, e.g., an S3 path or SharePoint URL. Enables direct retrieval by consulting analysts.',
  superseded_by_document_id BIGINT COMMENT 'Self-referencing identifier pointing to the newer document record that supersedes this one. Nullable when this is the current version. Enables document lineage traversal.',
  title STRING COMMENT 'Human-readable title or name of the document as it appears on the artifact, e.g., ''CVS Caremark PBM Services Agreement'' or ''Q3 2024 PBM Audit Workpaper — Optum Rx''.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this document record was last modified in the PillarRx lakehouse. Used to detect stale records and support incremental ETL processing.',
  uploaded_by STRING COMMENT 'Username or display name of the PillarRx staff member who uploaded the document artifact into the system. Provides accountability for document intake.',
  version_number INT COMMENT 'Monotonically increasing version counter for the document artifact. Incremented each time a revised version is uploaded, enabling version history tracking.',
  CONSTRAINT pk_document PRIMARY KEY (document_id)
)
COMMENT 'Stores compliance and engagement evidence artifacts retained on behalf of each employer client — executed PBM contracts and amendments, signed engagement SOWs, audit workpapers and PBM response letters, invoice support packages, and data-use agreements.'
;

CREATE TABLE IF NOT EXISTS pillarrx.client.employer (
  audit_services_enabled BOOLEAN COMMENT 'Indicates whether PBM audit services (discount, rebate, dispensing-fee guarantee reconciliation) are active for this employer client.',
  baa_effective_date DATE COMMENT 'Date on which the HIPAA Business Associate Agreement (BAA) between PillarRx and the employer became effective. Required before PHI data processing begins.',
  billing_contact_email STRING COMMENT 'Email address for the employer''s accounts payable or finance contact. Used by NetSuite/Brown & Brown Finance for consulting fee invoice delivery.',
  cap_enrolled BOOLEAN COMMENT 'Indicates whether the employer client is enrolled in PillarRx''s Copay Assistance Program (CAP) managed via the PAX application. Drives CAP eligibility and reporting.',
  city STRING COMMENT 'City of the employer''s principal mailing address. Used for geographic segmentation, benchmarking, and regulatory correspondence.',
  client_status STRING COMMENT 'Current lifecycle status of the employer client engagement with PillarRx. Drives data processing, reporting, and billing eligibility.',
  client_type STRING COMMENT 'Classification of the employer client by organizational type. Supports segmentation for benchmarking, reporting, and consulting service delivery.',
  country_code STRING COMMENT 'ISO 3166-1 alpha-3 country code for the employer''s principal address. Defaults to USA for domestic employer clients.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the employer record was first created in the PillarRx platform. Audit trail for record provenance and data governance.',
  data_sharing_agreement_on_file BOOLEAN COMMENT 'Indicates whether a signed data sharing or Business Associate Agreement (BAA) is on file for this employer, authorizing PillarRx to receive and process PHI/PII.',
  division_id BIGINT COMMENT 'Reference to the Division within the Company > Division > Client hierarchy. Intermediate organizational scope above the employer client.',
  doing_business_as_name STRING COMMENT 'Trade or operating name of the employer if different from the legal name. Used in client-facing reporting and communications.',
  effective_date DATE COMMENT 'Date on which the employer client relationship with PillarRx became active. Defines the start of data aggregation, consulting services, and billing.',
  ein STRING COMMENT 'IRS-assigned federal Employer Identification Number (EIN) in XX-XXXXXXX format. Required for ERISA plan filings, Form 5500, and DOL reporting.',
  eligible_member_count INT COMMENT 'Current count of members eligible for pharmacy benefits under this employer''s plan. Used for PMPM/PMPY calculations, benchmarking, and consulting fee sizing.',
  employee_count INT COMMENT 'Total number of employees at the employer organization. Used for plan size segmentation, benchmarking peer group assignment, and consulting scope sizing.',
  employer_code STRING COMMENT 'Short alphanumeric code uniquely identifying the employer within PillarRx systems. Used in file naming, ETL pipelines, and reporting identifiers.',
  employer_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the employer client record within the PillarRx platform. Primary key for the employer master record.',
  first_claims_date DATE COMMENT 'Date of the earliest pharmacy claim on record for this employer client. Establishes the historical data horizon for trend analysis and benchmarking.',
  funding_type STRING COMMENT 'Indicates how the employer funds pharmacy benefits. Self-funded plans bear claim risk directly; fully insured plans pay premiums to a carrier. Drives audit and financial analysis approach.',
  industry_segment STRING COMMENT 'Industry classification of the employer (e.g., manufacturing, healthcare, education, retail). Used for peer benchmarking and trend analysis in consulting deliverables.',
  legal_name STRING COMMENT 'Full legal name of the employer organization as registered. Used for contract documents, audit deliverables, and regulatory filings.',
  mailing_address_line1 STRING COMMENT 'Primary street address line for the employer''s principal office. Used for formal correspondence, contract delivery, and regulatory filings.',
  mailing_address_line2 STRING COMMENT 'Secondary address line (suite, floor, PO Box) for the employer''s principal office. Supplements mailing_address_line1 for complete address formatting.',
  medical_claims_integration_enabled BOOLEAN COMMENT 'Indicates whether medical claims data is integrated for this employer to support Total Cost of Care (TCOC) analysis alongside pharmacy claims.',
  naics_code STRING COMMENT 'Six-digit NAICS code identifying the employer''s primary industry. Enables standardized industry benchmarking of pharmacy spend and GDR across peer cohorts.',
  netsuite_customer_code STRING COMMENT 'NetSuite/Brown & Brown Finance customer identifier for this employer. Used for consulting fee billing, AR tracking, and GL reconciliation.',
  notes STRING COMMENT 'Free-text field for internal PillarRx notes about the employer client, such as special contractual terms, onboarding exceptions, or consulting engagement context.',
  onboarding_date DATE COMMENT 'Date on which the employer client onboarding process was initiated in PillarRx systems. Tracks data provisioning and ETL pipeline setup milestones.',
  organization_id BIGINT COMMENT 'Reference to the parent Company in the Company > Division > Client organizational hierarchy. Scopes the employer to its top-level entity.',
  pbm_contract_model STRING COMMENT 'PBM pricing model under which the employer operates. Pass-through means transparent cost-plus pricing; spread means PBM retains difference between plan paid and pharmacy reimbursement.',
  pbm_count INT COMMENT 'Number of PBMs currently contracted by this employer. Employers with multiple PBMs require cross-PBM normalization and Member 360 identity resolution.',
  plan_name STRING COMMENT 'Name of the employer-sponsored health plan under which pharmacy benefits are administered. Used in member communications and benefit documents.',
  plan_sponsor_name STRING COMMENT 'Name of the ERISA plan sponsor, which may differ from the employer legal name when a trust or holding entity sponsors the health plan.',
  plan_year_start_month INT COMMENT 'Calendar month (1–12) in which the employer plan year begins. Determines benefit accumulator reset dates for deductibles, OOP, and MOOP calculations.',
  primary_contact_email STRING COMMENT 'Email address of the primary employer-side contact. Used for consulting deliverable distribution, reporting, and account communications.',
  primary_contact_name STRING COMMENT 'Full name of the primary employer-side contact responsible for the PillarRx consulting engagement. Used for communication and account management.',
  primary_contact_phone STRING COMMENT 'Phone number of the primary employer-side contact for the PillarRx engagement. Used for account management and urgent consulting communications.',
  prior_auth_analysis_enabled BOOLEAN COMMENT 'Indicates whether prior authorization (PA) analytics are active for this employer client. Enables PA approval rate, denial trend, and step therapy reporting.',
  salesforce_account_code STRING COMMENT 'Salesforce CRM Account ID for this employer client. Cross-reference key linking the employer master record to the CRM for engagement and fee tracking.',
  state_code STRING COMMENT 'Two-letter USPS state abbreviation for the employer''s principal address. Used for state-level PBM regulatory compliance, benchmarking, and geographic reporting.',
  termination_date DATE COMMENT 'Date on which the employer client relationship with PillarRx ended. Null for active clients. Drives data retention, reporting cutoff, and billing cessation.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp of the most recent update to the employer record. Supports change detection, audit trails, and incremental ETL processing in the lakehouse.',
  zip_code STRING COMMENT 'US ZIP or ZIP+4 postal code for the employer''s principal address. Supports geographic analysis and state regulatory jurisdiction determination.',
  CONSTRAINT pk_employer PRIMARY KEY (employer_id)
)
COMMENT 'Master record for each employer client served by PillarRx within the Company > Division > Client organizational hierarchy. Represents the authoritative identity of an employer-sponsored health plan sponsor — the entity whose pharmacy spend PillarRx'
;

CREATE TABLE IF NOT EXISTS pillarrx.client.onboarding_event (
  account_manager STRING COMMENT 'Name of the PillarRx account manager overseeing the client relationship and responsible for onboarding milestone communication to the employer client.',
  actual_go_live_date DATE COMMENT 'Date on which the client was confirmed live on the PillarRx platform with validated claims feeds active. Null until go-live is achieved.',
  assigned_analyst STRING COMMENT 'Name of the PillarRx analyst responsible for executing and coordinating the client onboarding tasks and data provisioning milestones.',
  audit_services_enabled BOOLEAN COMMENT 'Indicates whether PBM audit services (AWP discount, dispensing fee, rebate guarantee reconciliation) are in scope for this client onboarding.',
  baa_executed_date DATE COMMENT 'Date the HIPAA Business Associate Agreement was fully executed, required before any PHI or claims data is provisioned to PillarRx systems.',
  cap_management_enabled BOOLEAN COMMENT 'Indicates whether the PAX copay assistance program management module is activated for this client as part of the onboarding scope.',
  claims_feed_format STRING COMMENT 'File format of the incoming PBM claims feed being configured during onboarding (e.g., NCPDP D.0, flat file CSV, EDI 835). [ENUM-REF-CANDIDATE: NCPDP_D0|flat_file_csv|flat_file_pipe|edi_835|custom_xml|sftp_json — promote to reference product]',
  claims_feed_frequency STRING COMMENT 'Agreed frequency at which the PBM will transmit claims data files to PillarRx during and after onboarding (daily, weekly, biweekly, monthly, on-demand).',
  client_consulting_engagement_id BIGINT COMMENT 'Reference to the consulting engagement associated with this onboarding event, linking onboarding milestones to the billable engagement scope.',
  client_onboarding_contact STRING COMMENT 'Name of the primary contact at the employer client responsible for coordinating onboarding activities, data access, and UAT sign-off.',
  client_onboarding_contact_email STRING COMMENT 'Email address of the employer client''s primary onboarding contact, used for milestone notifications, feed setup coordination, and UAT communications.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this onboarding event record was first created in the PillarRx platform, used for audit trail and SLA elapsed-time calculations.',
  data_provisioning_complete_date DATE COMMENT 'Date on which all multi-tenant data provisioning tasks (tenant setup, feed configuration, access controls) were completed for this client.',
  data_sharing_agreement_date DATE COMMENT 'Date the data sharing agreement (DSA) was fully executed between PillarRx and the employer client, authorizing PBM claims data transfer.',
  delay_reason STRING COMMENT 'Categorized reason for onboarding delay when actual go-live date exceeds target. Used for SLA root-cause analysis and process improvement. [ENUM-REF-CANDIDATE',
  eligibility_feed_format STRING COMMENT 'File format of the member eligibility feed being configured during onboarding (e.g., EDI 834, flat file). Required for member enrollment provisioning.',
  employer_id BIGINT COMMENT 'FK to client.employer.employer_id — Onboarding lifecycle is tracked per new employer client; each onboarding event must resolve to its employer.',
  event_code STRING COMMENT 'Unique business-facing alphanumeric code identifying this onboarding event, used in Salesforce CRM and internal tracking (e.g., OB-2024-0042).',
  feed_validation_complete_date DATE COMMENT 'Date on which claims and eligibility feed validation (format checks, record counts, financial reconciliation) was confirmed complete for this client.',
  first_claims_load_date DATE COMMENT 'Date on which the first batch of pharmacy claims data was successfully loaded and validated in the PillarRx data warehouse for this client.',
  historical_claims_end_date DATE COMMENT 'Latest date of service for the historical claims load window during onboarding. Defines the analysis baseline period for benchmarking and audit.',
  historical_claims_start_date DATE COMMENT 'Earliest date of service for historical pharmacy claims to be loaded during onboarding, establishing the baseline for trend and audit analysis.',
  medical_claims_integration_enabled BOOLEAN COMMENT 'Indicates whether medical claims integration for Total Cost of Care (TCOC) analysis is activated for this client during onboarding.',
  member_360_enabled BOOLEAN COMMENT 'Indicates whether cross-PBM Member 360 identity resolution is activated for this client during onboarding, enabling unified member view across PBM sources.',
  netsuite_project_code STRING COMMENT 'NetSuite project identifier linked to this onboarding event for consulting fee billing, resource tracking, and GL cost allocation via Brown & Brown Finance.',
  onboarding_employer_id BIGINT COMMENT 'Reference to the employer client being onboarded within the Company > Division > Client hierarchy.',
  onboarding_event_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for each client onboarding lifecycle event record on the PillarRx platform.',
  onboarding_notes STRING COMMENT 'Free-text field capturing analyst notes, blockers, special instructions, or client-specific provisioning requirements relevant to this onboarding event.',
  onboarding_phase STRING COMMENT 'Current phase of the client onboarding lifecycle: contract signed, data provisioning, feed validation, user acceptance testing (UAT), go-live, or post-go-live review.',
  onboarding_priority STRING COMMENT 'Business priority assigned to this onboarding event, used to allocate analyst resources and sequence provisioning tasks across concurrent client onboardings.',
  onboarding_status STRING COMMENT 'Current workflow status of the onboarding event indicating whether provisioning milestones are on track, blocked, completed, or cancelled.',
  onboarding_type STRING COMMENT 'Categorizes the nature of the onboarding event: new client, addition of a new PBM to an existing client, PBM transition, contract renewal, or client reactivation.',
  pbm_count INT COMMENT 'Number of PBMs (e.g., CVS Caremark, Optum Rx, Express Scripts) in scope for this client onboarding, driving feed configuration complexity.',
  pbm_scope STRING COMMENT 'Pipe-delimited list of PBM names in scope for this onboarding event (e.g., CVS Caremark|Optum Rx|Express Scripts). Drives feed setup tasks.',
  primary_employer_id BIGINT COMMENT 'FK to client.employer.employer_id — Onboarding lifecycle is per new employer client; FK required to track provisioning per client.',
  prior_auth_analysis_enabled BOOLEAN COMMENT 'Indicates whether prior authorization (PA) analytics are in scope for this client onboarding, enabling PA approval rate and step therapy reporting.',
  salesforce_onboarding_code STRING COMMENT 'Salesforce CRM record identifier for this onboarding event, enabling cross-system traceability between the PillarRx data warehouse and CRM pipeline.',
  sla_met_flag BOOLEAN COMMENT 'Indicates whether the onboarding was completed within the contracted SLA target days. Set to true when actual go-live date is on or before the SLA deadline.',
  sla_target_days INT COMMENT 'Contracted number of calendar days from onboarding start to go-live, as defined in the consulting engagement SLA for this client.',
  start_date DATE COMMENT 'Date on which the client onboarding process formally commenced, typically aligned with contract execution or signed data sharing agreement.',
  target_go_live_date DATE COMMENT 'Planned date by which the client should be fully provisioned and live on the PillarRx platform with active claims data flowing.',
  uat_complete_date DATE COMMENT 'Date on which user acceptance testing was signed off by the client, confirming reporting and analytics outputs meet agreed specifications.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp of the most recent update to this onboarding event record, supporting change tracking and audit compliance across the onboarding lifecycle.',
  CONSTRAINT pk_onboarding_event PRIMARY KEY (onboarding_event_id)
)
COMMENT 'Tracks the client onboarding lifecycle for each new employer client added to the PillarRx platform, including multi-tenant data provisioning milestones. Captures onboarding start date, target go-live date, actual go-live date, onboarding phase (contract'
;

CREATE TABLE IF NOT EXISTS pillarrx.client.pbm_assignment (
  assignment_code STRING COMMENT 'Externally-known business identifier or reference code for this PBM assignment, used in client communications, contract documents, and PBM data feeds.',
  assignment_status STRING COMMENT 'Current lifecycle state of the PBM assignment for the client. Active indicates claims are being processed; terminated indicates the contract has ended.',
  audit_frequency STRING COMMENT 'Scheduled frequency of PBM contract and claims audits conducted by PillarRx for this assignment. Drives consulting engagement planning and deliverable scheduling.',
  awp_discount_brand_pct DECIMAL(7,4) COMMENT 'Guaranteed contractual discount percentage off AWP for brand-name drugs under this PBM assignment. Core metric for PBM contract audit and benchmarking.',
  awp_discount_generic_pct DECIMAL(7,4) COMMENT 'Guaranteed contractual discount percentage off AWP for generic drugs under this PBM assignment. Used in Generic Dispensing Rate (GDR) and cost benchmarking analysis.',
  awp_discount_specialty_pct DECIMAL(7,4) COMMENT 'Guaranteed contractual discount percentage off AWP for specialty medications (SMN) under this PBM assignment. Critical for specialty pharmacy spend monitoring.',
  claims_feed_format STRING COMMENT 'Format of the pharmacy claims data feed delivered by this PBM for ingestion into the PillarRx claims aggregation platform. Drives ETL pipeline configuration.',
  claims_feed_frequency STRING COMMENT 'Frequency at which the PBM delivers pharmacy claims data files to PillarRx for aggregation and analysis. Impacts data freshness for client reporting.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM entity (e.g., CVS Caremark, Optum Rx, Express Scripts, Navitus) contracted to administer pharmacy benefits for the client.',
  contract_end_date DATE COMMENT 'Contractual expiration date of the PBM agreement. Used for renewal tracking and PBM audit scheduling. Null if contract is evergreen.',
  contract_start_date DATE COMMENT 'Date the underlying PBM contract was executed and became legally binding. May differ from effective_date if there is a pre-implementation period.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this PBM assignment record was first created in the PillarRx data platform. Used for audit trail and data lineage tracking.',
  dispensing_fee_mail DECIMAL(10,4) COMMENT 'Contracted dispensing fee amount paid per claim for mail-order pharmacy fills under this PBM assignment. Used in dispensing fee guarantee auditing.',
  dispensing_fee_retail DECIMAL(10,4) COMMENT 'Contracted dispensing fee amount paid to retail pharmacies per claim under this PBM assignment. Used in dispensing fee guarantee auditing.',
  dispensing_fee_specialty DECIMAL(10,4) COMMENT 'Contracted dispensing fee amount paid per claim for specialty pharmacy fills under this PBM assignment. Used in specialty spend monitoring and audit.',
  division_formulary_id BIGINT COMMENT 'PBM-assigned identifier for the formulary applied under this assignment. Used to cross-reference formulary data in drug reference and benefit analysis.',
  effective_date DATE COMMENT 'Date on which the PBM assignment becomes binding and the PBM begins adjudicating pharmacy claims on behalf of the employer client.',
  eligibility_feed_format STRING COMMENT 'Format of the member eligibility file submitted to the PBM under this assignment. Drives eligibility management system integration and member enrollment workflows.',
  employer_id BIGINT COMMENT 'FK to client.employer.employer_id — pbm_assignment owns the employer-to-PBM relationship; it must FK to the employer it scopes. Core to multi-PBM claims aggregation.',
  is_340b_eligible BOOLEAN COMMENT 'Indicates whether the client is eligible for 340B federal drug discount pricing under this PBM assignment. Relevant for HRSA 340B program compliance and savings analysis.',
  is_mail_order_included BOOLEAN COMMENT 'Indicates whether mail-order pharmacy benefits are included under this PBM assignment. Drives mail-order channel analysis and dispensing fee audit scope.',
  is_rebate_passthrough BOOLEAN COMMENT 'Indicates whether manufacturer rebates are passed through 100% to the client (pass-through model) versus retained in whole or part by the PBM (spread model).',
  is_specialty_included BOOLEAN COMMENT 'Indicates whether specialty pharmacy benefits (SMN, LDD) are administered under this PBM assignment. Drives specialty spend monitoring scope.',
  last_audit_date DATE COMMENT 'Date of the most recently completed PBM audit for this assignment. Used to track audit cadence compliance and schedule next audit engagement.',
  mac_list_id BIGINT COMMENT 'Foreign key linking to drug.mac_list. Business justification: PBM assignments reference specific MAC pricing lists that govern generic reimbursement rates.',
  network_name STRING COMMENT 'Name of the pharmacy network (e.g., preferred retail, standard retail, mail, specialty) contracted under this PBM assignment for claim adjudication.',
  next_renewal_date DATE COMMENT 'Date by which the PBM contract must be renewed or renegotiated. Triggers consulting engagement for contract benchmarking and guarantee renegotiation.',
  notes STRING COMMENT 'Free-text field for consulting team notes regarding special contract terms, implementation considerations, or audit findings specific to this PBM assignment.',
  pbm_account_manager STRING COMMENT 'Name of the PBM-side account manager or client services representative responsible for this client relationship. Used for escalation and contract management.',
  pbm_assignment_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for a PBM assignment record linking an employer client to a contracted PBM for pharmacy benefit administration.',
  pbm_client_code STRING COMMENT 'The identifier assigned by the PBM to this employer client in the PBM''s own system. Required for claims feed ingestion, eligibility file submission, and PBM portal access.',
  pbm_contract_id BIGINT COMMENT 'Foreign key linking to client.pbm_contract. Business justification: A pbm_assignment is the operational instantiation of a pbm_contract. The assignment references the contract under which the PBM relationship operates.',
  pbm_employer_id BIGINT COMMENT 'Reference to the employer client within the Company > Division > Client hierarchy for whom this PBM is contracted to administer pharmacy benefits.',
  pillarrx_analyst STRING COMMENT 'Name of the PillarRx consulting analyst assigned to manage and audit this PBM assignment on behalf of the employer client.',
  pricing_model STRING COMMENT 'The contractual pricing model under which the PBM operates for this client. Pass-through means transparent cost-plus; spread means PBM retains the difference between plan paid and pharmacy reimbursement.',
  rebate_guarantee_brand DECIMAL(10,4) COMMENT 'Guaranteed minimum rebate amount per brand claim or per member per year (PMPY) committed by the PBM for brand drugs. Used in rebate reconciliation and DIR analysis.',
  rx_bin STRING COMMENT 'Six-digit Bank Identification Number used to route pharmacy claims to the correct PBM processor at the point of sale. Printed on member ID cards.',
  rx_group STRING COMMENT 'Pharmacy benefit group identifier assigned by the PBM to segment members under a specific benefit design within the client''s plan. Printed on member ID cards.',
  rx_pcn STRING COMMENT 'Processor Control Number used alongside RxBIN to route pharmacy claims to the correct PBM sub-processor or benefit plan. Printed on member ID cards.',
  termination_date DATE COMMENT 'Date on which the PBM assignment ends and the PBM ceases to adjudicate claims for the client. Null indicates an open-ended active assignment.',
  termination_reason STRING COMMENT 'Business reason for the termination of this PBM assignment (e.g., PBM switch, client offboarding, contract non-renewal). Populated only when assignment_status is terminated.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this PBM assignment record was last modified in the PillarRx data platform. Used for change tracking and incremental ETL processing.',
  CONSTRAINT pk_pbm_assignment PRIMARY KEY (pbm_assignment_id)
)
COMMENT 'Tracks which PBMs (CVS Caremark, Optum Rx, Express Scripts, Navitus, EmpiRx Health, BCBS Michigan, Rightway, Prime Therapeutics, ServeYou, Carelon) are contracted to administer pharmacy benefits for a given employer client, including effective/termination'
;

CREATE TABLE IF NOT EXISTS pillarrx.client.pbm_contract (
  amendment_number STRING COMMENT 'Identifier for the most recent amendment to the base contract. Null for original contracts with no amendments. Tracks contract version lineage.',
  audit_frequency STRING COMMENT 'Contractually agreed frequency at which PillarRx or the plan sponsor may conduct a PBM audit. Drives audit scheduling in the consulting engagement calendar.',
  audit_rights_clause BOOLEAN COMMENT 'Indicates whether the contract includes an explicit audit rights clause granting the plan sponsor or its designee (PillarRx) the right to audit PBM claims and pricing.',
  auto_renewal BOOLEAN COMMENT 'Indicates whether the contract automatically renews at expiration unless notice of termination is provided within the required notice period.',
  awp_discount_brand_pct DECIMAL(7,4) COMMENT 'Guaranteed AWP discount percentage for brand drugs at retail. Used in PBM guarantee audits to verify actual discount performance against contracted rates.',
  awp_discount_generic_pct DECIMAL(7,4) COMMENT 'Guaranteed AWP discount percentage for generic drugs at retail. Benchmarked against actual claims to identify discount shortfalls during PBM audits.',
  awp_discount_mail_brand_pct DECIMAL(7,4) COMMENT 'Guaranteed AWP discount percentage for brand drugs dispensed through mail order. Mail order rates are typically negotiated separately from retail.',
  awp_discount_mail_generic_pct DECIMAL(7,4) COMMENT 'Guaranteed AWP discount percentage for generic drugs dispensed through mail order. Used in mail order channel audit reconciliation.',
  awp_discount_specialty_pct DECIMAL(7,4) COMMENT 'Guaranteed AWP discount percentage for specialty drugs. Critical for specialty spend monitoring given high per-unit costs of specialty medications.',
  ber_brand DECIMAL(7,4) COMMENT 'Brand Effective Rate representing the net effective discount on brand drugs inclusive of rebates. Distinct from GER; used in PBM performance benchmarking.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM entity (e.g., CVS Caremark, Optum Rx, Express Scripts) that is party to this contract.',
  contract_name STRING COMMENT 'Human-readable name or title for the contract, typically combining the client name and PBM name (e.g., ''Acme Corp – CVS Caremark 2024 Agreement'').',
  contract_notes STRING COMMENT 'Free-text field for PillarRx analysts to capture material contract terms, negotiation context, audit findings, or special provisions not captured in structured fields.',
  contract_number STRING COMMENT 'Externally assigned contract number issued by the PBM or negotiated between the employer and PBM. Used as the primary business identifier for audit and reconciliation.',
  contract_status STRING COMMENT 'Current lifecycle state of the PBM contract. Drives audit eligibility, claims feed activation, and consulting engagement scoping.',
  contract_term_years DECIMAL(4,1) COMMENT 'Total duration of the PBM contract in years as negotiated. Used for benchmarking contract length and planning renewal timelines.',
  contract_type STRING COMMENT 'Classification of the PBM contract by funding and customization model. Determines audit approach and applicable regulatory framework under ERISA.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this PBM contract record was first created in the PillarRx data platform. Used for audit trail and data lineage tracking.',
  dir_fee_applicable BOOLEAN COMMENT 'Indicates whether Direct and Indirect Remuneration (DIR) fees apply under this contract, which can retroactively reduce pharmacy reimbursements and affect net plan cost.',
  dispensing_fee_mail DECIMAL(10,4) COMMENT 'Contracted dispensing fee (in USD) per fill for mail order pharmacy channel. Typically lower than retail due to volume and automation efficiencies.',
  dispensing_fee_retail DECIMAL(10,4) COMMENT 'Contracted dispensing fee (in USD) paid to retail pharmacies per prescription fill. Audited against actual claim dispensing fees to identify overcharges.',
  dispensing_fee_specialty DECIMAL(10,4) COMMENT 'Contracted dispensing fee (in USD) per fill for specialty pharmacy channel. Specialty fees may include clinical services and patient support programs.',
  effective_date DATE COMMENT 'Date on which the PBM contract becomes binding and claims adjudication under its terms begins. Used to scope audit and benchmarking analysis periods.',
  employer_id BIGINT COMMENT 'FK to client.employer.employer_id — pbm_contract stores terms negotiated between a specific employer and PBM; employer FK required.',
  execution_date DATE COMMENT 'Date the contract was fully executed (signed by all parties). May precede the effective date. Used for legal and compliance tracking.',
  expiration_date DATE COMMENT 'Date on which the PBM contract expires. Null for evergreen contracts. Used to trigger renewal analysis and audit scheduling.',
  formulary_name STRING COMMENT 'Name of the drug formulary (covered drug list) associated with this PBM contract. Identifies the tier structure and coverage rules applicable to the plan.',
  ger_brand DECIMAL(7,4) COMMENT 'Guaranteed Effective Rate for brand drugs, representing the all-in net cost per unit after discounts and rebates. Used in GER audit reconciliation.',
  is_340b_eligible BOOLEAN COMMENT 'Indicates whether the client is eligible to participate in the 340B federal drug discount program under this PBM contract.',
  is_rebate_passthrough BOOLEAN COMMENT 'Indicates whether the contract is structured as a rebate pass-through model where 100% of manufacturer rebates flow to the plan sponsor.',
  is_spread_pricing BOOLEAN COMMENT 'Indicates whether the PBM retains spread (the difference between plan paid and pharmacy reimbursement) as a revenue source under this contract.',
  last_audit_date DATE COMMENT 'Date the most recent PBM audit was completed for this contract. Used to track audit cadence compliance and schedule next audit.',
  mac_list_name STRING COMMENT 'Name or identifier of the MAC list used by the PBM to set maximum reimbursement for generic drugs. MAC list identity is critical for generic pricing audits.',
  network_name STRING COMMENT 'Name of the pharmacy network (retail, mail, specialty) contracted under this PBM agreement. Determines which pharmacies members may use for in-network benefits.',
  next_renewal_date DATE COMMENT 'Anticipated or scheduled date for contract renewal negotiation. Drives PillarRx consulting engagement planning and rebid analysis timelines.',
  pbm_account_manager STRING COMMENT 'Name of the PBM-side account manager responsible for this client contract. Used for escalation and relationship management during audits.',
  pbm_contract_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for a PBM contract record in the PillarRx data platform. Primary key for the pbm_contract entity.',
  pbm_employer_id BIGINT COMMENT 'Reference to the employer client for whom this PBM contract is in effect. Links the contract to the Company > Division > Client hierarchy.',
  pillarrx_analyst STRING COMMENT 'Name of the PillarRx consulting analyst assigned to manage audit and benchmarking activities for this PBM contract.',
  pricing_model STRING COMMENT 'The contractual pricing model governing how the PBM is compensated. Pass-through means the plan pays actual drug cost; spread means PBM retains the difference between plan paid and pharmacy reimbursement.',
  rebate_guarantee_brand DECIMAL(10,4) COMMENT 'Minimum guaranteed rebate amount (in USD) per brand claim as negotiated in the PBM contract. Used in rebate reconciliation to identify shortfalls.',
  rebate_guarantee_specialty DECIMAL(10,4) COMMENT 'Minimum guaranteed rebate amount (in USD) per specialty claim. Specialty rebates are increasingly significant as specialty spend grows.',
  rebate_passthrough_pct DECIMAL(7,4) COMMENT 'Percentage of manufacturer rebates that the PBM is contractually required to pass through to the plan sponsor. 100% indicates a fully pass-through model.',
  renewal_notice_days INT COMMENT 'Number of days prior to expiration that written notice of non-renewal must be provided. Critical for client renewal planning and PBM rebid scheduling.',
  termination_date DATE COMMENT 'Actual date the contract was terminated early, if applicable. Distinct from expiration_date which is the scheduled end. Null if not terminated early.',
  termination_reason STRING COMMENT 'Reason the contract was terminated prior to its scheduled expiration date. Populated only when termination_date is set.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this PBM contract record was last modified in the PillarRx data platform. Used for change tracking and ETL incremental load processing.',
  CONSTRAINT pk_pbm_contract PRIMARY KEY (pbm_contract_id)
)
COMMENT 'Stores the contractual terms negotiated between an employer client and a PBM, as audited by PillarRx. Captures contract effective and expiration dates, pricing model (pass-through vs.'
;

-- ---------------------------------------------------------------------------
-- Schema: company
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS pillarrx.company.client_contact (
  address_line1 STRING COMMENT 'Primary street address line for the contact''s business mailing address. Used for formal correspondence and consulting deliverable distribution.',
  address_line2 STRING COMMENT 'Secondary address line (suite, floor, mail stop) for the contact''s business mailing address.',
  city STRING COMMENT 'City component of the contact''s business mailing address.',
  client_contact_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for a client contact record within the PillarRx enterprise data platform.',
  contact_status STRING COMMENT 'Current lifecycle status of the contact record. Inactive or terminated contacts are retained for historical audit trail but excluded from active communications.',
  country_code STRING COMMENT 'ISO 3166-1 alpha-3 country code for the contact''s business mailing address (e.g., USA, CAN).',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this client contact record was first created in the PillarRx enterprise data platform. Supports audit trail and data lineage requirements.',
  department STRING COMMENT 'Organizational department of the contact at the employer client (e.g., Human Resources, Finance, Legal, Benefits Administration).',
  effective_date DATE COMMENT 'Date on which this contact became active and authorized to represent the client in PillarRx engagements. Used for eligibility and access control in consulting workflows.',
  email STRING COMMENT 'Primary business email address for the contact. Used for consulting report delivery, CAP program communications, and PBM audit correspondence.',
  fax STRING COMMENT 'Business fax number for the contact. Used for formal document transmission in benefits administration and PBM audit workflows.',
  first_name STRING COMMENT 'Given name of the client contact person (e.g., HR benefits manager, billing contact, executive sponsor).',
  is_primary BOOLEAN COMMENT 'Indicates whether this contact is the designated primary point of contact for the client. Each client should have exactly one primary contact per role type.',
  job_title STRING COMMENT 'Official job title of the contact at the employer client organization (e.g., Director of Benefits, VP of Human Resources, CFO).',
  last_name STRING COMMENT 'Family name of the client contact person.',
  linked_company_client_id BIGINT COMMENT 'FK to company.company_client.company_client_id — Contacts are employer-side people associated with a Client; Client FK is intrinsic.',
  linkedin_url STRING COMMENT 'LinkedIn profile URL for the contact. Used by PillarRx consulting team for relationship management and executive sponsor engagement tracking in Salesforce CRM.',
  mobile_phone STRING COMMENT 'Mobile phone number for the contact, stored in E.164 format. Used for urgent communications and two-factor authentication where applicable.',
  notes STRING COMMENT 'Free-text notes captured by the PillarRx consulting team regarding this contact, including relationship context, communication preferences, or engagement history.',
  phone STRING COMMENT 'Primary business phone number for the contact, stored in E.164 format. Used for direct outreach by PillarRx consulting team.',
  phone_extension STRING COMMENT 'Optional phone extension for the contact''s direct line within the employer organization''s phone system.',
  postal_code STRING COMMENT 'ZIP or ZIP+4 postal code for the contact''s business mailing address.',
  preferred_contact_method STRING COMMENT 'The contact''s preferred channel for receiving communications from PillarRx consulting team.',
  primary_company_client_id BIGINT COMMENT 'Reference to the employer client this contact is associated with, within the Company > Division > Client hierarchy.',
  receives_cap_communications BOOLEAN COMMENT 'Indicates whether this contact receives communications related to the Copay Assistance Program (CAP) managed via the PAX application.',
  receives_invoices BOOLEAN COMMENT 'Indicates whether this contact receives consulting fee invoices from PillarRx. Aligns with the billing contact role for NetSuite/Brown & Brown Finance AR workflows.',
  receives_reports BOOLEAN COMMENT 'Indicates whether this contact is on the distribution list for PillarRx consulting reports, benchmarking analyses, and PBM audit deliverables.',
  role_type STRING COMMENT 'Functional role this contact plays in the PillarRx client engagement. Drives routing of communications, invoices, and consulting deliverables. [ENUM-REF-CANDIDATE: promote to reference product if roles expand]',
  salesforce_contact_id BIGINT COMMENT 'Unique identifier for this contact record in the Salesforce CRM system. Enables bidirectional synchronization between the data lakehouse and CRM for consulting engagement management.',
  state_code STRING COMMENT 'Two-letter USPS state abbreviation for the contact''s business mailing address (e.g., MI, TX, CA).',
  termination_date DATE COMMENT 'Date on which this contact''s association with the client was terminated (e.g., employee departure, role change). Null if the contact is currently active.',
  tertiary_company_client_id BIGINT COMMENT 'FK to company.company_client.company_client_id — Contacts belong to a Client; CRM joins require this FK.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this client contact record was last modified. Used for change detection in ETL pipelines and Salesforce CRM synchronization.',
  CONSTRAINT pk_client_contact PRIMARY KEY (client_contact_id)
)
COMMENT 'Stores contact persons associated with a Client — including HR benefits managers, finance contacts, and executive sponsors. Captures full name, title, role type (primary benefits contact, billing contact, executive sponsor), email, phone, and active'
;

CREATE TABLE IF NOT EXISTS pillarrx.company.client_division_assignment (
  assignment_org_division_id BIGINT COMMENT 'FK to company.org_division.org_division_id — Bridge must resolve its Division endpoint; without both FKs the VREQ-004 multi-division modeling is non-functional.',
  assignment_reason STRING COMMENT 'Free-text description of the business rationale for creating or modifying this client-division assignment. Documents why a client spans multiple divisions or was reassigned.',
  assignment_status STRING COMMENT 'Current lifecycle status of the client-division assignment. Drives whether claims, eligibility, and reporting for this client are scoped to the linked division.',
  assignment_type STRING COMMENT 'Categorizes the purpose of the client-division link. Primary indicates the default division; secondary or reporting assignments support multi-division analytics and claims scoping.',
  cap_enabled BOOLEAN COMMENT 'Indicates whether the Copay Assistance Program (CAP) is active for members under this client-division assignment. Drives PAX application enrollment and copay card reconciliation workflows.',
  claims_scoped_flag BOOLEAN COMMENT 'Indicates whether pharmacy claims for this client are delivered and scoped at the division grain under this assignment. Drives PBM claims feed partitioning and reporting segmentation.',
  client_division_assignment_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the client-to-division assignment record. Primary key for this bridge entity linking an employer client to one or more organizational divisions.',
  client_division_fk BIGINT COMMENT 'FK to company.org_division.org_division_id — Bridge endpoint — Division side of the multi-division assignment.',
  client_division_org_division_id BIGINT COMMENT 'FK to company.org_division.org_division_id — Bridge side pointing to the Division a Client is assigned to (multi-division span support).',
  client_org_division_id BIGINT COMMENT 'Reference to the organizational division to which the client is assigned. A client may be linked to multiple divisions when data is delivered or scoped at the division grain.',
  company_client_id BIGINT COMMENT 'FK to company.company_client.company_client_id — Bridge endpoint — Client side of the multi-division assignment.',
  company_pbm_id BIGINT COMMENT 'Foreign key linking to company.pbm. Business justification: Division assignment may be scoped to a specific PBM (clients can have different PBMs for different divisions). Currently denormalized as pbm_source (STRING).',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this client-division assignment record was first created in the system. Provides the audit trail anchor for the records lifecycle.',
  data_sharing_consent BOOLEAN COMMENT 'Indicates whether the client has provided consent for PillarRx to receive and process claims and eligibility data scoped to this division assignment. Required for HIPAA BAA compliance.',
  dir_applicable BOOLEAN COMMENT 'Indicates whether Direct and Indirect Remuneration (DIR) fees apply to pharmacy reimbursements under this client-division assignment. Relevant for Medicare Part D plan auditing.',
  division_pbm_contract_id BIGINT COMMENT 'Foreign key linking to division.division_pbm_contract. Business justification: Assignment tracks which division-specific PBM contract applies to client''s division scope. Critical for claims routing, audit scope determination, and guarantee tracking.',
  effective_date DATE COMMENT 'Date on which the client-division assignment becomes active and binding for claims scoping, eligibility management, and consulting reporting purposes.',
  eligibility_scoped_flag BOOLEAN COMMENT 'Indicates whether member eligibility data for this client is managed and scoped at the division level under this assignment. Supports multi-division benefit group administration.',
  external_assignment_code STRING COMMENT 'Identifier for this client-division assignment as recorded in an external or upstream source system (e.g., Salesforce, PBM feed, eligibility management system). Supports cross-system reconciliation.',
  hipaa_baa_on_file BOOLEAN COMMENT 'Indicates whether a signed HIPAA Business Associate Agreement is on file for this client-division assignment, authorizing PillarRx to handle PHI on behalf of the client.',
  is_primary_division BOOLEAN COMMENT 'Indicates whether this division is the primary organizational division for the client. Exactly one active assignment per client should carry this flag as true for unambiguous default scoping.',
  medical_integration_flag BOOLEAN COMMENT 'Indicates whether medical claims data is integrated with pharmacy claims for Total Cost of Care (TCOC) analysis under this client-division assignment.',
  member_count INT COMMENT 'Number of active members associated with this client-division assignment at the time of last eligibility load. Used for PMPM rate calculations and division-level capacity planning.',
  org_division_id BIGINT COMMENT 'FK to company.org_division.org_division_id — Bridge resolves Client<->Division many-to-many; needs the Division leg.',
  override_indicator BOOLEAN COMMENT 'Indicates whether this assignment was manually overridden from the default division scoping logic. Flags records requiring additional audit scrutiny in the eligibility management system.',
  override_reason STRING COMMENT 'Explanation for why the default division assignment logic was overridden. Populated only when override_indicator is true. Supports audit trail for eligibility scoping decisions.',
  pass_through_pricing BOOLEAN COMMENT 'Indicates whether the PBM contract for this client-division assignment operates under a pass-through (transparent) pricing model rather than a spread-based model.',
  plan_year_end_date DATE COMMENT 'End date of the benefit plan year applicable to this client-division assignment. Defines the boundary for annual claims aggregation, OOP accumulator resets, and consulting deliverable scoping.',
  plan_year_start_date DATE COMMENT 'Start date of the benefit plan year applicable to this client-division assignment. Used to align claims analysis periods, deductible resets, and PMPM/PMPY reporting cycles.',
  primary_company_client_id BIGINT COMMENT 'Reference to the employer client being assigned to a division. Supports multi-division client scoping within the Company > Division > Client hierarchy.',
  prior_auth_tracking_flag BOOLEAN COMMENT 'Indicates whether prior authorization analytics are enabled for this client-division assignment. Activates PA data ingestion and reporting in the consulting analytics suite.',
  rds_eligible BOOLEAN COMMENT 'Indicates whether the client under this division assignment qualifies for the CMS Retiree Drug Subsidy program, applicable to employer-sponsored retiree prescription drug coverage.',
  rebate_pass_through BOOLEAN COMMENT 'Indicates whether manufacturer rebates are passed through to the client under the PBM contract associated with this client-division assignment. Relevant for pass-through pricing model audits.',
  reporting_scoped_flag BOOLEAN COMMENT 'Indicates whether consulting analytics and BI reporting for this client are segmented at the division grain under this assignment. Enables division-level benchmarking and trend analysis.',
  rx_bin STRING COMMENT 'Six-digit Bank Identification Number used for pharmacy claim routing to the PBM under this client-division assignment. Identifies the payer in the NCPDP claims adjudication network.',
  rx_group STRING COMMENT 'The RxGroup code used by the PBM to identify the benefit group associated with this client-division assignment. Used for claims routing and eligibility matching at the division grain.',
  rx_pcn STRING COMMENT 'Processor Control Number used alongside RxBIN to route pharmacy claims to the correct PBM processor for this client-division assignment. Enables sub-routing within a BIN.',
  salesforce_record_code STRING COMMENT 'Salesforce CRM record identifier corresponding to this client-division assignment. Enables bidirectional synchronization between the data lakehouse and the CRM for client management workflows.',
  specialty_carve_out BOOLEAN COMMENT 'Indicates whether specialty pharmacy benefits are carved out to a separate PBM or specialty pharmacy network for members under this client-division assignment.',
  termination_date DATE COMMENT 'Date on which the client-division assignment ends. Null indicates an open-ended active assignment. Used to enforce temporal scoping of claims and eligibility data.',
  tertiary_company_client_id BIGINT COMMENT 'FK to company.company_client.company_client_id — Bridge resolves Client<->Division many-to-many; needs the Client leg.',
  three_forty_b_eligible BOOLEAN COMMENT 'Indicates whether the client under this division assignment is eligible to participate in the federal 340B drug discount program administered by HRSA.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp of the most recent modification to this client-division assignment record. Used for change detection, incremental ETL processing, and audit compliance.',
  CONSTRAINT pk_client_division_assignment PRIMARY KEY (client_division_assignment_id)
)
COMMENT 'Bridge enabling a client to span multiple divisions and receive separate division-specific data'
;

CREATE TABLE IF NOT EXISTS pillarrx.company.client_onboarding (
  actual_go_live_date DATE COMMENT 'The actual date on which the client went live with PillarRx services, receiving first claims delivery and analytics access.',
  baa_executed BOOLEAN COMMENT 'Indicates whether a HIPAA-required Business Associate Agreement has been executed between PillarRx and the employer client prior to PHI data exchange.',
  baa_execution_date DATE COMMENT 'The date on which the HIPAA Business Associate Agreement was fully executed between PillarRx and the employer client.',
  cancellation_reason STRING COMMENT 'Describes the reason the onboarding engagement was cancelled, if applicable. Populated only when onboarding_status is ''cancelled''.',
  cap_enrollment_required BOOLEAN COMMENT 'Indicates whether the client requires setup of the Copay Assistance Program (CAP) in the PAX application as part of this onboarding engagement.',
  claims_history_start_date DATE COMMENT 'The earliest date of service for which historical pharmacy claims data will be extracted from the PBM for this client onboarding.',
  client_contact_email STRING COMMENT 'Email address of the primary contact at the employer client for onboarding coordination and communications.',
  client_contact_name STRING COMMENT 'Full name of the primary contact person at the employer client responsible for coordinating the onboarding engagement on the client side.',
  client_onboarding_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the client onboarding engagement record. Primary key for this entity.',
  company_client_id BIGINT COMMENT 'FK to company.company_client.company_client_id — Onboarding is a per-Client workflow; the Client FK is mandatory for workflow scoping.',
  company_pbm_id BIGINT COMMENT 'Foreign key linking to company.pbm. Business justification: Onboarding tracks which PBM the client is onboarding with. Currently denormalized as pbm_name (STRING).',
  created_timestamp TIMESTAMP COMMENT 'The timestamp when this onboarding engagement record was first created in the system, used for audit and lineage tracking.',
  eligibility_file_received BOOLEAN COMMENT 'Indicates whether the initial member eligibility file has been received from the client or PBM and loaded into the Eligibility Management System.',
  eligibility_load_date DATE COMMENT 'The date on which the initial member eligibility file was successfully loaded into the PillarRx Eligibility Management System.',
  engagement_name STRING COMMENT 'Human-readable name for this onboarding engagement, typically the employer client name and plan year (e.g., ''Acme Corp 2025 Onboarding'').',
  first_claims_file_date DATE COMMENT 'The date on which the first pharmacy claims data file was received from the PBM and ingested into the PillarRx claims feed platform.',
  first_claims_load_date DATE COMMENT 'The date on which the first pharmacy claims data file was successfully processed and loaded into the Enterprise Data Warehouse for this client.',
  medical_claims_integration_in_scope BOOLEAN COMMENT 'Indicates whether medical claims integration for Total Cost of Care (TCOC) analysis is included in the consulting scope for this onboarding.',
  member_count_expected INT COMMENT 'The anticipated number of eligible members (subscribers and dependents) expected to be loaded for this client plan, used for capacity planning.',
  member_count_loaded INT COMMENT 'The actual number of member eligibility records successfully loaded into the system, used to validate completeness against the expected count.',
  onboarding_lead STRING COMMENT 'Name of the PillarRx consulting team member responsible for managing and coordinating this client onboarding engagement.',
  onboarding_notes STRING COMMENT 'Free-text field for capturing key decisions, blockers, special instructions, or contextual notes relevant to this client onboarding engagement.',
  onboarding_status STRING COMMENT 'Current lifecycle state of the onboarding engagement, tracking progress from initiation through completion or cancellation.',
  onboarding_type STRING COMMENT 'Categorizes the nature of the onboarding engagement: new client, PBM transition, plan year renewal, adding a PBM feed, or expanding consulting scope.',
  org_division_id BIGINT COMMENT 'Reference to the division under which this client onboarding engagement is scoped within the organizational hierarchy.',
  organization_id BIGINT COMMENT 'Reference to the top-level company in the multi-tenant Company > Division > Client hierarchy for this onboarding engagement.',
  pax_setup_complete BOOLEAN COMMENT 'Indicates whether the PAX copay assistance management application has been fully configured for this client, including CAP enrollment and manufacturer program setup.',
  pbm_audit_in_scope BOOLEAN COMMENT 'Indicates whether PBM contract and guarantee audit services (discount, rebate, dispensing-fee guarantee auditing) are included in this onboarding engagement scope.',
  pbm_client_code STRING COMMENT 'The client identifier assigned by the PBM to this employer plan, used for claims feed extraction and data authorization requests.',
  pbm_data_agreement_signed BOOLEAN COMMENT 'Indicates whether the data use agreement or letter of authorization (LOA) with the PBM has been executed, enabling claims data extraction.',
  plan_effective_date DATE COMMENT 'The effective start date of the employer health plan being onboarded, which determines the claims history window and eligibility load period.',
  plan_year_end_date DATE COMMENT 'The end date of the employer plan year being onboarded, used to scope claims data extraction and benefit configuration.',
  primary_company_client_id BIGINT COMMENT 'Reference to the employer client being onboarded within the Company > Division > Client hierarchy.',
  prior_auth_analysis_in_scope BOOLEAN COMMENT 'Indicates whether prior authorization (PA) analytics are included in the consulting scope for this client onboarding engagement.',
  reporting_suite_provisioned BOOLEAN COMMENT 'Indicates whether the client''s access to the BI and Consulting Reporting Suite (benchmarking, trend, audit dashboards) has been provisioned.',
  requested_date DATE COMMENT 'The date on which the client onboarding engagement was formally requested or initiated, typically aligned with the Salesforce opportunity close date.',
  rx_bin STRING COMMENT 'The 6-digit Bank Identification Number (BIN) used to route pharmacy claims to the correct PBM processor for this client''s benefit plan.',
  rx_group STRING COMMENT 'The pharmacy benefit group identifier assigned by the PBM to this employer plan, used on member ID cards and for claims adjudication routing.',
  rx_pcn STRING COMMENT 'The Processor Control Number (PCN) used in conjunction with RxBIN to route pharmacy claims to the correct PBM sub-processor or plan.',
  salesforce_opportunity_code STRING COMMENT 'The Salesforce CRM opportunity or account record ID linked to this onboarding engagement, enabling traceability from sales to delivery.',
  target_go_live_date DATE COMMENT 'The planned date by which the client should be fully onboarded and receiving claims data and consulting deliverables.',
  tertiary_company_client_id BIGINT COMMENT 'FK to company.company_client.company_client_id — Onboarding tracks a specific Client''s provisioning lifecycle; must reference the Client.',
  updated_timestamp TIMESTAMP COMMENT 'The timestamp when this onboarding engagement record was most recently modified, supporting audit trail and change tracking.',
  CONSTRAINT pk_client_onboarding PRIMARY KEY (client_onboarding_id)
)
COMMENT 'Tracks the lifecycle of a new Client onboarding engagement at PillarRx — from initial data provisioning request through PBM feed setup, eligibility load, and first claims delivery.'
;

CREATE TABLE IF NOT EXISTS pillarrx.company.client_pbm_contract (
  audit_lookback_months INT COMMENT 'Number of months into the past that the client is contractually permitted to audit PBM claims and pricing. Defines the scope of PillarRx audit engagements.',
  audit_rights BOOLEAN COMMENT 'Indicates whether the client has contractual rights to audit PBM claims data and pricing. Foundational for PillarRx PBM audit engagements.',
  auto_renewal BOOLEAN COMMENT 'Indicates whether this contract automatically renews at the end of the plan year unless terminated. Relevant for contract lifecycle management and client notifications.',
  awp_edition_lag_days INT COMMENT 'Number of days of lag between the AWP pricing source publication date and the date used for claim adjudication under this contract. Affects audit accuracy.',
  awp_source STRING COMMENT 'Drug pricing reference source used to determine AWP for ingredient cost calculations under this contract (e.g., Medi-Span, First DataBank).',
  brand_effective_rate DECIMAL(7,4) COMMENT 'Contracted blended discount rate applied to brand drug ingredient costs, expressed as a percentage off AWP. Core PBM audit benchmark metric (BER).',
  claim_pbm_id BIGINT COMMENT 'FK to company.pbm.pbm_id — The other side of the Client<->PBM contract relationship; required for guarantee reconciliation and audit.',
  client_pbm_contract_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the client-PBM contract record. Primary key for this entity. MASTER_AGREEMENT role — effective-dated Type-2 contract between a client employer and a PBM.',
  company_client_id BIGINT COMMENT 'FK to company.company_client.company_client_id — Contract terms must resolve to the Client for guarantee reconciliation and audit — engineer would never ship without it.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM (e.g., CVS Caremark, Optum Rx, Express Scripts) that is the counterparty to this contract.',
  contract_name STRING COMMENT 'Human-readable name or title of the contract (e.g., ''Acme Corp CVS Caremark 2024 Agreement''). Used for display and reporting in the consulting suite.',
  contract_number STRING COMMENT 'Externally-known contract or agreement number assigned by the PBM or the client. Used for audit correspondence and PBM reconciliation. BUSINESS_IDENTIFIER for this agreement.',
  contract_pbm_fk BIGINT COMMENT 'FK to company.pbm.pbm_id — Contract terms are between a Client and a specific PBM; audit joins require the PBM identity.',
  contract_status STRING COMMENT 'Current lifecycle state of the client-PBM contract. LIFECYCLE_STATUS for this MASTER_AGREEMENT. Drives eligibility for claims processing and audit scope.',
  contract_type STRING COMMENT 'Classification of the employer plan funding arrangement under this contract: fully-insured, self-funded, Administrative Services Only (ASO), or hybrid.',
  dir_fee_applicable BOOLEAN COMMENT 'Indicates whether Direct and Indirect Remuneration (DIR) fees apply under this contract. DIR fees affect net drug cost and are a key audit focus.',
  effective_date DATE COMMENT 'Date on which this contract version becomes binding and claims processing begins under its terms. EFFECTIVE_FROM for Type-2 history tracking.',
  formulary_name STRING COMMENT 'Name of the drug formulary (covered drug list) applied under this contract. Identifies the tier structure and coverage rules governing member cost-sharing.',
  formulary_type STRING COMMENT 'Classification of the formulary structure: open (all drugs covered), closed (only listed drugs covered), or incentive (tiered cost-sharing to steer utilization).',
  gdr_guarantee_pct DECIMAL(7,4) COMMENT 'Contractually guaranteed minimum Generic Dispensing Rate (GDR) — the percentage of claims that must be dispensed as generics. Used in PBM performance auditing.',
  generic_effective_rate DECIMAL(7,4) COMMENT 'Contracted blended discount rate applied to generic drug ingredient costs, expressed as a percentage off AWP. Core PBM audit benchmark metric (GER).',
  mac_appeal_turnaround_days INT COMMENT 'Contractually required number of business days within which the PBM must respond to a MAC pricing appeal. Relevant for state MAC transparency law compliance.',
  mac_list_name STRING COMMENT 'Name or identifier of the Maximum Allowable Cost (MAC) list used by the PBM for generic drug reimbursement under this contract.',
  mail_brand_awp_discount DECIMAL(7,4) COMMENT 'Contracted AWP discount percentage for brand drugs dispensed via mail-order pharmacy. Used in mail-order guarantee reconciliation.',
  mail_dispensing_fee DECIMAL(8,4) COMMENT 'Contracted per-claim dispensing fee (in USD) paid to mail-order pharmacies under this contract. Used in dispensing-fee guarantee reconciliation.',
  mail_generic_awp_discount DECIMAL(7,4) COMMENT 'Contracted AWP discount percentage for generic drugs dispensed via mail-order pharmacy. Typically higher than retail due to volume.',
  mail_order_mandatory BOOLEAN COMMENT 'Indicates whether the contract requires mandatory mail-order dispensing for maintenance medications. Affects member cost-sharing and pharmacy channel routing.',
  notes STRING COMMENT 'Free-text field for consulting team annotations regarding contract terms, negotiation history, or audit findings relevant to this contract version.',
  notice_period_days INT COMMENT 'Number of days of advance written notice required to terminate this contract. Critical for client transition planning and PBM audit engagement timelines.',
  pbm_fk BIGINT COMMENT 'FK to company.pbm.pbm_id — Each contract binds a Client to a specific PBM; the PBM master is required to interpret BIN/PCN routing and contract model. No engineer would ship the contract table without this FK.',
  plan_year_end_date DATE COMMENT 'Last day of the employer plan year covered by this contract. Used to scope claims analysis and guarantee reconciliation periods.',
  plan_year_start_date DATE COMMENT 'First day of the employer plan year covered by this contract. May differ from the contract effective date for mid-year amendments.',
  pricing_model STRING COMMENT 'Contractual pricing arrangement between the client and PBM. Pass-through: client pays actual drug cost. Spread: PBM retains difference. Hybrid: combination of both. CLASSIFICATION_OR_TYPE for this agreement.',
  primary_company_client_id BIGINT COMMENT 'Reference to the employer client who is party to this PBM contract. Links to the client entity within the Company > Division > Client hierarchy.',
  rebate_guarantee_pmpm DECIMAL(10,4) COMMENT 'Contractually guaranteed minimum rebate amount per member per month (PMPM) that the PBM must pass through to the client. Used in rebate reconciliation.',
  rebate_pass_through_pct DECIMAL(7,4) COMMENT 'Percentage of manufacturer rebates that the PBM is contractually required to pass through to the client. 100% = full pass-through model.',
  retail_brand_awp_discount DECIMAL(7,4) COMMENT 'Contracted AWP discount percentage for brand drugs dispensed at retail pharmacies. Core input for PBM discount guarantee auditing.',
  retail_dispensing_fee DECIMAL(8,4) COMMENT 'Contracted per-claim dispensing fee (in USD) paid to retail pharmacies under this contract. Component of dispensing-fee guarantee auditing.',
  retail_generic_awp_discount DECIMAL(7,4) COMMENT 'Contracted AWP discount percentage for generic drugs dispensed at retail pharmacies. Used in PBM guarantee reconciliation and audit.',
  rx_bin STRING COMMENT 'Six-digit Bank Identification Number (BIN) used to route pharmacy claims to the correct PBM processor under this contract. Required for claims adjudication.',
  rx_group STRING COMMENT 'Pharmacy benefit group identifier used in claim adjudication to identify the specific benefit plan under this contract at the point of dispensing.',
  rx_pcn STRING COMMENT 'Processor Control Number (PCN) used alongside RxBIN to route pharmacy claims to the correct PBM plan or benefit group under this contract.',
  scc_version STRING COMMENT 'Version label for this Type-2 slowly changing contract record (e.g., ''v1'', ''v2''). Supports historical contract term tracking across amendments and renewals.',
  specialty_brand_awp_discount DECIMAL(7,4) COMMENT 'Contracted AWP discount percentage for brand specialty drugs. Critical for specialty spend monitoring and PBM audit deliverables.',
  specialty_carve_out BOOLEAN COMMENT 'Indicates whether specialty drug management is carved out to a separate specialty PBM or vendor rather than managed under this primary PBM contract.',
  specialty_dispensing_fee DECIMAL(8,4) COMMENT 'Contracted per-claim dispensing fee (in USD) paid to specialty pharmacies under this contract. Specialty fee structures often differ from retail.',
  specialty_drug_list_name STRING COMMENT 'Name of the specialty drug list (Limited Distribution Drug list or specialty tier) applied under this contract for specialty medication management.',
  specialty_generic_awp_discount DECIMAL(7,4) COMMENT 'Contracted AWP discount percentage for generic specialty drugs. Specialty pharmacy spend is a primary cost driver requiring separate tracking.',
  superseded_by_client_pbm_contract_id BIGINT COMMENT 'Reference to the newer client_pbm_contract record that replaced this version. Null for the current active version. Supports Type-2 SCD chain navigation.',
  termination_date DATE COMMENT 'Date on which this contract version ceases to be binding. Null for open-ended or currently active contracts. EFFECTIVE_UNTIL for Type-2 history tracking.',
  tertiary_company_client_id BIGINT COMMENT 'FK to company.company_client.company_client_id — A PBM contract is for a specific Client; without this FK the Type-2 contract terms cannot be joined to the employer they govern for guarantee reconciliation.',
  three_forty_b_applicable BOOLEAN COMMENT 'Indicates whether the 340B federal drug discount program applies to any covered entities under this contract. Affects drug cost calculations and audit scope.',
  CONSTRAINT pk_client_pbm_contract PRIMARY KEY (client_pbm_contract_id)
)
COMMENT 'Effective-dated (Type-2) master of the contractual relationship between a Client and a PBM for a defined plan year/contract term. Captures pricing model (pass-through, spread, hybrid), generic effective rate (GER), brand effective rate (BER), AWP discount'
;

CREATE TABLE IF NOT EXISTS pillarrx.company.company_benefit_group (
  accumulator_integration_type STRING COMMENT 'Defines how copay assistance program (CAP) payments are treated in deductible and OOP accumulators. Determines whether manufacturer copay card amounts count toward member cost-sharing.',
  benefit_group_code STRING COMMENT 'Externally-known alphanumeric code identifying the benefit group as assigned by the PBM or employer plan. Used for claims routing and eligibility matching.',
  benefit_group_name STRING COMMENT 'Human-readable name of the benefit group as defined by the employer plan (e.g., ''Active Employees PPO'', ''Retirees HRA''). Used in reporting and member communications.',
  benefit_group_status STRING COMMENT 'Current lifecycle state of the benefit group. Drives eligibility adjudication and reporting inclusion. Active groups are currently in force for member enrollment.',
  company_benefit_group_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the benefit group record in the PillarRx data platform. Primary key for the company_benefit_group entity.',
  company_client_fk BIGINT COMMENT 'FK to company.company_client.company_client_id — Benefit groups belong to a Client; eligibility and claims resolve plan design through this FK.',
  company_client_id BIGINT COMMENT 'FK to company.company_client.company_client_id — A benefit group is a plan-design unit under a Client; eligibility and claims scope through this FK.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM (e.g., CVS Caremark, Optum Rx, Express Scripts) that administers this benefit group on behalf of the client.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this benefit group record was first created in the PillarRx data platform. Audit field for data governance and lineage tracking.',
  daw_brand_penalty_amount DECIMAL(10,2) COMMENT 'Additional dollar amount charged to the member when a brand drug is dispensed and a generic equivalent is available (DAW penalty). Null if daw_policy does not impose a penalty.',
  daw_policy STRING COMMENT 'Plan policy governing how Dispense As Written (DAW) codes affect member cost-sharing. Determines whether members pay a brand penalty when a generic equivalent is available.',
  deductible_family_amount DECIMAL(12,2) COMMENT 'Aggregate dollar amount a family unit must pay out-of-pocket for covered pharmacy claims before the plan begins to pay for any family member.',
  deductible_individual_amount DECIMAL(12,2) COMMENT 'Dollar amount an individual member must pay out-of-pocket for covered pharmacy claims before the plan begins to pay. Resets each plan year.',
  division_formulary_id BIGINT COMMENT 'Reference to the formulary (covered drug list) assigned to this benefit group, defining which drugs are covered and at what tier.',
  effective_date DATE COMMENT 'Date on which this benefit group design becomes effective and governs pharmacy benefit adjudication for enrolled members. Start of the plan year or mid-year amendment date.',
  formulary_tier_count INT COMMENT 'Number of cost-sharing tiers defined in the formulary structure for this benefit group (e.g., 3-tier: generic/preferred brand/non-preferred brand).',
  is_current_record BOOLEAN COMMENT 'Type-2 Slowly Changing Dimension (SCD) flag. True indicates this is the currently active version of the benefit group record. False indicates a historical version superseded by a later amendment.',
  ldd_carve_out BOOLEAN COMMENT 'Indicates whether limited distribution drugs (LDD) are carved out to a specific specialty pharmacy or handled under a separate benefit arrangement for this benefit group.',
  mail_days_supply_standard INT COMMENT 'Standard days supply allowed per mail-order pharmacy fill under this benefit group (e.g., 90 days). Typically 3x the retail days supply.',
  mail_order_mandatory BOOLEAN COMMENT 'Indicates whether this benefit group mandates mail-order dispensing for maintenance medications after a defined number of retail fills. True = mandatory mail-order program in effect.',
  mail_order_mandatory_fill_threshold INT COMMENT 'Number of retail fills allowed for a maintenance drug before mail-order becomes mandatory. Applicable only when mail_order_mandatory is True.',
  moop_family_amount DECIMAL(12,2) COMMENT 'Maximum aggregate dollar amount a family unit pays in cost-sharing per plan year before the plan covers 100% of covered pharmacy costs for all family members.',
  moop_individual_amount DECIMAL(12,2) COMMENT 'Maximum dollar amount an individual member pays in cost-sharing per plan year before the plan covers 100% of covered pharmacy costs. ACA-mandated limit.',
  plan_year_end_date DATE COMMENT 'Last day of the benefit plan year associated with this benefit group. Marks the end of the accumulator period for deductible and out-of-pocket tracking.',
  plan_year_start_date DATE COMMENT 'First day of the benefit plan year associated with this benefit group. Deductible and out-of-pocket accumulators reset on this date annually.',
  primary_company_client_id BIGINT COMMENT 'Reference to the employer client under whose plan this benefit group is defined. Aligns with the Company > Division > Client hierarchy.',
  prior_auth_required BOOLEAN COMMENT 'Indicates whether this benefit group applies prior authorization (PA) requirements for certain drug classes or tiers. True = PA program is active for this benefit group.',
  quantity_limit_applied BOOLEAN COMMENT 'Indicates whether quantity limit (QL) edits are applied to claims under this benefit group, restricting the dispensed quantity to plan-defined maximums.',
  rebate_pass_through BOOLEAN COMMENT 'Indicates whether manufacturer rebates collected by the PBM are passed through to the employer client plan. True = pass-through (transparent) model; False = spread/retained model.',
  record_effective_date DATE COMMENT 'Date on which this specific SCD Type-2 version of the benefit group record became the active version in the data platform. Distinct from the business effective_date.',
  record_expiration_date DATE COMMENT 'Date on which this SCD Type-2 version of the benefit group record was superseded by a newer version. Null for the current active record. Enables point-in-time historical queries.',
  retail_days_supply_standard INT COMMENT 'Standard days supply allowed per retail pharmacy fill under this benefit group (e.g., 30 days). Drives quantity limit edits and cost-sharing calculations.',
  rx_bin STRING COMMENT 'Six-digit Bank Identification Number (BIN) printed on the member ID card and transmitted on pharmacy claims to route the claim to the correct PBM processor.',
  rx_group STRING COMMENT 'RxGroup code transmitted on pharmacy claims to identify the benefit group at point-of-sale. Used by pharmacies to route claims to the correct PBM plan.',
  rx_pcn STRING COMMENT 'Processor Control Number (PCN) used alongside RxBIN to further route pharmacy claims to the correct PBM sub-processor or plan segment.',
  source_system_code STRING COMMENT 'Code identifying the operational source system from which this benefit group record was ingested (e.g., ''EMS'' for Eligibility Management System, ''CVS'' for CVS Caremark feed).',
  specialty_coinsurance_pct DECIMAL(5,4) COMMENT 'Member coinsurance rate (as a decimal, e.g., 0.20 = 20%) applied to specialty medication claims. Used when specialty drugs are subject to coinsurance rather than a flat copay.',
  specialty_oop_max_amount DECIMAL(12,2) COMMENT 'Maximum annual out-of-pocket amount a member pays specifically for specialty medications under this benefit group, if a separate specialty OOP cap is defined.',
  specialty_pharmacy_network STRING COMMENT 'Defines the specialty pharmacy network structure for this benefit group. Determines which specialty pharmacies members may use for specialty medication dispensing.',
  step_therapy_required BOOLEAN COMMENT 'Indicates whether step therapy (ST) protocols are enforced under this benefit group, requiring members to try lower-cost alternatives before accessing higher-tier drugs.',
  termination_date DATE COMMENT 'Date on which this benefit group design ceases to be effective. Null for open-ended active groups. Supports Type-2 SCD history for plan design changes.',
  tier1_copay_mail_amount DECIMAL(10,2) COMMENT 'Fixed member copay for Tier 1 (generic) drugs dispensed via mail-order pharmacy. Typically lower than retail to incentivize mail-order utilization.',
  tier1_copay_retail_amount DECIMAL(10,2) COMMENT 'Fixed member copay for Tier 1 (typically generic) drugs dispensed at a retail pharmacy. Core cost-sharing parameter for plan design analysis.',
  tier2_copay_mail_amount DECIMAL(10,2) COMMENT 'Fixed member copay for Tier 2 (preferred brand) drugs dispensed via mail-order pharmacy.',
  tier2_copay_retail_amount DECIMAL(10,2) COMMENT 'Fixed member copay for Tier 2 (typically preferred brand) drugs dispensed at a retail pharmacy.',
  tier3_copay_mail_amount DECIMAL(10,2) COMMENT 'Fixed member copay for Tier 3 (non-preferred brand) drugs dispensed via mail-order pharmacy.',
  tier3_copay_retail_amount DECIMAL(10,2) COMMENT 'Fixed member copay for Tier 3 (typically non-preferred brand) drugs dispensed at a retail pharmacy.',
  tier4_copay_retail_amount DECIMAL(10,2) COMMENT 'Fixed member copay for Tier 4 (typically specialty or non-formulary) drugs dispensed at a retail pharmacy. Null if the benefit group has fewer than 4 tiers.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this benefit group record was last modified in the PillarRx data platform. Used for change detection and audit trail maintenance.',
  CONSTRAINT pk_company_benefit_group PRIMARY KEY (company_benefit_group_id)
)
COMMENT 'Effective-dated plan-design unit (benefit group / BG) governing pharmacy benefit rules for a cohort of members under a Client. Stores RxGroup identifier, BIN, PCN, formulary tier structure, deductible, copay/coinsurance schedule, MOOP, DAW policy'
;

CREATE TABLE IF NOT EXISTS pillarrx.company.company_client (
  billing_address_city STRING COMMENT 'City component of the employer Client''s billing address for consulting fee invoicing and regulatory jurisdiction determination.',
  billing_address_line1 STRING COMMENT 'First line of the employer Client''s billing address used for consulting fee invoicing through NetSuite and Brown & Brown Finance accounts receivable.',
  billing_address_state STRING COMMENT 'Two-letter U.S. state code for the employer Client''s billing address. Used for state PBM transparency law compliance, state board of pharmacy jurisdiction, and tax reporting.',
  billing_address_zip STRING COMMENT 'ZIP or ZIP+4 postal code for the employer Client''s billing address. Used for geographic segmentation, state jurisdiction mapping, and consulting fee invoicing.',
  cap_enrolled_flag BOOLEAN COMMENT 'Indicates whether the employer Client participates in PillarRx''s Copay Assistance Program (CAP) managed via the PAX application for manufacturer copay card and coupon tracking.',
  client_code STRING COMMENT 'Externally-known short alphanumeric code uniquely identifying the employer Client across PillarRx systems, PBM feeds, and consulting deliverables. Used as the operational business key.',
  client_name STRING COMMENT 'Full legal name of the employer Client organization as registered. Used in consulting reports, PBM audit deliverables, and client-facing communications.',
  client_status STRING COMMENT 'Current lifecycle status of the employer Client engagement with PillarRx. Controls data ingestion, reporting eligibility, and consulting service delivery.',
  client_type STRING COMMENT 'Classification of the employer Client by organizational type. Drives benefit design expectations, regulatory obligations (ERISA, DOL), and benchmarking peer groupings.',
  company_client_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the employer Client record within the Company > Division > Client hierarchy. Primary key for the company_client entity.',
  company_division_fk BIGINT COMMENT 'FK to company.org_division.org_division_id — Client''s primary Division linkage (leaf of the hierarchy). Needed for tenant scoping of claims/members.',
  company_org_division_fk BIGINT COMMENT 'FK to company.org_division.org_division_id — A Client is the leaf under a Division. Required to resolve the tenancy chain and scope claims/members.',
  company_org_division_id BIGINT COMMENT 'FK to company.org_division.org_division_id — Client''s primary Division linkage in the Company>Division>Client hierarchy (VREQ-003). Keep as primary assignment; multi-division spans handled via client_division_assignment bridge.',
  consulting_fee_model STRING COMMENT 'Billing model used for PillarRx consulting fees for this employer Client. Drives revenue recognition in NetSuite and Brown & Brown Finance. PMPM = Per Member Per Month.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the employer Client record was first created in the PillarRx data platform. Supports audit trail, data lineage, and onboarding timeline tracking.',
  data_feed_frequency STRING COMMENT 'Frequency at which pharmacy claims data is received from the PBM(s) for this employer Client. Governs ETL scheduling in the PBM Claims Feed Ingestion Platform.',
  effective_date DATE COMMENT 'Date on which the employer Client''s engagement with PillarRx became active and pharmacy claims data ingestion commenced. Start of the binding consulting relationship.',
  employee_count INT COMMENT 'Total number of employees at the employer Client organization. Used for plan size segmentation, benchmarking peer grouping, and consulting engagement scoping.',
  formulary_type STRING COMMENT 'Classification of the employer Client''s drug formulary structure. Open formularies cover all drugs; closed restrict to listed drugs; incentive tiers guide member cost-sharing.',
  industry_segment STRING COMMENT 'Industry classification of the employer Client (e.g., manufacturing, retail, healthcare, education). Used for benchmarking pharmacy spend against industry peers.',
  medical_integration_flag BOOLEAN COMMENT 'Indicates whether medical claims data is integrated for this employer Client to support Total Cost of Care (TCOC) analysis alongside pharmacy claims.',
  member_count INT COMMENT 'Current number of eligible members (subscribers and dependents) enrolled under this employer Client''s pharmacy benefit plan. Used for PMPM and PMPY calculations.',
  multi_pbm_flag BOOLEAN COMMENT 'Indicates whether the employer Client uses more than one PBM for pharmacy benefit administration. Drives Member 360 identity resolution logic and cross-PBM normalization workflows.',
  naics_code STRING COMMENT 'Six-digit NAICS code classifying the employer Client''s primary business activity. Supports industry-level benchmarking and regulatory reporting segmentation.',
  netsuite_customer_code STRING COMMENT 'Unique identifier for this employer Client in the NetSuite financial system used by Brown & Brown Finance for consulting fee billing, GL posting, and accounts receivable.',
  onboarding_date DATE COMMENT 'Date on which the employer Client''s onboarding process was initiated in PillarRx systems. Distinct from effective_date; tracks the operational start of data provisioning.',
  org_division_id BIGINT COMMENT 'FK to company.org_division.org_division_id — Leaf node of hierarchy references its parent Division (primary assignment); core to Company>Division>Client.',
  pass_through_model BOOLEAN COMMENT 'Indicates whether the employer Client operates under a pass-through (transparent) PBM pricing model where actual drug costs are passed to the plan without spread. Drives audit methodology.',
  pbm_contract_number STRING COMMENT 'Contract or account number assigned by the primary PBM to identify this employer Client''s pharmacy benefit arrangement. Used in PBM audit and guarantee reconciliation.',
  plan_name STRING COMMENT 'Name of the employer-sponsored health plan under which pharmacy benefits are administered. Appears on member communications, EOBs, and PBM contract documents.',
  plan_year_start_month INT COMMENT 'Calendar month (1–12) in which the employer''s benefit plan year begins. Determines deductible reset, OOP accumulator logic, and annual trend reporting periods.',
  primary_contact_email STRING COMMENT 'Email address of the primary benefits administrator at the employer Client. Used for consulting deliverable distribution and CAP program communications via PAX.',
  primary_contact_name STRING COMMENT 'Full name of the primary benefits administrator or HR contact at the employer Client organization. Used for consulting engagement communications and report delivery.',
  primary_contact_phone STRING COMMENT 'Phone number of the primary benefits administrator at the employer Client organization. Used for consulting engagement coordination and urgent issue escalation.',
  primary_pbm STRING COMMENT 'The principal PBM administering pharmacy benefits for this employer Client. A client may have multiple PBMs; this identifies the primary one for reporting defaults.',
  prior_auth_tracking_flag BOOLEAN COMMENT 'Indicates whether Prior Authorization (PA) analytics are enabled for this employer Client, enabling PA approval rate, denial trend, and step therapy compliance reporting.',
  rebate_sharing_pct DECIMAL(5,2) COMMENT 'Percentage of manufacturer rebates passed through to the employer Client by the PBM under the contract terms. Used in PBM guarantee reconciliation and DIR analysis.',
  retiree_drug_subsidy_flag BOOLEAN COMMENT 'Indicates whether the employer Client participates in the CMS Retiree Drug Subsidy (RDS) program, which provides federal subsidy payments for qualifying retiree drug coverage.',
  rx_bin STRING COMMENT 'Six-digit Bank Identification Number (BIN) used to route pharmacy claims to the correct PBM processor at point of sale. Printed on the member''s pharmacy ID card.',
  rx_group STRING COMMENT 'RxGroup identifier used on pharmacy claims to route adjudication to the correct employer benefit plan. Corresponds to the group field on the member''s pharmacy ID card.',
  rx_pcn STRING COMMENT 'Processor Control Number (PCN) used alongside RxBIN to route pharmacy claims to the correct plan within a PBM. Printed on the member''s pharmacy ID card.',
  salesforce_account_code STRING COMMENT 'Unique identifier for this employer Client in the Salesforce CRM system. Enables cross-system linkage between the data lakehouse and consulting engagement management records.',
  short_name STRING COMMENT 'Abbreviated or commonly-used display name for the employer Client. Used in dashboards, report headers, and UI labels where the full legal name is too long.',
  specialty_carve_out_flag BOOLEAN COMMENT 'Indicates whether specialty pharmacy benefits are carved out to a separate specialty PBM or vendor rather than managed under the primary PBM contract. Affects claims routing.',
  tax_identification_number STRING COMMENT 'Federal Employer Identification Number (EIN) assigned by the IRS. Used for ERISA plan identification, regulatory filings, and Brown & Brown finance reconciliation.',
  termination_date DATE COMMENT 'Date on which the employer Client''s engagement with PillarRx ended. Null for active clients. Used to scope claims analysis windows and close out consulting engagements.',
  three_forty_b_eligible_flag BOOLEAN COMMENT 'Indicates whether the employer Client or any of its covered entities qualifies for the federal 340B drug discount program administered by HRSA.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when the employer Client record was most recently modified in the PillarRx data platform. Supports change detection, ETL incremental loads, and audit trail.',
  CONSTRAINT pk_company_client PRIMARY KEY (company_client_id)
)
COMMENT 'Master record for an employer Client — the leaf node of the Company > Division > Client hierarchy. Each Client is an employer whose health plan members fill prescriptions through one or more PBMs.'
;

CREATE TABLE IF NOT EXISTS pillarrx.company.company_consulting_engagement (
  account_manager_code BIGINT COMMENT 'Reference to the PillarRx account manager or client relationship owner responsible for the client relationship associated with this engagement.',
  actual_completion_date DATE COMMENT 'The actual date on which all deliverables for the consulting engagement were completed and accepted by the client.',
  audit_finding_count INT COMMENT 'Number of discrete audit findings or exceptions identified during a PBM audit engagement. Applicable when engagement_type is pbm_audit.',
  awp_discount_baseline_pct DECIMAL(5,2) COMMENT 'Client''s effective AWP discount rate at the start of the engagement, used as the benchmark for PBM contract guarantee audit comparisons.',
  cap_program_included BOOLEAN COMMENT 'Indicates whether Copay Assistance Program (CAP) setup, analysis, or management is within the scope of this consulting engagement.',
  claims_analysis_period_end DATE COMMENT 'End of the pharmacy claims data window being analyzed for this engagement.',
  claims_analysis_period_start DATE COMMENT 'Start of the pharmacy claims data window being analyzed for this engagement (e.g., beginning of the audit or benchmarking period).',
  client_satisfaction_score DECIMAL(3,1) COMMENT 'Post-engagement client satisfaction rating on a 1.0–5.0 scale, collected via client feedback survey. Supports consulting quality management.',
  collected_amount DECIMAL(18,2) COMMENT 'Total amount received from the client for this engagement to date, in USD. Supports AR aging and cash collection tracking.',
  company_client_fk BIGINT COMMENT 'FK to company.company_client.company_client_id — Engagement is delivered to a Client; billing and deliverables resolve through this FK.',
  company_client_id BIGINT COMMENT 'FK to company.company_client.company_client_id — Every engagement is delivered to a Client; the engagement master references the Client.',
  company_consulting_engagement_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for a PillarRx consulting engagement record in the enterprise data warehouse.',
  contracted_fee_amount DECIMAL(18,2) COMMENT 'Total consulting fee agreed in the Statement of Work for this engagement, in USD. Revenue basis for PillarRx fee-based consulting model.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this consulting engagement record was first created in the enterprise data warehouse.',
  currency_code STRING COMMENT 'ISO 4217 three-letter currency code for all monetary amounts on this engagement. Typically USD for PillarRx domestic employer clients.',
  delivery_model STRING COMMENT 'Mode of engagement delivery indicating whether consulting services are delivered remotely, on-site at the client location, or in a hybrid arrangement.',
  end_date DATE COMMENT 'The contractually agreed date on which the consulting engagement scope of work is expected to conclude. Nullable for open-ended engagements.',
  engagement_description STRING COMMENT 'Free-text narrative describing the scope, objectives, and deliverables of the consulting engagement as agreed in the Statement of Work.',
  engagement_name STRING COMMENT 'Descriptive title of the consulting engagement (e.g., ''FY2024 PBM Audit – Acme Corp'', ''CAP Program Setup – Q1 2025'').',
  engagement_number STRING COMMENT 'Externally-visible alphanumeric reference code assigned to this consulting engagement, used in client communications, SOWs, and invoicing.',
  engagement_status STRING COMMENT 'Current lifecycle state of the consulting engagement from initiation through delivery and closure.',
  engagement_type STRING COMMENT 'Classification of the consulting engagement by service type delivered. [ENUM-REF-CANDIDATE: pbm_audit|benchmarking|formulary_analysis|cap_setup|tcoc_review|prior_auth_analysis|specialty_review|rebate_audit|custom — promote to reference product]',
  estimated_savings_amount DECIMAL(18,2) COMMENT 'Projected dollar savings identified for the client as a result of this engagement (e.g., AWP discount improvements, rebate recovery, DIR recoupment).',
  fee_structure_type STRING COMMENT 'Billing model governing how consulting fees are charged for this engagement (e.g., fixed project fee, hourly rate, milestone-based, retainer).',
  gdr_baseline_pct DECIMAL(5,2) COMMENT 'Client''s Generic Dispensing Rate at the start of the engagement period, expressed as a percentage. Baseline for benchmarking and opportunity identification.',
  invoiced_amount DECIMAL(18,2) COMMENT 'Total amount invoiced to the client for this engagement to date, in USD. Used for revenue recognition and AR reconciliation in NetSuite.',
  is_recurring BOOLEAN COMMENT 'Indicates whether this engagement is part of a recurring annual or periodic consulting arrangement with the client (e.g., annual PBM audit).',
  lead_consultant_code BIGINT COMMENT 'Reference to the PillarRx internal staff member designated as the lead consultant responsible for delivering this engagement.',
  org_division_id BIGINT COMMENT 'Reference to the division within the organizational hierarchy under which this engagement is scoped.',
  parent_engagement_company_consulting_engagement_id BIGINT COMMENT 'Self-referencing identifier linking this engagement to a parent engagement when it is a sub-engagement or renewal of a prior scoped project.',
  pbm_in_scope STRING COMMENT 'Comma-delimited list of PBMs whose data is under analysis for this engagement (e.g., CVS Caremark, Optum Rx, Express Scripts). Supports multi-PBM audit scoping.',
  primary_company_client_id BIGINT COMMENT 'Reference to the employer client for whom this consulting engagement is being delivered within the Company > Division > Client hierarchy.',
  prior_auth_analysis_included BOOLEAN COMMENT 'Indicates whether Prior Authorization (PA) utilization analysis is within the scope of this consulting engagement.',
  priority_level STRING COMMENT 'Business priority assigned to this engagement, used for resource allocation and scheduling across PillarRx consulting capacity.',
  realized_savings_amount DECIMAL(18,2) COMMENT 'Actual dollar savings confirmed as realized by the client following implementation of recommendations from this engagement.',
  rebate_guarantee_reviewed BOOLEAN COMMENT 'Indicates whether PBM rebate guarantees were included in the scope of this engagement (e.g., rebate audit or GER/BER reconciliation).',
  salesforce_opportunity_code STRING COMMENT 'The Salesforce CRM opportunity record identifier linked to this consulting engagement, enabling traceability from sales pipeline to delivery.',
  signed_date DATE COMMENT 'Date the Statement of Work (SOW) or consulting agreement was executed and signed by both PillarRx and the client.',
  sow_document_reference STRING COMMENT 'Document management system reference or URL pointing to the executed Statement of Work for this engagement.',
  specialty_spend_reviewed DECIMAL(18,2) COMMENT 'Subset of total plan spend attributable to specialty medications within the engagement scope. Supports specialty pharmacy trend analysis.',
  start_date DATE COMMENT 'The contractually agreed date on which the consulting engagement scope of work begins.',
  tcoc_integration_included BOOLEAN COMMENT 'Indicates whether medical claims integration for Total Cost of Care (TCOC) analysis is within the scope of this consulting engagement.',
  total_plan_spend_reviewed DECIMAL(18,2) COMMENT 'Aggregate plan-paid pharmacy spend (in USD) across all claims within the scope of this engagement. Basis for benchmarking and audit materiality.',
  total_rx_claims_reviewed BIGINT COMMENT 'Total count of pharmacy claims included in the scope of analysis for this engagement. Key volume metric for PBM audit and benchmarking engagements.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this consulting engagement record was last modified in the enterprise data warehouse.',
  CONSTRAINT pk_company_consulting_engagement PRIMARY KEY (company_consulting_engagement_id)
)
COMMENT 'Master record for a consulting engagement delivered by PillarRx to a Client. Represents a scoped, fee-based advisory project such as a PBM audit, benchmarking study, formulary analysis, CAP program setup, or total cost of care review.'
;

CREATE TABLE IF NOT EXISTS pillarrx.company.company_engagement_deliverable (
  actual_fee_usd DECIMAL(18,2) COMMENT 'Actual consulting fee in US dollars billed or to be billed for this deliverable. May differ from estimated fee due to scope changes or adjustments.',
  analysis_period_end_date DATE COMMENT 'End date of the pharmacy claims or data analysis window covered by this deliverable (e.g., last date of service included in a PBM audit).',
  analysis_period_start_date DATE COMMENT 'Start date of the pharmacy claims or data analysis window covered by this deliverable (e.g., first date of service included in a PBM audit).',
  audit_finding_count INT COMMENT 'Number of discrete audit findings or recommendations included in this deliverable. Applicable to PBM audit and guarantee reconciliation deliverable types.',
  awp_discount_reported DECIMAL(5,4) COMMENT 'Effective AWP discount percentage reported in this deliverable for brand or generic drugs, expressed as a decimal. Core PBM contract guarantee audit metric.',
  billable_indicator BOOLEAN COMMENT 'Indicates whether this deliverable is billable to the client as part of the consulting engagement fee structure. False for complimentary or internal deliverables.',
  billing_milestone_code STRING COMMENT 'Code referencing the consulting fee billing milestone in NetSuite that this deliverable triggers upon acceptance. Links deliverable completion to revenue recognition.',
  cap_savings_usd DECIMAL(18,2) COMMENT 'Total copay assistance program (CAP) savings in USD reported in this deliverable, reflecting manufacturer copay card and coupon offsets tracked via PAX.',
  client_accepted_date DATE COMMENT 'Date on which the client formally accepted or acknowledged the deliverable. Null if not yet accepted. Drives billing milestone triggers.',
  client_contact_email STRING COMMENT 'Email address of the primary client-side contact for this deliverable. Used for delivery and follow-up communications.',
  client_contact_name STRING COMMENT 'Name of the primary client-side contact to whom the deliverable is addressed or delivered. Business-confidential engagement data.',
  company_client_id BIGINT COMMENT 'Reference to the employer client (within the Company > Division > Client hierarchy) for whom this deliverable was produced.',
  company_consulting_engagement_id BIGINT COMMENT 'FK to company.company_consulting_engagement.company_consulting_engagement_id — Deliverables are line items within an engagement header; classic header->line FK required for SLA/deliverable tracking.',
  company_deliverable_engagement_fk BIGINT COMMENT 'FK to company.company_consulting_engagement.company_consulting_engagement_id — Deliverables are line items within an engagement (header->line); mandatory for SLA/project tracking.',
  company_engagement_deliverable_description STRING COMMENT 'Narrative description of the deliverable scope, methodology, and key findings summary. Provides context for the deliverable beyond its title and type.',
  company_engagement_deliverable_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for each consulting engagement deliverable record within the PillarRx enterprise data platform.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this deliverable record was first created in the enterprise data platform. Supports audit trail and record lineage.',
  currency_code STRING COMMENT 'ISO 4217 three-letter currency code for fee amounts on this deliverable. Typically USD for PillarRx domestic engagements.',
  deliverable_format STRING COMMENT 'The output format in which the deliverable is produced and delivered to the client (e.g., PDF report, Excel workbook, PowerPoint deck, interactive dashboard).',
  deliverable_number STRING COMMENT 'Externally-visible business identifier for this deliverable, used in client communications, invoicing, and engagement tracking (e.g., DLV-2024-000123).',
  deliverable_status STRING COMMENT 'Current lifecycle state of the deliverable within the consulting workflow (draft through delivered or cancelled).',
  deliverable_title STRING COMMENT 'Human-readable title of the deliverable as presented to the client (e.g., ''Q3 2024 PBM Audit Report — CVS Caremark'').',
  deliverable_type STRING COMMENT 'Classification of the consulting deliverable by its analytical purpose. [ENUM-REF-CANDIDATE: pbm_audit|benchmarking|formulary_analysis|cap_savings_summary|trend_analysis|prior_auth_analysis|tcoc_report|other — promote to reference product]',
  delivered_date DATE COMMENT 'Actual date the deliverable was formally delivered to the client. Null if not yet delivered. Used for SLA tracking and engagement performance measurement.',
  delivery_method STRING COMMENT 'Channel or method used to deliver the completed deliverable to the client (e.g., secure portal upload, email, in-person presentation, video call).',
  due_date DATE COMMENT 'Contractually or operationally committed date by which the deliverable must be completed and delivered to the client.',
  estimated_fee_usd DECIMAL(18,2) COMMENT 'Estimated consulting fee in US dollars associated with this deliverable. Used for engagement budgeting and revenue forecasting. Business-confidential pricing data.',
  file_location_uri STRING COMMENT 'Secure URI or path to the stored deliverable artifact (e.g., cloud storage path, SharePoint URL). Business-confidential as it may reference PHI-containing reports.',
  gdr_reported DECIMAL(5,4) COMMENT 'Generic Dispensing Rate (GDR) reported in this deliverable, expressed as a decimal (e.g., 0.8750 = 87.50%). Key PBM performance benchmark metric.',
  identified_savings_usd DECIMAL(18,2) COMMENT 'Dollar value of savings opportunities or audit findings identified in this deliverable (e.g., PBM guarantee shortfalls, copay assistance savings, formulary optimization). Core consulting output metric.',
  is_client_accepted BOOLEAN COMMENT 'Indicates whether the client has formally acknowledged or accepted the deliverable. Relevant for milestone-based consulting fee billing.',
  is_final BOOLEAN COMMENT 'Indicates whether this version of the deliverable is the final, authoritative version delivered to the client. False for drafts and interim revisions.',
  lead_consultant STRING COMMENT 'Name of the PillarRx consulting team member primarily responsible for producing and delivering this deliverable.',
  member_count_analyzed INT COMMENT 'Number of distinct health plan members included in the analysis underlying this deliverable. Provides population context for PMPM and PMPY metrics.',
  netsuite_invoice_code STRING COMMENT 'Identifier of the corresponding NetSuite invoice record for this deliverable. Links consulting deliverable to the financial billing record for revenue recognition.',
  pbm_scope STRING COMMENT 'The PBM(s) in scope for this deliverable (e.g., CVS Caremark, Optum Rx, Express Scripts). May be a single PBM name or a comma-delimited list for multi-PBM analyses.',
  primary_company_consulting_engagement_id BIGINT COMMENT 'Reference to the parent consulting engagement under which this deliverable was produced. Links deliverable to its engagement context.',
  reviewer_name STRING COMMENT 'Name of the PillarRx team member who reviewed and approved the deliverable prior to client delivery. Supports quality control and sign-off tracking.',
  salesforce_opportunity_code STRING COMMENT 'Identifier of the corresponding Salesforce CRM opportunity or engagement record. Enables cross-system traceability between the data platform and CRM.',
  scope_notes STRING COMMENT 'Free-text notes documenting any inclusions, exclusions, caveats, or limitations specific to the scope of this deliverable (e.g., excluded specialty claims, limited to commercial lines).',
  total_claims_analyzed BIGINT COMMENT 'Count of pharmacy claim transactions included in the analysis underlying this deliverable. Provides scale context for audit and benchmarking deliverables.',
  total_plan_spend_usd DECIMAL(18,2) COMMENT 'Total pharmacy plan spend in USD covered by the analysis in this deliverable. Key headline metric for PBM audit and trend analysis deliverables.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this deliverable record was most recently modified. Tracks changes to status, fees, findings, or delivery details throughout the deliverable lifecycle.',
  version_number STRING COMMENT 'Version identifier for the deliverable (e.g., 1.0, 1.1, 2.0). Tracks revisions made after initial delivery, such as corrections or client-requested updates.',
  CONSTRAINT pk_company_engagement_deliverable PRIMARY KEY (company_engagement_deliverable_id)
)
COMMENT 'Tracks individual deliverables within a consulting engagement — for example, a PBM audit report, a benchmarking deck, a formulary gap analysis, or a CAP savings summary.'
;

CREATE TABLE IF NOT EXISTS pillarrx.company.company_pbm (
  awp_discount_brand DECIMAL(5,2) COMMENT 'Contracted AWP discount percentage applied to brand-name drugs by this PBM. Used as a benchmark in PBM guarantee reconciliation and GER/BER audit analysis.',
  awp_discount_generic DECIMAL(5,2) COMMENT 'Contracted AWP discount percentage applied to generic drugs by this PBM. Used as a benchmark in PBM guarantee reconciliation and generic dispensing rate (GDR) analysis.',
  bin STRING COMMENT 'Six-digit Bank Identification Number (BIN) used to route retail pharmacy claims to this PBM''s adjudication system at the point of sale.',
  claims_feed_delivery_method STRING COMMENT 'Technical delivery mechanism used by the PBM to transmit claims data files to PillarRx (e.g., SFTP, API, S3 bucket, secure email).',
  claims_feed_format STRING COMMENT 'Technical format of the claims data feed delivered by this PBM to PillarRx''s ingestion platform (e.g., NCPDP D.0, flat file, EDI 835, proprietary).',
  claims_feed_frequency STRING COMMENT 'Frequency at which the PBM delivers claims data files to PillarRx''s ingestion platform. Drives ETL scheduling and data freshness SLA monitoring.',
  company_pbm_code STRING COMMENT 'Internal PillarRx alphanumeric code uniquely identifying the PBM across all systems, ETL pipelines, and multi-PBM claims normalization processes.',
  company_pbm_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for each Pharmacy Benefit Manager (PBM) record in the PillarRx enterprise data platform.',
  company_pbm_name STRING COMMENT 'Full legal or trade name of the Pharmacy Benefit Manager (e.g., CVS Caremark, Optum Rx, Express Scripts, Navitus, EmpiRx Health).',
  company_pbm_status STRING COMMENT 'Current lifecycle status of the PBM relationship within PillarRx. Drives whether claims feeds, audits, and reporting pipelines are active for this PBM.',
  company_pbm_type STRING COMMENT 'Classification of the PBM by operational model and market scope. Supports benchmarking segmentation and PBM audit strategy differentiation.',
  contract_end_date DATE COMMENT 'Expiration date of the PillarRx data access or consulting agreement with this PBM. Null indicates an open-ended or evergreen agreement.',
  contract_start_date DATE COMMENT 'Effective start date of the PillarRx data access or consulting agreement with this PBM. Defines the earliest date for which claims data is contractually available.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this PBM master record was first created in the PillarRx enterprise data platform. Supports audit trail and record lineage.',
  data_lag_days INT COMMENT 'Typical number of calendar days between the pharmacy claim date of service (DOS) and the date the claim appears in PillarRx''s ingestion platform for this PBM.',
  dir_reporting_available BOOLEAN COMMENT 'Indicates whether the PBM provides Direct and Indirect Remuneration (DIR) fee data in its claims feed, required for accurate net cost analysis under CMS Part D rules.',
  dispensing_fee_mail DECIMAL(10,2) COMMENT 'Contracted dispensing fee (in USD) paid to mail-order pharmacies by this PBM. Used in PBM audit and mail-order dispensing fee guarantee reconciliation.',
  dispensing_fee_retail DECIMAL(10,2) COMMENT 'Contracted dispensing fee (in USD) paid to retail network pharmacies by this PBM. Used in PBM audit and dispensing fee guarantee reconciliation.',
  formulary_data_available BOOLEAN COMMENT 'Indicates whether the PBM provides formulary and drug tier data to PillarRx for formulary analysis and drug utilization review (DUR) consulting services.',
  headquarters_city STRING COMMENT 'City where the PBM''s principal corporate headquarters is located. Used for reference and consulting engagement documentation.',
  headquarters_country STRING COMMENT 'Three-letter ISO 3166-1 alpha-3 country code for the PBM''s principal corporate headquarters (e.g., USA).',
  headquarters_state STRING COMMENT 'Two-letter US state abbreviation for the PBM''s principal corporate headquarters. Relevant for state PBM licensure and transparency law compliance tracking.',
  is_340b_capable BOOLEAN COMMENT 'Indicates whether the PBM supports 340B federal drug discount program claims processing and reporting for eligible covered entities among PillarRx clients.',
  is_cap_integrated BOOLEAN COMMENT 'Indicates whether this PBM is integrated with PillarRx''s PAX copay assistance program (CAP) application for real-time copay card tracking and manufacturer coupon reconciliation.',
  mac_list_name STRING COMMENT 'Name or identifier of the Maximum Allowable Cost (MAC) pricing list used by this PBM for generic drug reimbursement. Used in PBM audit and MAC transparency analysis.',
  member_id_format STRING COMMENT 'Description or regex pattern of the member identifier format used by this PBM in claims data. Critical for Member 360 identity resolution and cross-PBM member matching.',
  notes STRING COMMENT 'Free-text field for operational notes, known data quality issues, feed quirks, or consulting context specific to this PBM''s data integration with PillarRx.',
  npi STRING COMMENT 'Ten-digit National Provider Identifier (NPI) assigned to the PBM as a health plan or payer entity, used in HIPAA-compliant claim transactions.',
  parent_organization STRING COMMENT 'Name of the parent corporation or health system that owns the PBM (e.g., CVS Health for CVS Caremark, UnitedHealth Group for Optum Rx, Cigna for Express Scripts).',
  pcn STRING COMMENT 'Processor Control Number (PCN) used in conjunction with the BIN to route pharmacy claims to the correct PBM adjudication processor or sub-processor.',
  pricing_model STRING COMMENT 'Indicates whether the PBM operates on a spread pricing model, a pass-through (transparent) model, or a hybrid. Critical for PBM audit and GER/BER guarantee reconciliation.',
  primary_contact_email STRING COMMENT 'Email address of the primary PBM account manager or relationship contact. Used for data feed issue escalation and consulting engagement communication.',
  primary_contact_name STRING COMMENT 'Name of the primary account manager or relationship contact at the PBM assigned to PillarRx for consulting engagement and data feed coordination.',
  primary_contact_phone STRING COMMENT 'Phone number of the primary PBM account manager or relationship contact for operational and consulting engagement coordination.',
  prior_auth_data_available BOOLEAN COMMENT 'Indicates whether the PBM provides prior authorization (PA) data to PillarRx for PA analytics, step therapy (ST), and quantity limit (QL) analysis.',
  rebate_eligible BOOLEAN COMMENT 'Indicates whether manufacturer rebate data is available from this PBM for inclusion in PillarRx consulting analyses and PBM guarantee reconciliation.',
  rx_group STRING COMMENT 'Default RxGroup identifier associated with this PBM used for pharmacy claim routing and benefit group identification at the point of dispensing.',
  short_name STRING COMMENT 'Abbreviated or commonly used name for the PBM used in reporting, dashboards, and consulting deliverables (e.g., Caremark, OptumRx, ESI).',
  specialty_pharmacy_supported BOOLEAN COMMENT 'Indicates whether the PBM manages specialty pharmacy benefits and provides specialty drug claims data, enabling specialty spend monitoring and trend reporting.',
  supports_adjustments BOOLEAN COMMENT 'Indicates whether the PBM''s claims feed includes adjustment transactions (claim corrections). Affects claims normalization and audit reconciliation logic.',
  supports_reversals BOOLEAN COMMENT 'Indicates whether the PBM''s claims feed includes reversal transactions (claim cancellations). Affects claims normalization logic and net-paid calculations.',
  tax_identification_number STRING COMMENT 'Federal Employer Identification Number (EIN/TIN) for the PBM entity. Used in financial reconciliation, 1099 reporting, and Brown & Brown finance integration.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this PBM master record was last modified in the PillarRx enterprise data platform. Supports change tracking and data governance.',
  CONSTRAINT pk_company_pbm PRIMARY KEY (company_pbm_id)
)
COMMENT 'Master reference record for each Pharmacy Benefit Manager (PBM) that PillarRx ingests claims data from or audits on behalf of clients. Covers CVS Caremark, Optum Rx, Express Scripts, Navitus, EmpiRx Health, BCBS Michigan, Rightway Healthcare, Prime'
;

CREATE TABLE IF NOT EXISTS pillarrx.company.consulting_fee (
  adjustment_amount DECIMAL(18,2) COMMENT 'Dollar amount of any credit, discount, or correction applied to the billed amount. Negative values represent credits; positive values represent surcharges.',
  approved_by STRING COMMENT 'Name or identifier of the Pillarrx staff member who approved this consulting fee for issuance. Supports internal authorization controls and SOX audit trail.',
  approved_date DATE COMMENT 'Date on which this consulting fee billing event was internally approved for issuance to the client.',
  billed_amount DECIMAL(18,2) COMMENT 'Gross consulting fee amount billed to the client for this billing event, in USD, before any adjustments or credits. Core monetary fact for AR reporting.',
  billing_period_end_date DATE COMMENT 'Last calendar date of the billing period covered by this consulting fee event. Paired with billing_period_start_date to define the service window.',
  billing_period_start_date DATE COMMENT 'First calendar date of the billing period covered by this consulting fee event. Used for period-over-period trend analysis and client reporting.',
  company_client_id BIGINT COMMENT 'Reference to the employer client (within the Company > Division > Client hierarchy) to whom this consulting fee is billed.',
  company_consulting_engagement_id BIGINT COMMENT 'FK to company.company_consulting_engagement.company_consulting_engagement_id — Fee billing events resolve to a specific engagement; revenue recognition joins through this FK.',
  company_pbm_id BIGINT COMMENT 'Foreign key linking to company.pbm. Business justification: Fee may be associated with a specific PBM (e.g., fees for PBM-specific audit work). Currently denormalized as pbm_source (STRING). Adding pbm_id FK normalizes this relationship.',
  consulting_engagement_fk BIGINT COMMENT 'FK to company.company_consulting_engagement.company_consulting_engagement_id — Fee billing resolves to company_consulting_engagement — stated explicitly in the fee description.',
  consulting_fee_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for each consulting fee billing event record in the Pillarrx enterprise data warehouse.',
  contract_reference STRING COMMENT 'Reference to the client contract or statement of work (SOW) document that authorizes this consulting fee. Used for contract-to-invoice reconciliation.',
  cost_center_code STRING COMMENT 'Brown & Brown Finance cost center code associated with the Pillarrx division responsible for delivering the consulting engagement billed on this fee record.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this consulting fee record was first created in the enterprise data warehouse. Audit field for data lineage and SOX compliance.',
  currency_code STRING COMMENT 'ISO 4217 three-letter currency code for all monetary amounts on this fee record. Pillarrx operates primarily in USD.',
  dispute_reason STRING COMMENT 'Free-text description of the client''s stated reason for disputing this invoice. Populated only when is_disputed is true.',
  dispute_resolved_date DATE COMMENT 'Date on which a disputed invoice was formally resolved. Null if dispute is still open or no dispute exists.',
  due_date DATE COMMENT 'The date by which payment is contractually due from the client. Used for accounts receivable aging and collections tracking in NetSuite.',
  fee_status STRING COMMENT 'Current lifecycle status of the consulting fee billing event. Tracks progression from draft through issuance, payment, or dispute resolution.',
  fee_type STRING COMMENT 'Classification of the fee structure for this billing event. [ENUM-REF-CANDIDATE: flat_fee|milestone|retainer|per_member|hourly|project — promote to reference product]',
  gl_account_code STRING COMMENT 'General Ledger account code in NetSuite/Brown & Brown Finance to which this consulting fee revenue is posted for financial reporting and SOX compliance.',
  invoice_date DATE COMMENT 'The date on which the invoice was formally issued to the client. Represents the principal business event timestamp for this billing transaction.',
  invoice_number STRING COMMENT 'Externally-visible invoice reference number issued to the client for this consulting fee billing event. Sourced from NetSuite/Brown & Brown Finance AR module.',
  is_disputed BOOLEAN COMMENT 'Indicates whether the client has formally disputed this invoice. When true, the fee is placed on hold pending resolution and excluded from collectible AR.',
  is_recurring BOOLEAN COMMENT 'Indicates whether this fee is part of a recurring billing schedule (e.g., monthly retainer) as opposed to a one-time or milestone-based charge.',
  member_count INT COMMENT 'Number of eligible health plan members used as the basis for per-member fee calculations (Per Member Per Month or Per Member Per Year fee types).',
  milestone_name STRING COMMENT 'Name or description of the engagement milestone triggering this billing event when fee_type is milestone (e.g., ''PBM Audit Report Delivery'', ''Onboarding Complete'').',
  net_fee_amount DECIMAL(18,2) COMMENT 'Final net consulting fee amount due after applying adjustments (billed_amount + adjustment_amount). Represents the client''s actual payment obligation.',
  netsuite_invoice_code STRING COMMENT 'Internal invoice record identifier in the NetSuite/Brown & Brown Finance AR system. Used for cross-system reconciliation between the data warehouse and the financial system of record.',
  notes STRING COMMENT 'Free-text internal notes or client-facing memo line associated with this consulting fee billing event. May include context for adjustments or special billing arrangements.',
  org_division_id BIGINT COMMENT 'Reference to the Division within the Company > Division > Client hierarchy under which this fee is billed. Supports multi-tenant revenue reporting.',
  outstanding_balance DECIMAL(18,2) COMMENT 'Remaining unpaid balance on this invoice (net_fee_amount minus paid_amount). Used for AR aging and collections management.',
  paid_amount DECIMAL(18,2) COMMENT 'Total amount actually received from the client against this invoice. May differ from net_fee_amount if partial payments or disputes exist.',
  payment_method STRING COMMENT 'Method by which the client remitted payment for this invoice (e.g., ACH, wire transfer, check). Populated upon payment receipt.',
  payment_received_date DATE COMMENT 'The date on which payment was received from the client for this invoice. Null if payment has not yet been received.',
  payment_terms STRING COMMENT 'Contractual payment terms governing when the client must remit payment (e.g., Net 30). Drives due_date calculation and AR aging bucket assignment.',
  pmpm_rate DECIMAL(10,4) COMMENT 'Per Member Per Month consulting fee rate applied when fee_type is per_member. Multiplied by member_count and months in billing period to derive billed_amount.',
  primary_company_consulting_engagement_id BIGINT COMMENT 'Reference to the parent consulting engagement under which this fee was billed. Links to company_consulting_engagement.',
  salesforce_opportunity_code STRING COMMENT 'Reference to the Salesforce CRM opportunity record associated with this consulting engagement and fee. Enables CRM-to-billing reconciliation.',
  service_category STRING COMMENT 'Categorical classification of the consulting service type billed. Aligns with Pillarrx core business functions for revenue reporting. [ENUM-REF-CANDIDATE: promote to reference product]',
  service_description STRING COMMENT 'Free-text description of the consulting services rendered during the billing period, as it appears on the client invoice (e.g., PBM audit, CAP management, benchmarking).',
  tertiary_company_consulting_engagement_id BIGINT COMMENT 'FK to company.company_consulting_engagement.company_consulting_engagement_id — Fee billing events are recognized at the client-engagement grain; revenue recognition feeding NetSuite AR requires resolving the fee to its engagement.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this consulting fee record was last modified in the enterprise data warehouse. Supports change tracking and audit trail requirements.',
  void_reason STRING COMMENT 'Reason for voiding this consulting fee record. Populated only when fee_status is void (e.g., duplicate invoice, client contract termination, billing error).',
  CONSTRAINT pk_consulting_fee PRIMARY KEY (consulting_fee_id)
)
COMMENT 'Records consulting fee billing events issued to a Client for a specific consulting engagement (resolves to company_consulting_engagement). Stores invoice reference number, billing period, fee type (flat fee, milestone, retainer, per-member), billed'
;

CREATE TABLE IF NOT EXISTS pillarrx.company.member (
  address_line_1 STRING COMMENT 'Primary street address line for the member.',
  address_line_2 STRING COMMENT 'Secondary address line (apartment, suite, unit number).',
  city STRING COMMENT 'City of the member''s address.',
  company_client_id BIGINT COMMENT 'Reference to the employer client whose health plan covers this member.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM that provided this member record.',
  copay_assistance_eligible BOOLEAN COMMENT 'Indicates whether the member is eligible for copay assistance programs managed by PillarRx.',
  country STRING COMMENT 'Three-letter ISO country code of the member''s address.',
  date_of_birth DATE COMMENT 'Date of birth of the member. Used for age-based analytics and member matching.',
  email_address STRING COMMENT 'Email address for member communication and digital outreach.',
  enrollment_effective_date DATE COMMENT 'Date when the member''s coverage became effective.',
  enrollment_status STRING COMMENT 'Current enrollment status of the member in the health plan.',
  enrollment_termination_date DATE COMMENT 'Date when the member''s coverage was terminated. Null if currently active.',
  first_name STRING COMMENT 'First name of the member as provided by the PBM or employer.',
  gender STRING COMMENT 'Gender of the member. M=Male, F=Female, U=Unknown, X=Non-binary/Other.',
  language_preference STRING COMMENT 'Preferred language for member communication. en=English, es=Spanish, fr=French, zh=Chinese, other=Other.',
  last_name STRING COMMENT 'Last name (surname) of the member as provided by the PBM or employer.',
  medicare_beneficiary_identifier STRING COMMENT 'Medicare Beneficiary Identifier assigned by CMS. Applicable for Medicare-eligible members.',
  member_360_key STRING COMMENT 'Unified identifier linking this member across multiple PBMs and data sources. Supports Member 360 unified view objective.',
  member_id BIGINT NOT NULL COMMENT 'Primary key for member',
  middle_name STRING COMMENT 'Middle name or initial of the member.',
  pbm_member_id BIGINT COMMENT 'Member identifier assigned by the source PBM. Used for cross-referencing with PBM claim files. May vary across PBMs for the same individual.',
  phone_number STRING COMMENT 'Primary contact phone number for the member.',
  plan_name STRING COMMENT 'Name of the health plan or benefit design under which this member is enrolled.',
  plan_year INT COMMENT 'Calendar or benefit year for which this member enrollment applies.',
  postal_code STRING COMMENT 'ZIP or postal code of the member''s address. Five-digit or ZIP+4 format.',
  record_created_timestamp TIMESTAMP COMMENT 'Timestamp when this member record was first created in the PillarRx system.',
  record_updated_timestamp TIMESTAMP COMMENT 'Timestamp when this member record was last updated in the PillarRx system.',
  relationship_to_subscriber STRING COMMENT 'Relationship of this member to the primary subscriber. Self indicates this member is the subscriber.',
  social_security_number STRING COMMENT 'Social Security Number of the member. Used for identity verification and member matching. Highly restricted.',
  source_file_name STRING COMMENT 'Name of the source file from which this member record was extracted.',
  source_system STRING COMMENT 'Name of the source system or PBM that provided this member record.',
  state STRING COMMENT 'Two-letter state or province code of the member''s address.',
  subscriber_id BIGINT COMMENT 'Reference to the primary policyholder (subscriber) on the employer plan. Null if this member is the subscriber.',
  CONSTRAINT pk_member PRIMARY KEY (member_id)
)
COMMENT 'Member scoped to Company/Client via company_client_id; division-specific data derived through company.client_division_assignment, not a direct member->division FK A member is a real person (patient) who fills prescriptions; members are humans, not claim records. The same member may appear across multiple PBMs with different identifiers (Member 360 unified view).'
;

CREATE TABLE IF NOT EXISTS pillarrx.company.org_division (
  benefit_group_code STRING COMMENT 'Code identifying the benefit group (BG) configuration applied to members enrolled under this Division. Governs copay, coinsurance, deductible, and out-of-pocket parameters.',
  bin_number STRING COMMENT 'Six-digit Bank Identification Number (BIN) used to route pharmacy claims to the correct PBM processor for this Division''s benefit plan at the point of dispensing.',
  cap_enabled BOOLEAN COMMENT 'Indicates whether the Copay Assistance Program (CAP) is active for members enrolled under this Division. When true, PAX application manages copay card tracking and manufacturer coupon reconciliation.',
  client_count INT COMMENT 'Number of employer Clients currently grouped under this Division in the Company > Division > Client hierarchy. Used for organizational reporting and consulting engagement scoping.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the Division record was first created in the PillarRx Enterprise Data Warehouse. Used for audit trail, data lineage, and record lifecycle management.',
  data_sharing_consent BOOLEAN COMMENT 'Indicates whether the employer client has provided consent for PillarRx to use this Division''s de-identified claims data in aggregate benchmarking and industry analytics.',
  deductible_integrated BOOLEAN COMMENT 'Indicates whether the pharmacy deductible is integrated with the medical deductible for members under this Division. Affects total cost of care (TCOC) accumulator logic.',
  dir_applicable BOOLEAN COMMENT 'Indicates whether Direct and Indirect Remuneration (DIR) fees apply to pharmacy reimbursements under this Division''s plan. Relevant for Medicare Part D and specialty pharmacy audit.',
  division_formulary_id BIGINT COMMENT 'Identifier of the drug formulary (covered drug list) assigned to this Division''s pharmacy benefit plan. Determines tier-based cost sharing and prior authorization requirements.',
  division_name STRING COMMENT 'Human-readable name of the Division as recognized by the employer client and used in consulting reports, dashboards, and eligibility communications.',
  division_status STRING COMMENT 'Current lifecycle status of the Division record. Controls whether the Division is eligible to receive new Client assignments and whether its data is included in active reporting.',
  division_type STRING COMMENT 'Categorical classification of the Division''s organizational purpose (e.g., regional grouping, product line, retiree population). [ENUM-REF-CANDIDATE: regional|product_line|business_unit|subsidiary|retiree|cobra|other — promote to reference product]',
  effective_date DATE COMMENT 'Date on which the Division became operationally active and eligible for Client enrollment and pharmacy benefit administration within the PillarRx platform.',
  external_division_code STRING COMMENT 'Division identifier as supplied by the employer client or PBM source system. Preserved for cross-reference and reconciliation against PBM eligibility files and claims feeds.',
  funding_type STRING COMMENT 'Indicates how the Division''s pharmacy benefit plan is funded. Self-funded plans bear claim risk directly; fully insured plans transfer risk to a carrier. Drives audit and benchmarking methodology.',
  hipaa_baa_executed BOOLEAN COMMENT 'Indicates whether a HIPAA Business Associate Agreement (BAA) has been executed between PillarRx and the plan sponsor for this Division, authorizing PHI access for consulting services.',
  medical_claims_integrated BOOLEAN COMMENT 'Indicates whether medical claims data is integrated with pharmacy claims for this Division to support total cost of care (TCOC) analysis and cross-domain consulting reporting.',
  member_count_active INT COMMENT 'Current count of active members enrolled under this Division. Used for PMPM and PMPY calculations, capacity planning, and consulting engagement scoping. Point-in-time snapshot value.',
  n340b_eligible BOOLEAN COMMENT 'Indicates whether the Division''s plan population is eligible to participate in the 340B federal drug discount program administered by HRSA. Affects drug pricing and rebate calculations.',
  netsuite_entity_code STRING COMMENT 'Identifier of the corresponding entity in NetSuite / Brown & Brown Finance for consulting fee billing, general ledger allocation, and accounts receivable tracking at the Division level.',
  oop_integrated BOOLEAN COMMENT 'Indicates whether the pharmacy out-of-pocket (OOP) maximum is integrated with the medical OOP maximum for members under this Division. Affects MOOP accumulator logic.',
  org_division_description STRING COMMENT 'Free-text narrative describing the business purpose, population, or organizational context of the Division. Used by consulting staff for client onboarding documentation.',
  org_division_id BIGINT NOT NULL COMMENT 'Unique surrogate key identifying a Division within the PillarRx multi-tenant hierarchy (Company > Division > Client). Generated by the Enterprise Data Warehouse.',
  organization_id BIGINT COMMENT 'Identifier referencing the related company id for the org division record in the company domain.',
  parent_organization_id BIGINT COMMENT 'FK to company.organization.organization_id — VREQ-003: a Division belongs to a Company; the single-parent chain is the backbone of the hierarchy.',
  pass_through_pricing BOOLEAN COMMENT 'Indicates whether the Division''s PBM contract operates on a pass-through (transparent) pricing model, where the plan pays actual drug cost without spread. Drives PBM audit methodology.',
  pbm_contract_id BIGINT COMMENT 'Identifier of the PBM contract governing pharmacy benefit administration for this Division. Links to PBM guarantee and audit records for discount, rebate, and dispensing-fee reconciliation.',
  pbm_group_code STRING COMMENT 'The RxGroup identifier assigned by the PBM to this Division''s pharmacy benefit population. Used for claim routing and eligibility verification at point of sale.',
  pcn STRING COMMENT 'Processor Control Number (PCN) used in conjunction with BIN to route pharmacy claims to the correct sub-processor or benefit plan within the PBM for this Division.',
  plan_sponsor_name STRING COMMENT 'Legal name of the employer or plan sponsor associated with this Division''s pharmacy benefit plan. Used in ERISA plan documents, EOBs, and regulatory filings.',
  plan_year_start_month INT COMMENT 'Calendar month (1–12) in which the Division''s benefit plan year begins. Determines deductible reset, out-of-pocket accumulator reset, and annual reporting periods.',
  primary_organization_id BIGINT COMMENT 'Reference to the parent Company in the PillarRx multi-tenant hierarchy. A Division always belongs to exactly one Company.',
  primary_pbm STRING COMMENT 'Name of the primary PBM administering pharmacy benefits for this Division. [ENUM-REF-CANDIDATE: CVS Caremark|Optum Rx|Express Scripts|Navitus|EmpiRx Health|BCBS Michigan|Rightway|Prime Therapeutics|ServeYou|Carelon — promote to reference product]',
  prior_auth_required BOOLEAN COMMENT 'Indicates whether the Division''s benefit plan requires prior authorization (PA) for any drug categories. Drives PA analytics module configuration and consulting audit scope.',
  quantity_limit_enforced BOOLEAN COMMENT 'Indicates whether quantity limits (QL) are enforced on drug dispensing for members under this Division''s benefit plan. Affects drug utilization review (DUR) and claims audit scope.',
  rds_eligible BOOLEAN COMMENT 'Indicates whether the Division''s retiree population qualifies for the CMS Retiree Drug Subsidy (RDS) program. Relevant for Divisions covering retiree benefit groups.',
  rebate_pass_through BOOLEAN COMMENT 'Indicates whether manufacturer rebates are passed through 100% to the plan sponsor for this Division, as opposed to being retained by the PBM. Critical for PBM contract audit and GER reconciliation.',
  reporting_region STRING COMMENT 'Geographic or organizational region assigned to this Division for benchmarking, trend analysis, and consulting report segmentation. Defined by PillarRx internal reporting taxonomy.',
  salesforce_division_id BIGINT COMMENT 'Identifier of the corresponding Division record in Salesforce CRM. Used to link consulting engagement activities, client relationship management, and fee billing to the organizational hierarchy.',
  short_name STRING COMMENT 'Abbreviated display name for the Division used in report headers, dashboard labels, and UI elements where space is constrained. Maximum 20 characters.',
  specialty_carve_out BOOLEAN COMMENT 'Indicates whether specialty pharmacy benefits are carved out to a separate specialty PBM or specialty pharmacy network for this Division, distinct from the primary PBM arrangement.',
  step_therapy_required BOOLEAN COMMENT 'Indicates whether step therapy (ST) protocols are enforced for any drug categories under this Division''s benefit plan. Relevant for formulary compliance and PA analytics.',
  termination_date DATE COMMENT 'Date on which the Division was deactivated or terminated. Null for currently active Divisions. Used to enforce eligibility boundaries in claims analysis and member enrollment.',
  tertiary_organization_id BIGINT COMMENT 'FK to company.organization.organization_id — VREQ-003: a Division belongs to exactly one Company. Core hierarchy edge.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp of the most recent update to the Division record in the PillarRx Enterprise Data Warehouse. Used for change detection, ETL incremental loads, and audit trail.',
  CONSTRAINT pk_org_division PRIMARY KEY (org_division_id)
)
COMMENT 'Master record for a Division within a Company in the PillarRx multi-tenant hierarchy (Company > Division > Client). A Division is a logical grouping of employer Clients under a Company umbrella — for example, a regional or product-line grouping within'
;

CREATE TABLE IF NOT EXISTS pillarrx.company.organization (
  address_line1 STRING COMMENT 'Primary street address line of the organization''s principal place of business. Used for ERISA plan filings, DOL reporting, and consulting engagement correspondence.',
  address_line2 STRING COMMENT 'Secondary address line (suite, floor, building) for the organization''s principal place of business. Supplements address_line1 for complete mailing address.',
  cap_enrolled BOOLEAN COMMENT 'Indicates whether the organization is enrolled in PillarRx''s Copay Assistance Program (CAP) managed via the PAX application. Drives CAP eligibility checks, manufacturer coupon reconciliation, and member assistance ledger processing.',
  city STRING COMMENT 'City of the organization''s principal place of business. Used in geographic segmentation for pharmacy spend benchmarking and state-level regulatory reporting.',
  country_code STRING COMMENT 'ISO 3166-1 alpha-3 three-letter country code for the organization''s principal place of business. Defaults to USA for domestic employer clients.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the organization record was first created in the PillarRx Enterprise Data Warehouse. Serves as the audit trail anchor for record lineage and data governance.',
  data_sharing_agreement_date DATE COMMENT 'Date on which the organization executed a data sharing or Business Associate Agreement (BAA) with PillarRx, authorizing receipt and processing of PHI/PII under HIPAA. Required before claims data ingestion begins.',
  ein STRING COMMENT 'Federal Employer Identification Number (EIN) assigned by the IRS. Used for ERISA plan identification, DOL reporting, and Brown & Brown finance reconciliation via NetSuite.',
  formulary_type STRING COMMENT 'Classification of the organization''s drug formulary structure. Drives formulary analysis, tier benchmarking, and prior authorization reporting in consulting deliverables.',
  hipaa_baa_on_file BOOLEAN COMMENT 'Indicates whether a signed HIPAA Business Associate Agreement (BAA) is on file for this organization. A BAA is required before PillarRx may receive or process Protected Health Information (PHI) on behalf of the organization.',
  industry_segment STRING COMMENT 'Industry classification of the employer organization (e.g., manufacturing, retail, healthcare, education, government). Used for benchmarking pharmacy spend against peer cohorts in consulting analytics.',
  legal_name STRING COMMENT 'Full legal registered name of the organization as it appears in corporate filings and contractual agreements. Used as the authoritative display name across consulting deliverables and client reporting.',
  medical_integration_enabled BOOLEAN COMMENT 'Indicates whether medical claims data has been integrated for this organization to support Total Cost of Care (TCOC) analysis. Drives availability of medical-pharmacy cross-analysis in consulting reporting.',
  member_count INT COMMENT 'Most recently reported total number of eligible members (subscribers and dependents) covered under the organization''s pharmacy benefit plan. Used for PMPM calculations and client sizing.',
  naic_company_code STRING COMMENT 'Five-digit NAIC company code assigned to the organization if it is a licensed insurance entity. Used for state regulatory reporting and insurance carrier identification.',
  naics_code STRING COMMENT 'Six-digit NAICS code identifying the primary industry of the organization. Supports peer benchmarking, trend analysis, and pharmacy spend segmentation in consulting deliverables.',
  netsuite_entity_code STRING COMMENT 'Brown & Brown NetSuite finance system entity identifier for this organization. Used for consulting fee billing, accounts receivable, and general ledger reconciliation under SOX controls.',
  notes STRING COMMENT 'Free-text field for capturing operational notes, special handling instructions, or consulting engagement context specific to this organization. Not used in automated processing.',
  onboarding_date DATE COMMENT 'Date on which the organization was formally onboarded into the PillarRx multi-tenant platform, including completion of data provisioning, eligibility feed setup, and initial PBM claims ingestion configuration.',
  organization_code STRING COMMENT 'Unique alphanumeric business code assigned to the organization within the PillarRx multi-tenant platform. Used as the tenant root key in ETL pipelines, eligibility feeds, and claims normalization.',
  organization_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the organization record. Serves as the primary key for the top-level Company entity in the PillarRx multi-tenant hierarchy (Company > Division > Client).',
  organization_status STRING COMMENT 'Current lifecycle status of the organization record within the PillarRx platform. Controls whether the organization''s data is included in active reporting, claims processing, and consulting engagement workflows.',
  organization_type STRING COMMENT 'Categorical classification of the organization''s role in the PillarRx ecosystem. Drives tenant configuration, data access scoping, and reporting templates.',
  parent_organization_id BIGINT COMMENT 'Self-referencing identifier pointing to the parent organization record. Supports hierarchical corporate structures where a Brown & Brown division or holding entity is the root tenant above this organization.',
  pass_through_model BOOLEAN COMMENT 'Indicates whether the organization''s PBM contract operates under a pass-through (transparent) pricing model rather than a spread-based model. Affects PBM audit methodology, GER/BER guarantee reconciliation, and DIR analysis.',
  pbm_count INT COMMENT 'Number of distinct PBMs (e.g., CVS Caremark, Optum Rx, Express Scripts) currently contracted to administer pharmacy benefits for this organization. Indicates multi-PBM complexity for claims aggregation.',
  plan_effective_date DATE COMMENT 'Date on which the organization''s pharmacy benefit plan became effective under PillarRx management. Marks the start of claims aggregation, eligibility tracking, and consulting engagement for this organization.',
  plan_termination_date DATE COMMENT 'Date on which the organization''s pharmacy benefit plan terminated or is scheduled to terminate under PillarRx management. Null for currently active organizations.',
  plan_year_start_month INT COMMENT 'Calendar month (1–12) in which the organization''s benefit plan year begins. Used to align PMPM, PMPY, deductible accumulator resets, and annual trend reporting to the correct plan year boundary.',
  postal_code STRING COMMENT 'ZIP or ZIP+4 postal code for the organization''s principal place of business. Used for geographic segmentation and mailing address completeness.',
  primary_contact_email STRING COMMENT 'Email address of the primary business contact at the organization. Used for consulting deliverable distribution, CAP program communications, and client onboarding notifications.',
  primary_contact_name STRING COMMENT 'Full name of the primary business contact at the organization (typically the benefits manager or HR director). Used for consulting engagement communication and client onboarding.',
  primary_contact_phone STRING COMMENT 'Primary phone number for the organization''s main business contact. Used for consulting engagement coordination and client support escalation.',
  prior_auth_tracking_enabled BOOLEAN COMMENT 'Indicates whether prior authorization (PA) analytics are enabled for this organization. Controls availability of PA approval rate, step therapy (ST), and quantity limit (QL) reporting in the consulting analytics module.',
  rebate_sharing_pct DECIMAL(5,2) COMMENT 'Contractual percentage of manufacturer rebates passed through to the organization by the PBM. Used in PBM contract guarantee reconciliation and rebate audit analysis. Expressed as a percentage (0.00–100.00).',
  salesforce_account_code STRING COMMENT 'Salesforce CRM Account record identifier for this organization. Used to link consulting engagement data, fee billing, and client relationship management records to the master organization.',
  short_name STRING COMMENT 'Abbreviated or commonly used name for the organization, used in dashboards, report headers, and UI display where the full legal name is too long.',
  soc2_audit_required BOOLEAN COMMENT 'Indicates whether the organization contractually requires PillarRx to provide SOC 2 audit reports as part of the consulting engagement. Drives compliance reporting obligations.',
  specialty_carve_out BOOLEAN COMMENT 'Indicates whether the organization has carved out specialty pharmacy benefits to a separate specialty PBM or specialty pharmacy network. Affects specialty spend monitoring, LDD tracking, and total cost of care analysis.',
  state_code STRING COMMENT 'Two-letter USPS state abbreviation for the organization''s principal place of business. Used for state PBM licensure compliance, state pharmacy transparency law applicability, and geographic reporting.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when the organization record was most recently modified in the PillarRx Enterprise Data Warehouse. Used for change detection in ETL pipelines and audit trail maintenance.',
  CONSTRAINT pk_organization PRIMARY KEY (organization_id)
)
COMMENT 'Master record (SSOT) for the top-level Company in the PillarRx multi-tenant hierarchy (Company > Division > Client) — the root tenant, typically a Brown & Brown division or direct corporate parent.'
;

CREATE TABLE IF NOT EXISTS pillarrx.company.subscriber (
  address_line1 STRING COMMENT 'Primary street address line for the subscriber''s residence. Used for member communications, eligibility verification, and geographic analytics.',
  address_line2 STRING COMMENT 'Secondary address line (apartment, suite, unit) for the subscriber''s residence. Supplements address_line1 when applicable.',
  benefit_group_code STRING COMMENT 'Code identifying the benefit group (BG) to which this subscriber is assigned. Determines formulary, copay tiers, deductible, and MOOP parameters applicable to the subscriber.',
  cap_enrolled_flag BOOLEAN COMMENT 'Indicates whether the subscriber is enrolled in a Copay Assistance Program (CAP) managed through the PAX application. Drives CAP eligibility checks during claims processing.',
  city STRING COMMENT 'City of the subscriber''s residential address. Used for geographic segmentation and regional pharmacy utilization analysis.',
  cobra_flag BOOLEAN COMMENT 'Indicates whether the subscriber is enrolled under COBRA continuation coverage following a qualifying event. Affects premium responsibility and benefit administration.',
  company_client_id BIGINT COMMENT 'FK to company.company_client.company_client_id — VREQ-004/VREQ-007: subscribers are scoped to Company/Client. The subscriber master is useless without its Client FK.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM (e.g., CVS Caremark, Optum Rx, Express Scripts) through which this subscriber''s pharmacy benefits are administered.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the subscriber record was first created in the PillarRx data platform. Supports audit trail and data lineage requirements.',
  date_of_birth DATE COMMENT 'Date of birth of the subscriber. Used for age-band analysis, Medicare eligibility determination, and member identity resolution across PBM sources.',
  dependent_count INT COMMENT 'Number of active dependent members (spouse, child, other) linked to this subscriber under the employer health plan. Used for family-level benefit accumulator analysis.',
  effective_date DATE COMMENT 'Date on which the subscriber''s pharmacy benefit coverage became effective under the employer health plan. Defines the start of eligibility for claims adjudication.',
  eligibility_load_date DATE COMMENT 'Date on which the subscriber''s eligibility record was loaded into the PillarRx platform from the source eligibility file. Used for data freshness monitoring and onboarding reconciliation.',
  eligibility_source_file STRING COMMENT 'Name or identifier of the eligibility file from which this subscriber record was loaded. Supports data lineage tracking and eligibility file reconciliation during client onboarding.',
  eligibility_system_code STRING COMMENT 'Subscriber identifier assigned by the Eligibility Management System. Used to link subscriber records to benefit group assignments and enrollment data.',
  email STRING COMMENT 'Primary email address for the subscriber. Used for CAP communications, eligibility notifications, and member outreach via the PAX application.',
  employee_number STRING COMMENT 'Employer-assigned employee identifier for the subscriber. Used to correlate subscriber records with HR/payroll systems during eligibility file processing and client onboarding.',
  employer_id BIGINT COMMENT 'Reference to the employer client whose health plan this subscriber is enrolled under within the Company > Division > Client hierarchy.',
  first_name STRING COMMENT 'Legal first (given) name of the subscriber as the primary policyholder on the employer health plan.',
  gender STRING COMMENT 'Biological sex/gender of the subscriber as reported by the PBM or eligibility source. M=Male, F=Female, U=Unknown. Used in clinical and demographic analytics.',
  last_name STRING COMMENT 'Legal last (family/surname) name of the subscriber as the primary policyholder on the employer health plan.',
  mbi STRING COMMENT 'CMS-assigned Medicare Beneficiary Identifier (MBI) for subscribers enrolled in Medicare. Required for RDS program reporting and Medicare coordination of benefits.',
  mdm_golden_code STRING COMMENT 'The golden-record identifier assigned by the Member 360 / MDM platform after cross-PBM identity resolution. Links this subscriber to their unified identity across all PBM sources.',
  member_id_at_pbm STRING COMMENT 'The subscriber''s member identifier as assigned by the PBM. This is the ID printed on the pharmacy benefit card and used in claim transactions. Distinct from the internal subscriber_id.',
  middle_name STRING COMMENT 'Middle name or initial of the subscriber. Often sparse from PBM source feeds; populated when available from eligibility files.',
  pbm_source STRING COMMENT 'Name of the PBM source system from which this subscriber record was ingested (e.g., CVS Caremark, Optum Rx, Express Scripts). Supports multi-PBM normalization.',
  pbm_subscriber_id BIGINT COMMENT 'The subscriber identifier as assigned by the PBM source system. Used to correlate subscriber records across PBM claims feeds during normalization and Member 360 identity resolution.',
  phone STRING COMMENT 'Primary contact phone number for the subscriber. Often sparse from PBM sources; populated from eligibility files when available.',
  plan_year_start_date DATE COMMENT 'Start date of the benefit plan year applicable to this subscriber. Used to reset deductible and out-of-pocket accumulators for annual claims analysis.',
  postal_code STRING COMMENT 'ZIP or ZIP+4 postal code for the subscriber''s residential address. Used for geographic pharmacy access analysis and regional benchmarking.',
  primary_company_benefit_group_id BIGINT COMMENT 'FK to company.company_benefit_group.company_benefit_group_id — Subscriber enrolls under a benefit group; needed for plan-design-aware eligibility.',
  rds_eligible_flag BOOLEAN COMMENT 'Indicates whether the subscriber qualifies for the CMS Retiree Drug Subsidy (RDS) program. Applicable to retiree subscribers with creditable prescription drug coverage.',
  rx_bin STRING COMMENT 'Six-digit Bank Identification Number (BIN) used to route pharmacy claims to the correct PBM processor. Printed on the member''s pharmacy benefit card.',
  rx_group STRING COMMENT 'Pharmacy benefit group identifier (RxGroup) used for claim routing and adjudication at the PBM. Printed on the member''s pharmacy benefit card.',
  rx_pcn STRING COMMENT 'Processor Control Number (PCN) used alongside RxBIN to route pharmacy claims to the correct PBM adjudication platform.',
  ssn_last4 STRING COMMENT 'Last four digits of the subscriber''s Social Security Number. Used for identity verification and matching across eligibility sources. Full SSN is never stored.',
  state_code STRING COMMENT 'Two-letter USPS state abbreviation for the subscriber''s residential address. Used for state-level benefit compliance and geographic reporting.',
  subscriber_client_fk BIGINT COMMENT 'FK to company.company_client.company_client_id — VREQ-004: subscribers are scoped to Company/Client not Division; the FK realizes that scoping.',
  subscriber_company_benefit_group_id BIGINT COMMENT 'FK to company.company_benefit_group.company_benefit_group_id — Subscribers enroll under a benefit group; required to resolve plan-design rules for a subscriber''s members.',
  subscriber_company_client_id BIGINT COMMENT 'FK to company.company_client.company_client_id — Subscribers are policyholders on a Client''s plan — scoped to Company/Client per VREQ-004.',
  subscriber_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the subscriber (primary policyholder) record within the PillarRx data platform.',
  subscriber_status STRING COMMENT 'Current lifecycle status of the subscriber''s enrollment on the employer health plan. Drives eligibility determination for pharmacy benefit adjudication.',
  subscriber_type STRING COMMENT 'Classification of the subscriber''s relationship to the employer plan. Determines benefit eligibility rules, RDS applicability, and COBRA administration.',
  termination_date DATE COMMENT 'Date on which the subscriber''s pharmacy benefit coverage ended. Null for currently active subscribers. Used for eligibility validation and claims audit.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when the subscriber record was last modified in the PillarRx data platform. Used to detect eligibility changes and trigger downstream refresh processes.',
  CONSTRAINT pk_subscriber PRIMARY KEY (subscriber_id)
)
COMMENT 'Master record for the primary policyholder (subscriber) on an employer Client''s health plan. A subscriber is the employee/certificate holder to whom one or more members (dependents: spouse, child, other) are linked.'
;

CREATE TABLE IF NOT EXISTS pillarrx.company.tenant_change_log (
  approval_status STRING COMMENT 'Workflow approval state for the change. Financially material or sensitive changes may require explicit approval before taking effect. AUTO_APPROVED for low-risk system-initiated changes.',
  approved_by STRING COMMENT 'Username or display name of the PillarRx staff member who approved the change. Null for auto-approved or pending changes. Required for financially material contract field changes.',
  approved_timestamp TIMESTAMP COMMENT 'Date and time (UTC) when the change was approved or rejected. Null for pending or auto-approved changes. Supports SLA tracking for change governance workflows.',
  batch_reference STRING COMMENT 'Identifier of the ETL batch, file load, or bulk-update job that produced this change event. Supports bulk-change investigation and PBM feed reconciliation audits.',
  benefit_group_code STRING COMMENT 'Benefit group code from the company_benefit_group record at the time of the change. Populated when target_table is company_benefit_group; null otherwise.',
  change_category STRING COMMENT 'Business classification of the change event to support trend analysis and audit reporting. [ENUM-REF-CANDIDATE: ONBOARDING|CONTRACT_RENEWAL|BENEFIT_CHANGE|CORRECTION|TERMINATION|REACTIVATION — promote to reference product if values expand]',
  change_description STRING COMMENT 'Human-readable narrative summarizing the business impact of the change (e.g., ''Updated AWP discount from 18% to 20% for brand drugs effective 2025-01-01''). Supports consulting audit deliverables.',
  change_reason STRING COMMENT 'Free-text or structured rationale explaining why the change was made (e.g., ''PBM contract renewal'', ''client onboarding correction'', ''benefit group restructure''). Supports audit trail review.',
  change_source_system STRING COMMENT 'Operational system that originated the change event (e.g., Eligibility Management System, PAX, PBM Claims Feed, Salesforce CRM, or manual data entry). Supports lineage tracing.',
  change_timestamp TIMESTAMP COMMENT 'Exact date and time (UTC) when the change event was committed to the source system. This is the principal event time for the log entry, distinct from the ETL load time.',
  change_type STRING COMMENT 'Category of data modification applied to the master record: INSERT (new record), UPDATE (field change), DELETE (hard removal), SOFT_DELETE (status deactivation), or RESTORE (reactivation).',
  changed_by_user STRING COMMENT 'Username or system account identifier of the actor who initiated the change. May be a human user (PillarRx consultant) or an automated ETL/integration process.',
  changed_field STRING COMMENT 'Name of the specific column/attribute within the target table that was modified. Null for INSERT or DELETE events where the entire record is the unit of change.',
  changed_record_reference BIGINT COMMENT 'Surrogate identifier of the specific master record that was modified (e.g., the organization_id, company_client_id, or client_pbm_contract_id that changed).',
  client_code STRING COMMENT 'Short alphanumeric code identifying the employer client at the time of the change. Denormalized for audit readability and cross-system correlation.',
  company_pbm_id BIGINT COMMENT 'Surrogate identifier of the PBM associated with the changed record. Populated for changes to client_pbm_contract or company_benefit_group records; null for organization-level changes.',
  contract_number STRING COMMENT 'External contract number from the client_pbm_contract record at the time of the change. Denormalized for audit readability without requiring a join to the contract table.',
  created_timestamp TIMESTAMP COMMENT 'Date and time (UTC) when this change log record was first written to the Enterprise Data Warehouse / Analytics Lakehouse Silver layer. Distinct from change_timestamp (the source event time).',
  division_id BIGINT COMMENT 'Surrogate identifier of the org_division within the Company > Division > Client hierarchy to which the changed record belongs. Null when the change is at the organization level.',
  effective_date DATE COMMENT 'The business-effective date on which the change takes operational effect (e.g., plan year start, contract renewal date). May differ from change_timestamp for retroactive or future-dated changes.',
  employer_id BIGINT COMMENT 'Surrogate identifier of the employer client (company_client) to which the changed record belongs. Null when the change is at the organization or division level.',
  ip_address STRING COMMENT 'IP address of the client or system that submitted the change request. Used for security monitoring and forensic audit. May be considered PII in some jurisdictions.',
  is_contract_financial_field BOOLEAN COMMENT 'Flags changes to financially material contract fields such as AWP discount rates, dispensing fees, rebate guarantees, or Generic Effective Rate (GER). Supports PBM audit and contract reconciliation workflows.',
  is_sensitive_field BOOLEAN COMMENT 'Indicates whether the changed_field contains Protected Health Information (PHI), Personally Identifiable Information (PII), or confidential financial data requiring restricted access to old_value and new_value.',
  new_record_version BIGINT COMMENT 'Version sequence number of the master record after this change was applied. Increments monotonically per changed_record_id within each target_table.',
  new_value DECIMAL(18,2) COMMENT 'String-serialized new value of the changed field after the modification was applied. Null for DELETE events. May contain sensitive business data depending on the target field.',
  old_value DECIMAL(18,2) COMMENT 'String-serialized prior value of the changed field before the modification was applied. Null for INSERT events. May contain sensitive business data depending on the target field.',
  organization_id BIGINT COMMENT 'Surrogate identifier of the top-level organization (Company) in the Company > Division > Client hierarchy to which the changed record belongs. Enables tenant-scoped audit queries.',
  plan_year STRING COMMENT 'Four-digit plan year (e.g., 2025) to which the change is associated. Enables plan-year-scoped audit reporting for PBM contract guarantee reconciliation and benefit group analysis.',
  prior_record_version BIGINT COMMENT 'Version sequence number of the master record before this change was applied. Supports Type-2 Slowly Changing Dimension (SCD) history reconstruction and point-in-time queries.',
  rollback_flag BOOLEAN COMMENT 'Indicates whether this log entry represents a rollback/reversal of a prior change. When true, the new_value restores the old_value from a previous log entry.',
  rolled_back_from_log_id BIGINT COMMENT 'References the tenant_change_log_id of the original change entry that this rollback reverses. Null when rollback_flag is false. Enables full change chain reconstruction.',
  session_code STRING COMMENT 'Application session identifier associated with the user action that triggered the change. Supports forensic investigation of unauthorized or erroneous modifications.',
  target_table STRING COMMENT 'Name of the master table whose record was changed. Scoped to the five audited tenant/contract entities: organization, org_division, company_client, client_pbm_contract, company_benefit_group.',
  tenant_change_log_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for each audit/change-log record capturing a material change to a tenant or contract master record. Role: EVENT_LOG.',
  CONSTRAINT pk_tenant_change_log PRIMARY KEY (tenant_change_log_id)
)
COMMENT 'Audit/change-log capturing every material change to tenant and contract master records — organization, org_division, company_client, client_pbm_contract, and company_benefit_group.'
;

-- ---------------------------------------------------------------------------
-- Schema: division
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS pillarrx.division.division (
  bin_number STRING COMMENT 'Six-digit BIN used to route pharmacy claims to the correct PBM processor for this Division. Appears on member ID cards alongside PCN and RxGroup.',
  cap_enrolled BOOLEAN COMMENT 'Indicates whether this Division participates in PillarRx''s Copay Assistance Program (CAP) managed via the PAX application for manufacturer copay card and coupon coordination.',
  company_id BIGINT COMMENT 'Identifier referencing the related company id for the division record in the division domain.',
  company_pbm_id BIGINT COMMENT 'Reference to the primary PBM (e.g., CVS Caremark, Optum Rx, Express Scripts) contracted to administer pharmacy benefits for this Division.',
  consulting_tier STRING COMMENT 'PillarRx consulting service tier assigned to this Division, determining the scope of analytics, reporting, and advisory services delivered under the consulting engagement.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this Division record was first created in the PillarRx platform. Used for audit trail, data lineage, and onboarding timeline tracking.',
  data_feed_format STRING COMMENT 'Format of the PBM claims data feed ingested for this Division. Drives ETL parsing logic in the PBM Claims Feed Ingestion Platform.',
  dir_applicable BOOLEAN COMMENT 'Indicates whether Direct and Indirect Remuneration (DIR) fees apply to this Division''s pharmacy claims. Relevant for Medicare Part D and employer plans with DIR reconciliation.',
  division_code STRING COMMENT 'Externally-known alphanumeric code that uniquely identifies this Division within the parent Company. Used in PBM feeds, eligibility files, and client reporting as the stable business key.',
  division_id BIGINT NOT NULL COMMENT 'Unique identifier for the division data product (auto-inserted during validation).',
  division_name STRING COMMENT 'Human-readable name of the Division as known to the employer client and PillarRx consultants. Used in all client-facing reports and dashboards.',
  division_status STRING COMMENT 'Current lifecycle state of the Division within PillarRx. Controls whether eligibility, claims processing, and consulting services are active for this Division.',
  division_type STRING COMMENT 'Categorical classification of the Division indicating the nature of the covered population (e.g., active employees, union trust, retirees, COBRA continuants).',
  effective_date DATE COMMENT 'Date on which this Division became active and eligible for pharmacy benefit services under the PillarRx platform. Aligns with plan year start or client onboarding date.',
  erisa_plan_number STRING COMMENT 'Three-digit ERISA plan number assigned by the employer for Form 5500 reporting. Required for self-funded employer plans subject to DOL reporting obligations.',
  external_division_code STRING COMMENT 'Division identifier as assigned by the PBM or external eligibility system. Preserved for cross-system reconciliation and PBM feed matching alongside the internal surrogate key.',
  feed_frequency STRING COMMENT 'Frequency at which the PBM transmits pharmacy claims data for this Division to the PillarRx ingestion platform. Impacts data freshness for reporting and audit.',
  funding_type STRING COMMENT 'Indicates how the Division''s pharmacy benefit is funded. Self-funded plans bear claim risk directly; fully insured plans pay premiums to a carrier. Drives audit and consulting scope.',
  medicare_part_d BOOLEAN COMMENT 'Indicates whether this Division includes Medicare Part D coverage (e.g., retiree drug subsidy or employer group waiver plan). Triggers CMS reporting and TrOOP accumulator rules.',
  member_count INT COMMENT 'Current number of active members enrolled in this Division. Used for PMPM and PMPY calculations, capacity planning, and consulting benchmarking.',
  naics_code STRING COMMENT 'Six-digit NAICS code for the employer group. Complements SIC for industry benchmarking and peer-group analytics in PillarRx consulting deliverables.',
  notes STRING COMMENT 'Free-text field for consultant-entered notes about this Division, such as special contractual arrangements, audit findings, or onboarding considerations.',
  organization_id BIGINT COMMENT 'Reference to the parent Company in the Company > Division > Client hierarchy. Every Division belongs to exactly one Company.',
  pbm_audit_frequency STRING COMMENT 'Contracted frequency at which PillarRx performs PBM performance audits (discount, rebate, dispensing fee guarantee reconciliation) for this Division.',
  pbm_group_code STRING COMMENT 'The RxGroup identifier assigned by the PBM to route pharmacy claims to this Division''s benefit plan. Printed on member ID cards and used in NCPDP claim transactions.',
  pcn STRING COMMENT 'Processor Control Number used in conjunction with BIN to route pharmacy claims to the correct adjudication platform for this Division.',
  plan_year_start_month INT COMMENT 'Calendar month (1–12) in which the Division''s benefit plan year begins. Drives annual deductible resets, OOP accumulator resets, and PMPM/PMPY reporting periods.',
  prior_auth_program BOOLEAN COMMENT 'Indicates whether this Division has an active Prior Authorization (PA) program in place with the PBM. Drives PA analytics and audit scope within PillarRx consulting.',
  program_340b BOOLEAN COMMENT 'Indicates whether this Division participates in the HRSA 340B federal drug discount program, enabling covered entities to purchase outpatient drugs at significantly reduced prices.',
  quantity_limit_program BOOLEAN COMMENT 'Indicates whether Quantity Limit (QL) edits are active for this Division''s benefit design, restricting the dispensed quantity per fill to clinically appropriate amounts.',
  rds_eligible BOOLEAN COMMENT 'Indicates whether this Division qualifies for the CMS Retiree Drug Subsidy (RDS) program, providing federal subsidy payments to employers maintaining retiree drug coverage.',
  rebate_pass_through BOOLEAN COMMENT 'Indicates whether manufacturer rebates collected by the PBM are passed through 100% to this Division (pass-through model) versus retained by the PBM (spread model).',
  sic_code STRING COMMENT 'Four-digit SIC code representing the industry of the employer group associated with this Division. Used for benchmarking pharmacy spend against industry peers.',
  specialty_carve_out BOOLEAN COMMENT 'Indicates whether specialty medications (SMN) are carved out to a separate specialty pharmacy or specialty PBM for this Division, separate from the primary PBM contract.',
  state_code STRING COMMENT 'Two-letter US state code representing the primary state of operation or situs for this Division. Drives state PBM licensure, transparency law compliance, and SPAP eligibility.',
  step_therapy_program BOOLEAN COMMENT 'Indicates whether Step Therapy (ST) protocols are active for this Division''s benefit design, requiring members to try lower-cost alternatives before brand or specialty drugs.',
  tax_identification_number STRING COMMENT 'Federal Employer Identification Number (EIN) for the employer entity associated with this Division. Used in ERISA filings and PBM contract execution.',
  termination_date DATE COMMENT 'Date on which this Division was terminated or deactivated. Null for currently active Divisions. Used to scope eligibility and claims history.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp of the most recent update to this Division record. Used for change detection, ETL incremental loads, and audit trail purposes.',
  CONSTRAINT pk_division PRIMARY KEY (division_id)
)
COMMENT 'DOMAIN: This domain owns the Division level of PillarRx''s Company > Division > Client multi-tenant hierarchy and everything that logically scopes to a Division: benefit group designs, PBM contracts and their guarantee reconciliation lifecycle'
;

CREATE TABLE IF NOT EXISTS pillarrx.division.division_benefit_group (
  accumulator_type STRING COMMENT 'Defines how pharmacy cost-sharing accumulators (deductible, OOP) are integrated with medical accumulators. ''integrated'' means pharmacy and medical share a single deductible/OOP pool; ''separate_rx'' means pharmacy has its own accumulator.',
  benefit_plan_id BIGINT COMMENT 'Reference to the parent benefit plan under which this benefit group is offered. A plan may have multiple benefit groups representing different cost-sharing tiers.',
  bin_number STRING COMMENT 'Six-digit Bank Identification Number (BIN / RxBIN) used to route pharmacy claims to the correct PBM processor at the point of sale. Required on the member ID card.',
  client_benefit_group_id BIGINT COMMENT 'Identifier referencing the related client benefit group id for the division benefit group record in the division domain.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM (e.g., CVS Caremark, Optum Rx, Express Scripts) that adjudicates claims for members enrolled in this benefit group.',
  copay_assistance_applies BOOLEAN COMMENT 'Indicates whether manufacturer copay assistance program (CAP) payments count toward the member''s deductible and OOP accumulator under this benefit group. Relevant for accumulator adjustment program (AAP) compliance.',
  daw_policy STRING COMMENT 'Plan-level Dispense As Written (DAW) policy governing whether brand drugs are covered when a generic equivalent exists. Drives member cost-share differentials and generic dispensing rate (GDR) targets.',
  deductible_family DECIMAL(12,2) COMMENT 'Annual aggregate deductible amount for a family unit enrolled in this benefit group. Once met, all family members receive plan-paid benefits regardless of individual deductible status.',
  deductible_individual DECIMAL(12,2) COMMENT 'Annual deductible amount that an individual member must satisfy before the plan begins paying drug costs. Expressed in USD. Zero indicates no deductible applies.',
  division_benefit_group_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for a benefit group record within a division. Primary key for this entity.',
  division_formulary_id BIGINT COMMENT 'Reference to the formulary (covered drug list) associated with this benefit group. Determines which drugs are covered and at what tier for members in this group.',
  effective_date DATE COMMENT 'Date on which this benefit group becomes active and eligible for claim adjudication. Defines the start of the benefit group''s coverage period.',
  employer_id BIGINT COMMENT 'Reference to the employer client whose plan members are enrolled in this benefit group. Scopes the benefit group to a specific employer within the division.',
  group_code STRING COMMENT 'The RxGroup code transmitted on pharmacy claims to identify the benefit group. Used by the PBM for adjudication routing and benefit design lookup. Corresponds to the NCPDP RxGroup field.',
  group_description STRING COMMENT 'Detailed description of the benefit group, including eligibility criteria, population served, or plan design notes. Supports consulting analysis and client documentation.',
  group_name STRING COMMENT 'Human-readable name for the benefit group as defined by the employer or PBM (e.g., ''Active Employees'', ''Retirees'', ''COBRA Members''). Used in reporting and member communications.',
  group_status STRING COMMENT 'Current lifecycle status of the benefit group. Controls whether new members can be enrolled and whether claims are adjudicated against this group''s benefit design.',
  is_340b_eligible BOOLEAN COMMENT 'Indicates whether members in this benefit group are eligible for 340B federal drug discount pricing. Relevant for covered entities and contract pharmacies participating in the HRSA 340B program.',
  is_hdhp BOOLEAN COMMENT 'Indicates whether this benefit group is associated with a High Deductible Health Plan (HDHP), making members eligible for a Health Savings Account (HSA). Affects deductible thresholds and first-dollar coverage rules.',
  is_medicare_part_d BOOLEAN COMMENT 'Indicates whether this benefit group is a Medicare Part D plan. When true, TrOOP (True Out-of-Pocket) tracking and CMS reporting requirements apply.',
  mail_order_days_supply INT COMMENT 'Standard days supply dispensed per fill for mail-order pharmacy under this benefit group (typically 90 days). Used in days-supply validation and cost-per-day analytics.',
  moop_family DECIMAL(12,2) COMMENT 'Maximum Out-of-Pocket (MOOP) limit for a family unit, inclusive of all cost-sharing components. Used for total cost of care (TCOC) analysis and ACA compliance reporting.',
  moop_individual DECIMAL(12,2) COMMENT 'Maximum Out-of-Pocket (MOOP) limit for an individual member, inclusive of all cost-sharing components (deductible, copay, coinsurance). Distinct from OOP max when plan design separates medical and pharmacy accumulators.',
  network_type STRING COMMENT 'Defines the pharmacy network access model for this benefit group. Determines which NCPDP-identified pharmacies are in-network and the cost-share differential for out-of-network dispensing.',
  oop_max_family DECIMAL(12,2) COMMENT 'Maximum annual out-of-pocket (OOP) amount for a family unit. Once the family aggregate OOP is reached, the plan covers 100% of eligible drug costs for all family members.',
  oop_max_individual DECIMAL(12,2) COMMENT 'Maximum annual out-of-pocket (OOP) amount an individual member pays for covered drugs. After this limit is reached, the plan covers 100% of eligible drug costs for the remainder of the plan year.',
  pbm_contract_id BIGINT COMMENT 'Reference to the PBM contract governing pricing, guarantees, and service terms for this benefit group. Links to the client_pbm_contract entity for audit and benchmarking purposes.',
  pbm_division_id BIGINT COMMENT 'FK to division.pbm_division.pbm_division_id — Benefit groups are sponsored within a Division (VREQ-003: every benefit group scoped to the hierarchy). Required scoping FK.',
  pcn STRING COMMENT 'Processor Control Number (RxPCN) used alongside BIN to route pharmacy claims to the correct sub-processor or benefit plan within the PBM. Printed on the member ID card.',
  plan_year_end_date DATE COMMENT 'End date of the benefit plan year for this group. Defines the accumulator reset boundary for deductible, OOP, and MOOP calculations.',
  plan_year_start_date DATE COMMENT 'Start date of the benefit plan year for this group. Determines when deductible, OOP, and MOOP accumulators reset. Typically January 1 for calendar-year plans.',
  primary_division_id BIGINT COMMENT 'Reference to the Division under which this benefit group is defined. Links to the org_division entity in the Company > Division > Client hierarchy.',
  prior_auth_required BOOLEAN COMMENT 'Indicates whether prior authorization (PA) is required for any drug class under this benefit group. When true, PA rules are enforced at adjudication for applicable NDCs.',
  quantity_limit_enforced BOOLEAN COMMENT 'Indicates whether quantity limits (QL) are enforced at adjudication for this benefit group. When true, dispensing quantities exceeding plan-defined limits require PA or are rejected.',
  record_created_timestamp TIMESTAMP COMMENT 'Timestamp when this benefit group record was first created in the PillarRx data platform. Used for audit trail and SCD Type-2 history management.',
  record_updated_timestamp TIMESTAMP COMMENT 'Timestamp when this benefit group record was last modified. Used for change detection, SCD Type-2 history tracking, and incremental ETL processing.',
  retail_days_supply INT COMMENT 'Standard days supply dispensed per fill at retail pharmacy under this benefit group (typically 30 days). Used in days-supply validation and channel-mix analytics.',
  retiree_drug_subsidy_eligible BOOLEAN COMMENT 'Indicates whether this benefit group qualifies for the CMS Retiree Drug Subsidy (RDS) program. When true, the employer may receive federal subsidy payments for qualifying retiree drug costs.',
  source_group_code STRING COMMENT 'The raw benefit group code as received from the source system or PBM feed before normalization. Preserved for reconciliation and audit traceability against PBM claim files.',
  specialty_drug_policy STRING COMMENT 'Plan-level policy governing how specialty medications (SMN) are covered under this benefit group. Drives specialty pharmacy channel requirements, prior authorization (PA), and step therapy (ST) rules.',
  specialty_pharmacy_required BOOLEAN COMMENT 'Indicates whether specialty medications must be dispensed through a designated specialty pharmacy. When true, retail dispensing of specialty drugs is not covered under this benefit group.',
  step_therapy_required BOOLEAN COMMENT 'Indicates whether step therapy (ST) protocols are enforced for this benefit group. When true, members must try preferred drugs before coverage of non-preferred alternatives is approved.',
  termination_date DATE COMMENT 'Date on which this benefit group is no longer active. Null for open-ended groups. Used for Type-2 SCD history and eligibility validation.',
  CONSTRAINT pk_division_benefit_group PRIMARY KEY (division_benefit_group_id)
)
COMMENT 'Defines a named benefit group (BG) within a Division, representing a distinct pharmacy benefit design offered to a subset of members under a Client plan. Captures the benefit group code (RxGroup), BIN, PCN, DAW policy, specialty drug policy, OOP/MOOP'
;

CREATE TABLE IF NOT EXISTS pillarrx.division.division_formulary (
  brand_drug_count INT COMMENT 'Number of brand-name drug products listed on this formulary. Used alongside generic drug count to assess formulary composition and Generic Dispensing Rate (GDR) potential.',
  company_pbm_id BIGINT COMMENT 'FK to company.pbm',
  division_formulary_description STRING COMMENT 'Free-text description of the formulary, including notable design features, coverage restrictions, or plan sponsor customizations. Used in consulting deliverables and client documentation.',
  division_formulary_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the formulary record in the PillarRx data lakehouse. Primary key for the formulary dimension.',
  division_formulary_name STRING COMMENT 'Human-readable name of the formulary as defined by the PBM or plan sponsor (e.g., ''Standard 4-Tier Formulary'', ''Preferred Drug List''). Used in client reporting and consulting deliverables.',
  division_formulary_status STRING COMMENT 'Current lifecycle state of the formulary. Active formularies are in use for claims adjudication. Superseded formularies have been replaced by a newer version. Supports Type-2 SCD history.',
  division_formulary_type STRING COMMENT 'Classification of the formulary structure. Open: any drug covered; Closed: only listed drugs covered; Incentive: cost-sharing differentials encourage preferred drugs; Exclusive/Managed: restricted access.',
  drug_count INT COMMENT 'Total number of National Drug Codes (NDCs) or drug products listed on this formulary. Used as a benchmarking metric in PBM consulting analysis to assess formulary breadth and coverage.',
  effective_date DATE COMMENT 'Date on which this formulary version becomes effective for claims adjudication. Used to determine which formulary applies to a given Date of Service (DOS).',
  employer_id BIGINT COMMENT 'Reference to the employer client whose benefit plan uses this formulary. Supports multi-tenant scoping within the Company > Division > Client hierarchy.',
  excluded_drug_count INT COMMENT 'Number of drugs explicitly excluded from coverage on this formulary. Exclusions are a key PBM cost-management lever and are audited for compliance with plan sponsor agreements.',
  expiration_date DATE COMMENT 'Date on which this formulary version expires and is no longer applicable for new claims. Null indicates an open-ended formulary with no defined end date.',
  generic_drug_count INT COMMENT 'Number of generic drug products listed on this formulary. Used to assess Generic Dispensing Rate (GDR) potential and formulary design effectiveness in driving cost-efficient dispensing.',
  generic_preferred_indicator BOOLEAN COMMENT 'Indicates whether this formulary design preferentially places generic drugs on lower-cost tiers to drive Generic Dispensing Rate (GDR). Key attribute for PBM audit and benchmarking analysis.',
  is_current_record BOOLEAN COMMENT 'Indicates whether this row is the current active version of the formulary in the Type-2 SCD history (True = current). Simplifies queries that need only the latest formulary state.',
  mail_order_indicator BOOLEAN COMMENT 'Indicates whether this formulary includes mail-order pharmacy benefit provisions (True). Mail-order formularies may carry different tier placements and dispensing fee structures than retail.',
  notes STRING COMMENT 'Free-text field for analyst or consultant notes regarding this formulary, such as mid-year changes, plan sponsor exceptions, or PBM audit findings. Not used in automated processing.',
  pass_through_indicator BOOLEAN COMMENT 'Indicates whether this formulary operates under a pass-through PBM pricing model where rebates and discounts are fully passed to the plan sponsor, as opposed to a spread pricing model.',
  pbm_contract_id BIGINT COMMENT 'Reference to the PBM contract under which this formulary is administered. Links the formulary to the division-level PBM contract.',
  pbm_formulary_division_formulary_id BIGINT COMMENT 'The formulary identifier assigned by the PBM (e.g., CVS Caremark, Optum Rx, Express Scripts). Used to cross-reference formulary data in PBM claims feeds and audit reconciliation.',
  plan_year INT COMMENT 'The benefit plan year (e.g., 2024) to which this formulary applies. Used to align formulary versions with annual plan renewals and PBM contract performance guarantee periods.',
  prior_auth_indicator BOOLEAN COMMENT 'Indicates whether this formulary requires prior authorization (PA) for any covered drugs. PA requirements are tracked for PBM audit and member affordability analysis.',
  quantity_limit_indicator BOOLEAN COMMENT 'Indicates whether this formulary applies quantity limit (QL) edits to covered drugs. Quantity limits restrict the dispensed amount per fill or per period to clinically appropriate levels.',
  rebate_eligible_indicator BOOLEAN COMMENT 'Indicates whether drugs on this formulary are eligible for manufacturer rebates. Rebate eligibility is a critical factor in PBM contract guarantee reconciliation and pass-through analysis.',
  scd_effective_date DATE COMMENT 'Start date of this formulary record''s validity window in the Type-2 slowly changing dimension (SCD) history. Enables point-in-time formulary lookups for claims audit and trend analysis.',
  scd_expiration_date DATE COMMENT 'End date of this formulary record''s validity window in the Type-2 SCD history. Null or 9999-12-31 indicates the current active record. Enables historical formulary reconstruction for PBM audits.',
  source STRING COMMENT 'Identifies the source system or data feed from which this formulary record was ingested (e.g., PBM claims feed, manual upload, eligibility system). Supports data lineage and audit traceability.',
  specialty_drug_count INT COMMENT 'Number of specialty medications (SMN) listed on this formulary. Used in specialty pharmacy spend monitoring and trend reporting for employer clients.',
  specialty_formulary_indicator BOOLEAN COMMENT 'Indicates whether this formulary is a specialty drug formulary (True) or a standard formulary (False). Specialty formularies govern high-cost specialty medications (SMN) and limited distribution drugs (LDD).',
  step_therapy_indicator BOOLEAN COMMENT 'Indicates whether this formulary enforces step therapy (ST) protocols requiring members to try preferred drugs before accessing non-preferred alternatives. Relevant to prior authorization (PA) analysis.',
  tier_count INT COMMENT 'Total number of cost-sharing tiers defined in this formulary (e.g., 3-tier, 4-tier, 5-tier). Drives member cost-share structure and is a key benchmarking dimension in PBM consulting analysis.',
  url STRING COMMENT 'Public or internal URL where the formulary drug list is published or accessible. Used for member communication, plan document references, and consulting deliverable links.',
  version STRING COMMENT 'Version identifier for this formulary, as assigned by the PBM or plan sponsor (e.g., ''v2024.1'', ''2024Q1''). Supports Type-2 slowly changing dimension (SCD) history tracking across formulary updates.',
  CONSTRAINT pk_division_formulary PRIMARY KEY (division_formulary_id)
)
COMMENT 'Master record for a drug formulary (covered drug list) associated with a benefit group and PBM contract. Captures the formulary name, formulary ID assigned by the PBM, effective date range, formulary type (open, closed, incentive), number of tiers'
;

CREATE TABLE IF NOT EXISTS pillarrx.division.division_formulary_tier (
  accumulator_program_applies BOOLEAN COMMENT 'Indicates whether a copay accumulator adjustment program (CAAP) is active for this tier, preventing manufacturer copay assistance from counting toward member deductible or MOOP.',
  brand_indicator BOOLEAN COMMENT 'Indicates whether this tier is designated for brand-name drugs. Supports Brand Effective Rate (BER) and AWP discount guarantee auditing.',
  coinsurance_pct DECIMAL(5,4) COMMENT 'Member''s percentage share of the drug cost at this tier after deductible (e.g., 0.20 = 20%). Null when the tier uses a flat copay instead of coinsurance.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM (e.g., CVS Caremark, Optum Rx, Express Scripts) that administers this formulary tier on behalf of the client.',
  copay_amount DECIMAL(10,2) COMMENT 'Fixed dollar amount the member pays per prescription fill at this tier (e.g., $10 for Generic, $40 for Preferred Brand). Zero if coinsurance-only tier.',
  coverage_type STRING COMMENT 'Indicates the dispensing channel to which this tier definition applies: retail (30-day), mail (90-day), specialty pharmacy, or both retail and mail.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this formulary tier record was first created in the PillarRx lakehouse. Supports audit trail and data governance requirements.',
  days_supply_limit INT COMMENT 'Maximum days supply allowed per fill at this tier (e.g., 30 for retail, 90 for mail). Enforced during adjudication and used in quantity limit analysis.',
  deductible_applies BOOLEAN COMMENT 'Indicates whether the plan deductible must be satisfied before this tier''s copay or coinsurance applies. True for most brand tiers; often False for generic tiers.',
  division_formulary_id BIGINT COMMENT 'Reference to the parent formulary to which this tier belongs. Links the tier to its governing covered drug list.',
  division_formulary_tier_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for a formulary tier record. Primary key for the formulary_tier dimension in the PillarRx analytics lakehouse.',
  division_formulary_tier_name STRING COMMENT 'Full descriptive name of the tier as defined by the PBM or plan sponsor (e.g., ''Tier 1 - Preferred Generic''). May differ from tier_label when PBMs use custom naming.',
  effective_date DATE COMMENT 'Date on which this formulary tier definition becomes effective for adjudication. Supports Type-2 slowly changing dimension (SCD) history tracking.',
  employer_id BIGINT COMMENT 'Reference to the employer client whose benefit plan uses this formulary tier. Supports multi-tenant scoping within the Company > Division > Client hierarchy.',
  expiration_date DATE COMMENT 'Date on which this formulary tier definition expires or is superseded. Null for currently active tiers. Supports SCD Type-2 history in the drug formulary dimension.',
  formulary_exception_allowed BOOLEAN COMMENT 'Indicates whether members may request a formulary exception to obtain a non-formulary drug at this tier''s cost share. Required for CMS Part D compliance.',
  generic_indicator BOOLEAN COMMENT 'Indicates whether this tier is designated for generic drugs. Used in Generic Dispensing Rate (GDR) analysis and PBM performance benchmarking.',
  is_current BOOLEAN COMMENT 'Type-2 SCD flag indicating whether this is the currently active version of the formulary tier record. True for the current row; False for historical rows.',
  mail_coinsurance_pct DECIMAL(5,4) COMMENT 'Member''s percentage cost share for a 90-day mail-order fill at this tier. Null when the mail tier uses a flat copay.',
  mail_copay_amount DECIMAL(10,2) COMMENT 'Fixed dollar copay for a 90-day mail-order supply at this tier. Typically lower than retail to incentivize mail utilization. Null if mail uses coinsurance.',
  max_copay_amount DECIMAL(10,2) COMMENT 'Maximum dollar cap on member cost share per fill at this tier when coinsurance applies. Protects members from excessive out-of-pocket on high-cost drugs.',
  maximizer_program_applies BOOLEAN COMMENT 'Indicates whether a copay maximizer program is active for this tier, extracting the full manufacturer copay card value without applying it to member OOP accumulators.',
  min_copay_amount DECIMAL(10,2) COMMENT 'Minimum dollar floor on member cost share per fill at this tier when coinsurance applies. Ensures a minimum member contribution even for low-cost drugs.',
  oop_applies BOOLEAN COMMENT 'Indicates whether member cost share at this tier accumulates toward the plan''s maximum out-of-pocket (MOOP) limit. Relevant for copay accumulator and maximizer program analysis.',
  pbm_tier_code STRING COMMENT 'The raw tier code as transmitted by the PBM in claims feeds or formulary files before normalization. Preserved for PBM audit reconciliation and cross-PBM benchmarking.',
  pbm_tier_name STRING COMMENT 'The raw tier label as transmitted by the PBM before normalization (e.g., ''Preferred Drug List Tier 2''). Retained for audit traceability and PBM contract reconciliation.',
  plan_year INT COMMENT 'The benefit plan year (e.g., 2024) to which this formulary tier definition applies. Enables year-over-year tier change analysis and PBM contract guarantee auditing.',
  preventive_tier BOOLEAN COMMENT 'Indicates this is a zero-cost-share preventive drug tier as required under ACA Section 2713 and IRS Notice 2019-45 for HSA-compatible plans.',
  prior_auth_required BOOLEAN COMMENT 'Indicates whether drugs on this tier require prior authorization (PA) before the plan will cover them. Drives PA workflow routing in the PillarRx analytics module.',
  quantity_limit_applies BOOLEAN COMMENT 'Indicates whether quantity limits (QL) are enforced at this tier, restricting the maximum dispensed quantity per fill or per period.',
  scd_end_date DATE COMMENT 'End date of this SCD Type-2 version row''s validity window. Null for the current active row; populated when a new version supersedes this record.',
  scd_start_date DATE COMMENT 'Start date of this SCD Type-2 version row''s validity window. Set when the record is first created or when a change creates a new version.',
  source_file_name STRING COMMENT 'Name of the PBM formulary extract file from which this tier record was loaded. Supports ETL traceability and PBM audit reconciliation.',
  specialty_tier BOOLEAN COMMENT 'Flags this tier as a specialty medication (SMN) tier, typically carrying the highest member cost share and subject to specialty pharmacy network restrictions.',
  step_therapy_required BOOLEAN COMMENT 'Indicates whether step therapy (ST) applies at this tier, requiring members to try a lower-cost drug before the plan covers the requested drug.',
  tier_code STRING COMMENT 'Short alphanumeric code identifying the tier as used in PBM data feeds and formulary files (e.g., T1, T2, T3, T4). Aligns with PBM-sourced formulary extract codes.',
  tier_description STRING COMMENT 'Free-text description of the tier''s purpose, drug categories covered, and any special cost-share rules. Used in member-facing EOB communications and consulting deliverables.',
  tier_label STRING COMMENT 'Human-readable name for the tier as displayed to members and plan sponsors (e.g., Generic, Preferred Brand, Non-Preferred Brand, Specialty). [ENUM-REF-CANDIDATE: Generic|Preferred Generic|Non-Preferred Generic|Preferred Brand|Non-Preferred',
  tier_number INT COMMENT 'Numeric rank of the tier within the formulary (e.g., 1=Generic, 2=Preferred Brand, 3=Non-Preferred Brand, 4=Specialty). Lower numbers typically indicate lower member cost share.',
  tier_status STRING COMMENT 'Current lifecycle state of the formulary tier record. Active tiers are in use for adjudication; retired tiers are preserved for historical audit.',
  tier_type STRING COMMENT 'Broad classification of the tier''s drug category (e.g., standard, specialty, preventive, select_care). Drives benefit design rules and member cost-share logic.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp of the most recent update to this formulary tier record. Used for change detection in incremental ETL loads and audit logging.',
  CONSTRAINT pk_division_formulary_tier PRIMARY KEY (division_formulary_tier_id)
)
COMMENT 'Defines an individual cost-sharing tier within a formulary and is the AUTHORITATIVE SSOT for member out-of-pocket obligation per tier. Captures the tier number, tier label (Generic, Preferred Brand, Non-Preferred Brand, Specialty), copay amount'
;

CREATE TABLE IF NOT EXISTS pillarrx.division.division_pbm_contract (
  admin_fee_pmpm DECIMAL(10,4) COMMENT 'Contracted PBM administrative fee charged per member per month (PMPM) for plan administration services. Distinct from dispensing fees; a fixed overhead cost component.',
  audit_lookback_months INT COMMENT 'Number of months prior to the audit request date for which the plan sponsor may audit PBM claims and pricing under the contract terms.',
  audit_rights_indicator BOOLEAN COMMENT 'Indicates whether the contract grants the plan sponsor (employer) the right to audit PBM claims data, pricing, and rebate calculations. Essential for PillarRx audit engagements.',
  auto_renewal_indicator BOOLEAN COMMENT 'Indicates whether the contract automatically renews at the end of the contract term unless notice of termination is provided by either party.',
  bin_number STRING COMMENT 'Six-digit Bank Identification Number (BIN / RxBIN) used to route pharmacy claims to the correct PBM processor at the point of sale. Required for claims adjudication.',
  brand_awp_discount_pct DECIMAL(7,4) COMMENT 'Contracted percentage discount off AWP for brand-name drugs dispensed at retail pharmacies. Core audit metric for PBM guarantee reconciliation.',
  clinical_program_fee_pmpm DECIMAL(10,4) COMMENT 'Contracted fee per member per month (PMPM) for PBM-managed clinical programs such as Drug Utilization Review (DUR), MTM, or prior authorization management.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM entity (CVS Caremark, Optum Rx, Express Scripts, etc.) that is the counterparty to this contract.',
  contract_document_url STRING COMMENT 'URL or path reference to the executed contract document stored in the document management system. Enables auditors and consultants to access the source agreement.',
  contract_name STRING COMMENT 'Human-readable name or short description of the PBM contract (e.g., ''Acme Corp CVS Caremark 2024 Agreement''). Used for display and reporting.',
  contract_number STRING COMMENT 'Externally-known contract number or agreement identifier assigned by the PBM or the contracting party. Used for audit, correspondence, and reconciliation with the PBM.',
  contract_status STRING COMMENT 'Current lifecycle state of the PBM contract. Drives eligibility for claims processing, audit activities, and reporting inclusion.',
  contract_type STRING COMMENT 'Classification of the PBM pricing model. Pass-through contracts expose actual drug costs; spread contracts allow PBM margin; ASO contracts are fee-only. Critical for audit and benchmarking.',
  contract_version STRING COMMENT 'Version or amendment number of the contract document (e.g., ''1.0'', ''2.1'', ''Amendment 3''). Tracks the evolution of contract terms over time.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this PBM contract record was first created in the system. Used for audit trail and data lineage tracking.',
  currency_code STRING COMMENT 'ISO 4217 three-letter currency code for all monetary amounts in this contract record. Typically USD for domestic employer-sponsored plans.',
  dir_fee_indicator BOOLEAN COMMENT 'Indicates whether Direct and Indirect Remuneration (DIR) fees apply under this contract. DIR fees are post-point-of-sale adjustments that affect net pharmacy reimbursement.',
  division_id BIGINT COMMENT 'Reference to the Division within the Company > Division > Client hierarchy that is the contracting party or oversight entity for this PBM contract.',
  division_pbm_contract_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for a PBM contract record negotiated on behalf of a Division or Client. Primary key for this entity. Role: MASTER_AGREEMENT.',
  effective_date DATE COMMENT 'Date on which the PBM contract becomes binding and claims processing under its terms begins. Aligns with plan year start in most employer-sponsored plans.',
  employer_id BIGINT COMMENT 'Reference to the specific employer Client whose health plan is governed by this PBM contract. Nullable when the contract is negotiated at the Division level covering multiple clients.',
  execution_date DATE COMMENT 'Date on which the PBM contract was fully executed (signed by all parties). May differ from the effective date when contracts are signed retroactively.',
  formulary_type STRING COMMENT 'Classification of the formulary structure under this contract. Open formularies cover all drugs; closed formularies restrict to a defined list; incentive formularies use tiered cost-sharing.',
  gdr_guarantee_pct DECIMAL(7,4) COMMENT 'Contracted minimum Generic Dispensing Rate (GDR) guaranteed by the PBM. Failure to meet this threshold may trigger financial penalties or credits under the contract.',
  generic_awp_discount_pct DECIMAL(7,4) COMMENT 'Contracted percentage discount off AWP for generic drugs dispensed at retail pharmacies. Used in Generic Dispensing Rate (GDR) and savings analysis.',
  guaranteed_rebate_pmpm DECIMAL(10,4) COMMENT 'Minimum guaranteed rebate amount per member per month (PMPM) committed by the PBM under this contract. Used in rebate reconciliation and guarantee auditing.',
  mail_brand_awp_discount_pct DECIMAL(7,4) COMMENT 'Contracted AWP discount percentage for brand-name drugs dispensed through mail-order pharmacy. Typically higher than retail brand discount.',
  mail_dispensing_fee DECIMAL(10,4) COMMENT 'Contracted flat dispensing fee (in USD) paid per mail-order prescription fill. Mail dispensing fees are typically lower than retail due to volume efficiencies.',
  mail_generic_awp_discount_pct DECIMAL(7,4) COMMENT 'Contracted AWP discount percentage for generic drugs dispensed through mail-order pharmacy. Used in mail-order savings and GDR analysis.',
  member_id_prefix STRING COMMENT 'Prefix applied to member identifiers under this PBM contract. Used during Member 360 identity resolution to distinguish PBM-specific member ID formats across sources.',
  notes STRING COMMENT 'Free-text field for consultant or analyst annotations regarding contract terms, negotiation history, exceptions, or audit findings not captured in structured fields.',
  pbm_division_id BIGINT COMMENT 'FK to division.pbm_division.pbm_division_id — Every PBM contract is negotiated on behalf of a Division; contract must point to its owning division per VREQ-003 scoping.',
  pcn STRING COMMENT 'Processor Control Number (RxPCN) used in conjunction with BIN to route pharmacy claims to the correct PBM sub-processor or benefit plan. Required for claims adjudication.',
  performance_guarantee_indicator BOOLEAN COMMENT 'Indicates whether the PBM contract includes performance guarantees (e.g., GDR targets, clinical program outcomes, member satisfaction). Triggers guarantee reconciliation workflows.',
  plan_type STRING COMMENT 'Type of health plan covered by this PBM contract. Determines applicable regulatory framework (ERISA for commercial, CMS for Medicare Part D, etc.).',
  pricing_model STRING COMMENT 'The drug ingredient cost pricing methodology specified in the contract. Determines how pharmacy reimbursement is calculated (e.g., AWP Discount, MAC, Guaranteed Effective Rate).',
  rebate_pass_through_indicator BOOLEAN COMMENT 'Indicates whether manufacturer rebates collected by the PBM are passed through 100% to the plan (True) or retained partially by the PBM as spread (False). Critical transparency metric.',
  renewal_notice_days INT COMMENT 'Number of days prior to contract termination date by which either party must provide written notice to prevent auto-renewal or to initiate termination.',
  retail_dispensing_fee DECIMAL(10,4) COMMENT 'Contracted flat dispensing fee (in USD) paid to retail pharmacies per prescription fill under this PBM contract. A key component of total pharmacy reimbursement.',
  rx_group STRING COMMENT 'Pharmacy benefit group identifier (RxGroup) printed on the member ID card. Used by pharmacies to identify the benefit plan and apply correct cost-sharing at adjudication.',
  specialty_awp_discount_pct DECIMAL(7,4) COMMENT 'Contracted percentage discount off AWP for specialty medications (SMN). Specialty spend is a primary cost driver and this rate is a key audit guarantee.',
  spread_pricing_indicator BOOLEAN COMMENT 'Indicates whether the PBM retains a spread (difference between plan-paid amount and pharmacy reimbursement). False for pass-through contracts. Key audit and transparency flag.',
  termination_date DATE COMMENT 'Date on which the PBM contract ends or is terminated. Nullable for open-ended contracts. Claims with a Date of Service (DOS) after this date are out-of-contract.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this PBM contract record was last modified. Used for change tracking, ETL incremental loads, and audit trail purposes.',
  CONSTRAINT pk_division_pbm_contract PRIMARY KEY (division_pbm_contract_id)
)
COMMENT 'Master record for a PBM contract negotiated on behalf of a Division or Client. Captures the contracted PBM name, contract effective and termination dates, pricing model type (pass-through vs.'
;

CREATE TABLE IF NOT EXISTS pillarrx.division.engagement (
  account_manager STRING COMMENT 'Full name of the PillarRx account manager responsible for the client relationship associated with this engagement.',
  actual_end_date DATE COMMENT 'The date the engagement was actually closed or completed, which may differ from the contractual end_date due to extensions or early termination.',
  analysis_period_end DATE COMMENT 'End date of the pharmacy claims or data analysis window for this engagement. Defines the claims date-of-service (DOS) range included in deliverables.',
  analysis_period_start DATE COMMENT 'Start date of the pharmacy claims or data analysis window for this engagement. May differ from the engagement start_date (e.g., retrospective audits).',
  audit_finding_count INT COMMENT 'Number of audit findings identified during a PBM audit engagement. Populated upon completion of audit work; null for non-audit engagements.',
  contract_value DECIMAL(18,2) COMMENT 'Total contracted consulting fee value for this engagement in USD. Used for revenue recognition, billing, and NetSuite/Brown & Brown Finance GL posting.',
  cost_center_code STRING COMMENT 'Cost center code in NetSuite to which internal labor and overhead costs for this engagement are allocated. Supports financial reporting and profitability analysis.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this division_engagement record was first created in the data platform. Supports audit trail and data lineage requirements.',
  currency_code STRING COMMENT 'ISO 4217 three-letter currency code for all monetary amounts on this engagement (e.g., USD). PillarRx operates primarily in USD.',
  data_received_date DATE COMMENT 'Date on which the required PBM claims data or eligibility files were received from the client or PBM, enabling analysis to begin.',
  deliverable_count INT COMMENT 'Total number of formal deliverables (reports, analyses, presentations) committed under this engagement per the SOW. Used for progress tracking.',
  division_id BIGINT COMMENT 'Reference to the Division within the Company > Division > Client hierarchy that owns this consulting engagement.',
  division_pbm_contract_id BIGINT COMMENT 'Foreign key linking to division.division_pbm_contract. Business justification: Links an engagement to a specific PBM contract when the engagement is contract-specific (e.g., single-contract audit).',
  end_date DATE COMMENT 'Contractual or operational end date on which the consulting engagement is scheduled to conclude. Null for open-ended engagements.',
  engagement_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for a consulting engagement scoped to a Division. Primary key for the division_engagement entity.',
  engagement_name STRING COMMENT 'Human-readable name or title of the consulting engagement (e.g., ''FY2024 PBM Audit – Acme Corp Division''). Used in reporting and client deliverables.',
  engagement_number STRING COMMENT 'Externally-known alphanumeric identifier for the consulting engagement, used in client communications, SOWs, and invoicing. Sourced from Salesforce CRM.',
  engagement_status STRING COMMENT 'Current lifecycle state of the consulting engagement. Drives workflow routing, billing eligibility, and reporting inclusion.',
  engagement_type STRING COMMENT 'Classification of the engagement by delivery model: recurring (ongoing retainer), project (defined scope/timeline), or ad_hoc (one-time request).',
  estimated_savings DECIMAL(18,2) COMMENT 'Estimated dollar savings identified for the client through this engagement (e.g., audit recoveries, rebate variances, formulary optimization). Raw estimate, not guaranteed.',
  fee_structure STRING COMMENT 'Billing model governing how consulting fees are calculated and invoiced for this engagement (e.g., flat fee, PMPM, milestone-based).',
  gl_account_code STRING COMMENT 'General Ledger (GL) account code in NetSuite used to post consulting fee revenue for this engagement. Supports Brown & Brown Finance SOX controls.',
  is_cap_management BOOLEAN COMMENT 'Indicates whether this engagement includes Copay Assistance Program (CAP) management via the PAX application. True = CAP management in scope.',
  is_pbm_audit BOOLEAN COMMENT 'Indicates whether this engagement includes a PBM audit service line (contract guarantee reconciliation, discount/rebate/dispensing-fee audit). True = audit in scope.',
  is_rebate_reconciliation BOOLEAN COMMENT 'Indicates whether this engagement includes rebate reconciliation (manufacturer and PBM rebate audit and pass-through verification). True = rebate reconciliation in scope.',
  is_tcoc_integration BOOLEAN COMMENT 'Indicates whether this engagement integrates medical claims data for Total Cost of Care (TCOC) analysis. True = medical claims feed in scope.',
  kickoff_date DATE COMMENT 'Date of the formal kickoff meeting with the client for this engagement. Marks the transition from contracting to active delivery.',
  last_review_date DATE COMMENT 'Date of the most recent internal or client-facing review or status meeting for this engagement. Used for engagement health monitoring.',
  lead_consultant STRING COMMENT 'Full name of the PillarRx consultant who is the primary owner and accountable lead for this engagement. Used for workload tracking and client communications.',
  member_count INT COMMENT 'Number of covered members in scope for this engagement at the time of initiation. Used for PMPM fee calculation and benchmarking normalization.',
  next_milestone_date DATE COMMENT 'Target date for the next scheduled deliverable or milestone in the engagement timeline. Supports proactive project management and client communication.',
  notes STRING COMMENT 'Free-text field for internal notes, special instructions, or context relevant to this engagement. Not shared externally in deliverables.',
  pbm_scope STRING COMMENT 'Comma-separated list of PBM(s) in scope for this engagement (e.g., CVS Caremark, Optum Rx, Express Scripts). Drives claims data extraction and audit targeting.',
  pmpm_rate DECIMAL(10,4) COMMENT 'Consulting fee rate expressed as a Per Member Per Month (PMPM) dollar amount. Applicable only when fee_structure = pmpm. Used for invoice calculation.',
  priority STRING COMMENT 'Business priority level assigned to this engagement, used for resource allocation and scheduling within the consulting team.',
  realized_savings DECIMAL(18,2) COMMENT 'Actual dollar savings confirmed and realized by the client as a result of this engagement. Populated post-implementation; distinct from estimated_savings.',
  salesforce_opportunity_code STRING COMMENT 'Identifier of the corresponding Opportunity record in Salesforce CRM. Enables cross-system traceability between CRM pipeline and the data warehouse engagement record.',
  service_line STRING COMMENT 'Primary consulting service line delivered under this engagement. [ENUM-REF-CANDIDATE: pbm_audit|benchmarking|trend_analysis|cap_management|rebate_reconciliation|prior_auth_analysis|tcoc_integration — promote to reference product]',
  sow_reference STRING COMMENT 'Document reference number or title of the Statement of Work (SOW) governing this engagement. Links the data record to the executed legal/contractual document.',
  start_date DATE COMMENT 'Contractual or operational start date on which the consulting engagement becomes active and work may commence.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this division_engagement record was most recently modified. Used for incremental ETL processing and change detection in the Silver layer.',
  CONSTRAINT pk_engagement PRIMARY KEY (engagement_id)
)
COMMENT 'Master record for a consulting engagement scoped to a Division (and optionally a specific service line: PBM audit, benchmarking, trend analysis, copay assistance management, rebate reconciliation).'
;

CREATE TABLE IF NOT EXISTS pillarrx.division.formulary_drug_placement (
  age_restriction_max INT COMMENT 'Maximum member age (in years) allowed for coverage under this formulary drug placement. Null indicates no maximum age restriction applies.',
  age_restriction_min INT COMMENT 'Minimum member age (in years) required for coverage under this formulary drug placement. Null indicates no minimum age restriction applies.',
  coinsurance_pct DECIMAL(5,4) COMMENT 'Percentage of drug cost the member pays as coinsurance for this formulary tier placement (e.g., 0.20 = 20%). Null when cost-sharing is fixed copay-based.',
  copay_amount DECIMAL(10,2) COMMENT 'Fixed dollar copay amount the member is responsible for when filling a drug under this formulary tier placement. Null when cost-sharing is coinsurance-based.',
  coverage_type STRING COMMENT 'Indicates the dispensing channel(s) for which this formulary drug placement applies: retail pharmacy, mail-order, specialty pharmacy, or both retail and mail.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this formulary drug placement record was first created in the data platform. Used for audit trail and SCD history management.',
  days_supply_limit INT COMMENT 'Maximum days supply allowed per fill for this formulary drug placement (e.g., 30 days at retail, 90 days at mail order). Enforced at point-of-sale adjudication.',
  division_formulary_tier_id BIGINT COMMENT 'Reference to the formulary tier definition record that specifies cost-sharing rules for this drug placement.',
  drug_name STRING COMMENT 'Brand or generic drug name associated with this formulary placement. Denormalized for reporting convenience; authoritative name resides in the NDC/drug reference dimension.',
  effective_date DATE COMMENT 'Date on which this formulary drug placement becomes effective and governs member cost-sharing for claims adjudicated on or after this date.',
  excluded_indicator BOOLEAN COMMENT 'Indicates whether this drug is explicitly excluded from formulary coverage. Excluded drugs are not covered under the plan and require non-formulary exception processing.',
  formulary_alternative_ndc_code STRING COMMENT 'NDC of the preferred formulary alternative drug recommended when this placement carries restrictions (PA, ST, QL). Supports member and prescriber messaging for step therapy.',
  formulary_drug_placement_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for a formulary drug placement record associating a drug (NDC or GPI) with a formulary tier during a defined effective period.',
  formulary_status_code STRING COMMENT 'NCPDP-standard formulary status code indicating coverage disposition: 1=On Formulary, 2=Non-Formulary, 3=Formulary with Restrictions, 4=Not Covered, 5=Covered, 6=Prior Auth. [ENUM-REF-CANDIDATE: promote to reference product if values expand]',
  formulary_tier_id BIGINT COMMENT 'FK to division.formulary_tier.formulary_tier_id — Placement assigns an NDC/GPI to a specific tier; placement must reference the tier it lands on.',
  gender_restriction STRING COMMENT 'Gender restriction for this formulary drug placement: M=Male only, F=Female only, U=No restriction. Applies to gender-specific drugs (e.g., contraceptives, hormone therapy).',
  generic_indicator STRING COMMENT 'Indicates whether the drug placed on this formulary tier is a brand, generic, or biosimilar product. Drives Generic Dispensing Rate (GDR) analytics and rebate tracking.',
  gpi STRING COMMENT '14-digit Medi-Span Generic Product Identifier representing the drug class or therapeutic group when formulary placement is defined at the GPI level rather than specific NDC.',
  is_current BOOLEAN COMMENT 'Type-2 SCD flag indicating whether this is the current active version of the formulary drug placement record. True for the most recent version; False for historical versions.',
  limited_distribution_indicator BOOLEAN COMMENT 'Indicates whether this drug is a Limited Distribution Drug (LDD), available only through select specialty pharmacies designated by the manufacturer.',
  mail_coinsurance_pct DECIMAL(5,4) COMMENT 'Percentage of drug cost the member pays as coinsurance for mail-order dispensing under this formulary tier placement. Null when mail cost-sharing is fixed copay-based.',
  mail_copay_amount DECIMAL(10,2) COMMENT 'Fixed dollar copay amount for mail-order dispensing of this drug under this formulary tier placement. Often lower than retail copay to incentivize mail utilization.',
  ndc_code STRING COMMENT '11-digit FDA-assigned National Drug Code identifying the specific drug product, labeler, and package size placed on this formulary tier. Null when placement is GPI-level.',
  otc_indicator BOOLEAN COMMENT 'Indicates whether this formulary drug placement covers an over-the-counter (OTC) product. OTC coverage is plan-specific and may carry different cost-sharing rules.',
  pa_required BOOLEAN COMMENT 'Indicates whether a Prior Authorization (PA) is required before this drug will be covered under the formulary placement. True triggers PA workflow at point of dispensing.',
  placement_level STRING COMMENT 'Indicates whether this formulary placement is defined at the specific NDC level, GPI drug class level, or broader GPI therapeutic class level.',
  placement_status STRING COMMENT 'Current lifecycle status of this formulary drug placement record. Active placements govern current benefit adjudication; inactive or terminated records are retained for historical audit.',
  preferred_indicator BOOLEAN COMMENT 'Indicates whether this drug is designated as a preferred product within its tier, typically associated with lower member cost-sharing and higher rebate eligibility.',
  primary_division_formulary_id BIGINT COMMENT 'Reference to the formulary (covered drug list) on which this drug placement is defined. Links to the parent formulary record.',
  primary_formulary_division_formulary_id BIGINT COMMENT 'FK to division.formulary.formulary_id — Placement is scoped to a formulary; needed for formulary change tracking over time.',
  prior_auth_rule_id BIGINT COMMENT 'Foreign key linking to division.prior_auth_rule. Business justification: Links a drug placement to the PA rule that applies when pa_required is true. When a drug on a formulary requires prior authorization, this FK identifies the specific rule.',
  quantity_limit_amount DECIMAL(10,3) COMMENT 'Maximum quantity (units, tablets, mL, etc.) allowed per fill or per defined period when a Quantity Limit applies to this formulary placement. Null when QL is not required.',
  quantity_limit_days INT COMMENT 'Number of days supply over which the quantity limit amount applies for this formulary drug placement (e.g., 30 days, 90 days). Null when QL is not required.',
  quantity_limit_required BOOLEAN COMMENT 'Indicates whether a Quantity Limit (QL) restriction applies to this formulary drug placement, capping the dispensable quantity per fill or per defined period.',
  rebate_eligible_indicator BOOLEAN COMMENT 'Indicates whether claims filled under this formulary drug placement are eligible for manufacturer rebates. Supports rebate contract reconciliation and DIR fee analysis.',
  scd_version INT COMMENT 'Incrementing version number for Type-2 Slowly Changing Dimension (SCD) history tracking of this formulary drug placement record. Version 1 is the original; higher values are subsequent changes.',
  source_pbm_formulary_division_formulary_id BIGINT COMMENT 'The PBM''s native formulary identifier for this drug placement as received in the PBM claims or formulary feed. Supports traceability back to the originating PBM source system.',
  specialty_drug_indicator BOOLEAN COMMENT 'Indicates whether this formulary drug placement is classified as a specialty medication (SMN), typically requiring specialty pharmacy dispensing and enhanced clinical management.',
  step_therapy_required BOOLEAN COMMENT 'Indicates whether Step Therapy (ST) applies to this formulary placement, requiring the member to try a preferred drug before coverage of this drug is approved.',
  termination_date DATE COMMENT 'Date on which this formulary drug placement expires or is removed. Null indicates an open-ended placement with no defined end. Supports Type-2 SCD history tracking.',
  therapeutic_class_code STRING COMMENT 'Drug therapeutic class code from Medi-Span or First DataBank (FDB) classification system associated with this formulary placement. Supports formulary analysis by drug class.',
  therapeutic_class_name STRING COMMENT 'Human-readable therapeutic class name corresponding to the therapeutic class code for this formulary drug placement. Used in formulary reporting and consulting deliverables.',
  tier_name STRING COMMENT 'Human-readable label for the formulary tier assigned to this drug (e.g., ''Generic'', ''Preferred Brand'', ''Non-Preferred Brand'', ''Specialty''). Supports reporting and member communications.',
  tier_number INT COMMENT 'Numeric tier level assigned to this drug on the formulary (e.g., 1=Generic, 2=Preferred Brand, 3=Non-Preferred Brand, 4=Specialty). Drives member cost-sharing.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this formulary drug placement record was last modified in the data platform. Tracks changes for SCD Type-2 history and audit compliance.',
  CONSTRAINT pk_formulary_drug_placement PRIMARY KEY (formulary_drug_placement_id)
)
COMMENT 'Transactional/association record capturing the placement of a specific NDC (or GPI drug class) on a formulary tier during a defined effective period. Stores the NDC or GPI, the assigned tier number, prior authorization (PA) requirement flag, step therapy'
;

CREATE TABLE IF NOT EXISTS pillarrx.division.pbm_feed (
  baa_effective_date DATE COMMENT 'Date on which the HIPAA Business Associate Agreement with the PBM became effective for this feed. Used for compliance auditing and to ensure PHI exchange is covered by a valid BAA.',
  baa_on_file BOOLEAN COMMENT 'Indicates whether a signed HIPAA Business Associate Agreement (BAA) is on file with this PBM for this feed. A BAA is legally required before PHI can be exchanged. Feeds without a BAA must not be activated.',
  claim_types_included STRING COMMENT 'Pipe-delimited list of claim transaction types included in this feed (e.g., ''fill|reversal|adjustment''). Defines the scope of claim data expected and drives validation rules in the ingestion pipeline.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM entity (CVS Caremark, Optum Rx, Express Scripts, Navitus, EmpiRx Health, BCBS Michigan, Rightway, Prime Therapeutics, ServeYou, Carelon) that is the source of this claims data feed.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this PBM feed configuration record was first created in the system. Supports audit trail and feed lifecycle tracking per SOC 2 change management controls.',
  delivery_frequency STRING COMMENT 'How often the PBM delivers claim extract files for this feed. Daily feeds support near-real-time analytics; monthly feeds are common for smaller PBMs or historical loads.',
  delivery_method STRING COMMENT 'Technical mechanism by which the PBM delivers claim extract files to PillarRx. SFTP is most common; API-based and cloud storage (S3) delivery are increasingly used by modern PBMs.',
  division_id BIGINT COMMENT 'Reference to the division within the Company > Division > Client hierarchy that this PBM feed serves. A division may have multiple PBM feeds across different PBMs.',
  dos_end_date DATE COMMENT 'Latest date of service (DOS) for claims expected in this feed. Null for ongoing feeds. Used to validate that the feed does not include claims outside the contracted coverage period.',
  dos_start_date DATE COMMENT 'Earliest date of service (DOS) for claims expected in this feed. Defines the historical coverage window for the feed and is used to validate that claims are within the contracted data scope.',
  effective_date DATE COMMENT 'Date on which this PBM feed agreement became or becomes active. Claims with a date of service on or after this date are expected to be included in the feed.',
  encryption_required BOOLEAN COMMENT 'Indicates whether feed files from this PBM must be encrypted (e.g., PGP) in transit. Required for HIPAA-compliant PHI transmission. Drives automated decryption steps in the ingestion pipeline.',
  expected_member_count INT COMMENT 'Approximate number of eligible members expected to appear in this feed. Used as a baseline for feed volume validation; significant deviations trigger data quality alerts.',
  feed_code STRING COMMENT 'Short alphanumeric code uniquely identifying this feed configuration within the PBM Claims Feed Ingestion Platform. Used in ETL pipeline routing and file naming conventions.',
  feed_name STRING COMMENT 'Human-readable name identifying this PBM feed configuration, typically combining the division name and PBM name (e.g., ''Acme Corp - CVS Caremark Pharmacy Claims''). Used in UI and reporting.',
  feed_status STRING COMMENT 'Current operational lifecycle status of this PBM feed. Active feeds are receiving and processing claim extracts. Suspended feeds are temporarily halted. Terminated feeds are permanently closed.',
  feed_type STRING COMMENT 'Classification of the data content delivered by this feed. Pharmacy claim feeds carry NCPDP-standard Rx claim transactions. Medical claim feeds carry HIPAA 837 transactions.',
  file_delimiter STRING COMMENT 'Character used to separate fields in delimited feed files (e.g., pipe ''|'', comma '','', tab). Null for non-delimited formats such as fixed-width or XML. Required for ETL parsing configuration.',
  file_encoding STRING COMMENT 'Character encoding standard used in the PBM feed files. UTF-8 is the modern default; legacy PBM systems may deliver ISO-8859-1 or ASCII-encoded files requiring transformation.',
  file_format STRING COMMENT 'Technical file format of the claim extract delivered by the PBM. Fixed-width and delimited (CSV/pipe) are legacy PBM formats; EDI 835/837 are HIPAA-standard transaction formats.',
  file_naming_pattern STRING COMMENT 'Expected filename pattern or regex for incoming feed files from this PBM (e.g., ''ACME_CVS_{YYYYMMDD}.txt''). Used by the ingestion platform to identify, validate, and route incoming files.',
  includes_medical_claims BOOLEAN COMMENT 'Indicates whether this feed includes medical claims in addition to pharmacy claims. True for integrated PBM/medical feeds used in total cost of care (TCOC) analysis.',
  includes_rebate_data BOOLEAN COMMENT 'Indicates whether this feed includes manufacturer rebate or DIR (Direct and Indirect Remuneration) data alongside claim transactions. Relevant for pass-through PBM contract auditing.',
  is_pass_through BOOLEAN COMMENT 'Indicates whether the PBM contract for this feed operates on a pass-through (transparent) pricing model. Pass-through feeds require additional spread and rebate reconciliation analytics.',
  last_file_received_date DATE COMMENT 'Date on which the most recent feed file was successfully received from the PBM. Used for feed monitoring, SLA tracking, and alerting when expected files are not delivered on schedule.',
  last_successful_load_date DATE COMMENT 'Date on which the most recent feed file was successfully ingested and loaded into the data lakehouse. Distinct from receipt date; a file may be received but fail validation before loading.',
  lookback_days INT COMMENT 'Number of days of historical claims included in each feed extract. PBMs may include a rolling lookback window to capture late-arriving adjustments and reversals (e.g., 90 days for DIR reconciliation).',
  normalization_profile STRING COMMENT 'Name of the ETL normalization mapping profile applied to this feed during ingestion. Each PBM has a unique field layout; the profile maps source fields to the PillarRx canonical claim schema.',
  notes STRING COMMENT 'Free-text field for operational notes about this PBM feed configuration, such as known data quirks, PBM-specific field mappings, historical issues, or onboarding context captured during client setup.',
  pbm_client_code STRING COMMENT 'The client or group identifier assigned by the PBM to identify the division or employer group in the PBM''s system. Used for feed routing, file validation, and claim matching.',
  pbm_contact_email STRING COMMENT 'Email address of the primary PBM technical or account contact for this feed. Used for feed delivery notifications, issue resolution, and schema change communications.',
  pbm_contact_name STRING COMMENT 'Name of the primary PBM account representative or technical contact responsible for this data feed. Used for issue escalation and feed configuration changes.',
  pbm_contract_id BIGINT COMMENT 'Reference to the PBM contract record governing the terms under which this data feed is provided. Links the feed to the broader PBM service agreement for audit and reconciliation purposes.',
  pbm_feed_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the division-PBM feed configuration record. Primary key for this master agreement entity governing how PillarRx receives claim extracts from a PBM on behalf of a division.',
  pbm_group_code STRING COMMENT 'The benefit group identifier used by the PBM to segment members within the employer plan. Corresponds to the RxGroup field in pharmacy claim routing and is used to scope claim extracts.',
  pgp_key_reference STRING COMMENT 'Reference identifier for the PGP public key used to decrypt incoming feed files from this PBM. The actual key material is stored in the secrets vault; this field holds the key alias or fingerprint.',
  rx_bin STRING COMMENT 'Six-digit Bank Identification Number (BIN) used to route pharmacy claims to the correct PBM processor at the point of sale. A key identifier for validating that claims in this feed belong to the correct PBM.',
  rx_pcn STRING COMMENT 'Processor Control Number (PCN) used in conjunction with RxBIN to route pharmacy claims to the correct PBM sub-processor or plan. Validates claim routing for this feed.',
  schema_version STRING COMMENT 'Version identifier of the PBM feed file layout or API schema in use (e.g., ''3.2'', ''5.0.1''). PBMs periodically update their extract formats; version tracking enables backward-compatible ingestion.',
  sftp_host STRING COMMENT 'Hostname or IP address of the SFTP server from which PillarRx retrieves feed files for this PBM connection. Confidential infrastructure detail used by the ETL ingestion platform.',
  sftp_path STRING COMMENT 'Remote directory path on the SFTP server where the PBM deposits claim extract files for this feed. Used by the automated ingestion job to locate and retrieve files.',
  sftp_username STRING COMMENT 'Username credential used to authenticate to the PBM SFTP server for this feed. Stored as a reference; actual credentials are managed in a secrets vault per SOC 2 controls.',
  termination_date DATE COMMENT 'Date on which this PBM feed agreement ends. Null for open-ended feeds. Claims with a date of service after this date should not be expected from this feed.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this PBM feed configuration record was last modified. Used for change tracking, audit logging, and detecting configuration drift in the ingestion platform.',
  CONSTRAINT pk_pbm_feed PRIMARY KEY (pbm_feed_id)
)
COMMENT 'Master record for a data feed/source connection by which PillarRx receives pharmacy (and medical) claim extracts for a specific Division from a specific PBM.'
;

CREATE TABLE IF NOT EXISTS pillarrx.division.pbm_guarantee_period (
  actual_member_months INT COMMENT 'Actual number of member months recorded during this guarantee period. Used as the denominator for PMPM calculations and to validate eligibility for guarantee measurement.',
  audit_completion_date DATE COMMENT 'Date on which the PBM performance audit for this guarantee period was completed and findings were finalized. Used to track consulting engagement timelines.',
  audit_status STRING COMMENT 'Current status of the PBM performance audit for this guarantee period. Tracks PillarRx consulting audit workflow from initiation through findings delivery to the client.',
  awp_discount_guarantee_brand DECIMAL(7,4) COMMENT 'Contractually guaranteed AWP discount percentage for brand drugs during this period. Expressed as a decimal (e.g., 0.1800 = 18.00%). Baseline for PBM audit.',
  awp_discount_guarantee_generic DECIMAL(7,4) COMMENT 'Contractually guaranteed AWP discount percentage for generic drugs during this period. Expressed as a decimal (e.g., 0.8500 = 85.00%). Baseline for PBM audit.',
  awp_discount_guarantee_specialty DECIMAL(7,4) COMMENT 'Contractually guaranteed AWP discount percentage for specialty drugs during this period. Expressed as a decimal. Specialty spend is a primary driver of total pharmacy cost.',
  ber_guarantee DECIMAL(7,4) COMMENT 'Brand Effective Rate (BER) guarantee for this period, representing the blended net cost per brand claim after all discounts and rebates. Expressed as a decimal.',
  client_report_delivered_date DATE COMMENT 'Actual date on which the guarantee period performance report was delivered to the employer client. Used to measure consulting engagement timeliness and SLA adherence.',
  client_report_due_date DATE COMMENT 'Date by which PillarRx must deliver the guarantee period performance report to the employer client. Drives consulting engagement scheduling and deliverable tracking.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM entity (e.g., CVS Caremark, Optum Rx, Express Scripts) whose performance guarantees are being measured in this period.',
  contract_fk BIGINT COMMENT 'FK to division.pbm_contract.pbm_contract_id — A guarantee period measures a specific PBM contract; parent FK required for reconciliation chain.',
  contract_year_number INT COMMENT 'Sequential year number within the PBM contract term (e.g., Year 1, Year 2, Year 3). Used to track guarantee escalation schedules and multi-year contract performance.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this guarantee period record was first created in the system. Supports audit trail and data lineage requirements.',
  dir_applicable_indicator BOOLEAN COMMENT 'Indicates whether Direct and Indirect Remuneration (DIR) fees apply during this guarantee period. DIR fees affect net drug cost and are subject to CMS regulatory scrutiny.',
  dispensing_fee_guarantee_mail DECIMAL(10,4) COMMENT 'Maximum guaranteed dispensing fee per mail-order claim for this period. Expressed in USD. Mail-order dispensing fees are typically lower than retail on a per-fill basis.',
  dispensing_fee_guarantee_retail DECIMAL(10,4) COMMENT 'Maximum guaranteed dispensing fee per retail claim for this period. Expressed in USD. Compared against actual dispensing fees paid to assess PBM compliance.',
  dispute_description STRING COMMENT 'Narrative description of the nature of the dispute, including the specific guarantee metric(s) contested and the basis for the disagreement with the PBM.',
  dispute_indicator BOOLEAN COMMENT 'Indicates whether the client or PillarRx has formally disputed the PBM''s performance results or remediation position for this guarantee period.',
  division_pbm_contract_id BIGINT COMMENT 'Reference to the PBM contract under which this guarantee period is evaluated. Links the period to its governing contract terms.',
  employer_id BIGINT COMMENT 'Reference to the employer client whose pharmacy spend is subject to PBM performance guarantees during this period.',
  end_date DATE COMMENT 'Last date of the measurement window for PBM performance guarantee evaluation. Claims with a date of service within start_date and end_date are included.',
  evaluation_year INT COMMENT 'Calendar or plan year (e.g., 2024) associated with this guarantee period. Supports year-over-year trend analysis and annual reconciliation reporting.',
  gdr_guarantee DECIMAL(7,4) COMMENT 'Minimum guaranteed Generic Dispensing Rate (GDR) for this period. Expressed as a decimal (e.g., 0.8800 = 88.00%). Low GDR may indicate formulary or substitution issues.',
  ger_guarantee DECIMAL(7,4) COMMENT 'Guaranteed Effective Rate (GER) for brand drugs, representing the net effective AWP discount after rebates for this period. Expressed as a decimal. Key PBM audit metric.',
  guarantee_period_contract_fk BIGINT COMMENT 'FK to division.pbm_contract.pbm_contract_id — A guarantee period is ''evaluated against a specific PBM contract'' — this transaction->master FK is the backbone of the reconciliation chain and no engineer would ship without it.',
  guarantee_period_pbm_contract_fk BIGINT COMMENT 'FK to division.pbm_contract.pbm_contract_id — Each guarantee period evaluates a specific PBM contract. Transaction->master link required for reconciliation lineage.',
  guarantee_shortfall_amount DECIMAL(18,2) COMMENT 'Dollar amount by which the PBM failed to meet financial guarantees during this period. Expressed in USD. Positive value indicates a shortfall owed to the client by the PBM.',
  mac_guarantee_indicator BOOLEAN COMMENT 'Indicates whether a Maximum Allowable Cost (MAC) pricing guarantee applies to this period. When true, the PBM is contractually bound to a specific MAC list and pricing methodology.',
  measurement_basis STRING COMMENT 'Defines the claim population used to measure PBM performance against guarantees (e.g., paid claims net of reversals). Ensures consistent audit methodology.',
  minimum_member_months INT COMMENT 'Minimum number of member months required for the guarantee period to be eligible for performance measurement. Protects against small-sample distortions in guarantee calculations.',
  notes STRING COMMENT 'Free-text field for analyst or consultant notes regarding this guarantee period, such as methodology exceptions, PBM communications, or client-specific context.',
  pass_through_indicator BOOLEAN COMMENT 'Indicates whether the PBM contract for this period operates on a pass-through (transparent) pricing model. Pass-through contracts eliminate spread pricing and require full rebate disclosure.',
  pbm_contract_fk BIGINT COMMENT 'FK to division.pbm_contract.pbm_contract_id — A guarantee measurement period is evaluated against a specific PBM contract; master->period lineage required for variance tracing.',
  pbm_data_received_date DATE COMMENT 'Actual date on which PBM claims data and performance reports were received by PillarRx for this guarantee period. Compared against submission deadline for compliance tracking.',
  pbm_guarantee_period_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for a PBM guarantee period record. Primary key for this entity.',
  pbm_submission_deadline DATE COMMENT 'Contractual deadline by which the PBM must submit claims data and performance reports for this guarantee period. Missed deadlines may trigger contract remedies.',
  period_name STRING COMMENT 'Human-readable label for the guarantee period, such as ''CY2024 Annual Guarantee Period'' or ''2024 H1 Semi-Annual Review''. Used in reporting and client deliverables.',
  period_status STRING COMMENT 'Current lifecycle state of the guarantee period. Drives workflow routing for audit, reconciliation, and client reporting activities.',
  period_type STRING COMMENT 'Classification of the measurement cadence for this guarantee period. Drives how performance results are aggregated and reported to the client.',
  rebate_guarantee_pmpm DECIMAL(10,4) COMMENT 'Minimum guaranteed rebate amount per member per month (PMPM) for this period. Expressed in USD. Used to assess whether PBM rebate pass-through meets contractual minimums.',
  remediation_amount DECIMAL(18,2) COMMENT 'Dollar amount agreed upon or paid by the PBM to remediate guarantee shortfalls for this period. Expressed in USD. May differ from shortfall_amount after negotiation.',
  remediation_status STRING COMMENT 'Current status of the remediation process for any guarantee shortfall identified in this period. Tracks the resolution lifecycle from identification through payment or waiver.',
  start_date DATE COMMENT 'First date of the measurement window during which PBM performance guarantees are evaluated. Aligns with the contract year or sub-period definition.',
  total_claim_count INT COMMENT 'Total number of pharmacy claims included in the guarantee period measurement population. Used to validate statistical significance and support PBM audit reconciliation.',
  total_drug_spend DECIMAL(18,2) COMMENT 'Total plan-paid drug spend (ingredient cost plus dispensing fees) during this guarantee period. Expressed in USD. Primary financial baseline for guarantee reconciliation.',
  total_rebates_received DECIMAL(18,2) COMMENT 'Total rebate dollars received from the PBM during this guarantee period. Expressed in USD. Compared against rebate guarantee to identify shortfalls requiring remediation.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this guarantee period record was last modified. Used to detect stale records and support incremental ETL processing in the Databricks lakehouse.',
  CONSTRAINT pk_pbm_guarantee_period PRIMARY KEY (pbm_guarantee_period_id)
)
COMMENT 'Defines a discrete measurement period (typically annual or semi-annual) during which PBM performance guarantees are evaluated against a specific PBM contract.'
;

CREATE TABLE IF NOT EXISTS pillarrx.division.pbm_guarantee_result (
  actual_value DECIMAL(18,6) COMMENT 'The actual measured value achieved by the PBM for the guarantee metric during the evaluation period. Compared against guaranteed_value to determine pass/fail.',
  awp_basis DECIMAL(18,2) COMMENT 'Total AWP of drugs in the evaluation population. Used as the denominator for AWP discount guarantee calculations and PBM audit benchmarking.',
  channel_type STRING COMMENT 'Pharmacy dispensing channel scope for this guarantee result (retail, mail order, specialty, or all channels combined). Affects benchmark applicability.',
  claim_count INT COMMENT 'Number of pharmacy claims included in the guarantee evaluation population for this result. Used to validate statistical significance and audit scope.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM (e.g., CVS Caremark, Optum Rx, Express Scripts) against whose contractual guarantee this result is measured.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this guarantee result record was first captured in the system. Used for audit trail and data lineage tracking.',
  currency_code STRING COMMENT 'ISO 4217 three-letter currency code for all monetary amounts on this record. Typically USD for PillarRx domestic employer clients.',
  dir_included BOOLEAN COMMENT 'Indicates whether Direct and Indirect Remuneration (DIR) fees are included in the guarantee calculation. Affects net effective discount and plan cost analysis.',
  dispute_date DATE COMMENT 'Date on which the formal dispute was filed against this guarantee result. Establishes the dispute timeline for resolution tracking and SLA monitoring.',
  dispute_reason STRING COMMENT 'Narrative explanation of the basis for disputing this guarantee result. Captured when is_disputed is True; used in PBM correspondence and audit documentation.',
  drug_category STRING COMMENT 'Drug classification scope to which this guarantee result applies. Determines whether the metric covers brand, generic, specialty, or all drug categories.',
  employer_id BIGINT COMMENT 'Reference to the employer client whose PBM guarantee is being reconciled. Supports multi-tenant scoping within the Company > Division > Client hierarchy.',
  evaluation_date DATE COMMENT 'The date on which the guarantee metric was formally evaluated and this result record was produced. Principal business event date for this transaction.',
  ger_applicable BOOLEAN COMMENT 'Indicates whether a Guaranteed Effective Rate (GER) applies to this guarantee metric. GER guarantees a blended effective discount rate across the drug mix.',
  guarantee_metric_code STRING COMMENT 'Standardized code identifying the specific guarantee metric being evaluated (e.g., AWP_DISCOUNT_BRAND, GDR, DISPENSING_FEE, REBATE_GUARANTEE). Drives reporting categorization.',
  guarantee_metric_name STRING COMMENT 'Human-readable name of the guarantee metric being evaluated (e.g., ''Brand AWP Discount'', ''Generic Dispensing Rate'', ''Dispensing Fee Guarantee''). Used in client reports.',
  guarantee_type STRING COMMENT 'Classification of the guarantee category. Segments results by the type of PBM contractual commitment being audited (e.g., discount, dispensing fee, rebate, GDR).',
  guaranteed_value DECIMAL(18,6) COMMENT 'The contractually committed guarantee threshold value (e.g., AWP discount percentage, dispensing fee cap, GDR target). Expressed in the unit defined by guarantee_metric_code.',
  is_disputed BOOLEAN COMMENT 'Indicates whether the PBM or client has formally disputed this guarantee result. Triggers dispute workflow and holds remedy payment pending resolution.',
  is_pass BOOLEAN COMMENT 'Boolean flag indicating whether the PBM met the contractual guarantee threshold. True = guarantee met; False = guarantee missed and remedy may apply.',
  is_reconciled BOOLEAN COMMENT 'Indicates whether this guarantee result has been fully reconciled, including remedy payment receipt and client sign-off. Closes the audit cycle for this metric.',
  metric_unit STRING COMMENT 'Unit of measure for the guarantee metric values (guaranteed_value, actual_value, variance_value). Enables correct interpretation of numeric results across different metric types.',
  notes STRING COMMENT 'Free-text notes capturing analyst observations, PBM communications, or contextual details about this guarantee result. Used in consulting deliverables and audit documentation.',
  pbm_contract_id BIGINT COMMENT 'Reference to the PBM contract that defines the guarantee terms being evaluated. Ties the result to the governing contractual agreement.',
  pbm_guarantee_period_id BIGINT COMMENT 'FK to division.pbm_guarantee_period.pbm_guarantee_period_id — Each result row is ''the outcome of a PBM guarantee reconciliation for a specific guarantee period'' — mandatory header->line FK.',
  pbm_guarantee_result_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for a PBM guarantee reconciliation result record. Primary key for this entity. Role: TRANSACTION_HEADER.',
  pbm_period_fk BIGINT COMMENT 'FK to division.pbm_guarantee_period.pbm_guarantee_period_id — Each result rolls up to its guarantee period; without this the reconciliation chain cannot be traced for variance root-cause.',
  pbm_report_reference STRING COMMENT 'Reference number or name of the PBM-issued performance report from which pbm_reported_value was sourced. Supports audit traceability back to PBM documentation.',
  pbm_reported_value DECIMAL(18,6) COMMENT 'The guarantee metric value as self-reported by the PBM in their performance report. Compared to actual_value (PillarRx-calculated) to identify discrepancies for audit.',
  period_end_date DATE COMMENT 'End date of the measurement period covered by this guarantee result. Denormalized from the parent guarantee period for reporting convenience.',
  period_start_date DATE COMMENT 'Start date of the measurement period covered by this guarantee result. Denormalized from the parent guarantee period for reporting convenience.',
  primary_pbm_guarantee_period_id BIGINT COMMENT 'Reference to the parent PBM guarantee period under which this result was evaluated. Links result to its measurement window and contract context.',
  reconciliation_date DATE COMMENT 'Date on which this guarantee result was marked as fully reconciled. Null if is_reconciled is False. Used for period-close reporting.',
  remedy_amount DECIMAL(18,2) COMMENT 'Dollar amount owed by the PBM to the client as a financial remedy for failing to meet the guarantee. Zero if the guarantee was met or waived.',
  remedy_due_date DATE COMMENT 'Contractually required date by which the PBM must remit the remedy payment to the client. Drives accounts receivable follow-up and PBM performance tracking.',
  remedy_paid_amount DECIMAL(18,2) COMMENT 'Dollar amount actually received from the PBM as remedy payment. May differ from remedy_amount if disputed or partially settled.',
  remedy_received_date DATE COMMENT 'Date on which the PBM remedy payment was actually received by the client. Compared to remedy_due_date to identify late payments.',
  remedy_variance_amount DECIMAL(18,2) COMMENT 'Difference between remedy_amount and remedy_paid_amount. Tracks outstanding or disputed remedy balances for follow-up and client reporting.',
  resolution_date DATE COMMENT 'Date on which a disputed guarantee result was formally resolved. Null if dispute is still open. Used to measure dispute cycle time.',
  result_number STRING COMMENT 'Externally-known business identifier for this guarantee result record, used in client deliverables, audit reports, and PBM correspondence.',
  result_status STRING COMMENT 'Current lifecycle status of the guarantee result. Indicates whether the PBM met, missed, or is under review for the evaluated guarantee metric.',
  source_file_name STRING COMMENT 'Name of the source data file from which this guarantee result was loaded or derived. Supports ETL lineage, reprocessing, and audit traceability.',
  total_drug_spend DECIMAL(18,2) COMMENT 'Total pharmacy drug spend included in the guarantee evaluation population. Provides financial context for the scale of the guarantee measurement.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this guarantee result record was last modified. Tracks revisions from dispute resolution, restatements, or PBM data corrections.',
  variance_value DECIMAL(18,6) COMMENT 'Difference between actual_value and guaranteed_value. Positive variance indicates PBM outperformed; negative indicates underperformance and potential financial remedy.',
  CONSTRAINT pk_pbm_guarantee_result PRIMARY KEY (pbm_guarantee_result_id)
)
COMMENT 'Transactional record capturing the outcome of a PBM guarantee reconciliation for a specific guarantee period and metric. References its parent pbm_guarantee_period.'
;

CREATE TABLE IF NOT EXISTS pillarrx.division.prior_auth_request (
  appeal_date DATE COMMENT 'Date on which the appeal of a denied PA was formally submitted. Null if no appeal has been filed.',
  appeal_indicator BOOLEAN COMMENT 'Indicates whether a formal appeal has been filed against a PA denial decision. Triggers appeal tracking workflow in the Prior Authorization Analytics module.',
  appeal_outcome STRING COMMENT 'Result of the PA appeal review. Overturned appeals result in authorization; upheld appeals confirm the original denial.',
  benefit_plan_id BIGINT COMMENT 'Identifier of the specific benefit plan or benefit group under which this PA request is evaluated. Determines formulary tier and cost-sharing rules.',
  clinical_indication STRING COMMENT 'Diagnosis or clinical rationale submitted by the prescriber to support the PA request. Contains PHI. Used for clinical appropriateness review.',
  company_pbm_id BIGINT COMMENT 'Identifier of the PBM (e.g., CVS Caremark, Optum Rx, Express Scripts) that adjudicates this PA request on behalf of the plan.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this PA request record was first created in the PillarRx lakehouse. Supports audit trail and data lineage.',
  days_supply_requested INT COMMENT 'Number of days supply of the drug requested in the PA submission. Used to evaluate quantity limit compliance and dispensing channel appropriateness.',
  decision_date DATE COMMENT 'Calendar date the PBM or plan issued a final decision (approval, denial, or cancellation) on the PA request.',
  decision_timestamp TIMESTAMP COMMENT 'Precise date and time the PA decision was rendered. Used to compute exact turnaround hours for SLA and regulatory compliance reporting.',
  denial_reason_code STRING COMMENT 'Standardized code issued by the PBM indicating the reason for PA denial (e.g., not medically necessary, step therapy required, non-formulary). Null if approved.',
  denial_reason_description STRING COMMENT 'Free-text or standardized description of the denial reason provided by the PBM. Supports member communication and consulting audit analysis.',
  division_id BIGINT COMMENT 'Identifier of the PillarRx division responsible for managing this client engagement. Supports multi-tenant data scoping.',
  drug_name STRING COMMENT 'Brand or generic name of the drug for which PA is requested. Sourced from Medi-Span or FDB. Supports human-readable reporting without dimension join.',
  effective_date DATE COMMENT 'Date from which an approved PA authorization is valid for claim adjudication. Claims filled before this date will not satisfy the PA requirement.',
  employer_id BIGINT COMMENT 'Identifier of the employer client (plan sponsor) under whose benefit plan this PA request was submitted. Links to the Company > Division > Client hierarchy.',
  expiration_date DATE COMMENT 'Date on which the approved PA authorization expires. Claims filled after this date require a new PA submission.',
  formulary_tier STRING COMMENT 'Formulary tier of the requested drug under the applicable benefit plan at the time of PA submission. Influences cost-sharing and PA criteria.',
  icd10_diagnosis_code STRING COMMENT 'ICD-10-CM diagnosis code submitted with the PA request to establish medical necessity. PHI. Supports clinical analytics and denial pattern analysis.',
  is_specialty_drug BOOLEAN COMMENT 'Indicates whether the requested drug is classified as a specialty medication (SMN). Specialty drugs typically have higher PA rates and require additional clinical review.',
  linked_rx_claim_id BIGINT COMMENT 'Identifier of the pharmacy claim (rx_claim) that was adjudicated using this PA authorization. Enables PA-to-claim linkage for audit and utilization analysis.',
  notes STRING COMMENT 'Free-text notes or supplemental clinical documentation attached to the PA request by the prescriber, plan, or PillarRx consulting team.',
  pa_number STRING COMMENT 'Externally assigned PA reference number issued by the PBM or plan upon submission. Used for claim adjudication linkage and audit trail.',
  pa_status STRING COMMENT 'Current lifecycle status of the PA request. Drives workflow routing, member notification, and consulting audit reporting.',
  pa_type STRING COMMENT 'Classification of the PA request by processing urgency or timing. Expedited PAs have regulatory turnaround requirements under CMS and state law.',
  pbm_name STRING COMMENT 'Name of the PBM that processed this PA request (e.g., CVS Caremark, Optum Rx, Express Scripts). Denormalized for direct reporting without dimension join.',
  pbm_pa_reference STRING COMMENT 'PBM-assigned internal reference number for this PA request as received in the PBM claims feed or PA data extract. Supports cross-system reconciliation.',
  prescriber_npi STRING COMMENT '10-digit NPI of the prescribing provider who initiated the PA request. Sourced from NPPES. Used for prescriber-level PA analytics.',
  prior_auth_request_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the prior authorization request record in the PillarRx lakehouse. Primary key for this entity.',
  prior_auth_rule_id BIGINT COMMENT 'Foreign key linking to division.prior_auth_rule. Business justification: Links a PA request to the specific PA rule that triggered it. Prior auth requests are evaluated against PA rules defined in the benefit group/formulary.',
  quantity_limit_unit STRING COMMENT 'Unit of measure for the quantity limit value (e.g., tablets, ml, days supply). Required to interpret the quantity_limit_value correctly.',
  quantity_limit_value DECIMAL(10,3) COMMENT 'Maximum quantity or days supply authorized per fill or period under the PA approval. Null if no quantity limit applies to this PA.',
  source_file_name STRING COMMENT 'Name of the source data file from which this PA record was loaded. Supports data lineage, audit trail, and ETL troubleshooting.',
  step_therapy_required BOOLEAN COMMENT 'Indicates whether the PA denial or criteria requires the member to try a preferred (step) drug before the requested drug will be authorized.',
  submission_date DATE COMMENT 'Calendar date the PA request was formally submitted to the PBM or plan. Used to calculate turnaround time and regulatory compliance.',
  submission_timestamp TIMESTAMP COMMENT 'Precise date and time the PA request was submitted. Supports SLA measurement and expedited PA regulatory turnaround tracking.',
  turnaround_hours DECIMAL(8,2) COMMENT 'Elapsed hours from PA submission to decision. Stored as a business-captured field from the PBM feed; not derived in this layer. Used for SLA and regulatory compliance.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this PA request record was last modified in the PillarRx lakehouse. Tracks status changes, appeal updates, and data corrections.',
  CONSTRAINT pk_prior_auth_request PRIMARY KEY (prior_auth_request_id)
)
COMMENT 'Transactional record capturing an individual prior authorization request submitted for a member and drug under a specific benefit group. Stores the requesting prescriber NPI, the target NDC, the clinical indication, the submission date, the PBM decision'
;

CREATE TABLE IF NOT EXISTS pillarrx.division.prior_auth_rule (
  age_max_years INT COMMENT 'Maximum member age in years for this rule to apply. Used for pediatric or geriatric-specific PA criteria. Null if no upper age restriction.',
  age_min_years INT COMMENT 'Minimum member age in years required for this rule to apply or for the drug to be approved without PA. Null if no age restriction.',
  appeals_allowed_indicator BOOLEAN COMMENT 'Indicates whether the member or prescriber may file a formal appeal if the PA request is denied under this rule. Required for ERISA plan compliance.',
  approval_duration_days INT COMMENT 'Number of days a PA approval remains valid once granted before re-authorization is required. Drives PA renewal workflow in the Prior Authorization Analytics module.',
  client_benefit_group_id BIGINT COMMENT 'Reference to the benefit group under which this PA or ST rule is enforced, scoping the rule to a specific employer plan benefit design.',
  clinical_criteria_summary STRING COMMENT 'Plain-language summary of the clinical criteria a member must meet to satisfy this PA or ST rule (e.g., ''Diagnosis of moderate-to-severe RA; trial of 2 DMARDs required'').',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM (e.g., CVS Caremark, Optum Rx, Express Scripts) that administers and enforces this prior authorization rule.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this prior authorization rule record was first created in the Pillarrx lakehouse. Used for audit trail and data lineage.',
  diagnosis_code_required STRING COMMENT 'ICD-10-CM diagnosis code that must be present on the PA request for approval. Comma-separated list if multiple qualifying diagnoses exist.',
  division_benefit_group_id BIGINT COMMENT 'FK to division.division_benefit_group.division_benefit_group_id — PA/ST rules are applied within a benefit group or formulary; benefit-group scoping is needed for UM compliance analysis.',
  division_formulary_id BIGINT COMMENT 'Reference to the formulary on which this rule is defined. A rule may be formulary-scoped rather than benefit-group-scoped when the PBM manages rules at the formulary level.',
  effective_date DATE COMMENT 'Date on which this prior authorization or utilization management rule becomes enforceable for claims adjudication.',
  formulary_tier STRING COMMENT 'Formulary cost-sharing tier to which the target drug belongs under this rule. Tier placement affects member cost share and PA applicability.',
  gender_restriction STRING COMMENT 'Gender restriction for this rule: M=Male only, F=Female only, U=No restriction (unrestricted). Applies to gender-specific clinical criteria.',
  limited_distribution_indicator BOOLEAN COMMENT 'Indicates whether the target drug is a limited distribution drug (LDD) available only through select specialty pharmacies, adding an additional access control layer.',
  notes STRING COMMENT 'Free-text field for consultant or analyst annotations regarding this rule, such as PBM-specific nuances, client exceptions, or audit findings.',
  override_allowed_indicator BOOLEAN COMMENT 'Indicates whether a pharmacist or prescriber override is permitted at point of sale without a formal PA approval (e.g., emergency supply override).',
  pbm_rule_reference_code STRING COMMENT 'Native identifier assigned by the PBM system to this rule in their adjudication platform. Used for cross-referencing during PBM audits and guarantee reconciliation.',
  prior_auth_rule_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the prior authorization or step therapy rule record in the Pillarrx lakehouse.',
  prior_version_rule_prior_auth_rule_id BIGINT COMMENT 'Self-referencing identifier pointing to the previous version of this rule record. Enables Type-2 slowly changing dimension history traversal for audit and trend analysis.',
  quantity_limit_days INT COMMENT 'Number of days in the measurement period for the quantity limit (e.g., 30 days, 90 days). Defines the rolling window for QL enforcement.',
  quantity_limit_unit STRING COMMENT 'Unit of measure for the quantity limit value (e.g., tablets, mL, units). Required when quantity_limit_value is populated. [ENUM-REF-CANDIDATE: tablets|capsules|mL|units|patches|vials|grams|mcg — promote to reference product]',
  quantity_limit_value DECIMAL(10,3) COMMENT 'Maximum dispensable quantity allowed per fill or per period under a quantity limit rule (e.g., 30 tablets per 30 days). Null for non-QL rule types.',
  renewal_required_indicator BOOLEAN COMMENT 'Indicates whether this PA rule requires periodic renewal after the initial approval duration expires, triggering re-evaluation of clinical criteria.',
  rule_code STRING COMMENT 'Externally-known alphanumeric code assigned by the PBM or plan to uniquely identify this PA/ST/QL rule within their system. Used for audit and reconciliation.',
  rule_name STRING COMMENT 'Human-readable name describing the prior authorization or utilization management rule (e.g., ''Humira PA Criteria'', ''Specialty Step Therapy - TNF Inhibitors'').',
  rule_status STRING COMMENT 'Current lifecycle state of the rule: active (enforced), inactive (suspended), pending (approved but not yet effective), retired (superseded or removed).',
  rule_type STRING COMMENT 'Classifies the utilization management rule: PA=Prior Authorization, ST=Step Therapy, QL=Quantity Limit, NF=Non-Formulary, SP=Specialty Designation. [ENUM-REF-CANDIDATE: PA|ST|QL|NF|SP|DAW — promote to reference product if additional types emerge]',
  rule_version STRING COMMENT 'Version number of this rule definition (e.g., ''1.0'', ''2.3''). Incremented when clinical criteria or parameters are updated. Supports Type-2 SCD history tracking.',
  specialty_drug_indicator BOOLEAN COMMENT 'Indicates whether this rule governs a specialty medication (SMN), which typically requires specialty pharmacy dispensing and enhanced clinical management.',
  step_sequence_number INT COMMENT 'Ordinal position of this drug in the step therapy ladder (1=first-line, 2=second-line, etc.). Null for PA and QL rules that are not step-based.',
  step_therapy_predecessor_name STRING COMMENT 'Brand or generic name of the step therapy predecessor drug. Denormalized for readability in PA analytics and consulting deliverables.',
  step_therapy_predecessor_ndc_code STRING COMMENT '11-digit NDC of the first-line drug that must be tried and failed before the target drug is approved under a step therapy rule. Null for non-ST rule types.',
  target_drug_name STRING COMMENT 'Brand or generic drug name associated with the target NDC or GPI. Denormalized for readability in reporting and consulting deliverables.',
  target_gpi STRING COMMENT '14-digit Medi-Span Generic Product Identifier representing the drug class or therapeutic group to which this rule applies when scoped above the NDC level.',
  target_ndc_code STRING COMMENT '11-digit FDA National Drug Code identifying the specific drug product to which this rule applies. Mutually exclusive with target_gpi when rule is NDC-level.',
  termination_date DATE COMMENT 'Date on which this rule ceases to be enforceable. Null indicates the rule is open-ended with no scheduled end date.',
  therapeutic_class_code STRING COMMENT 'Drug therapeutic class code (e.g., Medi-Span or FDB therapeutic class) identifying the clinical category of drugs governed by this rule.',
  therapeutic_class_name STRING COMMENT 'Human-readable name of the therapeutic drug class (e.g., ''TNF Inhibitors'', ''SGLT2 Inhibitors'') for reporting and consulting analysis.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp of the most recent modification to this prior authorization rule record. Used for change detection and incremental ETL processing.',
  CONSTRAINT pk_prior_auth_rule PRIMARY KEY (prior_auth_rule_id)
)
COMMENT 'Master record defining a prior authorization (PA) or step therapy (ST) rule applied within a benefit group or formulary. Captures the rule type (PA, ST, QL), the target NDC or GPI drug class, the clinical criteria summary, the step therapy predecessor'
;

CREATE TABLE IF NOT EXISTS pillarrx.division.rebate_contract (
  rebate_contract_id BIGINT NOT NULL COMMENT 'Primary key for rebate_contract',
  CONSTRAINT pk_rebate_contract PRIMARY KEY (rebate_contract_id)
)
COMMENT 'The rebate contract table in the division domain.'
;

CREATE TABLE IF NOT EXISTS pillarrx.division.rebate_payment (
  primary_rebate_contract_id BIGINT COMMENT 'Reference to program.rebate_contract.rebate_contract_id.',
  rebate_payment_id BIGINT NOT NULL COMMENT 'Primary key for rebate_payment',
  secondary_rebate_contract_id BIGINT COMMENT 'Reference to program.rebate_contract.rebate_contract_id.',
  CONSTRAINT pk_rebate_payment PRIMARY KEY (rebate_payment_id)
)
COMMENT 'The rebate payment table in the division domain.'
;

CREATE TABLE IF NOT EXISTS pillarrx.division.reconciliation_deliverable (
  actual_amount DECIMAL(18,2) COMMENT 'The actual dollar amount delivered by the PBM for the audit period as determined by PillarRx claims analysis. Compared against guaranteed_amount to compute variance.',
  audit_period_end_date DATE COMMENT 'End date of the claims or payment period covered by this reconciliation deliverable. Paired with audit_period_start_date to define the full audit window.',
  audit_period_start_date DATE COMMENT 'Start date of the claims or payment period covered by this reconciliation deliverable. Defines the scope of the PBM audit or rebate reconciliation window.',
  awp_discount_actual_pct DECIMAL(8,4) COMMENT 'Actual AWP discount percentage achieved by the PBM for the audit period as computed from normalized claims data. Compared against awp_discount_guaranteed_pct.',
  awp_discount_guaranteed_pct DECIMAL(8,4) COMMENT 'Contractually guaranteed AWP discount percentage for the audit period. Compared against awp_discount_actual_pct to identify brand or generic discount shortfalls.',
  claim_count_audited INT COMMENT 'Total number of pharmacy claims included in the audit scope for this reconciliation deliverable. Supports per-claim rate calculations and audit completeness validation.',
  client_name STRING COMMENT 'Name of the employer client for whom this deliverable was produced. Denormalized for reporting. Confidential as it identifies a specific consulting client relationship.',
  client_response_due_date DATE COMMENT 'Deadline by which the client must accept, dispute, or respond to the reconciliation deliverable findings. Drives consulting engagement SLA tracking.',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM (e.g., CVS Caremark, Optum Rx, Express Scripts) whose contract guarantees or rebate payments are subject to this reconciliation.',
  consulting_fee_id BIGINT COMMENT 'Reference to the consulting fee record associated with this deliverable for NetSuite/Brown & Brown Finance billing and GL reconciliation.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this reconciliation deliverable record was first created in the system. Used for audit trail and data lineage.',
  currency_code STRING COMMENT 'ISO 4217 three-letter currency code for all monetary amounts on this deliverable. Typically USD for PillarRx employer plan clients.',
  deliverable_engagement_fk BIGINT COMMENT 'FK to division.division_engagement.division_engagement_id — Every deliverable is produced under an engagement; required to close the accountability loop and attribute recovery amounts.',
  deliverable_number STRING COMMENT 'Externally-visible business identifier for this reconciliation deliverable, used in client communications, audit reports, and Salesforce CRM tracking.',
  deliverable_status STRING COMMENT 'Current workflow state of the reconciliation deliverable. [ENUM-REF-CANDIDATE: draft|in_review|pending_client|delivered|accepted|disputed|closed — promote to reference product]',
  deliverable_type STRING COMMENT 'Classification of the reconciliation deliverable by audit scope. [ENUM-REF-CANDIDATE: pbm_audit|rebate_reconciliation|guarantee_audit|spread_analysis|dir_reconciliation|combined — promote to reference product]',
  dispensing_fee_actual DECIMAL(10,4) COMMENT 'Actual average dispensing fee per claim billed by the PBM during the audit period. Compared against dispensing_fee_guaranteed to identify fee overcharges.',
  dispensing_fee_guaranteed DECIMAL(10,4) COMMENT 'Contractually guaranteed dispensing fee per claim for the audit period. Compared against actual dispensing fees billed by the PBM to identify overcharges.',
  dispute_amount DECIMAL(18,2) COMMENT 'Dollar amount formally disputed by the PBM or client in response to this reconciliation deliverable findings. Nullable when no dispute has been raised.',
  dispute_reason STRING COMMENT 'Free-text or coded explanation of the basis for the dispute raised against this reconciliation deliverable. Captured for audit trail and resolution tracking.',
  dispute_status STRING COMMENT 'Current status of any formal dispute raised against the PBM findings in this deliverable. Tracks dispute lifecycle from submission through resolution.',
  division_engagement_fk BIGINT COMMENT 'FK to division.division_engagement.division_engagement_id — Each client-facing deliverable is produced under a specific consulting engagement; closes the accountability loop.',
  employer_id BIGINT COMMENT 'Reference to the employer client for whom this reconciliation deliverable was produced within the Company > Division > Client hierarchy.',
  engagement_fk BIGINT COMMENT 'FK to division.division_engagement.division_engagement_id — Each deliverable is produced under a consulting engagement; FK closes the accountability loop.',
  engagement_id BIGINT COMMENT 'Reference to the division-level consulting engagement under which this reconciliation deliverable was produced.',
  guarantee_type STRING COMMENT 'Category of PBM contractual guarantee being reconciled. [ENUM-REF-CANDIDATE: awp_discount|dispensing_fee|rebate|mac|ger|ber|dir — promote to reference product]',
  guaranteed_amount DECIMAL(18,2) COMMENT 'The contractually guaranteed dollar amount the PBM committed to deliver for the audit period (e.g., guaranteed rebate total or guaranteed effective rate savings).',
  is_pass_through BOOLEAN COMMENT 'Indicates whether the PBM contract under audit operates on a pass-through (transparent) pricing model. Affects how spread and rebate reconciliation logic is applied.',
  issued_date DATE COMMENT 'The date on which the reconciliation deliverable was formally issued and transmitted to the client. Principal business event date for this transaction.',
  notes STRING COMMENT 'Free-text field for analyst notes, caveats, or contextual commentary on the reconciliation deliverable findings. Not used for structured data.',
  pbm_contract_id BIGINT COMMENT 'Reference to the PBM contract record whose guarantee terms are being audited in this reconciliation deliverable.',
  pbm_guarantee_result_id BIGINT COMMENT 'Reference to the primary PBM guarantee result record (discount, dispensing fee, or rebate guarantee) tied to this deliverable. Nullable when deliverable covers rebate-only reconciliation.',
  rebate_actual_pmpm DECIMAL(10,4) COMMENT 'Actual rebate amount on a per-member-per-month basis for the audit period as reconciled from PBM remittance data. Compared against rebate_guaranteed_pmpm.',
  rebate_guaranteed_pmpm DECIMAL(10,4) COMMENT 'Contractually guaranteed rebate amount on a per-member-per-month basis for the audit period. Key PBM performance benchmark metric.',
  rebate_payment_id BIGINT COMMENT 'Reference to the rebate payment record reconciled within this deliverable. Nullable when deliverable covers guarantee-only audit outcomes.',
  reconciliation_deliverable_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the reconciliation deliverable record. Primary key for this entity.',
  recovery_amount DECIMAL(18,2) COMMENT 'Dollar amount recovered or credited to the client as a result of this reconciliation deliverable. May be less than variance_amount if partially disputed or settled.',
  report_file_reference STRING COMMENT 'Path or URI to the reconciliation report document (PDF, Excel) stored in the document management system or data lakehouse. Enables direct access to the client-facing artifact.',
  resolution_date DATE COMMENT 'Date on which the reconciliation deliverable dispute or open finding was formally resolved between PillarRx, the client, and the PBM.',
  salesforce_opportunity_code STRING COMMENT 'Salesforce CRM opportunity or case identifier linked to this reconciliation deliverable for consulting engagement tracking and client relationship management.',
  total_drug_spend DECIMAL(18,2) COMMENT 'Aggregate plan drug spend across all claims in the audit scope for this deliverable. Used as the denominator for rebate-as-percent-of-spend and AWP discount calculations.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this reconciliation deliverable record was last modified. Supports change tracking and audit trail requirements.',
  variance_amount DECIMAL(18,2) COMMENT 'Dollar difference between guaranteed_amount and actual_amount (guaranteed minus actual). Positive value indicates a shortfall owed to the client by the PBM.',
  variance_pct DECIMAL(8,4) COMMENT 'Variance expressed as a percentage of the guaranteed amount. Enables benchmarking of PBM performance shortfalls across clients and audit periods.',
  CONSTRAINT pk_reconciliation_deliverable PRIMARY KEY (reconciliation_deliverable_id)
)
COMMENT 'Transactional record capturing a client-facing reconciliation/audit deliverable produced under a division_engagement, tying one or more pbm_guarantee_result and/or rebate_payment reconciliation outcomes to an accountable consulting output.'
;

-- ---------------------------------------------------------------------------
-- Schema: drug
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS pillarrx.drug.classification (
  ahfs_therapeutic_class_code STRING COMMENT 'AHFS pharmacologic-therapeutic classification code. Used as a supplemental classification standard in clinical drug utilization review (DUR) and formulary analysis.',
  biologic_flag BOOLEAN COMMENT 'Indicates whether the drug is a biologic product (large-molecule, derived from living organisms). Biologics are subject to distinct formulary management, biosimilar substitution policies, and rebate structures.',
  biosimilar_flag BOOLEAN COMMENT 'Indicates whether the drug is an FDA-approved biosimilar to a reference biologic. Supports biosimilar substitution analysis and step therapy (ST) protocol design for employer clients.',
  classification_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for each drug therapeutic classification record. Primary key for the classification data product.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this classification record was first created in the PillarRx data platform. Supports data lineage, audit trail, and SCD Type-2 history management for the drug classification dimension.',
  dea_schedule_code STRING COMMENT 'DEA controlled substance schedule (CI–CV) or NCS for non-controlled. Drives dispensing restrictions, days-supply limits, and prior authorization requirements in PBM benefit design analysis.',
  drug_340b_eligible_flag BOOLEAN COMMENT 'Indicates whether the drug is eligible for the federal 340B drug discount program. Used in 340B program management and manufacturer program analysis for covered entity clients.',
  effective_date DATE COMMENT 'Date on which this classification record became effective for the associated NDC. Supports Type-2 slowly changing dimension (SCD) history tracking for drug classification changes over time.',
  expiration_date DATE COMMENT 'Date on which this classification record expired or was superseded. NULL indicates the record is currently active. Supports Type-2 SCD history and point-in-time classification lookups for historical claim analysis.',
  fdb_therapeutic_class_code STRING COMMENT 'First DataBank therapeutic class code for the drug. Provides an alternative classification hierarchy to Medi-Span GPI, used for cross-source validation and FDB-sourced client reporting.',
  fdb_therapeutic_class_name STRING COMMENT 'Human-readable label for the FDB therapeutic class. Supports dual-source classification reporting where clients require FDB-aligned terminology.',
  formulary_tier_typical STRING COMMENT 'Typical formulary tier placement for this drug class/NDC based on standard PBM formulary structures. Used as a reference benchmark in formulary analysis and PBM contract consulting.',
  generic_indicator STRING COMMENT 'Indicates whether the drug is a brand, generic, brand-generic (authorized generic), or over-the-counter product. Core driver of Generic Dispensing Rate (GDR) calculations and formulary tier assignment.',
  gpi14 STRING COMMENT 'Wolters Kluwer Medi-Span 14-digit Generic Product Identifier. Encodes the full therapeutic hierarchy: drug group, class, subclass, name, name extension, dosage form, and strength.',
  gpi2_drug_group_code STRING COMMENT 'First 2 digits of the Medi-Span GPI representing the top-level drug group (e.g., cardiovascular, anti-infective). Used for high-level therapeutic spend aggregation.',
  gpi2_drug_group_name STRING COMMENT 'Human-readable label for the 2-digit Medi-Span GPI drug group (e.g., ''Cardiovascular Agents''). Used in consulting reports and benchmarking dashboards.',
  gpi4_drug_class_code STRING COMMENT 'First 4 digits of the Medi-Span GPI representing the drug class within the group (e.g., ACE inhibitors within cardiovascular). Supports mid-level therapeutic trend analysis.',
  gpi4_drug_class_name STRING COMMENT 'Human-readable label for the 4-digit Medi-Span GPI drug class (e.g., ''ACE Inhibitors''). Used in PBM audit and formulary tier analysis reports.',
  gpi6_drug_subclass_code STRING COMMENT 'First 6 digits of the Medi-Span GPI representing the drug subclass. Provides granular therapeutic segmentation for formulary analysis and rebate program identification.',
  gpi6_drug_subclass_name STRING COMMENT 'Human-readable label for the 6-digit Medi-Span GPI drug subclass. Used in specialty spend monitoring and therapeutic category benchmarking.',
  is_current BOOLEAN COMMENT 'Boolean flag indicating whether this is the currently active classification record for the NDC. Simplifies current-state queries in the Type-2 SCD drug classification dimension without requiring date range filtering.',
  limited_distribution_flag BOOLEAN COMMENT 'Indicates whether the drug is a Limited Distribution Drug (LDD) available only through select specialty pharmacies. Impacts network adequacy analysis and specialty pharmacy spend monitoring.',
  maintenance_drug_flag BOOLEAN COMMENT 'Indicates whether the drug is classified as a maintenance medication (chronic, long-term use). Used in mail-order incentive analysis and 90-day supply benefit design consulting.',
  multisource_code STRING COMMENT 'Medi-Span multisource code indicating generic availability: M=multisource (generic available), O=originator brand, N=no generic available, Y=generic product. Used in GDR auditing and MAC pricing applicability.',
  ndc11 STRING COMMENT 'The 11-digit National Drug Code uniquely identifying the drug product. Carried here for denormalized lookup convenience alongside the FK to the NDC master.',
  ndc_status STRING COMMENT 'Lifecycle status of this classification record for the associated NDC. Indicates whether the classification is currently active, inactive, discontinued, or pending validation.',
  orphan_drug_flag BOOLEAN COMMENT 'Indicates whether the drug has FDA orphan drug designation for rare disease treatment. Orphan drugs typically carry high costs and are relevant to specialty spend monitoring and affordability intelligence.',
  otc_flag BOOLEAN COMMENT 'Indicates whether the drug is available over-the-counter without a prescription. OTC drugs are typically excluded from PBM formulary coverage and require separate benefit design consideration.',
  prior_auth_typical_flag BOOLEAN COMMENT 'Indicates whether prior authorization (PA) is typically required for this drug class based on standard PBM formulary management practices. Used as a benchmark in PA analysis and benefit design consulting.',
  quantity_limit_typical_flag BOOLEAN COMMENT 'Indicates whether quantity limits (QL) are typically applied to this drug class in standard PBM formulary management. Used in benefit design analysis and PBM audit services.',
  rems_flag BOOLEAN COMMENT 'Indicates whether the drug has an FDA-mandated Risk Evaluation and Mitigation Strategy (REMS) program. REMS drugs require special dispensing controls and are relevant to specialty pharmacy network analysis.',
  rx_otc_indicator STRING COMMENT 'Medi-Span indicator for whether the drug requires a prescription (Rx), is available OTC, or has dual Rx/OTC status. Complements the OTC flag with the source-system coded value.',
  source_version STRING COMMENT 'Version or release identifier of the source drug reference file from which this classification was loaded (e.g., Medi-Span quarterly release label). Supports audit and reproducibility of historical analyses.',
  specialty_drug_flag BOOLEAN COMMENT 'Indicates whether the drug is classified as a specialty medication (SMN) requiring special handling, cold chain, or limited distribution. Key driver of specialty pharmacy spend monitoring and trend reporting.',
  step_therapy_typical_flag BOOLEAN COMMENT 'Indicates whether step therapy (ST) is typically required for this drug class. Used as a benchmark in step therapy protocol analysis and PBM formulary consulting for employer clients.',
  therapeutic_equivalent_code STRING COMMENT 'FDA Orange Book therapeutic equivalence code (e.g., AB, AA, BX). Indicates whether the drug has been evaluated and rated as therapeutically equivalent to a reference listed drug. Used in generic substitution and DAW code analysis.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this classification record was last updated in the PillarRx data platform. Used to detect classification changes from source drug reference feeds and trigger SCD Type-2 versioning.',
  CONSTRAINT pk_classification PRIMARY KEY (classification_id)
)
COMMENT 'Therapeutic and clinical classification attributes for each NDC, sourced from Medi-Span GPI and FDB therapeutic class hierarchies, maintained at the NDC grain and FK-linked to the ndc master.'
;

CREATE TABLE IF NOT EXISTS pillarrx.drug.drug_formulary (
  brand_drug_count INT COMMENT 'Number of brand-name drug products listed on this formulary. Used in formulary composition analysis and brand-versus-generic benchmarking for PBM audit engagements.',
  daw_policy STRING COMMENT 'The formulary-level policy governing how DAW codes are handled. Defines whether brand dispensing is allowed, penalized with higher cost-share, or whether generic substitution is mandated.',
  drug_count INT COMMENT 'Total number of National Drug Codes (NDCs) or drug products listed on this formulary at the time of the effective date. Supports formulary breadth benchmarking across PBMs.',
  drug_formulary_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for each formulary record in the PillarRx data lakehouse. Primary key for the drug_formulary dimension.',
  effective_date DATE COMMENT 'The date on which this formulary version becomes effective for adjudication and benefit administration. Supports Type-2 slowly changing dimension history tracking.',
  formulary_code STRING COMMENT 'Externally-known alphanumeric code assigned by the PBM or plan sponsor to uniquely identify this formulary (covered drug list). Used in claims routing and benefit configuration.',
  formulary_description STRING COMMENT 'Free-text description of the formulary, including its intended population, design philosophy, or notable features. Used in consulting deliverables and client-facing reporting.',
  formulary_name STRING COMMENT 'Human-readable name of the formulary as defined by the PBM or plan sponsor (e.g., ''Standard 4-Tier Formulary'', ''Specialty Preferred Formulary''). Used in reporting and client communications.',
  formulary_source STRING COMMENT 'The originating data source for this formulary record. Identifies whether the formulary was received via PBM claims feed, manually entered, provided by the client, or sourced from FDB or Medi-Span reference data.',
  formulary_status STRING COMMENT 'Current lifecycle state of the formulary. Active formularies are in use for adjudication; retired formularies are historical; pending formularies are approved but not yet effective.',
  formulary_type STRING COMMENT 'Classification of the formulary structure. Open formularies cover most drugs; closed formularies restrict to listed drugs only; incentive formularies apply differential cost-sharing to drive preferred drug use.',
  generic_drug_count INT COMMENT 'Number of generic drug products listed on this formulary. Used to calculate the Generic Dispensing Rate (GDR) potential and benchmark formulary generic utilization incentives.',
  generic_tier_label STRING COMMENT 'The label assigned to the generic drug tier in this formulary (e.g., ''Tier 1'', ''Generic''). Used in member communications, EOB displays, and formulary comparison reporting.',
  has_preventive_tier BOOLEAN COMMENT 'Indicates whether this formulary includes a zero-cost-share preventive drug tier as required under ACA Section 2713 for preventive care mandates.',
  has_specialty_tier BOOLEAN COMMENT 'Indicates whether this formulary includes a dedicated specialty drug tier. True when a specialty tier exists; False for formularies that do not separately classify specialty medications.',
  is_current_record BOOLEAN COMMENT 'Type-2 SCD flag indicating whether this row is the currently active version of the formulary record. True for the current version; False for historical versions superseded by a later update.',
  list_type STRING COMMENT 'Indicates whether this is a national PBM standard formulary, a custom formulary negotiated for a specific client, or a client-specific formulary. Drives consulting analysis segmentation.',
  loaded_timestamp TIMESTAMP COMMENT 'The timestamp when this formulary record was first loaded into the PillarRx data lakehouse Silver layer. Supports data freshness monitoring and ETL audit trail.',
  lob STRING COMMENT 'The line of business for which this formulary is designed. Determines applicable regulatory requirements (e.g., CMS Part D formulary rules for Medicare, ACA rules for exchange plans).',
  mail_order_supported BOOLEAN COMMENT 'Indicates whether this formulary supports mail-order pharmacy dispensing with differentiated cost-sharing. Mail order typically offers 90-day supply at reduced copay to encourage adherence.',
  non_preferred_brand_tier_label STRING COMMENT 'The label assigned to the non-preferred brand drug tier in this formulary (e.g., ''Tier 3'', ''Non-Preferred Brand''). Used in formulary benchmarking and member cost-share analysis.',
  pass_through_model BOOLEAN COMMENT 'Indicates whether this formulary operates under a pass-through (transparent) PBM pricing model where rebates and spread are passed directly to the plan sponsor rather than retained by the PBM.',
  pbm_name STRING COMMENT 'Name of the PBM that administers this formulary (e.g., CVS Caremark, Optum Rx, Express Scripts, Navitus, EmpiRx Health). Supports multi-PBM formulary benchmarking.',
  plan_year INT COMMENT 'The benefit plan year (e.g., 2024) to which this formulary applies. Formularies are typically updated annually; plan year scopes the formulary for trend and audit analysis.',
  preferred_brand_tier_label STRING COMMENT 'The label assigned to the preferred brand drug tier in this formulary (e.g., ''Tier 2'', ''Preferred Brand''). Supports formulary tier structure documentation and PBM audit.',
  primary_drug_division_formulary_id BIGINT COMMENT 'The PBM''s own internal identifier for this formulary as received in claims feeds or formulary files from CVS Caremark, Optum Rx, Express Scripts, Navitus, and other PBM partners.',
  prior_auth_required BOOLEAN COMMENT 'Indicates whether prior authorization (PA) utilization management is applied to any drugs on this formulary. True when PA programs are active; used in PA analysis and audit reporting.',
  quantity_limit_applied BOOLEAN COMMENT 'Indicates whether quantity limit (QL) utilization management controls are applied to any drugs on this formulary. Quantity limits cap the dispensed amount per fill or per period.',
  rebate_eligible BOOLEAN COMMENT 'Indicates whether drugs on this formulary are eligible for manufacturer rebate programs. Rebate eligibility is a key factor in PBM contract guarantee reconciliation and DIR analysis.',
  scd_end_date DATE COMMENT 'The date on which this Type-2 SCD row was superseded by a newer version. Null for the currently active record. Used with scd_start_date for point-in-time formulary history reconstruction.',
  scd_start_date DATE COMMENT 'The date on which this Type-2 SCD row became the active version in the data lakehouse. Used with scd_end_date to reconstruct point-in-time formulary snapshots for audit and trend analysis.',
  source_file_name STRING COMMENT 'Name of the source file or feed from which this formulary record was ingested (e.g., PBM formulary extract filename). Supports data lineage tracking and ETL audit within the lakehouse.',
  specialty_drug_count INT COMMENT 'Number of specialty medications (SMN) listed on this formulary. Specialty drug count is a key metric for specialty spend monitoring and copay assistance program (CAP) scoping.',
  specialty_pharmacy_required BOOLEAN COMMENT 'Indicates whether specialty medications on this formulary must be dispensed through a designated specialty pharmacy network. Relevant for limited distribution drug (LDD) management.',
  specialty_tier_label STRING COMMENT 'The label assigned to the specialty drug tier in this formulary (e.g., ''Tier 4'', ''Specialty''). Specialty tier tracking is critical for high-cost drug spend monitoring and CAP program management.',
  step_therapy_required BOOLEAN COMMENT 'Indicates whether step therapy (ST) utilization management protocols are applied to any drugs on this formulary. Step therapy requires trial of preferred drugs before coverage of non-preferred alternatives.',
  termination_date DATE COMMENT 'The date on which this formulary version is no longer effective. Null indicates the record is currently active. Used with effective_date to implement Type-2 SCD history.',
  tier_count INT COMMENT 'Total number of cost-sharing tiers defined in this formulary (e.g., 3-tier, 4-tier, 5-tier). Drives tier structure analysis and member cost-share benchmarking across PBMs.',
  updated_timestamp TIMESTAMP COMMENT 'The timestamp when this formulary record was last modified in the PillarRx data lakehouse. Used for change detection, SCD processing, and data quality monitoring.',
  version STRING COMMENT 'Version identifier for this formulary as assigned by the PBM or plan sponsor (e.g., ''v2024.1'', ''Q1-2024''). Supports tracking of mid-year formulary updates and change management.',
  CONSTRAINT pk_drug_formulary PRIMARY KEY (drug_formulary_id)
)
COMMENT 'Master record for each formulary (covered drug list) managed or analyzed by PillarRx on behalf of employer clients. A formulary is the PBM-administered list of covered drugs with associated tier structures and utilization management rules.'
;

CREATE TABLE IF NOT EXISTS pillarrx.drug.drug_formulary_tier (
  cap_eligible BOOLEAN COMMENT 'Indicates whether drugs on this tier are eligible for copay assistance program (CAP) enrollment via the PAX application. Drives CAP program management and manufacturer coupon reconciliation.',
  coinsurance_rate DECIMAL(5,4) COMMENT 'Member coinsurance percentage (stored as decimal, e.g., 0.20 = 20%) applied to drug cost at this tier when the benefit design uses percentage cost-share instead of flat copay.',
  company_pbm_id BIGINT COMMENT 'Foreign key linking to company.pbm. Business justification: Tier structures (copay amounts, coinsurance rates, PA requirements) vary by PBM. PillarRx compares tier definitions across PBMs for client benchmarking and contract negotiations.',
  copay_mail_90 DECIMAL(10,2) COMMENT 'Fixed member copay amount for a 90-day mail-order pharmacy fill at this tier. Mail-order cost-share is typically lower to incentivize channel migration.',
  copay_retail_30 DECIMAL(10,2) COMMENT 'Fixed member copay amount for a 30-day retail pharmacy fill at this tier. Represents the member''s flat-dollar cost-share obligation at point of sale.',
  copay_retail_90 DECIMAL(10,2) COMMENT 'Fixed member copay amount for a 90-day retail pharmacy fill at this tier. Supports extended-supply benefit design analysis and member OOP optimization.',
  cost_share_type STRING COMMENT 'Indicates the member cost-share mechanism for this tier: flat copay, percentage coinsurance, copay until deductible then coinsurance, or waived (e.g., preventive). Drives adjudication logic.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this formulary tier record was first created in the data platform. Supports audit trail and SCD history management.',
  deductible_applies BOOLEAN COMMENT 'Indicates whether the plan deductible must be satisfied before plan benefits apply for drugs on this tier. Critical for member OOP calculation and benefit design auditing.',
  division_formulary_id BIGINT COMMENT 'Reference to the parent formulary (covered drug list) to which this tier belongs. Links the tier to its sponsoring benefit plan formulary.',
  drug_formulary_id BIGINT COMMENT 'FK to drug.drug_formulary.drug_formulary_id — Tiers belong to a formulary (header->structure). Required for any tier benchmarking join.',
  drug_formulary_tier_formulary_fk BIGINT COMMENT 'FK to drug.drug_formulary.drug_formulary_id — Tier structure belongs to a parent formulary; FK required for formulary tier benchmarking.',
  drug_formulary_tier_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for a formulary tier record. Primary key for the drug_formulary_tier dimension supporting Type-2 slowly changing history.',
  effective_date DATE COMMENT 'Date on which this formulary tier definition becomes effective for benefit adjudication. Required for Type-2 SCD history tracking and plan year alignment.',
  formulary_source STRING COMMENT 'Identifies the originating data source for this formulary tier record (e.g., pbm_feed, manual, medi_span, fdb, client_upload). Supports data lineage and ETL audit traceability.',
  formulary_year INT COMMENT 'The benefit plan year (e.g., 2024) to which this formulary tier definition applies. Enables year-over-year formulary change analysis and trend reporting.',
  is_current BOOLEAN COMMENT 'Indicates whether this is the current active version of the formulary tier record (True) or a historical version (False). Standard Type-2 SCD current-row flag.',
  mail_order_allowed BOOLEAN COMMENT 'Indicates whether drugs on this tier are eligible for mail-order dispensing. Relevant for channel optimization analysis and member benefit communication.',
  max_copay DECIMAL(10,2) COMMENT 'Maximum member copay ceiling applied when coinsurance is used, capping the member''s cost-share per fill. Protects members from catastrophic per-fill costs on high-cost specialty drugs.',
  min_copay DECIMAL(10,2) COMMENT 'Minimum member copay floor applied when coinsurance is used, ensuring the member pays at least this amount per fill regardless of drug cost. Common in specialty tier designs.',
  oop_applies BOOLEAN COMMENT 'Indicates whether member cost-share at this tier accumulates toward the plan maximum out-of-pocket (MOOP). Relevant for CAP program management and affordability analysis.',
  preferred_network_only BOOLEAN COMMENT 'Indicates whether this tier''s cost-share applies only at preferred network pharmacies. Non-preferred pharmacy fills may incur higher cost-share or be excluded.',
  primary_drug_formulary_id BIGINT COMMENT 'FK to drug.drug_formulary.drug_formulary_id — tiers belong to a formulary; parent FK required for tier structure analysis.',
  prior_auth_required BOOLEAN COMMENT 'Indicates whether prior authorization (PA) is required for drugs placed on this tier. Supports PA analysis and PBM audit workflows.',
  quantity_limit_applies BOOLEAN COMMENT 'Indicates whether quantity limits (QL) are applied to drugs on this tier, restricting the dispensed quantity per fill or per period.',
  rebate_eligible BOOLEAN COMMENT 'Indicates whether drugs placed on this tier are eligible for manufacturer rebates. Supports PBM rebate guarantee auditing and DIR (Direct and Indirect Remuneration) analysis.',
  scd_version INT COMMENT 'Sequential version number for this formulary tier record under Type-2 SCD history management. Version 1 is the original record; increments with each change event.',
  specialty_pharmacy_required BOOLEAN COMMENT 'Indicates whether drugs on this tier must be dispensed through a designated specialty pharmacy. Supports limited distribution drug (LDD) and specialty spend monitoring.',
  specialty_tier BOOLEAN COMMENT 'Indicates whether this tier is designated as a specialty medication (SMN) tier, typically carrying the highest cost-share. Drives specialty pharmacy spend monitoring and reporting.',
  step_therapy_required BOOLEAN COMMENT 'Indicates whether step therapy (ST) protocols apply to drugs on this tier, requiring trial of lower-cost alternatives before coverage at this tier level.',
  termination_date DATE COMMENT 'Date on which this formulary tier definition expires or is superseded. NULL indicates the record is currently active. Required for Type-2 SCD history tracking.',
  tier_code STRING COMMENT 'Short alphanumeric code uniquely identifying the tier within a formulary (e.g., T1, T2, T3, T4, SPEC). Used as the operational key in claims adjudication and benefit configuration.',
  tier_description STRING COMMENT 'Free-text description of the formulary tier, including benefit design nuances, coverage conditions, or member-facing explanatory notes used in EOB and consulting deliverables.',
  tier_name STRING COMMENT 'Human-readable name for the formulary tier (e.g., Tier 1 Generic, Tier 2 Preferred Brand, Tier 3 Non-Preferred Brand, Tier 4 Specialty). Displayed in member EOBs and consulting reports.',
  tier_number INT COMMENT 'Numeric rank of the tier within the formulary (1 = lowest cost-share, ascending). Enables ordered reporting and cost-share comparison across tiers.',
  tier_status STRING COMMENT 'Current lifecycle status of the formulary tier record. Supports Type-2 SCD history management and controls whether the tier is available for claims adjudication.',
  tier_type STRING COMMENT 'Categorical classification of the tier by drug class or benefit design (e.g., generic, preferred_brand, non_preferred_brand, specialty, preventive, custom). Drives formulary analytics and benchmarking.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this formulary tier record was last modified in the data platform. Supports incremental ETL processing and SCD change detection.',
  CONSTRAINT pk_drug_formulary_tier PRIMARY KEY (drug_formulary_tier_id)
)
COMMENT 'Defines the cost-sharing tier structure within a formulary. Each tier represents a benefit level (e.g., Tier 1 Generic, Tier 2 Preferred Brand, Tier 3 Non-Preferred Brand, Tier 4 Specialty) with associated member cost-share parameters.'
;

CREATE TABLE IF NOT EXISTS pillarrx.drug.drug_prescriber (
  credential STRING COMMENT 'Professional credential or degree suffix of the prescribing provider (e.g., MD, DO, NP, PA-C, PharmD) as registered in NPPES. Indicates prescribing authority type.',
  dea_number STRING COMMENT 'DEA registration number authorizing the prescriber to prescribe controlled substances. Required for Schedule II-V drug prescriptions. Format: 2 letters + 7 digits.',
  deactivation_date DATE COMMENT 'Date the NPI was deactivated in NPPES (e.g., provider retired, deceased, or license revoked). Null if the NPI is currently active.',
  drug_prescriber_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the prescribing provider record in the PillarRx data lakehouse. Primary key for the drug_prescriber dimension.',
  effective_end_date DATE COMMENT 'Type-2 SCD history tracking column sourced from the authoritative external reference feed.',
  effective_start_date DATE COMMENT 'Type-2 SCD history tracking column sourced from the authoritative external reference feed.',
  entity_type_code STRING COMMENT 'NPPES entity type: 1 = Individual (person), 2 = Organization. Drug prescribers are typically type 1 (individual), but group practices may appear as type 2.',
  enumeration_date DATE COMMENT 'Date the NPI was assigned to the prescriber by NPPES. Indicates when the provider was first registered in the national provider registry.',
  erx_capable BOOLEAN COMMENT 'Indicates whether the prescriber is capable of transmitting electronic prescriptions (ERx). True = ERx enabled. Used in PBM workflow routing and compliance tracking.',
  first_name STRING COMMENT 'Legal first name (given name) of the prescribing provider as registered in NPPES. Used for display, search, and audit reporting.',
  gender STRING COMMENT 'Gender of the prescribing provider as registered in NPPES. M = Male, F = Female, U = Unknown/Not Provided. Used for demographic reporting.',
  group_practice_pac_code STRING COMMENT 'CMS Provider Associate-level Identifier (PAC ID) for the group practice or organization the prescriber is affiliated with. Links individual providers to group entities in CMS data.',
  individual_pac_code STRING COMMENT 'CMS Provider Associate-level Identifier (PAC ID) uniquely assigned to the individual prescriber across all CMS enrollment records. Supports cross-program provider linkage.',
  is_controlled_substance_authorized BOOLEAN COMMENT 'Indicates whether the prescriber holds a valid DEA registration authorizing controlled substance prescribing. True = DEA number on file and valid.',
  is_current BOOLEAN COMMENT 'Type-2 SCD history tracking column sourced from the authoritative external reference feed.',
  is_current_record BOOLEAN COMMENT 'Indicates whether this SCD Type-2 row is the current active version of the prescriber record. True = current. Simplifies queries that need only the latest prescriber attributes.',
  is_specialty_prescriber BOOLEAN COMMENT 'Indicates whether the prescriber is classified as a specialty prescriber based on taxonomy code mapping. True = specialty prescriber. Used for specialty drug spend segmentation.',
  last_name STRING COMMENT 'Legal last name (family name) of the prescribing provider as registered in NPPES. Used for display, search, and audit reporting.',
  last_update_date DATE COMMENT 'Date the prescribers NPPES record was last updated by the provider or CMS. Used to detect stale records and trigger refresh from the NPPES data feed.',
  license_state STRING COMMENT 'Two-letter US state abbreviation where the prescribers primary medical or prescribing license is issued. Used for cross-state prescribing compliance checks.',
  medicare_participation_indicator STRING COMMENT 'Indicates whether the prescriber accepts Medicare assignment (Y = participating, N = non-participating). Relevant for Medicare Part D claim analysis and member cost-share.',
  middle_name STRING COMMENT 'Middle name or initial of the prescribing provider as registered in NPPES. Supports full-name disambiguation when last and first names are identical.',
  name_prefix STRING COMMENT 'Honorific prefix for the prescribing provider (e.g., Dr., Prof.) as registered in NPPES. Used in formal correspondence and reporting displays.',
  npi STRING COMMENT '10-digit National Provider Identifier assigned by CMS via NPPES. Primary business key for the prescriber. Used to link prescriptions to the authoritative provider record.',
  npi_status STRING COMMENT 'Current status of the NPI in NPPES: active = valid and in use, deactivated = administratively deactivated, retired = provider no longer practicing.',
  organization_name STRING COMMENT 'Legal organization name for entity-type-2 (organizational) NPI records, or the practice/group name associated with an individual prescriber. Sourced from NPPES.',
  pecos_enrolled BOOLEAN COMMENT 'Indicates whether the prescriber is enrolled in the CMS Provider Enrollment, Chain, and Ownership System (PECOS). Required for Medicare Part D prescribing eligibility.',
  practice_address_line1 STRING COMMENT 'Primary street address line of the prescribers practice location as registered in NPPES. Used for geographic prescribing analysis and provider directory maintenance.',
  practice_address_line2 STRING COMMENT 'Secondary address line (suite, floor, unit) of the prescribers practice location as registered in NPPES. Supplements the primary address line.',
  practice_city STRING COMMENT 'City of the prescribers primary practice location as registered in NPPES. Used for geographic segmentation in prescribing trend and benchmarking reports.',
  practice_fax STRING COMMENT '10-digit fax number for the prescribers primary practice location. Used for electronic prescription routing and prior authorization document transmission.',
  practice_phone STRING COMMENT '10-digit phone number for the prescribers primary practice location as registered in NPPES. Used for provider outreach and prior authorization coordination.',
  practice_state STRING COMMENT 'Two-letter US state abbreviation of the prescribers primary practice location. Used for state-level prescribing analytics and cross-state dispensing compliance.',
  practice_zip STRING COMMENT '5- or 9-digit US postal ZIP code of the prescribers primary practice location. Supports geographic clustering and regional prescribing pattern analysis.',
  prescriber_type STRING COMMENT 'Broad classification of the prescribers professional role. Derived from taxonomy code. Used for prescribing authority analysis and PBM audit segmentation.',
  reactivation_date DATE COMMENT 'Date a previously deactivated NPI was reactivated in NPPES. Null if the NPI has never been deactivated or has not been reactivated.',
  record_created_timestamp TIMESTAMP COMMENT 'Timestamp when this prescriber record was first created in the PillarRx data lakehouse. Supports data lineage, audit trail, and SCD Type-2 history management.',
  record_updated_timestamp TIMESTAMP COMMENT 'Timestamp when this prescriber record was last modified in the PillarRx data lakehouse. Used for change detection, ETL delta processing, and audit trail.',
  scd_effective_end_date DATE COMMENT 'End date of the validity period for this Type-2 SCD record. Null indicates the current active version. Set when a new version supersedes this record.',
  scd_effective_start_date DATE COMMENT 'Start date of the validity period for this Type-2 SCD record. Indicates when this version of the prescriber record became effective in the PillarRx data lakehouse.',
  source_file_name STRING COMMENT 'Type-2 SCD history tracking column sourced from the authoritative external reference feed.',
  source_load_date DATE COMMENT 'Type-2 SCD history tracking column sourced from the authoritative external reference feed.',
  specialty_description STRING COMMENT 'Plain-language specialty description derived from taxonomy or PBM claim data (e.g., Oncology, Cardiology, Primary Care). Used for specialty drug spend segmentation.',
  state_license_number STRING COMMENT 'State-issued medical or prescribing license number for the provider. Used in PBM audit and compliance validation to confirm prescribing authority in the dispensing state.',
  taxonomy_code STRING COMMENT 'NUCC Health Care Provider Taxonomy code identifying the prescribers specialty and classification (e.g., 207R00000X = Internal Medicine). Primary taxonomy from NPPES.',
  taxonomy_description STRING COMMENT 'Human-readable description of the NUCC taxonomy code (e.g., Internal Medicine, Family Practice, Nurse Practitioner). Used in specialty-level prescribing analytics.',
  CONSTRAINT pk_drug_prescriber PRIMARY KEY (drug_prescriber_id)
)
COMMENT 'Derived Silver-layer prescriber table. JOINs to the authoritative external reference tables reference.nppes_provider and reference.nucc_taxonomy which hold the source-of-truth external provider records; this table itself is a derived join product, not the authoritative source.'
;

CREATE TABLE IF NOT EXISTS pillarrx.drug.equivalence (
  awp_savings_pct DECIMAL(7,4) COMMENT 'Estimated percentage cost savings when substituting the source NDC with the equivalent NDC, calculated from AWP unit prices at time of crosswalk creation. Used in savings opportunity reporting.',
  biosimilar_interchangeable BOOLEAN COMMENT 'Indicates whether the equivalent NDC is an FDA-designated interchangeable biosimilar to the source biologic. Interchangeable biosimilars may be substituted without prescriber intervention.',
  cap_substitution_flag BOOLEAN COMMENT 'Indicates whether this equivalence pair is relevant to copay assistance program (CAP) substitution logic in the PAX application. Flags pairs where a brand-to-generic switch may affect CAP eligibility.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this equivalence crosswalk record was first created in the PillarRx lakehouse. Supports audit trail and data governance requirements.',
  dosage_form_match BOOLEAN COMMENT 'Indicates whether the source and equivalent NDCs share the same dosage form (e.g., tablet, capsule, solution). A mismatch may restrict substitution eligibility under state pharmacy law.',
  effective_date DATE COMMENT 'The date on which this equivalence crosswalk relationship became effective. Used in time-bounded formulary analysis and historical claims auditing to apply the correct equivalence at date of service.',
  equivalence_id BIGINT NOT NULL COMMENT 'Unique surrogate primary key for each NDC-to-GPI therapeutic equivalence and generic substitution crosswalk record.',
  equivalence_status STRING COMMENT 'Current lifecycle status of this equivalence crosswalk record. Active records are used in live formulary and claims analysis; superseded records are retained for historical audit.',
  equivalence_type STRING COMMENT 'Classifies the nature of the equivalence relationship. Drives substitution logic in formulary analysis, generic dispensing rate (GDR) calculations, and copay assistance program (CAP) eligibility.',
  equivalent_drug_name STRING COMMENT 'Human-readable drug name for the equivalent NDC as sourced from Medi-Span or FDB. Supports analyst readability and reporting without requiring a join to the NDC dimension.',
  equivalent_generic_indicator STRING COMMENT 'Indicates whether the equivalent NDC is a brand, generic, or branded generic product. Confirms the substitution direction (e.g., brand-to-generic) for GDR and savings opportunity reporting.',
  equivalent_gpi14 STRING COMMENT 'The 14-digit GPI code of the equivalent NDC. Enables GPI-level therapeutic grouping and substitution logic independent of specific NDC packaging variants.',
  equivalent_multisource_code STRING COMMENT 'Medi-Span multisource code for the equivalent NDC. Confirms the equivalent is a true generic (Y) or multisource brand (M) for substitution and GDR reporting purposes.',
  equivalent_ndc11 STRING COMMENT 'The 11-digit NDC of the therapeutically equivalent or generic substitute drug. Represents the target side of the substitution crosswalk used in formulary analysis and claims auditing.',
  expiration_date DATE COMMENT 'The date on which this equivalence crosswalk relationship expires or was superseded. Null indicates an open-ended active relationship. Supports Type-2 SCD history for the drug dimension.',
  formulary_substitution_flag BOOLEAN COMMENT 'Indicates whether this equivalence pair is actively used in formulary-level substitution recommendations for PillarRx client plan analysis. Distinguishes reference data from operationally applied substitutions.',
  gpi10_match BOOLEAN COMMENT 'Indicates whether the source and equivalent NDCs share the same 10-digit GPI prefix, confirming same drug, strength, and dosage form. Used to validate the precision of the equivalence relationship.',
  gpi12_match BOOLEAN COMMENT 'Indicates whether the source and equivalent NDCs share the same 12-digit GPI prefix, confirming same drug, strength, dosage form, and route. Provides finer equivalence precision than GPI10.',
  is_current BOOLEAN COMMENT 'Indicates whether this is the current active version of the equivalence crosswalk record. Supports Type-2 slowly changing dimension (SCD) pattern for the drug equivalence history table.',
  ldd_flag BOOLEAN COMMENT 'Indicates whether the source or equivalent NDC is a limited distribution drug (LDD), restricting dispensing to select specialty pharmacies. LDD status may prevent substitution in standard retail networks.',
  orange_book_code STRING COMMENT 'FDA Orange Book therapeutic equivalence evaluation code (e.g., AB, AA, BX) for the equivalent NDC relative to the source. AB-rated products are considered therapeutically equivalent and substitutable.',
  reference_source STRING COMMENT 'The authoritative external data source from which this equivalence relationship was derived. Medi-Span and FDB are primary sources; Orange Book is used for FDA therapeutic equivalence codes.',
  reference_source_version STRING COMMENT 'Version or release identifier of the external reference source file from which this equivalence record was loaded. Supports data lineage, audit, and refresh cycle tracking.',
  route_match BOOLEAN COMMENT 'Indicates whether the source and equivalent NDCs share the same route of administration (e.g., oral, injectable). Route mismatches typically disqualify automatic substitution.',
  source_drug_name STRING COMMENT 'Human-readable drug name for the source NDC as sourced from Medi-Span or FDB. Supports analyst readability and reporting without requiring a join to the NDC dimension.',
  source_generic_indicator STRING COMMENT 'Indicates whether the source NDC is a brand, generic, or branded generic product. Used in generic dispensing rate (GDR) analysis and substitution opportunity identification.',
  source_gpi14 STRING COMMENT 'The 14-digit GPI code of the source NDC, representing its full therapeutic classification hierarchy from Medi-Span. Used to group drugs by therapeutic equivalence class.',
  source_load_date DATE COMMENT 'The date on which the source reference file (Medi-Span or FDB) containing this equivalence record was loaded into the PillarRx lakehouse. Supports data lineage and refresh cycle auditing.',
  source_multisource_code STRING COMMENT 'Medi-Span multisource code for the source NDC. M=multisource brand, O=originator brand, N=single-source brand, Y=generic. Drives substitution eligibility logic.',
  specialty_substitution_flag BOOLEAN COMMENT 'Indicates whether either the source or equivalent NDC is classified as a specialty medication (SMN). Specialty substitutions require additional clinical and formulary review before application.',
  strength_match BOOLEAN COMMENT 'Indicates whether the source and equivalent NDCs have the same drug strength. Strength mismatches require prescriber authorization before substitution and affect DAW code compliance.',
  substitution_allowed BOOLEAN COMMENT 'Indicates whether the equivalent NDC is permitted as a generic substitute for the source NDC under applicable state pharmacy law and formulary policy. Core flag for DAW code analysis.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this equivalence crosswalk record was last modified in the PillarRx lakehouse. Used to detect stale records and trigger downstream refresh in formulary and claims analysis pipelines.',
  CONSTRAINT pk_equivalence PRIMARY KEY (equivalence_id)
)
COMMENT 'NDC-to-GPI therapeutic-equivalence and generic-substitution crosswalk. This product is the SSOT for SUBSTITUTION/INTERCHANGE semantics (not clinical classification — see classification).'
;

CREATE TABLE IF NOT EXISTS pillarrx.drug.formulary_drug (
  age_restriction_max INT COMMENT 'Maximum member age (in years) for formulary coverage of this drug. Null indicates no maximum age restriction. Used in pediatric or geriatric formulary management.',
  age_restriction_min INT COMMENT 'Minimum member age (in years) required for formulary coverage of this drug. Null indicates no minimum age restriction. Used in utilization management and PA criteria.',
  assigned_drug_formulary_tier_id BIGINT COMMENT 'FK to drug.drug_formulary_tier.drug_formulary_tier_id — The association entity assigns an NDC/GPI to a tier within a formulary; FK to tier is mandatory for coverage and tier-placement analysis.',
  coinsurance_rate DECIMAL(5,4) COMMENT 'Member coinsurance percentage applied to this drug''s cost at the assigned tier, expressed as a decimal (e.g., 0.20 = 20%). Used when benefit design uses percentage cost-sharing.',
  copay_amount DECIMAL(10,2) COMMENT 'Fixed member copay dollar amount for this drug at the assigned formulary tier. Represents the member''s out-of-pocket cost share per fill under the plan benefit design.',
  coverage_level STRING COMMENT 'Indicates whether formulary coverage is applied at the specific NDC level, the GPI drug class level, or a broader GPI group. Determines how claims are matched to this formulary entry.',
  deductible_applies BOOLEAN COMMENT 'Indicates whether the plan deductible must be satisfied before cost-sharing applies for this drug. Relevant for high-deductible health plan (HDHP) benefit designs.',
  dosage_form STRING COMMENT 'Physical form of the drug product (e.g., tablet, capsule, solution, injection). Sourced from Medi-Span or FDB. Relevant for formulary management and specialty drug identification.',
  drug_prescriber_id BIGINT COMMENT 'FK to drug.drug_prescriber.drug_prescriber_id — auto-injected by v1.1.0 silo-last-resort-inbound-fk-injection to break silo on drug.drug_prescriber',
  drug_strength STRING COMMENT 'Strength of the drug product as listed on the formulary (e.g., ''10mg'', ''500mg/5mL''). Sourced from Medi-Span or FDB drug reference data.',
  effective_date DATE COMMENT 'Date on which this drug''s formulary placement becomes effective. Supports Type-2 slowly changing dimension history and point-in-time formulary lookups for claims adjudication.',
  formulary_alternative_available BOOLEAN COMMENT 'Indicates whether a preferred formulary alternative exists for this drug. Used in member communications and PBM audit analysis to identify substitution opportunities.',
  formulary_drug_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the formulary drug association record. Primary key for the formulary_drug entity.',
  formulary_drug_name STRING COMMENT 'Drug name as it appears on the formulary (may be brand or generic name). Used in member-facing formulary lookups, EOB communications, and consulting reports.',
  formulary_note STRING COMMENT 'Free-text note or clinical criteria associated with this drug''s formulary placement. May include PA criteria summaries, step therapy requirements, or coverage conditions.',
  formulary_status STRING COMMENT 'Coverage status of the drug on the formulary. Indicates whether the drug is covered, excluded, or subject to utilization management restrictions. [ENUM-REF-CANDIDATE',
  formulary_version STRING COMMENT 'Version identifier of the formulary in which this drug placement was defined. Used to track formulary changes across plan years and support PBM contract audit comparisons.',
  gender_restriction STRING COMMENT 'Gender restriction for formulary coverage of this drug (M=Male only, F=Female only, none=no restriction). Used in utilization management and formulary audit validation.',
  generic_indicator STRING COMMENT 'Classifies the drug as brand, generic, biosimilar, or branded generic. Sourced from Medi-Span or FDB drug reference. Drives Generic Dispensing Rate (GDR) analytics.',
  gpi STRING COMMENT '14-digit Medi-Span Generic Product Identifier classifying the drug at the therapeutic class and ingredient level. Used for formulary grouping when coverage applies at the GPI level rather than specific NDC.',
  is_current BOOLEAN COMMENT 'Type-2 SCD current record indicator. True when this row represents the active formulary drug placement. False for historical rows superseded by a newer version.',
  limited_distribution BOOLEAN COMMENT 'Indicates whether this drug is a Limited Distribution Drug (LDD), available only through select specialty pharmacies designated by the manufacturer.',
  mail_order_coinsurance_rate DECIMAL(5,4) COMMENT 'Member coinsurance percentage for this drug when dispensed via mail order, expressed as a decimal. Applies when the benefit design uses percentage cost-sharing for mail channel.',
  mail_order_copay_amount DECIMAL(10,2) COMMENT 'Fixed member copay dollar amount for this drug when dispensed via mail order pharmacy. Typically lower than retail copay to incentivize mail order utilization.',
  oop_exempt BOOLEAN COMMENT 'Indicates whether member cost-sharing for this drug is excluded from accumulation toward the plan''s Maximum Out-of-Pocket (MOOP). Relevant for preventive drug exemptions.',
  plan_year INT COMMENT 'Calendar or benefit plan year (e.g., 2024) to which this formulary drug placement applies. Used for year-over-year formulary change analysis and client reporting.',
  preferred_alternative_ndc_code STRING COMMENT 'NDC of the preferred formulary alternative drug when formulary_alternative_available is true. Supports member cost-saving recommendations and PBM audit reporting.',
  primary_drug_formulary_id BIGINT COMMENT 'Reference to the parent formulary to which this drug entry belongs. Links the drug placement to a specific plan formulary.',
  primary_drug_formulary_tier_id BIGINT COMMENT 'Reference to the formulary tier (e.g., Tier 1 Generic, Tier 2 Preferred Brand) assigned to this drug within the formulary.',
  prior_auth_required BOOLEAN COMMENT 'Indicates whether a Prior Authorization (PA) is required before the plan will cover this drug. True triggers PA workflow at point of dispensing.',
  quantity_limit_amount DECIMAL(10,3) COMMENT 'Maximum quantity allowed per fill or per defined period when a Quantity Limit applies. Expressed in the drug''s dispensing unit (e.g., tablets, mL).',
  quantity_limit_days INT COMMENT 'Number of days supply over which the quantity limit applies. Used in conjunction with quantity_limit_amount to define the full QL restriction (e.g., 30 tablets per 30 days).',
  quantity_limit_required BOOLEAN COMMENT 'Indicates whether a Quantity Limit (QL) restriction applies to this drug on the formulary, capping the dispensable quantity per fill or per period.',
  rebate_eligible BOOLEAN COMMENT 'Indicates whether this formulary drug placement is eligible for manufacturer rebates. Used in PBM rebate guarantee auditing and DIR (Direct and Indirect Remuneration) analysis.',
  source_formulary_code STRING COMMENT 'Formulary identifier as provided by the originating PBM source system (e.g., CVS Caremark, Optum Rx, Express Scripts). Used for PBM audit reconciliation and cross-PBM formulary comparison.',
  source_pbm STRING COMMENT 'Name of the PBM that provided this formulary data (e.g., CVS Caremark, Optum Rx, Express Scripts). Supports multi-PBM formulary benchmarking and audit workflows.',
  specialty_drug BOOLEAN COMMENT 'Indicates whether this drug is classified as a specialty medication (SMN) on the formulary, typically requiring specialty pharmacy dispensing and additional management.',
  step_therapy_required BOOLEAN COMMENT 'Indicates whether Step Therapy (ST) applies, requiring the member to try a preferred drug before coverage of this drug is approved.',
  step_therapy_step_number INT COMMENT 'Numeric step in the Step Therapy (ST) protocol at which this drug is positioned (e.g., 1=first-line, 2=second-line). Null when step_therapy_required is false.',
  termination_date DATE COMMENT 'Date on which this drug''s formulary placement ends. Null indicates the record is currently active. Supports Type-2 SCD history for point-in-time formulary analysis.',
  therapeutic_class_code STRING COMMENT 'GPI-based therapeutic class code from Medi-Span classifying the drug by its pharmacological action and clinical use. Used for formulary tier grouping and trend analysis.',
  therapeutic_class_name STRING COMMENT 'Human-readable name of the therapeutic class corresponding to the therapeutic_class_code. Used in formulary reporting, benchmarking, and consulting deliverables.',
  tier_label STRING COMMENT 'Human-readable label for the formulary tier (e.g., ''Tier 1 - Generic'', ''Tier 2 - Preferred Brand'', ''Specialty''). Used in member-facing communications and reporting.',
  tier_number INT COMMENT 'Numeric tier level assigned to this drug on the formulary (e.g., 1=Generic, 2=Preferred Brand, 3=Non-Preferred Brand). Drives member cost-sharing calculations.',
  CONSTRAINT pk_formulary_drug PRIMARY KEY (formulary_drug_id)
)
COMMENT 'Association entity linking a specific NDC (or GPI drug group) to a formulary tier within a formulary, representing the covered drug list at the drug-formulary-tier grain. FK-linked to drug_formulary, drug_formulary_tier, and the ndc master.'
;

CREATE TABLE IF NOT EXISTS pillarrx.drug.mac_list (
  appeal_process_available BOOLEAN COMMENT 'Indicates whether pharmacies can appeal MAC prices on this list. State PBM transparency laws increasingly mandate MAC appeal rights; this flag supports compliance tracking.',
  appeal_turnaround_days INT COMMENT 'Maximum number of calendar days within which the PBM must respond to a MAC appeal from a pharmacy. Mandated by state PBM transparency laws in many states.',
  awp_discount_basis BOOLEAN COMMENT 'Indicates whether MAC prices on this list are expressed as a discount off AWP rather than as absolute per-unit prices. When true, the AWP discount percentage is the operative pricing mechanism.',
  client_specific BOOLEAN COMMENT 'Indicates whether this MAC list is negotiated specifically for a single employer client rather than applied across the PBM''s full network. Client-specific lists may offer better pricing.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this MAC list record was first created in the Pillarrx data lakehouse. Supports audit trail and data governance.',
  currency_code STRING COMMENT 'ISO 4217 three-letter currency code for all MAC prices on this list (e.g., USD). Supports multi-currency readiness for international plan sponsors.',
  dir_applicable BOOLEAN COMMENT 'Indicates whether Direct and Indirect Remuneration (DIR) fees apply to pharmacy reimbursements under this MAC list. Relevant for Medicare Part D plan sponsors and PBM audit.',
  drug_count INT COMMENT 'Total number of distinct NDCs or drug products included on this MAC list at the time of the current version. Used for benchmarking list breadth across PBMs.',
  drug_scope STRING COMMENT 'Defines which drug categories are covered by this MAC list. Most MAC lists apply to multi-source generic drugs; some PBMs extend MAC pricing to specialty or brand drugs.',
  effective_date DATE COMMENT 'The date on which this MAC list becomes effective for claims adjudication and pharmacy reimbursement. Defines the start of the binding pricing period.',
  formulary_linked BOOLEAN COMMENT 'Indicates whether this MAC list is tied to a specific formulary. Formulary-linked MAC lists restrict MAC pricing to drugs on the associated formulary tier structure.',
  is_current BOOLEAN COMMENT 'Boolean flag indicating whether this SCD Type-2 record is the current active version of the MAC list. True for the latest version; false for historical versions. Simplifies current-record queries.',
  list_code STRING COMMENT 'Externally-known alphanumeric code that uniquely identifies this MAC list within the PBM or plan sponsor system. Used for cross-referencing in claims adjudication and audit.',
  list_name STRING COMMENT 'Human-readable name of the MAC list (e.g., ''CVS Caremark Generic MAC Q1 2024''). Used in reporting, audit deliverables, and consulting benchmarking.',
  list_status STRING COMMENT 'Current lifecycle status of the MAC list. Active lists are in use for claims adjudication. Superseded lists have been replaced by a newer version. Used to filter current vs. historical lists.',
  list_type STRING COMMENT 'Categorizes the origin and governance of the MAC list. PBM-published lists are issued by the PBM; custom lists are negotiated for specific clients; state/federal MAC lists are regulatory.',
  mac_list_description STRING COMMENT 'Free-text description of the MAC list''s purpose, scope, or special conditions. Used by consulting analysts and auditors to understand the context of the list.',
  mac_list_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the MAC list record in the Pillarrx data lakehouse. Primary key for the mac_list product.',
  network_scope STRING COMMENT 'Identifies the dispensing channel(s) to which this MAC list applies: retail pharmacy network, mail-order, specialty pharmacy, or all channels. Drives reimbursement logic in claims adjudication.',
  notes STRING COMMENT 'Operational notes or annotations added by Pillarrx analysts regarding this MAC list, such as known anomalies, audit findings, or PBM communication records.',
  pass_through_indicator BOOLEAN COMMENT 'Indicates whether this MAC list is used under a pass-through (transparent) PBM pricing model where the plan pays actual pharmacy cost. Relevant for PBM contract audit and spread analysis.',
  pbm_list_id_external STRING COMMENT 'The PBM''s own internal identifier for this MAC list as received in claims feeds or contract documents. Preserved for reconciliation and audit traceability back to the source PBM system.',
  plan_year INT COMMENT 'The benefit plan year (e.g., 2024) to which this MAC list is associated. Used for annual benchmarking, trend analysis, and PBM contract guarantee reconciliation.',
  pricing_basis STRING COMMENT 'Defines the unit of measure for MAC prices on this list: per dispensing unit (tablet, capsule, ml), per package, or per claim. Critical for correct reimbursement calculation and audit.',
  reference_source STRING COMMENT 'The external drug pricing reference used to derive MAC prices on this list (e.g., Medi-Span, First DataBank, NADAC, or PBM proprietary). Affects audit methodology and price benchmarking.',
  scd_effective_date DATE COMMENT 'Start date of the current SCD Type-2 record version for this MAC list. Enables point-in-time historical queries for audit and benchmarking across plan years.',
  scd_expiration_date DATE COMMENT 'End date of the current SCD Type-2 record version. Set to a high-date (9999-12-31) for the current active record. Null or high-date indicates the record is the current version.',
  source_file_name STRING COMMENT 'Name of the source file or feed from which this MAC list record was loaded into the lakehouse. Supports data lineage, ETL audit, and issue investigation.',
  source_load_date DATE COMMENT 'The date on which this MAC list record was loaded from the source PBM or reference system into the Pillarrx data lakehouse. Used for data freshness monitoring and ETL audit.',
  source_pbm STRING COMMENT 'The PBM that published or administers this MAC list. Identifies the originating PBM for multi-PBM benchmarking and audit. [ENUM-REF-CANDIDATE: CVS Caremark|Optum Rx|Express Scripts|Navitus|EmpiRx Health|BCBS Michigan|Rightway|Prime',
  spread_applicable BOOLEAN COMMENT 'Indicates whether the PBM retains spread (difference between plan-paid MAC and pharmacy reimbursement) on claims adjudicated under this list. Key metric for PBM audit and contract transparency.',
  state_mandate_code STRING COMMENT 'Two-letter US state code if this MAC list was created or modified to comply with a specific state PBM transparency or MAC appeal law. Null if no state mandate applies.',
  termination_date DATE COMMENT 'The date on which this MAC list expires or is superseded. Null indicates an open-ended list currently in force. Used for SCD Type-2 history and audit period scoping.',
  update_frequency STRING COMMENT 'How frequently the PBM or plan sponsor updates this MAC list. Relevant for PBM audit and contract guarantee monitoring; more frequent updates may indicate aggressive MAC repricing.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this MAC list record was last modified in the Pillarrx data lakehouse. Used for change detection, incremental ETL processing, and audit.',
  version_number STRING COMMENT 'Version identifier for this MAC list, used to distinguish successive updates from the same PBM or plan sponsor. Supports audit trail and change-over-time analysis.',
  CONSTRAINT pk_mac_list PRIMARY KEY (mac_list_id)
)
COMMENT 'Master record for each Maximum Allowable Cost (MAC) list referenced by PBM networks and pharmacy reimbursement. A MAC list is a PBM-published or custom pricing list that sets the maximum per-unit reimbursement for multi-source generic drugs.'
;

CREATE TABLE IF NOT EXISTS pillarrx.drug.mac_pricing (
  appeal_status STRING COMMENT 'Current status of any pharmacy appeal of this MAC price. State PBM transparency laws require appeal processes for MAC prices below pharmacy acquisition cost.',
  awp_discount_percentage DECIMAL(5,2) COMMENT 'If this MAC price is expressed as a discount off AWP, this field captures the discount percentage (e.g., 80.00 for AWP-20%). Null if MAC is not AWP-based.',
  effective_date DATE COMMENT 'The date on which this MAC price becomes effective for this NDC on this MAC list. Critical for point-in-time pricing analysis and PBM audit.',
  expiration_date DATE COMMENT 'The date on which this MAC price expires or is superseded by a new price. Null indicates the price is currently active. Enables historical price tracking.',
  is_current BOOLEAN COMMENT 'Boolean flag indicating whether this is the current active MAC price for this NDC on this MAC list. Supports Type-2 SCD historical tracking.',
  mac_list_id BIGINT COMMENT 'Foreign key linking to the MAC list that contains this NDC pricing',
  mac_price DECIMAL(12,4) COMMENT 'The Maximum Allowable Cost price for this NDC on this MAC list, expressed per unit defined by pricing_basis. This is the maximum reimbursement amount the PBM will pay pharmacies for this drug.',
  mac_pricing_id BIGINT NOT NULL COMMENT 'Surrogate primary key for this MAC pricing record. Supports historical tracking of price changes for the same NDC-MAC list combination.',
  pharmacy_acquisition_cost DECIMAL(12,4) COMMENT 'The estimated pharmacy acquisition cost for this NDC at the time this MAC price was set. Used to identify below-cost MAC pricing that may trigger pharmacy appeals.',
  price_source STRING COMMENT 'The external drug pricing reference used to derive this MAC price (e.g., Medi-Span, FDB, NADAC, AMP). Used for PBM audit and pricing methodology validation.',
  pricing_basis STRING COMMENT 'Defines the unit of measure for this MAC price: per dispensing unit (tablet, capsule), per package, per mL, or per gram. Required to correctly apply MAC pricing to claims.',
  scd_effective_date DATE COMMENT 'Start date of the current SCD Type-2 record version for this MAC pricing entry. Enables point-in-time historical queries.',
  scd_expiration_date DATE COMMENT 'End date of the current SCD Type-2 record version. Set to a high-date (9999-12-31) for the current active version.',
  update_frequency STRING COMMENT 'How frequently the PBM updates the MAC price for this NDC on this list. Relevant for PBM audit and price volatility analysis.',
  CONSTRAINT pk_mac_pricing PRIMARY KEY (mac_pricing_id)
)
COMMENT 'This association product represents the pricing relationship between an NDC and a MAC list. It captures the Maximum Allowable Cost price for a specific drug on a specific PBM MAC list, including effective dates, pricing basis, and appeal status.'
;

CREATE TABLE IF NOT EXISTS pillarrx.drug.manufacturer (
  biosimilar_manufacturer_flag BOOLEAN COMMENT 'Indicates whether the manufacturer produces FDA-approved biosimilar products. Supports biosimilar substitution analysis, formulary tier strategy, and rebate benchmarking for employer clients.',
  cap_program_name STRING COMMENT 'Name of the manufacturer''s copay assistance program (CAP) as tracked in the PAX application. Used for program identification in member assistance ledger and manufacturer coupon reconciliation.',
  cap_program_url STRING COMMENT 'Web address for the manufacturer''s copay assistance program enrollment or information portal. Used by PillarRx consultants and members to access CAP enrollment resources.',
  controlled_substance_manufacturer_flag BOOLEAN COMMENT 'Indicates whether the manufacturer produces DEA-scheduled controlled substances. Supports drug utilization review (DUR) analysis and regulatory compliance monitoring for employer plan clients.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this manufacturer record was first created in the PillarRx enterprise data platform. Supports data lineage, audit trail, and record governance.',
  duns_number STRING COMMENT 'Dun & Bradstreet 9-digit DUNS number uniquely identifying the manufacturer as a business entity. Used for cross-referencing manufacturer identity in rebate contracts and consulting engagements.',
  effective_end_date DATE COMMENT 'Date on which this manufacturer record version was superseded or expired. NULL indicates the current active version. Supports Type-2 SCD history for point-in-time drug reference and rebate analysis.',
  effective_start_date DATE COMMENT 'Date on which this manufacturer record version became effective. Supports Type-2 slowly changing dimension (SCD) history tracking for the drug reference domain, enabling point-in-time drug reference lookups.',
  fda_establishment_code STRING COMMENT 'FDA-assigned establishment identifier for the manufacturer''s registered drug production facility. Supports regulatory compliance tracking and drug sourcing validation.',
  has_cap_program BOOLEAN COMMENT 'Indicates whether the manufacturer offers a copay assistance program (CAP) such as copay cards or coupons managed through the PAX application. Supports affordability intelligence and member OOP optimization.',
  headquarters_address_line1 STRING COMMENT 'Primary street address line of the manufacturer''s corporate headquarters. Used for business correspondence, contract management, and manufacturer program administration.',
  headquarters_address_line2 STRING COMMENT 'Secondary street address line (suite, floor, building) of the manufacturer''s corporate headquarters. Supplements the primary address for complete mailing and contract records.',
  headquarters_city STRING COMMENT 'City of the manufacturer''s corporate headquarters. Used in geographic analysis of manufacturer distribution and for contract correspondence.',
  headquarters_country STRING COMMENT 'ISO 3166-1 alpha-3 three-letter country code for the manufacturer''s corporate headquarters. Identifies domestic vs. international manufacturers relevant to 340B and import regulations.',
  headquarters_postal_code STRING COMMENT 'ZIP or ZIP+4 postal code of the manufacturer''s corporate headquarters. Used for geographic segmentation and mailing address validation.',
  headquarters_state STRING COMMENT 'Two-letter US state or territory code of the manufacturer''s corporate headquarters. Supports state-level regulatory compliance and geographic reporting.',
  is_340b_participating BOOLEAN COMMENT 'Indicates whether the manufacturer participates in the federal 340B Drug Pricing Program, which requires covered entities to receive discounted drug prices. Critical for 340B compliance and audit analysis.',
  is_current_record BOOLEAN COMMENT 'Boolean flag indicating whether this row is the current active version of the manufacturer record in the Type-2 SCD history. True = current; False = historical version. Simplifies current-state queries.',
  is_rebate_eligible BOOLEAN COMMENT 'Indicates whether the manufacturer has active rebate agreements applicable to PillarRx client plans. Drives rebate reconciliation workflows and PBM contract guarantee auditing.',
  labeler_code STRING COMMENT 'FDA-assigned 5-digit labeler code representing the first segment of the 11-digit NDC. Uniquely identifies the manufacturer or labeler responsible for the drug product.',
  ldd_manufacturer_flag BOOLEAN COMMENT 'Indicates whether the manufacturer produces limited distribution drugs (LDD) that are only available through select specialty pharmacies. Critical for specialty pharmacy network analysis and client consulting.',
  manufacturer_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for the pharmaceutical manufacturer or labeler record within the PillarRx enterprise data platform.',
  manufacturer_name STRING COMMENT 'Legal or trade name of the pharmaceutical manufacturer or labeler as registered with the FDA. Used as the primary human-readable identifier in drug reference lookups and consulting reports.',
  manufacturer_status STRING COMMENT 'Current lifecycle status of the manufacturer record. Inactive, acquired, merged, or dissolved statuses indicate the labeler is no longer independently operating and may affect drug reference validity.',
  manufacturer_type STRING COMMENT 'Categorical classification of the manufacturer by the primary nature of its drug portfolio: brand (innovator), generic, biosimilar, over-the-counter (OTC), or combination. Drives rebate strategy and formulary analysis.',
  organization_id BIGINT COMMENT 'Foreign key linking to company.organization. Business justification: Pharmaceutical manufacturers can also be PillarRx clients (self-insured employer health plans).',
  parent_company_name STRING COMMENT 'Name of the ultimate parent corporation that owns or controls the manufacturer. Supports rebate aggregation, manufacturer program management, and spend analysis at the enterprise parent level.',
  primary_contact_email STRING COMMENT 'Email address of the primary business contact at the manufacturer. Used for CAP program coordination, rebate reconciliation communications, and manufacturer program management.',
  primary_contact_name STRING COMMENT 'Name of the primary business contact at the manufacturer for rebate negotiations, copay assistance program (CAP) management, and manufacturer program administration.',
  primary_contact_phone STRING COMMENT 'Phone number of the primary business contact at the manufacturer. Supports direct outreach for copay assistance program (CAP) enrollment, rebate disputes, and manufacturer program coordination.',
  source_labeler_code STRING COMMENT 'The manufacturer or labeler identifier as assigned by the originating source system (Medi-Span, FDB, or FDA). Enables traceability back to the upstream reference data feed for reconciliation and audit.',
  specialty_manufacturer_flag BOOLEAN COMMENT 'Indicates whether the manufacturer primarily produces specialty medications (SMN). Supports specialty pharmacy spend monitoring, limited distribution drug (LDD) tracking, and specialty trend reporting.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when this manufacturer record was last modified in the PillarRx enterprise data platform. Used for change detection, SCD processing, and data quality monitoring.',
  CONSTRAINT pk_manufacturer PRIMARY KEY (manufacturer_id)
)
COMMENT 'Master record for pharmaceutical manufacturers and labelers whose drugs appear in PillarRx client claims. Stores labeler code (first 5 digits of NDC), manufacturer name, parent company name, manufacturer type (brand, generic, biosimilar, OTC)'
;

CREATE TABLE IF NOT EXISTS pillarrx.drug.ndc (
  application_number STRING COMMENT 'FDA New Drug Application (NDA), Abbreviated NDA (ANDA), or Biologics License Application (BLA) number. Links the NDC to its regulatory approval for biosimilar and generic analysis.',
  awp DECIMAL(18,4) COMMENT 'Average Wholesale Price',
  awp_effective_date DATE COMMENT 'Date on which the current AWP pricing became effective. Critical for point-in-time pricing lookups during PBM audit and claims repricing.',
  awp_package_price DECIMAL(12,4) COMMENT 'Average Wholesale Price for the full package (AWP per unit × package size). Used in ingredient cost benchmarking and PBM audit comparisons.',
  awp_unit_price DECIMAL(12,4) COMMENT 'Average Wholesale Price per dispensing unit as published by Medi-Span or FDB. Basis for AWP discount calculations in PBM contract audits and guarantee reconciliation.',
  biosimilar_indicator BOOLEAN COMMENT 'True if the drug is an FDA-approved biosimilar. Used in biosimilar substitution opportunity analysis and specialty spend optimization consulting.',
  brand_name STRING COMMENT 'Manufacturer-assigned brand/trade name for the drug product (e.g., LIPITOR). Null for generic-only products. Used in brand vs. generic spend analytics.',
  current_flag BOOLEAN COMMENT 'SCD2 current record flag',
  dea_schedule STRING COMMENT 'DEA controlled substance schedule (CI–CV) or ''unscheduled''. Drives DUR alerts, quantity limit rules, and regulatory compliance reporting for controlled substance utilization.',
  discontinuation_date DATE COMMENT 'Date the drug product was discontinued from the U.S. market. Null for active products. Used to identify claims dispensed after market withdrawal.',
  dosage_form STRING COMMENT 'Physical form of the drug product (e.g., tablet, capsule, solution, injection). Sourced from FDA labeling and drug reference files. Used in formulary and utilization analysis.',
  drug_name STRING COMMENT 'Full proprietary or established drug product name as published by the labeler and sourced from Medi-Span or FDB (e.g., LIPITOR, atorvastatin calcium).',
  drug_reference_source STRING COMMENT 'External reference source (Medi-Span/First DataBank)',
  drug_status STRING COMMENT 'Current FDA market status of the NDC (active, discontinued, recalled, pending, obsolete). Drives formulary maintenance and claim adjudication validity checks.',
  effective_date DATE COMMENT 'SCD2 effective date',
  effective_end_date DATE COMMENT 'Type-2 SCD history tracking column sourced from the authoritative external reference feed.',
  effective_start_date DATE COMMENT 'Type-2 SCD history tracking column sourced from the authoritative external reference feed.',
  expiration_date DATE COMMENT 'SCD2 expiration date',
  fdb_drug_id BIGINT COMMENT 'Medi-Span internal drug identifier for this NDC. Supports cross-reference and reconciliation between Medi-Span and FDB drug reference feeds in the lakehouse.',
  generic_indicator STRING COMMENT 'Attribute capturing the generic indicator for the ndc record in the drug domain.',
  generic_name STRING COMMENT 'International Nonproprietary Name (INN) or USAN generic name of the active ingredient(s) (e.g., atorvastatin calcium). Used for generic substitution analysis and GDR reporting.',
  gpi14 STRING COMMENT 'Medi-Span 14-digit Generic Product Identifier classifying the drug by therapeutic category, drug group, drug class, drug name, dosage form, route, and strength. Core to therapeutic class analysis.',
  is_current BOOLEAN COMMENT 'True if this row is the current active version of the NDC record in the Type-2 SCD. Simplifies queries that need only the latest drug attributes without date-range filtering.',
  ldd_indicator BOOLEAN COMMENT 'True if the drug is a Limited Distribution Drug available only through select specialty pharmacies. Used in specialty pharmacy network compliance and affordability analysis.',
  maintenance_drug_indicator BOOLEAN COMMENT 'True if the drug is classified as a maintenance medication (chronic, long-term use). Used in 90-day supply program analysis and mail-order vs. retail dispensing analytics.',
  manufacturer_id BIGINT COMMENT 'FK to drug.manufacturer.manufacturer_id — ndc declares labeler_code as FK to manufacturer in prose for 6 iterations but it is not verifiably wired. Manufacturer spend, rebate reconciliation, and 340B joins all depend on this FK. Must be mater',
  market_date DATE COMMENT 'Date the drug product was first commercially available in the U.S. market. Used in new-to-market drug trend analysis and formulary addition timing.',
  multi_source_indicator BOOLEAN COMMENT 'True if a generic equivalent is available from multiple manufacturers, enabling MAC pricing. Used in PBM audit and MAC pricing analysis.',
  ndc11_formatted STRING COMMENT 'NDC-11 displayed in hyphenated 5-4-2 format for human-readable reporting and EOB presentation (e.g., 12345-6789-01).',
  ndc_code STRING COMMENT 'National Drug Code (11-digit) primary drug identifier',
  ndc_id BIGINT NOT NULL COMMENT 'Surrogate primary key for the NDC dimension record. Supports Type-2 SCD versioning so each historical snapshot of an NDC has a unique row.',
  orange_book_code STRING COMMENT 'FDA Orange Book therapeutic equivalence code (e.g., AB, AA, BX). Determines generic substitutability for DAW code validation and GDR analysis.',
  otc_indicator BOOLEAN COMMENT 'True if the drug is available over-the-counter without a prescription. Used to flag OTC claims for benefit exclusion review and formulary compliance.',
  package_description STRING COMMENT 'Package information',
  package_size DECIMAL(10,4) COMMENT 'Number of units (tablets, mL, grams, etc.) in the dispensed package as defined by the NDC. Used in days-supply validation and unit-cost calculations.',
  package_size_unit STRING COMMENT 'Unit of measure for the package size (e.g., EA, ML, GM, TAB). Required to correctly interpret package_size in cost and utilization calculations.',
  reference_source_update_date DATE COMMENT 'Date the drug reference source (Medi-Span or FDB) last updated this NDC record. Used to track currency of drug reference data and trigger SCD version creation.',
  rems_indicator BOOLEAN COMMENT 'True if the FDA requires a Risk Evaluation and Mitigation Strategy (REMS) for this drug. Flags drugs with mandatory safety protocols for prior authorization and utilization management.',
  route_of_administration STRING COMMENT 'How the drug is administered (e.g., oral, intravenous, topical, subcutaneous). Used in specialty drug identification and medical vs. pharmacy benefit determination.',
  scd_effective_date DATE COMMENT 'Start date of this Type-2 SCD version row. Combined with scd_expiration_date to define the validity window for point-in-time pricing and classification lookups.',
  scd_expiration_date DATE COMMENT 'End date of this Type-2 SCD version row (9999-12-31 for the current active record). Enables point-in-time joins for historical claims repricing and PBM audit.',
  source_file_name STRING COMMENT 'Type-2 SCD history tracking column sourced from the authoritative external reference feed.',
  source_load_date DATE COMMENT 'Type-2 SCD history tracking column sourced from the authoritative external reference feed.',
  specialty_drug_indicator BOOLEAN COMMENT 'True if the drug is classified as a specialty medication requiring special handling, storage, or distribution. Drives specialty pharmacy spend monitoring and trend reporting.',
  strength STRING COMMENT 'Active ingredient strength and unit (e.g., 10 mg, 500 mg/5 mL). Used in clinical equivalence matching, step therapy analysis, and quantity limit validation.',
  therapeutic_class STRING COMMENT 'Attribute capturing the therapeutic class for the ndc record in the drug domain.',
  therapeutic_class_code STRING COMMENT 'Drug therapeutic class code derived from the GPI hierarchy (first 6 digits of GPI-14). Used for formulary tier analysis, utilization management, and benchmarking.',
  therapeutic_class_name STRING COMMENT 'Human-readable description of the therapeutic class (e.g., HMG-CoA Reductase Inhibitors). Supports consulting reports and client-facing trend analysis.',
  wac DECIMAL(18,4) COMMENT 'Wholesale Acquisition Cost',
  wac_effective_date DATE COMMENT 'Date on which the current WAC pricing became effective. Used for point-in-time WAC lookups in pass-through pricing audits.',
  wac_unit_price DECIMAL(12,4) COMMENT 'Wholesale Acquisition Cost per dispensing unit as published by Medi-Span or FDB. Used as an alternative pricing benchmark in pass-through PBM models and 340B analysis.',
  CONSTRAINT pk_ndc PRIMARY KEY (ndc_id)
)
COMMENT 'Derived Silver-layer NDC table. JOINs to the authoritative external reference tables (reference.fdb_drug, reference.medispan_drug) which hold the source-of-truth external drug records; this table itself is a derived join product, not the authoritative source.'
;

CREATE TABLE IF NOT EXISTS pillarrx.drug.ndc_price (
  awp_discount_pct DECIMAL(7,4) COMMENT 'The contracted AWP discount percentage applied to this NDC for ingredient cost reimbursement. Expressed as a positive decimal (e.g., 16.00 = 16% off AWP). Used in PBM contract guarantee auditing.',
  awp_package_price DECIMAL(12,4) COMMENT 'Average Wholesale Price for the full package size as published by Medi-Span or FDB. Used in package-level cost analysis and PBM audit reconciliation.',
  awp_unit_price DECIMAL(12,4) COMMENT 'Average Wholesale Price per dispensing unit as published by Medi-Span or FDB. AWP is the benchmark price used in PBM contract discount calculations and ingredient cost benchmarking.',
  currency_code STRING COMMENT 'ISO 4217 three-letter currency code for all monetary price fields in this record. Pillarrx operates in USD; this field supports multi-currency extensibility.',
  dea_schedule STRING COMMENT 'DEA controlled substance schedule for this NDC. CI = Schedule I through CV = Schedule V. Unscheduled = not a controlled substance. Required for controlled substance utilization reporting.',
  dosage_form STRING COMMENT 'Physical form of the drug product (e.g., TABLET, CAPSULE, SOLUTION, INJECTION, PATCH). Sourced from Medi-Span or FDB. Used in drug utilization and formulary analysis.',
  drug_name STRING COMMENT 'Brand or generic drug name for this NDC as published by Medi-Span or FDB. Denormalized onto the pricing record to support reporting without joining to the drug dimension.',
  effective_date DATE COMMENT 'The calendar date on which this pricing record becomes effective. Used with expiration_date to define the valid window for AWP, WAC, and MAC values. Supports Type-2 SCD history.',
  expiration_date DATE COMMENT 'The calendar date on which this pricing record expires and is superseded by a newer version. NULL indicates the record is currently active. Supports Type-2 SCD history.',
  formulary_tier STRING COMMENT 'Formulary cost-sharing tier associated with this NDC at the time of this pricing record (e.g., Tier 1 Generic, Tier 2 Preferred Brand). Supports formulary and benefit analysis.',
  generic_indicator STRING COMMENT 'Classifies the NDC as brand, generic, over-the-counter, or biosimilar. Drives Generic Dispensing Rate (GDR) calculations and brand/generic cost benchmarking in PBM audits.',
  gpi_code STRING COMMENT '14-digit Generic Product Identifier from Wolters Kluwer Medi-Span providing a hierarchical drug classification (drug group, class, subclass, name, name extension, dosage form, strength).',
  is_340b_eligible BOOLEAN COMMENT 'Indicates whether this NDC is eligible for the federal 340B drug discount program. Used in 340B program management and manufacturer discount reconciliation for covered entities.',
  is_current BOOLEAN COMMENT 'Flag indicating whether this is the currently active pricing record for the NDC. TRUE = current active row; FALSE = historical row. Supports efficient Type-2 SCD current-row filtering.',
  is_limited_distribution BOOLEAN COMMENT 'Indicates whether this NDC is a Limited Distribution Drug (LDD) available only through select specialty pharmacies. Affects reimbursement benchmarking and network adequacy analysis.',
  is_specialty_drug BOOLEAN COMMENT 'Indicates whether this NDC is classified as a specialty medication (SMN) requiring special handling, prior authorization, or specialty pharmacy dispensing. Critical for specialty spend monitoring.',
  labeler_name STRING COMMENT 'Name of the drug manufacturer or labeler as registered with the FDA for this NDC. Used in manufacturer program management, rebate tracking, and 340B analysis.',
  mac_list_id BIGINT COMMENT 'FK to drug.mac_list.mac_list_id — ndc_price MAC entries reference a mac_list; FK required for under-reimbursement appeals and MAC benchmarking.',
  mac_price DECIMAL(12,4) COMMENT 'Maximum Allowable Cost price for this NDC, representing the maximum reimbursement a PBM will pay for a generic or multi-source drug. Central to PBM contract MAC list auditing.',
  multisource_code STRING COMMENT 'Medi-Span/FDB multisource code indicating generic availability: O = originator brand, M = multisource brand, N = no generic available, Y = generic available. Drives MAC applicability.',
  ndc_mac_list_id BIGINT COMMENT 'Foreign key linking to drug.mac_list. Business justification: ndc_price can reference a MAC list when the price is MAC-based. Currently has mac_list_name (STRING) but needs proper FK to mac_list master. The mac_list_name string becomes redundant.',
  ndc_price_id BIGINT NOT NULL COMMENT 'Unique surrogate key for each time-versioned NDC pricing record in the Pillarrx drug reference domain.',
  obsolete_date DATE COMMENT 'Date on which the FDA or drug reference source marked this NDC as obsolete or discontinued. NULL if still active. Used to prevent claims matching to discontinued NDCs in audit workflows.',
  package_size DECIMAL(10,4) COMMENT 'Numeric quantity of dispensing units contained in the package for which package-level pricing (AWP, WAC) is expressed. Used to derive per-unit pricing from package pricing.',
  package_size_uom STRING COMMENT 'Unit of measure for the package size quantity (e.g., TAB for 30-tablet bottle, ML for 100mL vial). Distinct from unit_of_measure which applies to per-unit pricing.',
  price_change_type STRING COMMENT 'Describes the nature of the pricing change that triggered this new SCD Type-2 row. Used in drug price trend analysis and manufacturer price increase monitoring for employer clients.',
  price_source STRING COMMENT 'Identifies the authoritative external source that published this pricing record. Medi-Span (Wolters Kluwer) and First DataBank (FDB) are the primary drug reference feeds used by Pillarrx.',
  price_status STRING COMMENT 'Lifecycle status of this pricing record. ACTIVE = currently in effect; EXPIRED = past expiration_date; SUPERSEDED = replaced by a newer SCD row; PENDING = future-dated not yet effective.',
  price_type_code STRING COMMENT 'Classifies the primary pricing basis of this record. AWP = Average Wholesale Price, WAC = Wholesale Acquisition Cost, MAC = Maximum Allowable Cost, DP = Direct Price, SP = Suggested Price.',
  primary_mac_list_id BIGINT COMMENT 'FK to drug.mac_list.mac_list_id — ndc_price stores MAC values that belong to a specific MAC list; FK to mac_list enables under-reimbursement appeals analysis and MAC benchmarking (iteration-1 request).',
  prior_awp_unit_price DECIMAL(12,4) COMMENT 'The AWP per unit from the immediately preceding pricing record for this NDC. Retained on the new row to enable direct price change calculations without joining to the prior SCD row.',
  prior_wac_unit_price DECIMAL(12,4) COMMENT 'The WAC per unit from the immediately preceding pricing record for this NDC. Enables direct WAC change calculations for manufacturer price increase monitoring.',
  record_created_timestamp TIMESTAMP COMMENT 'Timestamp when this pricing record row was first inserted into the Pillarrx Silver layer. Supports audit trail and SCD Type-2 row lineage.',
  record_updated_timestamp TIMESTAMP COMMENT 'Timestamp when this pricing record row was last modified in the Pillarrx Silver layer. Tracks corrections or restatements to a pricing row after initial load.',
  repackaged_indicator BOOLEAN COMMENT 'Indicates whether this NDC belongs to a repackager rather than the original manufacturer. Repackaged NDCs may have different AWP/WAC values and require special handling in PBM audits.',
  route_of_administration STRING COMMENT 'The route by which the drug is administered (e.g., ORAL, INJECTABLE). Sourced from Medi-Span or FDB. Used in specialty drug identification and clinical utilization analysis.',
  source_file_name STRING COMMENT 'Name of the Medi-Span or FDB source file from which this pricing record was loaded. Supports data lineage tracing and audit of pricing feed ingestion.',
  source_load_date DATE COMMENT 'The date on which this pricing record was loaded from the external source feed (Medi-Span or FDB) into the Pillarrx lakehouse. Supports feed timeliness monitoring.',
  strength STRING COMMENT 'Strength of the active ingredient(s) for this NDC as labeled (e.g., 10MG, 500MG/5ML). Sourced from Medi-Span or FDB. Used in clinical and formulary analysis.',
  therapeutic_class_code STRING COMMENT 'Drug therapeutic class code from Medi-Span GPI or FDB therapeutic classification hierarchy. Used in drug utilization review (DUR), formulary analysis, and therapeutic category spend reporting.',
  therapeutic_class_name STRING COMMENT 'Human-readable name of the therapeutic class corresponding to therapeutic_class_code. Supports reporting and analytics without requiring a join to a separate classification table.',
  unit_of_measure STRING COMMENT 'The dispensing unit of measure for which per-unit pricing (AWP, WAC) is expressed. Examples: EA (each), ML (milliliter), GM (gram), TAB (tablet), CAP (capsule).',
  wac_package_price DECIMAL(12,4) COMMENT 'Wholesale Acquisition Cost for the full package size. Used in package-level manufacturer pricing analysis and 340B ceiling price calculations.',
  wac_unit_price DECIMAL(12,4) COMMENT 'Wholesale Acquisition Cost per dispensing unit as published by Medi-Span or FDB. WAC is the manufacturer list price before discounts and is used in 340B and rebate analytics.',
  CONSTRAINT pk_ndc_price PRIMARY KEY (ndc_price_id)
)
COMMENT 'Time-versioned pricing record for each NDC, capturing AWP (Average Wholesale Price), WAC (Wholesale Acquisition Cost), and MAC (Maximum Allowable Cost) values sourced from Medi-Span and FDB.'
;

CREATE TABLE IF NOT EXISTS pillarrx.drug.pharmacy (
  accreditation_code STRING COMMENT 'Accreditation body code for the pharmacy (e.g., URAC, ACHC, JCAHO, PCAB). Specialty pharmacies require accreditation for network participation. Used in network credentialing audits.',
  address_line1 STRING COMMENT 'Primary street address of the dispensing pharmacy location. Used for geographic analysis, network adequacy reporting, and member proximity analytics.',
  address_line2 STRING COMMENT 'Secondary address detail (suite, floor, unit) for the pharmacy location. Supplements address_line1 for complete mailing and geolocation purposes.',
  chain_code STRING COMMENT 'NCPDP-assigned chain code identifying the pharmacy chain affiliation (e.g., CVS, Walgreens, Rite Aid). Null for independent pharmacies. Used for chain vs. independent benchmarking.',
  chain_independent_status STRING COMMENT 'Attribute capturing the chain independent status for the pharmacy record in the drug domain.',
  chain_name STRING COMMENT 'Name of the pharmacy chain associated with chain_code (e.g., CVS Pharmacy, Walgreens). Null for independent pharmacies. Used in network analysis and client benchmarking reports.',
  city STRING COMMENT 'City in which the pharmacy is physically located. Used for geographic segmentation, network analysis, and state-level regulatory reporting.',
  country_code STRING COMMENT 'ISO 3166-1 alpha-3 country code for the pharmacy location (e.g., USA). Supports cross-border dispensing scenarios and international specialty pharmacy tracking.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this pharmacy record was first loaded into the Pillarrx lakehouse. Supports data lineage, audit trails, and SCD Type-2 version management.',
  dba_name STRING COMMENT 'Trade or doing-business-as name of the pharmacy when it differs from the legal name (e.g., a chain banner name). Used for consumer-facing reporting and benchmarking.',
  dea_number STRING COMMENT 'DEA registration number authorizing the pharmacy to dispense controlled substances. Required for Schedule II-V drug dispensing compliance and audit. Format: 2 letters + 7 digits.',
  dispensing_languages STRING COMMENT 'Comma-separated list of languages in which the pharmacy provides counseling and dispensing services (e.g., English, Spanish, Mandarin). Supports member access and health equity reporting.',
  dispensing_state_license STRING COMMENT 'State board of pharmacy license number authorizing the pharmacy to dispense medications in its operating state. Required for regulatory compliance and PBM network credentialing.',
  drive_through BOOLEAN COMMENT 'Indicates whether the pharmacy offers drive-through dispensing service (True). Used in member-facing network directory and access reporting for employer clients.',
  effective_date DATE COMMENT 'Start date of this Type-2 SCD record version, representing when this set of pharmacy attributes became effective. Used for point-in-time historical lookups on pharmacy claims.',
  effective_end_date DATE COMMENT 'Attribute capturing the effective end date for the pharmacy record in the drug domain.',
  effective_start_date DATE COMMENT 'Attribute capturing the effective start date for the pharmacy record in the drug domain.',
  expiration_date DATE COMMENT 'End date of this Type-2 SCD record version. Null indicates the current active version. When a pharmacy attribute changes, the prior row is closed with this date and a new row is opened.',
  fax STRING COMMENT 'Fax number for the pharmacy. Used for prior authorization transmissions and prescriber-to-pharmacy communications in PBM workflows.',
  is_340b BOOLEAN COMMENT 'Indicates whether the pharmacy participates in the federal 340B drug discount program (True). Critical for identifying 340B-eligible dispensing events and manufacturer program compliance.',
  is_chain BOOLEAN COMMENT 'Indicates whether the pharmacy is part of a chain (True) or is an independent pharmacy (False). Key segmentation flag for PBM network analysis and GDR benchmarking.',
  is_current BOOLEAN COMMENT 'Type-2 SCD flag indicating whether this row is the current (most recent) version of the pharmacy record (True) or a historical version (False). Simplifies current-state queries.',
  is_long_term_care BOOLEAN COMMENT 'Indicates whether the pharmacy is designated as a long-term care pharmacy serving nursing facilities or assisted living. Relevant for Medicare Part D and SPAP reporting.',
  is_mail_order BOOLEAN COMMENT 'Indicates whether the pharmacy operates as a mail-order dispensing facility (True). Mail-order pharmacies typically dispense 90-day supplies and are subject to different reimbursement guarantees.',
  is_specialty BOOLEAN COMMENT 'Indicates whether the pharmacy is designated as a specialty pharmacy (True). Specialty pharmacies dispense high-cost, complex medications (SMN/LDD). Drives specialty spend monitoring.',
  latitude DECIMAL(9,6) COMMENT 'Geographic latitude coordinate of the pharmacy location in decimal degrees. Used for member proximity analysis, network adequacy mapping, and geographic access reporting.',
  longitude DECIMAL(9,6) COMMENT 'Geographic longitude coordinate of the pharmacy location in decimal degrees. Used alongside latitude for network adequacy mapping and member access distance calculations.',
  ncpdp_id STRING COMMENT 'Identifier referencing the related ncpdp id for the pharmacy record in the drug domain.',
  ncpdp_number STRING COMMENT 'The 7-digit NCPDP provider identifier assigned by NCPDP to each dispensing pharmacy. Primary business key used for pharmacy routing on pharmacy claims and PBM adjudication.',
  ncpdp_source_date DATE COMMENT 'Date of the NCPDP Pharmacy File extract from which this record was sourced. Used for data lineage, refresh tracking, and identifying stale pharmacy reference data.',
  network_status STRING COMMENT 'Current network participation status of the pharmacy within PBM networks managed by Pillarrx clients. Drives member cost-sharing tiers and PBM contract guarantee applicability.',
  npi STRING COMMENT '10-digit NPI assigned to the pharmacy by CMS/NPPES. Used for crosswalk to medical claims, provider credentialing, and HIPAA standard transactions.',
  open_24_hours BOOLEAN COMMENT 'Indicates whether the pharmacy operates 24 hours per day (True). Used in member benefit communications and network adequacy assessments for employer clients.',
  pharmacy_id BIGINT NOT NULL COMMENT 'Surrogate primary key uniquely identifying each pharmacy record in the Pillarrx lakehouse. BIGINT sequence-generated; not exposed externally.',
  pharmacy_name STRING COMMENT 'Legal business name of the pharmacy as registered with NCPDP and state boards of pharmacy. Used for display, reporting, and audit deliverables.',
  pharmacy_network_id BIGINT COMMENT 'PBM-assigned network identifier for this pharmacy within a specific PBM network (e.g., CVS Caremark retail network code). Used for network tier assignment and reimbursement guarantee auditing.',
  pharmacy_type STRING COMMENT 'Attribute capturing the pharmacy type for the pharmacy record in the drug domain.',
  phone STRING COMMENT 'Primary 10-digit telephone number for the pharmacy. Used for member outreach, prior authorization coordination, and audit contact.',
  record_status STRING COMMENT 'Lifecycle status of this pharmacy dimension record. Active = currently dispensing; inactive = temporarily closed; terminated = permanently closed or removed from NCPDP file.',
  source_file_name STRING COMMENT 'Type-2 SCD history tracking column sourced from the authoritative external reference feed.',
  source_load_date DATE COMMENT 'Type-2 SCD history tracking column sourced from the authoritative external reference feed.',
  specialty_designation STRING COMMENT 'Attribute capturing the specialty designation for the pharmacy record in the drug domain.',
  state_code STRING COMMENT 'Two-letter USPS state abbreviation for the pharmacy location. Used for state board of pharmacy compliance, state PBM transparency law reporting, and geographic trend analysis.',
  time_zone STRING COMMENT 'IANA time zone identifier for the pharmacy location (e.g., America/Chicago). Used for date-of-service normalization across multi-time-zone claims aggregation.',
  type_code STRING COMMENT 'NCPDP-defined pharmacy type code classifying the dispensing channel (e.g., retail, mail order, specialty, long-term care, home infusion). Drives network tier and reimbursement logic.',
  type_description STRING COMMENT 'Human-readable description of the pharmacy type corresponding to pharmacy_type_code (e.g., Retail, Mail Order, Specialty, Long-Term Care). Used in reporting and client deliverables.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp of the most recent update to this pharmacy record in the Pillarrx lakehouse. Used for change detection, SCD Type-2 processing, and data freshness monitoring.',
  zip_code STRING COMMENT '5-digit or ZIP+4 postal code for the pharmacy location. Used for geographic clustering, network adequacy, and member proximity analysis.',
  CONSTRAINT pk_pharmacy PRIMARY KEY (pharmacy_id),
  CONSTRAINT uq_pharmacy_ncpdp_id UNIQUE (ncpdp_id)
)
COMMENT 'Derived Silver-layer pharmacy table. JOINs to the authoritative external reference table reference.ncpdp_pharmacy which holds the source-of-truth external pharmacy records; this table itself is a derived join product, not the authoritative source.'
;

CREATE TABLE IF NOT EXISTS pillarrx.drug.pharmacy_network (
  awp_discount_brand_pct DECIMAL(7,4) COMMENT 'Contracted AWP discount percentage applied to brand drug ingredient cost reimbursement for this pharmacy within this network. Core metric for PBM guarantee benchmarking (BER).',
  awp_discount_generic_pct DECIMAL(7,4) COMMENT 'Contracted AWP discount percentage applied to generic drug ingredient cost reimbursement for this pharmacy within this network. Used in GDR and GER audit calculations.',
  company_client_id BIGINT COMMENT 'Foreign key linking to company.company_client. Business justification: Some clients negotiate custom pharmacy networks or carve-outs (e.g., excluding mail-order, specialty-only networks).',
  company_pbm_id BIGINT COMMENT 'Reference to the PBM that owns and administers this pharmacy network contract (e.g., CVS Caremark, Optum Rx, Express Scripts).',
  contract_type STRING COMMENT 'PBM pricing model type for this network contract. Pass-through means transparent ingredient cost; spread means PBM retains difference between plan paid and pharmacy reimbursement.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when this pharmacy network participation record was first created in the lakehouse. Supports data lineage, audit, and SCD version management.',
  dir_applicable BOOLEAN COMMENT 'Indicates whether Direct and Indirect Remuneration (DIR) fees apply to claims adjudicated through this pharmacy network. Relevant for Medicare Part D plan sponsors and PBM audit.',
  dispensing_fee_mail DECIMAL(10,4) COMMENT 'Contracted dispensing fee (in USD) paid to the pharmacy per mail-order fill within this network. Distinct from retail fee due to 90-day supply economics.',
  dispensing_fee_retail DECIMAL(10,4) COMMENT 'Contracted dispensing fee (in USD) paid to the pharmacy per retail fill within this network. Used in PBM contract guarantee auditing and spread analysis.',
  dispensing_fee_specialty DECIMAL(10,4) COMMENT 'Contracted dispensing fee (in USD) paid to the pharmacy per specialty drug fill within this network. Key input for specialty spend monitoring and PBM audit.',
  effective_date DATE COMMENT 'Date on which the pharmacy''s participation in this PBM network becomes effective. Used for Type-2 SCD history and claims eligibility validation.',
  is_340b BOOLEAN COMMENT 'Indicates whether this pharmacy is a 340B covered entity or contract pharmacy within this network, eligible for federal drug discount pricing under HRSA 340B program.',
  is_mail_order BOOLEAN COMMENT 'Indicates whether this pharmacy participates as a mail-order dispensing location within this network. Relevant for 90-day supply benefit design and PMPM trend analysis.',
  is_preferred BOOLEAN COMMENT 'Indicates whether this pharmacy participates at the preferred tier within the network, typically associated with lower member cost-sharing and higher plan reimbursement rates.',
  is_specialty BOOLEAN COMMENT 'Indicates whether this pharmacy is designated as a specialty pharmacy within this network, authorized to dispense specialty and limited-distribution drugs (LDD).',
  mac_list_id BIGINT COMMENT 'FK to drug.mac_list.mac_list_id — pharmacy_network already carries a MAC list reference; once mac_list exists as a first-class entity this FK supports MAC guarantee auditing.',
  ncpdp_id STRING COMMENT '7-digit NCPDP pharmacy identifier for the participating pharmacy. Denormalized here for direct claims matching and audit without requiring a join to the pharmacy dimension.',
  network_adequacy_class STRING COMMENT 'Regulatory adequacy classification of the pharmacy network per CMS or state standards. Narrow and limited networks may trigger member access reporting requirements.',
  network_code STRING COMMENT 'PBM-assigned alphanumeric code uniquely identifying the pharmacy network (e.g., CVS_PREF_RETAIL, ESI_MAIL). Used for claims routing and benefit adjudication.',
  network_name STRING COMMENT 'Human-readable name of the pharmacy network as defined by the PBM (e.g., ''CVS Preferred Retail Network'', ''Express Scripts Standard Mail'').',
  network_status STRING COMMENT 'Current lifecycle state of the pharmacy network participation record. Active indicates the pharmacy is currently contracted within this network.',
  network_tier STRING COMMENT 'Cost-sharing tier designation for this pharmacy within the network. Tier 1 typically carries the lowest member cost-share; out-of-network carries the highest or no coverage.',
  network_type STRING COMMENT 'Classification of the pharmacy network by access model. Drives member cost-sharing tiers and PBM audit benchmarking. [ENUM-REF-CANDIDATE: standard_retail|preferred_retail|mail|specialty|narrow|limited_distribution — promote to reference product]',
  notes STRING COMMENT 'Free-text field for analyst or data steward notes regarding this pharmacy network participation record, such as contract exceptions, audit findings, or onboarding remarks.',
  pbm_network_file_date DATE COMMENT 'Date of the PBM network participation file from which this record was extracted. Used to track file vintage and detect stale network data in the lakehouse.',
  pbm_network_id_external STRING COMMENT 'The PBM''s own internal network identifier as received in claims feeds or contract files. Preserved for reconciliation against PBM-sourced data and audit traceability.',
  pharmacy_mac_list_fk BIGINT COMMENT 'FK to drug.mac_list.mac_list_id — pharmacy_network carries a MAC list reference; FK to mac_list required for MAC guarantee auditing.',
  pharmacy_mac_list_id BIGINT COMMENT 'Foreign key linking to drug.mac_list. Business justification: pharmacy_network references specific MAC (Maximum Allowable Cost) lists for pricing. Currently has mac_list_name (STRING) but needs proper FK to mac_list master.',
  pharmacy_ncpdp_id STRING COMMENT 'Reference to the pharmacy dimension record (keyed by NCPDP ID) that participates in this network.',
  pharmacy_network_id BIGINT NOT NULL COMMENT 'Unique surrogate identifier for each pharmacy network participation record linking a pharmacy (NCPDP ID) to a PBM network for a defined effective period.',
  pharmacy_network_mac_list_fk BIGINT COMMENT 'FK to drug.mac_list.mac_list_id — pharmacy_network carries a MAC list reference; now that mac_list is a first-class master this must FK to it for MAC guarantee auditing (iteration-1 request).',
  rxbin STRING COMMENT '6-digit BIN used to route pharmacy claims to the correct PBM processor for this network. Required for real-time adjudication and claims feed reconciliation.',
  rxgroup STRING COMMENT 'Pharmacy benefit group identifier associated with this network, used in claims adjudication to apply the correct formulary, cost-sharing, and network rules.',
  rxpcn STRING COMMENT 'Processor Control Number used alongside RxBIN to route pharmacy claims to the correct PBM sub-processor or plan for this network.',
  scd_current_flag BOOLEAN COMMENT 'Indicates whether this record is the current active version of the pharmacy network participation. True for the most recent version; False for historical versions.',
  scd_version INT COMMENT 'Monotonically increasing version number for Type-2 SCD history tracking. Each contract change or network renegotiation increments this version for the pharmacy-network combination.',
  source_record_code STRING COMMENT 'The native identifier of this record in the originating source system (e.g., PBM network file row key, NCPDP record ID). Enables upstream reconciliation and ETL traceability.',
  termination_date DATE COMMENT 'Date on which the pharmacy''s participation in this PBM network ends. Null indicates an open-ended active participation record.',
  tertiary_pharmacy_id BIGINT COMMENT 'FK to drug.pharmacy.pharmacy_id — Network participation records link a pharmacy (NCPDP) to a PBM network; FK to the pharmacy master is required for network adequacy analysis and preferred-pharmacy benchmarking.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp of the most recent update to this pharmacy network participation record. Used for incremental ETL processing and change detection in the Silver layer.',
  CONSTRAINT pk_pharmacy_network PRIMARY KEY (pharmacy_network_id)
)
COMMENT 'Defines PBM pharmacy network contracts and network participation records, linking a pharmacy (NCPDP ID) to a PBM network for a defined effective period. Stores network name, network type (standard retail, preferred retail, mail, specialty, narrow), PBM'
;

-- ---------------------------------------------------------------------------
-- Schema: program
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS pillarrx.program.accumulator_program (
  accumulator_program_id BIGINT NOT NULL COMMENT 'Surrogate primary key for accumulator program.',
  accumulator_type STRING COMMENT 'Type of accumulator or maximizer arrangement.',
  applicable_drug_list STRING COMMENT 'Drug list scope the program applies to.',
  client_id BIGINT COMMENT 'ADD column program.accumulator_program.client_id (BIGINT) as FK to client.employer.employer_id. ADD column program.accumulator_program.client_id (BIGINT) FK to client.employer.employer_id.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the record was created.',
  division_id BIGINT COMMENT 'Reference to division.division.division_id.',
  effective_end_date DATE COMMENT 'End date of the record''s effective period for Type-2 history.',
  effective_start_date DATE COMMENT 'Start date of the record''s effective period for Type-2 history.',
  employer_id BIGINT COMMENT 'Reference to client.employer.employer_id.',
  is_current BOOLEAN COMMENT 'Indicates whether this is the current version of the record.',
  manufacturer_assistance_counts_toward_deductible BOOLEAN COMMENT 'Indicates whether manufacturer assistance counts toward the member deductible.',
  manufacturer_assistance_counts_toward_oop BOOLEAN COMMENT 'Indicates whether manufacturer assistance counts toward member out-of-pocket.',
  maximizer_vendor_name STRING COMMENT 'Name of the maximizer vendor administering the program.',
  pbm_assignment_id BIGINT COMMENT 'ADD column program.accumulator_program.pbm_assignment_id (BIGINT) as FK to client.pbm_assignment.pbm_assignment_id. ADD column program.accumulator_program.pbm_assignment_id (BIGINT) FK to client.pbm_assignment.pbm_assignment_id.',
  savings_program_id BIGINT COMMENT 'Foreign key to the parent savings program.',
  state_override_required BOOLEAN COMMENT 'Indicates whether a state-level override is required.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when the record was last updated.',
  CONSTRAINT pk_accumulator_program PRIMARY KEY (accumulator_program_id)
)
COMMENT 'Copay accumulator and maximizer rules governing how manufacturer assistance counts toward member deductible and out-of-pocket.'
;

CREATE TABLE IF NOT EXISTS pillarrx.program.alternative_funding_program (
  afp_vendor_name STRING COMMENT 'Name of the alternative funding program vendor.',
  alternative_funding_program_id BIGINT NOT NULL COMMENT 'Surrogate primary key for alternative funding program.',
  applicable_drug_list STRING COMMENT 'Drug list scope the program applies to.',
  client_id BIGINT COMMENT 'ADD column program.alternative_funding_program.client_id (BIGINT) as FK to client.employer.employer_id. ADD column program.alternative_funding_program.client_id (BIGINT) FK to client.employer.employer_id.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the record was created.',
  employer_id BIGINT COMMENT 'Reference to client.employer.employer_id.',
  estimated_annual_savings DECIMAL(14,2) COMMENT 'Estimated annual savings generated by the program.',
  funding_source STRING COMMENT 'Funding source used by the alternative funding program.',
  member_consent_required BOOLEAN COMMENT 'Indicates whether member consent is required.',
  program_end_date DATE COMMENT 'Date the program ends.',
  program_start_date DATE COMMENT 'Date the program becomes effective.',
  program_status STRING COMMENT 'Current lifecycle status of the program.',
  savings_program_id BIGINT COMMENT 'Foreign key to the parent savings program.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when the record was last updated.',
  CONSTRAINT pk_alternative_funding_program PRIMARY KEY (alternative_funding_program_id)
)
COMMENT 'Third-party Alternative Funding Programs (AFPs) that redirect specialty drug procurement through manufacturer patient-assistance, charitable-foundation, international-sourcing, or copay-optimization channels to reduce plan-sponsor drug spend.'
;

CREATE TABLE IF NOT EXISTS pillarrx.program.charitable_assistance (
  application_required BOOLEAN COMMENT 'Indicates whether a formal application is required.',
  assistance_type STRING COMMENT 'Type of charitable assistance provided.',
  charitable_assistance_id BIGINT NOT NULL COMMENT 'Surrogate primary key for charitable assistance.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the record was created.',
  disease_state STRING COMMENT 'Disease state the assistance program targets.',
  foundation_name STRING COMMENT 'Name of the charitable foundation.',
  fund_status STRING COMMENT 'Current funding status of the assistance fund.',
  income_threshold_fpl_pct BIGINT COMMENT 'Income eligibility threshold as a percentage of the Federal Poverty Level.',
  insurance_requirement STRING COMMENT 'Insurance status required for eligibility.',
  max_annual_award DECIMAL(10,2) COMMENT 'Maximum annual award the foundation provides.',
  savings_program_id BIGINT COMMENT 'Foreign key to the parent savings program.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when the record was last updated.',
  CONSTRAINT pk_charitable_assistance PRIMARY KEY (charitable_assistance_id)
)
COMMENT 'Charitable foundation assistance programs that provide copay, premium, travel, or combined financial support to eligible members based on disease state and federal poverty level income thresholds.'
;

CREATE TABLE IF NOT EXISTS pillarrx.program.claim_savings_attribution (
  attributed_savings_amount DECIMAL(12,2) COMMENT 'Amount of savings attributed.',
  attribution_date DATE COMMENT 'Date the savings attribution was recorded.',
  attribution_type STRING COMMENT 'Type of savings attributed to the claim.',
  beneficiary STRING COMMENT 'Party that benefits from the attributed savings.',
  calculation_method STRING COMMENT 'Method used to calculate the attributed savings.',
  claim_savings_attribution_id BIGINT NOT NULL COMMENT 'Surrogate primary key for claim savings attribution.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the record was created.',
  member_id BIGINT COMMENT 'Reference to company.member.member_id.',
  rx_claim_id BIGINT COMMENT 'ADD column program.claim_savings_attribution.rx_claim_id (BIGINT) as FK to claim.rx_claim.rx_claim_id. ADD column program.claim_savings_attribution.rx_claim_id (BIGINT) FK to claim.rx_claim.rx_claim_id.',
  savings_program_id BIGINT COMMENT 'Reference to program.savings_program.savings_program_id.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when the record was last updated.',
  CONSTRAINT pk_claim_savings_attribution PRIMARY KEY (claim_savings_attribution_id)
)
COMMENT 'Claim-level decomposition attributing savings to rebates, copay assistance, 340B discounts, and other sources.'
;

CREATE TABLE IF NOT EXISTS pillarrx.program.contract_pharmacy_340b (
  contract_end_date DATE COMMENT 'Date the rebate contract ends.',
  contract_pharmacy_340b_id BIGINT NOT NULL COMMENT 'Surrogate primary key for contract pharmacy 340b.',
  contract_start_date DATE COMMENT 'Date the rebate contract begins.',
  contract_status STRING COMMENT 'Current status of the contract.',
  covered_entity_340b_id BIGINT COMMENT 'Foreign key to the parent 340B covered entity.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the record was created.',
  third_party_administrator STRING COMMENT 'Name of the third-party administrator managing the contract pharmacy.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when the record was last updated.',
  CONSTRAINT pk_contract_pharmacy_340b PRIMARY KEY (contract_pharmacy_340b_id)
)
COMMENT 'Contract pharmacy arrangements linked to 340B covered entities, including third-party administrators.'
;

CREATE TABLE IF NOT EXISTS pillarrx.program.copay_assistance_program (
  channel_restriction STRING COMMENT 'Pharmacy channel restriction for the program.',
  copay_assistance_program_id BIGINT NOT NULL COMMENT 'Surrogate primary key for copay assistance program.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the record was created.',
  enrollment_url STRING COMMENT 'URL where members can enroll in the program.',
  gpi14 STRING COMMENT '14-digit Generic Product Identifier for the targeted drug.',
  manufacturer_id BIGINT COMMENT 'ADD column program.copay_assistance_program.manufacturer_id (BIGINT) as FK to drug.manufacturer.manufacturer_id. ADD column program.copay_assistance_program.manufacturer_id (BIGINT) FK to drug.manufacturer.manufacturer_id.',
  member_target_copay DECIMAL(10,2) COMMENT 'Target member copay after assistance is applied.',
  ndc_id BIGINT COMMENT 'Reference to drug.ndc.ndc_id.',
  program_expiration_date DATE COMMENT 'Date the program expires.',
  program_max_annual_benefit DECIMAL(10,2) COMMENT 'Maximum annual benefit the program will pay.',
  program_max_per_fill DECIMAL(10,2) COMMENT 'Maximum benefit the program will pay per fill.',
  program_start_date DATE COMMENT 'Date the program becomes effective.',
  requires_enrollment BOOLEAN COMMENT 'Indicates whether member enrollment is required.',
  savings_program_id BIGINT COMMENT 'Foreign key to the parent savings program.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when the record was last updated.',
  CONSTRAINT pk_copay_assistance_program PRIMARY KEY (copay_assistance_program_id)
)
COMMENT 'Manufacturer copay card and eVoucher program details including benefit maximums and channel restrictions.'
;

CREATE TABLE IF NOT EXISTS pillarrx.program.covered_entity_340b (
  covered_entity_340b_id BIGINT NOT NULL COMMENT 'Surrogate primary key for covered entity 340b.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the record was created.',
  employer_id BIGINT COMMENT 'Reference to client.employer.employer_id.',
  entity_address_city STRING COMMENT 'City of the covered entity''s address.',
  entity_address_state STRING COMMENT 'State of the covered entity''s address.',
  entity_name STRING COMMENT 'Name of the 340B covered entity.',
  entity_npi STRING COMMENT 'National Provider Identifier of the covered entity.',
  entity_status STRING COMMENT 'Current 340B participation status of the entity.',
  entity_type STRING COMMENT 'Type of 340B covered entity.',
  hrsa_identifier STRING COMMENT 'HRSA-assigned 340B identifier for the entity.',
  registration_date DATE COMMENT 'Date the entity registered for the 340B program.',
  savings_program_id BIGINT COMMENT 'Foreign key to the parent savings program.',
  termination_date DATE COMMENT 'Date the entity''s 340B participation terminated.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when the record was last updated.',
  CONSTRAINT pk_covered_entity_340b PRIMARY KEY (covered_entity_340b_id)
)
COMMENT 'Registry of 340B covered entities such as DSH hospitals, FQHCs, and Ryan White clinics with HRSA identifiers.'
;

CREATE TABLE IF NOT EXISTS pillarrx.program.government_benefit_rule (
  annual_oop_cap DECIMAL(10,2) COMMENT 'Annual out-of-pocket cap mandated by the rule.',
  benefit_phase STRING COMMENT 'Benefit phase the rule governs.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the record was created.',
  government_benefit_rule_id BIGINT NOT NULL COMMENT 'Surrogate primary key for government benefit rule.',
  legislative_source STRING COMMENT 'Legislative source authorizing the rule.',
  manufacturer_discount_pct DECIMAL(5,2) COMMENT 'Mandated manufacturer discount percentage.',
  market_segment STRING COMMENT 'Government market segment the rule applies to.',
  member_coinsurance_pct DECIMAL(5,2) COMMENT 'Member coinsurance percentage in the benefit phase.',
  monthly_cost_cap DECIMAL(10,2) COMMENT 'Monthly cost cap mandated by the rule.',
  plan_liability_pct DECIMAL(5,2) COMMENT 'Plan liability percentage in the benefit phase.',
  rule_effective_date DATE COMMENT 'Date the rule becomes effective.',
  rule_expiration_date DATE COMMENT 'Date the rule expires.',
  rule_name STRING COMMENT 'Name of the government benefit rule.',
  savings_program_id BIGINT COMMENT 'Foreign key to the parent savings program.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when the record was last updated.',
  CONSTRAINT pk_government_benefit_rule PRIMARY KEY (government_benefit_rule_id)
)
COMMENT 'Government-mandated cost-sharing rules for Medicare Part D, Medicaid, VA, TRICARE, and IHP market segments used to model member out-of-pocket liability and plan financial exposure.'
;

CREATE TABLE IF NOT EXISTS pillarrx.program.member_accumulator_impact (
  accumulator_program_id BIGINT COMMENT 'Foreign key to the parent accumulator program.',
  assistance_credited_to_deductible DECIMAL(10,2) COMMENT 'Assistance amount credited to the member deductible.',
  assistance_credited_to_oop DECIMAL(10,2) COMMENT 'Assistance amount credited to member out-of-pocket.',
  assistance_excluded_from_accumulators DECIMAL(10,2) COMMENT 'Assistance amount excluded from member accumulators.',
  benefit_year BIGINT COMMENT 'Benefit year for the accumulator impact record.',
  copay_cliff_amount DECIMAL(10,2) COMMENT 'Copay amount the member faces at the copay cliff.',
  copay_cliff_date DATE COMMENT 'Date the member hits the copay cliff when assistance is exhausted.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the record was created.',
  member_accumulator_impact_id BIGINT NOT NULL COMMENT 'Surrogate primary key for member accumulator impact.',
  member_id BIGINT COMMENT 'ADD column program.member_accumulator_impact.member_id (BIGINT) as FK to company.member.member_id. ADD column program.member_accumulator_impact.member_id (BIGINT) FK to company.member.member_id.',
  member_true_oop_spend DECIMAL(10,2) COMMENT 'Member''s true out-of-pocket spend after accumulator treatment.',
  total_manufacturer_assistance_received DECIMAL(10,2) COMMENT 'Total manufacturer assistance received in the benefit year.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when the record was last updated.',
  CONSTRAINT pk_member_accumulator_impact PRIMARY KEY (member_accumulator_impact_id)
)
COMMENT 'Per-member per-benefit-year tracking of manufacturer assistance credited to or excluded from member accumulators.'
;

CREATE TABLE IF NOT EXISTS pillarrx.program.member_copay_enrollment (
  copay_assistance_program_id BIGINT COMMENT 'Foreign key to the parent copay assistance program.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the record was created.',
  disenrollment_date DATE COMMENT 'Date the member disenrolled from the program.',
  enrollment_date DATE COMMENT 'Date the member enrolled in the program.',
  enrollment_status STRING COMMENT 'Current enrollment status of the member.',
  member_copay_enrollment_id BIGINT NOT NULL COMMENT 'Surrogate primary key for member copay enrollment.',
  member_id BIGINT COMMENT 'ADD column program.member_copay_enrollment.member_id (BIGINT) as FK to company.member.member_id. ADD column program.member_copay_enrollment.member_id (BIGINT) FK to company.member.member_id.',
  remaining_annual_benefit DECIMAL(10,2) COMMENT 'Remaining annual benefit available to the member.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when the record was last updated.',
  ytd_fills_assisted BIGINT COMMENT 'Year-to-date count of fills assisted by the program.',
  ytd_manufacturer_paid DECIMAL(10,2) COMMENT 'Year-to-date amount paid by the manufacturer on the member''s behalf.',
  CONSTRAINT pk_member_copay_enrollment PRIMARY KEY (member_copay_enrollment_id)
)
COMMENT 'Member enrollment records in copay assistance programs with year-to-date manufacturer paid amounts and remaining benefit.'
;

CREATE TABLE IF NOT EXISTS pillarrx.program.patient_assistance_program (
  application_required BOOLEAN COMMENT 'Indicates whether a formal application is required.',
  bridge_supply_days BIGINT COMMENT 'Number of days of bridge drug supply the program provides.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the record was created.',
  gpi14 STRING COMMENT '14-digit Generic Product Identifier for the targeted drug.',
  income_threshold_fpl_pct BIGINT COMMENT 'Income eligibility threshold as a percentage of the Federal Poverty Level.',
  insurance_status_required STRING COMMENT 'Insurance status required for eligibility.',
  manufacturer_id BIGINT COMMENT 'ADD column program.patient_assistance_program.manufacturer_id (BIGINT) as FK to drug.manufacturer.manufacturer_id. ADD column program.patient_assistance_program.manufacturer_id (BIGINT) FK to drug.manufacturer.manufacturer_id.',
  ndc_id BIGINT COMMENT 'Reference to drug.ndc.ndc_id.',
  patient_assistance_program_id BIGINT NOT NULL COMMENT 'Surrogate primary key for patient assistance program.',
  program_covers STRING COMMENT 'Portion of cost the program covers.',
  program_expiration_date DATE COMMENT 'Date the program expires.',
  program_start_date DATE COMMENT 'Date the program becomes effective.',
  savings_program_id BIGINT COMMENT 'Foreign key to the parent savings program.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when the record was last updated.',
  CONSTRAINT pk_patient_assistance_program PRIMARY KEY (patient_assistance_program_id)
)
COMMENT 'Manufacturer free-drug and bridge-supply programs with income thresholds and insurance status requirements.'
;

CREATE TABLE IF NOT EXISTS pillarrx.program.program_type (
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the record was created.',
  display_order BIGINT COMMENT 'Ordinal used to sort program types for display.',
  program_category STRING COMMENT 'Business category of the savings program.',
  program_category_description STRING COMMENT 'Narrative description of the program category.',
  program_type_code STRING COMMENT 'Unique natural key code identifying the savings program type.',
  program_type_id BIGINT NOT NULL COMMENT 'Surrogate primary key for program type.',
  program_type_name STRING COMMENT 'Human-readable name of the savings program type.',
  reduces_member_oop BOOLEAN COMMENT 'Indicates whether this program reduces member out-of-pocket cost.',
  reduces_plan_cost BOOLEAN COMMENT 'Indicates whether this program reduces plan sponsor cost.',
  savings_program_id BIGINT COMMENT 'Reference to program.savings_program.savings_program_id.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when the record was last updated.',
  CONSTRAINT pk_program_type PRIMARY KEY (program_type_id)
)
COMMENT 'Reference table classifying savings programs into business categories such as manufacturer rebate, patient assistance, and accumulator or maximizer arrangements.'
;

CREATE TABLE IF NOT EXISTS pillarrx.program.rebate_contract (
  client_id BIGINT COMMENT 'ADD column program.rebate_contract.client_id (BIGINT) as FK to client.employer.employer_id. ADD column program.rebate_contract.client_id (BIGINT) FK to client.employer.employer_id.',
  contract_end_date DATE COMMENT 'Date the rebate contract ends.',
  contract_start_date DATE COMMENT 'Date the rebate contract begins.',
  contract_status STRING COMMENT 'Current status of the contract.',
  contract_type STRING COMMENT 'Type of rebate contract arrangement.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the record was created.',
  division_id BIGINT COMMENT 'ADD column program.rebate_contract.division_id (BIGINT) as nullable FK to division.division.division_id (null means client-wide contract). ADD column program.rebate_contract.division_id (BIGINT) FK to division.division.division_id. Nullable',
  effective_end_date DATE COMMENT 'End date of the record''s effective period for Type-2 history.',
  effective_start_date DATE COMMENT 'Start date of the record''s effective period for Type-2 history.',
  guaranteed_brand_effective_rate DECIMAL(8,4) COMMENT 'Guaranteed brand effective rebate rate.',
  guaranteed_generic_effective_rate DECIMAL(8,4) COMMENT 'Guaranteed generic effective rebate rate.',
  is_current BOOLEAN COMMENT 'Indicates whether this is the current version of the record.',
  manufacturer_id BIGINT COMMENT 'ADD column program.rebate_contract.manufacturer_id (BIGINT) as nullable FK to drug.manufacturer.manufacturer_id (nullable for aggregator contracts). ADD column program.rebate_contract.manufacturer_id (BIGINT) FK to drug.manufacturer.manufac',
  pass_through_pct DECIMAL(5,2) COMMENT 'Percentage of rebate value passed through to the plan sponsor.',
  pbm_assignment_id BIGINT COMMENT 'ADD column program.rebate_contract.pbm_assignment_id (BIGINT) as FK to client.pbm_assignment.pbm_assignment_id. ADD column program.rebate_contract.pbm_assignment_id (BIGINT) FK to client.pbm_assignment.pbm_assignment_id.',
  rebate_aggregator_name STRING COMMENT 'Name of the rebate aggregator managing the contract.',
  rebate_contract_id BIGINT NOT NULL COMMENT 'Surrogate primary key for rebate contract.',
  savings_program_id BIGINT COMMENT 'Foreign key to the parent savings program.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when the record was last updated.',
  CONSTRAINT pk_rebate_contract PRIMARY KEY (rebate_contract_id)
)
COMMENT 'Rebate contract terms negotiated with manufacturers or aggregators, including guaranteed effective rates and pass-through percentages.'
;

CREATE TABLE IF NOT EXISTS pillarrx.program.rebate_payment (
  actual_brand_effective_rate DECIMAL(8,4) COMMENT 'Actual realized brand effective rebate rate.',
  actual_generic_effective_rate DECIMAL(8,4) COMMENT 'Actual realized generic effective rebate rate.',
  admin_fee_amount DECIMAL(14,2) COMMENT 'Administrative fee deducted from the gross rebate.',
  brand_rebate_amount DECIMAL(14,2) COMMENT 'Portion of the rebate attributable to brand drugs.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the record was created.',
  eligible_claim_count BIGINT COMMENT 'Count of claims eligible for the rebate payment.',
  generic_rebate_amount DECIMAL(14,2) COMMENT 'Portion of the rebate attributable to generic drugs.',
  gross_rebate_amount DECIMAL(14,2) COMMENT 'Gross rebate amount before admin fees.',
  net_rebate_amount DECIMAL(14,2) COMMENT 'Net rebate amount after admin fees.',
  payment_period_end DATE COMMENT 'End date of the rebate payment period.',
  payment_period_start DATE COMMENT 'Start date of the rebate payment period.',
  payment_received_date DATE COMMENT 'Date the rebate payment was received.',
  rebate_contract_id BIGINT COMMENT 'Foreign key to the parent rebate contract.',
  rebate_payment_id BIGINT NOT NULL COMMENT 'Surrogate primary key for rebate payment.',
  rebate_per_claim DECIMAL(10,4) COMMENT 'Rebate amount allocated per eligible claim.',
  reconciliation_status STRING COMMENT 'Reconciliation status of the rebate payment.',
  specialty_rebate_amount DECIMAL(14,2) COMMENT 'Portion of the rebate attributable to specialty drugs.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when the record was last updated.',
  CONSTRAINT pk_rebate_payment PRIMARY KEY (rebate_payment_id)
)
COMMENT 'Actual rebate payments received per contract per period, with gross, admin fee, and net amounts and reconciliation status.'
;

CREATE TABLE IF NOT EXISTS pillarrx.program.savings_program (
  anti_kickback_restricted BOOLEAN COMMENT 'Indicates whether the program is restricted under anti-kickback rules.',
  applicable_market_segment STRING COMMENT 'Market segment the program applies to.',
  created_timestamp TIMESTAMP COMMENT 'Timestamp when the record was created.',
  external_program_code STRING COMMENT 'Identifier for the program in an external source system.',
  program_description STRING COMMENT 'Narrative description of the program.',
  program_name STRING COMMENT 'Name of the savings program.',
  program_status STRING COMMENT 'Current lifecycle status of the program.',
  program_subtype STRING COMMENT 'Finer-grained subtype classification of the program.',
  savings_program_id BIGINT NOT NULL COMMENT 'Surrogate primary key for savings program.',
  sponsor_name STRING COMMENT 'Name of the sponsoring entity.',
  sponsor_type STRING COMMENT 'Type of entity sponsoring the program.',
  updated_timestamp TIMESTAMP COMMENT 'Timestamp when the record was last updated.',
  CONSTRAINT pk_savings_program PRIMARY KEY (savings_program_id)
)
COMMENT 'Master registry of all cost-saving and cost-sharing programs that reduce drug costs for members, plan sponsors, or both.'
;

-- ---------------------------------------------------------------------------
-- Schema: reference
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS pillarrx.reference.external_source_load (
  effective_end_date DATE COMMENT 'Date this version of the record ceased to be effective (Type-2 SCD end).',
  effective_start_date DATE COMMENT 'Date this version of the record became effective (Type-2 SCD start).',
  etl_process_name STRING COMMENT 'ETL process name matching the DLH inventory (e.g., Load_Acq_External_FDB_ALL_ALL_ALL).',
  external_source_load_id BIGINT NOT NULL COMMENT 'Primary key for external_source_load',
  file_effective_date DATE COMMENT 'Effective date of the data in the file.',
  file_received_date DATE COMMENT 'Date the file was received.',
  is_current BOOLEAN COMMENT 'Flag indicating whether this is the current active version of the record (Type-2 SCD).',
  load_status STRING COMMENT 'Load status (success/partial/failed).',
  loaded_timestamp TIMESTAMP COMMENT 'Timestamp when the file was loaded.',
  medispan_drug_id BIGINT COMMENT 'Reference to reference.medispan_drug.medispan_drug_id.',
  record_count BIGINT COMMENT 'Number of records in the file.',
  source_file_name STRING COMMENT 'Name of the loaded source file.',
  source_load_code BIGINT COMMENT 'Surrogate primary key for the source load record.',
  source_load_date DATE COMMENT 'Date on which this record was loaded from the external source feed.',
  source_load_id BIGINT COMMENT 'Surrogate PK for the source file load.',
  source_name STRING COMMENT 'Source feed name (FIRSTDATABANK/MEDISPAN/NCPDP/NPPES/NUCC).',
  CONSTRAINT pk_external_source_load PRIMARY KEY (external_source_load_id)
)
COMMENT 'Audit trail for MAC External reference data file ingestion. One row per source file load.'
;

CREATE TABLE IF NOT EXISTS pillarrx.reference.fdb_drug (
  ahfs_code STRING COMMENT 'AHFS Pharmacologic-Therapeutic classification code.',
  desi_code STRING COMMENT 'Drug Efficacy Study Implementation rating.',
  effective_end_date DATE COMMENT 'Type-2 SCD effective end date for this version of the record.',
  effective_start_date DATE COMMENT 'Type-2 SCD effective start date for this version of the record.',
  fdb_drug_code STRING COMMENT 'FDB internal drug code (natural key).',
  fdb_drug_id BIGINT NOT NULL COMMENT 'Surrogate primary key for the FDB drug record.',
  fdb_obsolete_date DATE COMMENT 'Date the drug was marked obsolete by FDB.',
  fdb_pregnancy_category STRING COMMENT 'FDB pregnancy category.',
  fdb_therapeutic_class_code STRING COMMENT 'FDB therapeutic class code.',
  fdb_therapeutic_class_description STRING COMMENT 'FDB therapeutic class description.',
  hic3_code STRING COMMENT 'Hierarchic Ingredient Code level 3.',
  hic3_description STRING COMMENT 'Description of the HIC3 ingredient group.',
  hicl_seqno STRING COMMENT 'HIC Labeler sequence number.',
  is_current BOOLEAN COMMENT 'True when this is the current active version of the record.',
  ndc11 STRING COMMENT '11-digit NDC.',
  ndc_code STRING COMMENT '11-digit FDA National Drug Code. Natural key for drug identification; not an FK.',
  ndc_id BIGINT COMMENT 'Add column ndc_id (BIGINT, FK to drug.ndc.ndc_id) to reference.fdb_drug. ndc_id (BIGINT, FK to drug.ndc.ndc_id)',
  routed_dosage_form_code STRING COMMENT 'FDB routed dosage form code.',
  routed_generic_drug_name STRING COMMENT 'Routed generic drug name.',
  source_file_name STRING COMMENT 'Name of the source file this record was ingested from.',
  source_load_date DATE COMMENT 'Date the source file was loaded into the platform.',
  strength_description STRING COMMENT 'Drug strength description.',
  CONSTRAINT pk_fdb_drug PRIMARY KEY (fdb_drug_id)
)
COMMENT 'Authoritative FDB drug identifiers and classification cross-references sourced from the First DataBank NDDF Plus feed (source FIRSTDATABANK, ftp.fdbhealth.com). Supports dual-source drug validation alongside Medi-Span.'
;

CREATE TABLE IF NOT EXISTS pillarrx.reference.fdb_drug_interaction (
  clinical_effect_description STRING COMMENT 'Description of the clinical effect of the interaction.',
  documentation_level STRING COMMENT 'Documentation level (established/probable/suspected/possible/unlikely).',
  drug_1_fdb_drug_code STRING COMMENT 'FDB drug code for the first interacting drug.',
  drug_1_ndc11 STRING COMMENT '11-digit NDC for the first interacting drug.',
  drug_2_fdb_drug_code STRING COMMENT 'FDB drug code for the second interacting drug.',
  drug_2_ndc11 STRING COMMENT '11-digit NDC for the second interacting drug.',
  effective_end_date DATE COMMENT 'Type-2 SCD effective end date for this version of the record.',
  effective_start_date DATE COMMENT 'Type-2 SCD effective start date for this version of the record.',
  fdb_drug_id BIGINT COMMENT 'Reference to reference.fdb_drug.fdb_drug_id.',
  fdb_drug_interaction_id BIGINT NOT NULL COMMENT 'Primary key for fdb_drug_interaction',
  fdb_interaction_code BIGINT COMMENT 'Surrogate primary key for the FDB interaction record.',
  fdb_interaction_id BIGINT COMMENT 'Surrogate PK for the FDB interaction pair.',
  interaction_class_code STRING COMMENT 'FDB interaction class code.',
  interaction_severity STRING COMMENT 'Interaction severity (major/moderate/minor).',
  is_current BOOLEAN COMMENT 'True when this is the current active version of the record.',
  management_description STRING COMMENT 'Recommended clinical management of the interaction.',
  onset_description STRING COMMENT 'Onset of the interaction (rapid/delayed/not specified).',
  source_file_name STRING COMMENT 'Name of the source file this record was ingested from.',
  source_load_date DATE COMMENT 'Date the source file was loaded into the platform.',
  CONSTRAINT pk_fdb_drug_interaction PRIMARY KEY (fdb_drug_interaction_id)
)
COMMENT 'FDB drug-drug interaction pairs from the FDB Drug Interactions module (source FIRSTDATABANK, ftp.fdbhealth.com), used in DUR alerting and clinical decision support for PBM prior authorization workflows.'
;

CREATE TABLE IF NOT EXISTS pillarrx.reference.fdb_pricing (
  awp_package_price DECIMAL(12,4) COMMENT 'Average Wholesale Price per package.',
  awp_unit_price DECIMAL(12,4) COMMENT 'Average Wholesale Price per unit.',
  effective_end_date DATE COMMENT 'Type-2 SCD effective end date for this version of the record.',
  effective_start_date DATE COMMENT 'Type-2 SCD effective start date for this version of the record.',
  fdb_drug_id BIGINT COMMENT 'Reference to reference.fdb_drug.fdb_drug_id.',
  fdb_pricing_id BIGINT NOT NULL COMMENT 'Surrogate primary key for the FDB pricing record.',
  federal_upper_limit_price DECIMAL(12,4) COMMENT 'Federal Upper Limit price.',
  is_current BOOLEAN COMMENT 'True when this is the current active version of the record.',
  ndc11 STRING COMMENT '11-digit NDC.',
  ndc_id BIGINT COMMENT 'FK to drug.ndc.ndc_id.',
  package_size DECIMAL(10,4) COMMENT 'Package size quantity.',
  package_size_unit STRING COMMENT 'Unit of the package size.',
  pricing_effective_date DATE COMMENT 'Effective date of the pricing record.',
  source_file_name STRING COMMENT 'Name of the source file this record was ingested from.',
  source_load_date DATE COMMENT 'Date the source file was loaded into the platform.',
  unit_dose_indicator BOOLEAN COMMENT 'True if the package is unit-dose.',
  wac_package_price DECIMAL(12,4) COMMENT 'Wholesale Acquisition Cost per package.',
  wac_unit_price DECIMAL(12,4) COMMENT 'Wholesale Acquisition Cost per unit.',
  CONSTRAINT pk_fdb_pricing PRIMARY KEY (fdb_pricing_id)
)
COMMENT 'FDB-sourced AWP and WAC drug pricing benchmarks at the NDC level (source FIRSTDATABANK, ftp.fdbhealth.com). Feeds drug.ndc_price alongside Medi-Span pricing for dual-source validation and audit.'
;

CREATE TABLE IF NOT EXISTS pillarrx.reference.medispan_drug (
  dea_schedule STRING COMMENT 'DEA controlled substance schedule.',
  dosage_form STRING COMMENT 'Dosage form.',
  drug_name STRING COMMENT 'Full drug name.',
  effective_end_date DATE COMMENT 'Type-2 SCD effective end date for this version of the record.',
  effective_start_date DATE COMMENT 'Type-2 SCD effective start date for this version of the record.',
  generic_name STRING COMMENT 'Generic (non-proprietary) name.',
  gpi10_name_extension STRING COMMENT 'GPI level 10 name extension.',
  gpi12_dosage_form STRING COMMENT 'GPI level 12 dosage form.',
  gpi14 STRING COMMENT '14-digit Generic Product Identifier.',
  gpi14_strength STRING COMMENT 'GPI level 14 strength.',
  gpi2_drug_group STRING COMMENT 'GPI level 2 drug group.',
  gpi4_drug_class STRING COMMENT 'GPI level 4 drug class.',
  gpi6_drug_subclass STRING COMMENT 'GPI level 6 drug subclass.',
  gpi8_drug_name STRING COMMENT 'GPI level 8 drug name.',
  innovator_code STRING COMMENT 'Innovator (brand originator) code.',
  is_current BOOLEAN COMMENT 'True when this is the current active version of the record.',
  labeler_name STRING COMMENT 'Labeler or manufacturer name.',
  medispan_drug_code STRING COMMENT 'Medi-Span drug code (natural key).',
  medispan_drug_id BIGINT NOT NULL COMMENT 'Surrogate primary key for the Medi-Span drug record.',
  multisource_code STRING COMMENT 'Multisource code (M/O/N/Y).',
  ndc11 STRING COMMENT '11-digit NDC.',
  ndc_id BIGINT COMMENT 'FK to drug.ndc.ndc_id.',
  obsolete_date DATE COMMENT 'Date the drug was marked obsolete.',
  route_of_administration STRING COMMENT 'Route of administration.',
  source_file_name STRING COMMENT 'Name of the source file this record was ingested from.',
  source_load_date DATE COMMENT 'Date the source file was loaded into the platform.',
  CONSTRAINT pk_medispan_drug PRIMARY KEY (medispan_drug_id)
)
COMMENT 'Authoritative Medi-Span Master Drug Database (MDDB) drug reference record with full GPI hierarchy decomposition (source MEDISPAN, sftp.na.wolterskluwer.com). Primary source for therapeutic class analysis and GDR reporting.'
;

CREATE TABLE IF NOT EXISTS pillarrx.reference.medispan_gpi_hierarchy (
  effective_end_date DATE COMMENT 'Type-2 SCD effective end date for this version of the record.',
  effective_start_date DATE COMMENT 'Type-2 SCD effective start date for this version of the record.',
  gpi_code STRING COMMENT 'GPI code at this level.',
  gpi_description STRING COMMENT 'Description of the GPI code at this level.',
  gpi_hierarchy_code BIGINT COMMENT 'Surrogate primary key for the GPI hierarchy node.',
  gpi_hierarchy_id BIGINT COMMENT 'Surrogate primary key for the Medi-Span GPI classification hierarchy record.',
  gpi_level INT COMMENT 'GPI level (2/4/6/8/10/12/14).',
  gpi_level_name STRING COMMENT 'Name of the GPI level (drug_group/drug_class/drug_subclass/drug_name/name_extension/dosage_form/strength).',
  is_current BOOLEAN COMMENT 'True when this is the current active version of the record.',
  medispan_gpi_hierarchy_id BIGINT NOT NULL COMMENT 'Primary key for medispan_gpi_hierarchy',
  medispan_pricing_id BIGINT COMMENT 'Reference to reference.medispan_pricing.medispan_pricing_id.',
  parent_gpi_code STRING COMMENT 'GPI code of the parent level for self-join traversal.',
  source_file_name STRING COMMENT 'Name of the source file this record was ingested from.',
  source_load_date DATE COMMENT 'Date the source file was loaded into the platform.',
  CONSTRAINT pk_medispan_gpi_hierarchy PRIMARY KEY (medispan_gpi_hierarchy_id)
)
COMMENT 'Standalone GPI hierarchy for therapeutic class rollups and benchmarking. Enables self-join traversal from GPI-14 to GPI-2 drug group without denormalization.'
;

CREATE TABLE IF NOT EXISTS pillarrx.reference.medispan_pricing (
  awp_package_price DECIMAL(12,4) COMMENT 'Average Wholesale Price per package.',
  awp_unit_price DECIMAL(12,4) COMMENT 'Average Wholesale Price per unit.',
  effective_end_date DATE COMMENT 'Type-2 SCD effective end date for this version of the record.',
  effective_start_date DATE COMMENT 'Type-2 SCD effective start date for this version of the record.',
  federal_upper_limit_price DECIMAL(12,4) COMMENT 'Federal Upper Limit price.',
  is_current BOOLEAN COMMENT 'True when this is the current active version of the record.',
  medispan_drug_code STRING COMMENT 'Medi-Span drug code.',
  medispan_pricing_id BIGINT NOT NULL COMMENT 'Surrogate primary key for the Medi-Span pricing record.',
  ndc11 STRING COMMENT '11-digit NDC.',
  package_size DECIMAL(10,4) COMMENT 'Package size quantity.',
  package_size_unit STRING COMMENT 'Unit of the package size.',
  pricing_effective_date DATE COMMENT 'Effective date of the pricing record.',
  repackager_indicator BOOLEAN COMMENT 'True if the pricing is for a repackaged product.',
  source_file_name STRING COMMENT 'Name of the source file this record was ingested from.',
  source_load_date DATE COMMENT 'Date the source file was loaded into the platform.',
  unit_dose_indicator BOOLEAN COMMENT 'True if the package is unit-dose.',
  wac_package_price DECIMAL(12,4) COMMENT 'Wholesale Acquisition Cost per package.',
  wac_unit_price DECIMAL(12,4) COMMENT 'Wholesale Acquisition Cost per unit.',
  CONSTRAINT pk_medispan_pricing PRIMARY KEY (medispan_pricing_id)
)
COMMENT 'Medi-Span-sourced drug pricing benchmarks. Feeds drug.ndc_price alongside FDB pricing for dual-source validation.'
;

CREATE TABLE IF NOT EXISTS pillarrx.reference.ncpdp_dispensing_class (
  dispensing_class_code STRING COMMENT 'Surrogate primary key for the dispensing class record.',
  dispensing_class_description STRING COMMENT 'Description of the dispensing class (e.g., community/retail, institutional, mail order, long-term care, home infusion, specialty, nuclear, compounding, government).',
  dispensing_class_id BIGINT COMMENT 'Surrogate primary key for this reference table.',
  effective_end_date DATE COMMENT 'Type-2 SCD effective end date for this version of the record.',
  effective_start_date DATE COMMENT 'Type-2 SCD effective start date for this version of the record.',
  is_current BOOLEAN COMMENT 'True when this is the current active version of the record.',
  ncpdp_dispensing_class_id BIGINT NOT NULL COMMENT 'Primary key for ncpdp_dispensing_class',
  source_file_name STRING COMMENT 'Name of the source file this record was ingested from.',
  source_load_date DATE COMMENT 'Date the source file was loaded into the platform.',
  CONSTRAINT pk_ncpdp_dispensing_class PRIMARY KEY (ncpdp_dispensing_class_id)
)
COMMENT 'NCPDP dispensing class code set defining pharmacy channel types for network analysis.'
;

CREATE TABLE IF NOT EXISTS pillarrx.reference.ncpdp_pharmacy (
  address_line1 STRING COMMENT 'Primary street address line.',
  address_line2 STRING COMMENT 'Secondary street address line.',
  chain_code STRING COMMENT 'Chain organization code.',
  chain_name STRING COMMENT 'Chain organization name.',
  city STRING COMMENT 'City.',
  dba_name STRING COMMENT 'Doing-business-as name.',
  dea_number STRING COMMENT 'DEA registration number.',
  deactivation_date DATE COMMENT 'Date the pharmacy was deactivated.',
  dispensing_class_id BIGINT COMMENT 'FK to reference.ncpdp_dispensing_class.dispensing_class_code.',
  effective_end_date DATE COMMENT 'Type-2 SCD effective end date for this version of the record.',
  effective_start_date DATE COMMENT 'Type-2 SCD effective start date for this version of the record.',
  fax STRING COMMENT 'Fax number.',
  is_current BOOLEAN COMMENT 'True when this is the current active version of the record.',
  last_modified_date DATE COMMENT 'Date the record was last modified in NCPDP.',
  ncpdp_number STRING COMMENT '7-digit NCPDP provider ID (natural key).',
  ncpdp_pharmacy_id BIGINT NOT NULL COMMENT 'Surrogate primary key for the NCPDP pharmacy record.',
  ncpdp_status STRING COMMENT 'NCPDP status (active/inactive/closed).',
  npi STRING COMMENT '10-digit NPI of the pharmacy.',
  pharmacy_name STRING COMMENT 'Legal pharmacy name.',
  pharmacy_type_code STRING COMMENT 'NCPDP pharmacy type code.',
  phone STRING COMMENT 'Phone number.',
  source_file_name STRING COMMENT 'Name of the source file this record was ingested from.',
  source_load_date DATE COMMENT 'Date the source file was loaded into the platform.',
  state_code STRING COMMENT 'State code.',
  store_number STRING COMMENT 'Store number within a chain.',
  zip_code STRING COMMENT 'ZIP code.',
  CONSTRAINT pk_ncpdp_pharmacy PRIMARY KEY (ncpdp_pharmacy_id),
  CONSTRAINT uq_ncpdp_pharmacy_ncpdp_number UNIQUE (ncpdp_number)
)
COMMENT 'NCPDP pharmacy provider records from the NCPDP Provider Database file. SSOT for pharmacy identification by NCPDP number. Feeds drug.pharmacy in the Silver layer.'
;

CREATE TABLE IF NOT EXISTS pillarrx.reference.ncpdp_pharmacy_service (
  effective_end_date DATE COMMENT 'Type-2 SCD effective end date for this version of the record.',
  effective_start_date DATE COMMENT 'Type-2 SCD effective start date for this version of the record.',
  is_current BOOLEAN COMMENT 'True when this is the current active version of the record.',
  ncpdp_number STRING COMMENT 'FK to reference.ncpdp_pharmacy via ncpdp_number.',
  ncpdp_pharmacy_service_id BIGINT NOT NULL COMMENT 'Primary key for ncpdp_pharmacy_service',
  pharmacy_service_code BIGINT COMMENT 'Surrogate primary key for the pharmacy service record.',
  pharmacy_service_id BIGINT COMMENT 'Surrogate primary key for this reference table.',
  service_type_code STRING COMMENT 'NCPDP service type code.',
  service_type_description STRING COMMENT 'Description of the service type (e.g., 24-hour, drive-through, compounding, delivery, DME, e-prescribing, immunizations, specialty).',
  source_file_name STRING COMMENT 'Name of the source file this record was ingested from.',
  source_load_date DATE COMMENT 'Date the source file was loaded into the platform.',
  CONSTRAINT pk_ncpdp_pharmacy_service PRIMARY KEY (ncpdp_pharmacy_service_id)
)
COMMENT 'NCPDP pharmacy service capabilities. One-to-many from ncpdp_pharmacy - a pharmacy can offer multiple service types.'
;

CREATE TABLE IF NOT EXISTS pillarrx.reference.nppes_other_identifier (
  effective_end_date DATE COMMENT 'Type-2 SCD effective end date for this version of the record.',
  effective_start_date DATE COMMENT 'Type-2 SCD effective start date for this version of the record.',
  identifier_issuer STRING COMMENT 'Issuer of the identifier.',
  identifier_state STRING COMMENT 'State associated with the identifier.',
  identifier_type_code STRING COMMENT 'Type of alternate identifier (e.g., Medicaid, Medicare UPIN, state license).',
  identifier_value STRING COMMENT 'Value of the alternate identifier.',
  is_current BOOLEAN COMMENT 'True when this is the current active version of the record.',
  npi STRING COMMENT 'FK to reference.nppes_provider via npi.',
  nppes_other_id_code BIGINT COMMENT 'Surrogate primary key for the other identifier record.',
  nppes_other_id_id BIGINT COMMENT 'Surrogate primary key for this reference table.',
  nppes_other_identifier_id BIGINT NOT NULL COMMENT 'Primary key for nppes_other_identifier',
  source_file_name STRING COMMENT 'Name of the source file this record was ingested from.',
  source_load_date DATE COMMENT 'Date the source file was loaded into the platform.',
  CONSTRAINT pk_nppes_other_identifier PRIMARY KEY (nppes_other_identifier_id)
)
COMMENT 'Alternate provider identifiers reported in NPPES beyond the NPI itself. Supports cross-system provider matching.'
;

CREATE TABLE IF NOT EXISTS pillarrx.reference.nppes_provider (
  deactivation_date DATE COMMENT 'Date the NPI was deactivated.',
  effective_end_date DATE COMMENT 'Type-2 SCD effective end date for this version of the record.',
  effective_start_date DATE COMMENT 'Type-2 SCD effective start date for this version of the record.',
  entity_type_code STRING COMMENT 'Entity type code (1=individual, 2=organization).',
  enumeration_date DATE COMMENT 'Date the NPI was enumerated.',
  gender STRING COMMENT 'Provider gender (M/F/U).',
  is_current BOOLEAN COMMENT 'True when this is the current active version of the record.',
  is_organization_subpart BOOLEAN COMMENT 'True if the organization is a subpart.',
  last_update_date DATE COMMENT 'Date the NPPES record was last updated.',
  mailing_address_line1 STRING COMMENT 'Mailing address line 1.',
  mailing_address_line2 STRING COMMENT 'Mailing address line 2.',
  mailing_city STRING COMMENT 'Mailing city.',
  mailing_state STRING COMMENT 'Mailing state.',
  mailing_zip STRING COMMENT 'Mailing ZIP code.',
  npi STRING COMMENT '10-digit NPI (natural key).',
  npi_status STRING COMMENT 'NPI status (active/deactivated).',
  nppes_provider_id BIGINT NOT NULL COMMENT 'Surrogate primary key for the NPPES provider record.',
  parent_organization_lbn STRING COMMENT 'Parent organization legal business name.',
  parent_organization_tin STRING COMMENT 'Parent organization TIN.',
  practice_address_line1 STRING COMMENT 'Practice address line 1.',
  practice_address_line2 STRING COMMENT 'Practice address line 2.',
  practice_city STRING COMMENT 'Practice city.',
  practice_fax STRING COMMENT 'Practice fax number.',
  practice_phone STRING COMMENT 'Practice phone number.',
  practice_state STRING COMMENT 'Practice state.',
  practice_zip STRING COMMENT 'Practice ZIP code.',
  provider_credential STRING COMMENT 'Provider credential.',
  provider_first_name STRING COMMENT 'Provider first name.',
  provider_last_name STRING COMMENT 'Provider last name.',
  provider_middle_name STRING COMMENT 'Provider middle name.',
  provider_name_prefix STRING COMMENT 'Provider name prefix.',
  provider_organization_name STRING COMMENT 'Organization legal business name.',
  reactivation_date DATE COMMENT 'Date the NPI was reactivated.',
  sole_proprietor STRING COMMENT 'Sole proprietor indicator.',
  source_file_name STRING COMMENT 'Name of the source file this record was ingested from.',
  source_load_date DATE COMMENT 'Date the source file was loaded into the platform.',
  CONSTRAINT pk_nppes_provider PRIMARY KEY (nppes_provider_id),
  CONSTRAINT uq_nppes_provider_npi UNIQUE (npi)
)
COMMENT 'CMS NPPES NPI registry records. SSOT for provider identity by NPI. Feeds drug.drug_prescriber in the Silver layer.'
;

CREATE TABLE IF NOT EXISTS pillarrx.reference.nppes_provider_taxonomy (
  effective_end_date DATE COMMENT 'Type-2 SCD effective end date for this version of the record.',
  effective_start_date DATE COMMENT 'Type-2 SCD effective start date for this version of the record.',
  is_current BOOLEAN COMMENT 'True when this is the current active version of the record.',
  is_primary BOOLEAN COMMENT 'True if this is the provider''s primary taxonomy assignment.',
  license_number STRING COMMENT 'Provider license number for this taxonomy.',
  license_state STRING COMMENT 'State issuing the provider license.',
  npi STRING COMMENT 'FK to reference.nppes_provider via npi.',
  nppes_provider_taxonomy_id BIGINT NOT NULL COMMENT 'Primary key for nppes_provider_taxonomy',
  nppes_taxonomy_assignment_code STRING COMMENT 'Surrogate primary key for the taxonomy assignment.',
  nppes_taxonomy_assignment_id BIGINT COMMENT 'Surrogate PK for the taxonomy assignment.',
  source_file_name STRING COMMENT 'Name of the source file this record was ingested from.',
  source_load_date DATE COMMENT 'Date the source file was loaded into the platform.',
  taxonomy_code STRING COMMENT 'FK to reference.nucc_taxonomy via taxonomy_code.',
  CONSTRAINT pk_nppes_provider_taxonomy PRIMARY KEY (nppes_provider_taxonomy_id)
)
COMMENT 'Links an NPI to its NUCC taxonomy codes. A provider may hold multiple taxonomy assignments; is_primary marks the principal specialty.'
;

CREATE TABLE IF NOT EXISTS pillarrx.reference.nucc_taxonomy (
  classification STRING COMMENT 'Provider classification within the NUCC grouping (e.g., Internal Medicine). Represents the second level of the NUCC Health Care Provider Taxonomy hierarchy. Sourced from nucc.org taxonomy release file.',
  definition STRING COMMENT 'Full description of the taxonomy code.',
  effective_end_date DATE COMMENT 'Type-2 SCD effective end date for this version of the record.',
  effective_start_date DATE COMMENT 'Type-2 SCD effective start date for this version of the record.',
  grouping STRING COMMENT 'Top-level provider grouping label from the NUCC Health Care Provider Taxonomy code set (e.g., Allopathic & Osteopathic Physicians). Sourced from nucc.org taxonomy release file.',
  is_current BOOLEAN COMMENT 'True when this is the current active version of the record.',
  nucc_taxonomy_id BIGINT NOT NULL COMMENT 'Surrogate primary key for the NUCC taxonomy record.',
  source_file_name STRING COMMENT 'Name of the source file this record was ingested from.',
  source_load_date DATE COMMENT 'Date the source file was loaded into the platform.',
  specialization STRING COMMENT 'Sub-specialty within the NUCC classification (e.g., Cardiovascular Disease). Nullable — not all taxonomy codes carry a specialization. Represents the third level of the NUCC Health Care Provider Taxonomy hierarchy.',
  taxonomy_code STRING COMMENT 'NUCC taxonomy code (unique natural key, e.g., 207R00000X).',
  taxonomy_version STRING COMMENT 'NUCC taxonomy code set release version identifier (e.g., 23.1). Tracks which published NUCC release this row was sourced from, enabling version-aware taxonomy lookups and audit of code-set changes over time.',
  CONSTRAINT pk_nucc_taxonomy PRIMARY KEY (nucc_taxonomy_id),
  CONSTRAINT uq_nucc_taxonomy_taxonomy_code UNIQUE (taxonomy_code)
)
COMMENT 'NUCC Health Care Provider Taxonomy code set. Standalone reference for provider specialty classification. Referenced by reference.nppes_provider_taxonomy and by drug.drug_prescriber.taxonomy_code.'
;

-- =============================================================================
-- SECTION 3: FOREIGN KEY CONSTRAINTS
-- =============================================================================


-- claim schema FKs
ALTER TABLE pillarrx.claim.adjustment ADD CONSTRAINT fk_claim_adjustment_adjustment_original_rx_claim_id FOREIGN KEY (adjustment_original_rx_claim_id) REFERENCES pillarrx.claim.rx_claim (rx_claim_id);
ALTER TABLE pillarrx.claim.adjustment ADD CONSTRAINT fk_claim_adjustment_adjustment_rx_claim_id FOREIGN KEY (adjustment_rx_claim_id) REFERENCES pillarrx.claim.rx_claim (rx_claim_id);
ALTER TABLE pillarrx.claim.adjustment ADD CONSTRAINT fk_claim_adjustment_claim_benefit_group_id FOREIGN KEY (claim_benefit_group_id) REFERENCES pillarrx.claim.claim_benefit_group (claim_benefit_group_id);
ALTER TABLE pillarrx.claim.adjustment ADD CONSTRAINT fk_claim_adjustment_company_client_id FOREIGN KEY (company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.claim.adjustment ADD CONSTRAINT fk_claim_adjustment_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.claim.adjustment ADD CONSTRAINT fk_claim_adjustment_member_id FOREIGN KEY (member_id) REFERENCES pillarrx.company.member (member_id);
ALTER TABLE pillarrx.claim.adjustment ADD CONSTRAINT fk_claim_adjustment_pbm_assignment_id FOREIGN KEY (pbm_assignment_id) REFERENCES pillarrx.client.pbm_assignment (pbm_assignment_id);
ALTER TABLE pillarrx.claim.adjustment ADD CONSTRAINT fk_claim_adjustment_pbm_division_id FOREIGN KEY (pbm_division_id) REFERENCES pillarrx.division.division (division_id);
ALTER TABLE pillarrx.claim.adjustment ADD CONSTRAINT fk_claim_adjustment_pbm_feed_batch_id FOREIGN KEY (pbm_feed_batch_id) REFERENCES pillarrx.claim.pbm_feed_batch (pbm_feed_batch_id);
ALTER TABLE pillarrx.claim.adjustment ADD CONSTRAINT fk_claim_adjustment_primary_rx_claim_id FOREIGN KEY (primary_rx_claim_id) REFERENCES pillarrx.claim.rx_claim (rx_claim_id);
ALTER TABLE pillarrx.claim.adjustment ADD CONSTRAINT fk_claim_adjustment_to_rx_claim_id FOREIGN KEY (to_rx_claim_id) REFERENCES pillarrx.claim.rx_claim (rx_claim_id);
ALTER TABLE pillarrx.claim.claim_benefit_group ADD CONSTRAINT fk_claim_claim_benefit_group_client_benefit_group_id FOREIGN KEY (client_benefit_group_id) REFERENCES pillarrx.client.client_benefit_group (client_benefit_group_id);
ALTER TABLE pillarrx.claim.claim_benefit_group ADD CONSTRAINT fk_claim_claim_benefit_group_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.claim.claim_benefit_group ADD CONSTRAINT fk_claim_claim_benefit_group_division_benefit_group_id FOREIGN KEY (division_benefit_group_id) REFERENCES pillarrx.division.division_benefit_group (division_benefit_group_id);
ALTER TABLE pillarrx.claim.claim_benefit_group ADD CONSTRAINT fk_claim_claim_benefit_group_division_formulary_id FOREIGN KEY (division_formulary_id) REFERENCES pillarrx.division.division_formulary (division_formulary_id);
ALTER TABLE pillarrx.claim.claim_benefit_group ADD CONSTRAINT fk_claim_claim_benefit_group_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.claim.claim_prescriber ADD CONSTRAINT fk_claim_claim_prescriber_npi FOREIGN KEY (npi) REFERENCES pillarrx.reference.nppes_provider (npi);
ALTER TABLE pillarrx.claim.cob ADD CONSTRAINT fk_claim_cob_benefit_plan_id FOREIGN KEY (benefit_plan_id) REFERENCES pillarrx.client.benefit_plan (benefit_plan_id);
ALTER TABLE pillarrx.claim.cob ADD CONSTRAINT fk_claim_cob_company_client_id FOREIGN KEY (company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.claim.cob ADD CONSTRAINT fk_claim_cob_other_payer_company_pbm_id FOREIGN KEY (other_payer_company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.claim.cob ADD CONSTRAINT fk_claim_cob_pbm_division_id FOREIGN KEY (pbm_division_id) REFERENCES pillarrx.division.division (division_id);
ALTER TABLE pillarrx.claim.cob ADD CONSTRAINT fk_claim_cob_rx_claim_id FOREIGN KEY (rx_claim_id) REFERENCES pillarrx.claim.rx_claim (rx_claim_id);
ALTER TABLE pillarrx.claim.dur_event ADD CONSTRAINT fk_claim_dur_event_claim_prescriber_id FOREIGN KEY (claim_prescriber_id) REFERENCES pillarrx.claim.claim_prescriber (claim_prescriber_id);
ALTER TABLE pillarrx.claim.dur_event ADD CONSTRAINT fk_claim_dur_event_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.claim.dur_event ADD CONSTRAINT fk_claim_dur_event_dur_rx_claim_id FOREIGN KEY (dur_rx_claim_id) REFERENCES pillarrx.claim.rx_claim (rx_claim_id);
ALTER TABLE pillarrx.claim.dur_event ADD CONSTRAINT fk_claim_dur_event_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.claim.dur_event ADD CONSTRAINT fk_claim_dur_event_member_id FOREIGN KEY (member_id) REFERENCES pillarrx.company.member (member_id);
ALTER TABLE pillarrx.claim.dur_event ADD CONSTRAINT fk_claim_dur_event_ncpdp_id FOREIGN KEY (ncpdp_id) REFERENCES pillarrx.drug.pharmacy (ncpdp_id);  -- natural key FK
ALTER TABLE pillarrx.claim.dur_event ADD CONSTRAINT fk_claim_dur_event_pbm_assignment_id FOREIGN KEY (pbm_assignment_id) REFERENCES pillarrx.client.pbm_assignment (pbm_assignment_id);
ALTER TABLE pillarrx.claim.dur_event ADD CONSTRAINT fk_claim_dur_event_pbm_division_id FOREIGN KEY (pbm_division_id) REFERENCES pillarrx.division.division (division_id);
ALTER TABLE pillarrx.claim.dur_event ADD CONSTRAINT fk_claim_dur_event_pbm_feed_batch_id FOREIGN KEY (pbm_feed_batch_id) REFERENCES pillarrx.claim.pbm_feed_batch (pbm_feed_batch_id);
ALTER TABLE pillarrx.claim.dur_event ADD CONSTRAINT fk_claim_dur_event_prior_auth_id FOREIGN KEY (prior_auth_id) REFERENCES pillarrx.claim.prior_auth (prior_auth_id);
ALTER TABLE pillarrx.claim.dur_event ADD CONSTRAINT fk_claim_dur_event_rx_claim_id FOREIGN KEY (rx_claim_id) REFERENCES pillarrx.claim.rx_claim (rx_claim_id);
ALTER TABLE pillarrx.claim.dur_event ADD CONSTRAINT fk_claim_dur_event_to_rx_claim_id FOREIGN KEY (to_rx_claim_id) REFERENCES pillarrx.claim.rx_claim (rx_claim_id);
ALTER TABLE pillarrx.claim.medical_claim ADD CONSTRAINT fk_claim_medical_claim_benefit_plan_id FOREIGN KEY (benefit_plan_id) REFERENCES pillarrx.client.benefit_plan (benefit_plan_id);
ALTER TABLE pillarrx.claim.medical_claim ADD CONSTRAINT fk_claim_medical_claim_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.claim.medical_claim ADD CONSTRAINT fk_claim_medical_claim_member_id FOREIGN KEY (member_id) REFERENCES pillarrx.company.member (member_id);
ALTER TABLE pillarrx.claim.medical_claim ADD CONSTRAINT fk_claim_medical_claim_pbm_division_id FOREIGN KEY (pbm_division_id) REFERENCES pillarrx.division.division (division_id);
ALTER TABLE pillarrx.claim.member_oop_accumulator ADD CONSTRAINT fk_claim_member_oop_accumulator_accumulator_program_id FOREIGN KEY (accumulator_program_id) REFERENCES pillarrx.program.accumulator_program (accumulator_program_id);
ALTER TABLE pillarrx.claim.member_oop_accumulator ADD CONSTRAINT fk_claim_member_oop_accumulator_benefit_plan_id FOREIGN KEY (benefit_plan_id) REFERENCES pillarrx.client.benefit_plan (benefit_plan_id);
ALTER TABLE pillarrx.claim.member_oop_accumulator ADD CONSTRAINT fk_claim_member_oop_accumulator_claim_benefit_group_id FOREIGN KEY (claim_benefit_group_id) REFERENCES pillarrx.claim.claim_benefit_group (claim_benefit_group_id);
ALTER TABLE pillarrx.claim.member_oop_accumulator ADD CONSTRAINT fk_claim_member_oop_accumulator_company_client_id FOREIGN KEY (company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.claim.member_oop_accumulator ADD CONSTRAINT fk_claim_member_oop_accumulator_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.claim.member_oop_accumulator ADD CONSTRAINT fk_claim_member_oop_accumulator_member_id FOREIGN KEY (member_id) REFERENCES pillarrx.company.member (member_id);
ALTER TABLE pillarrx.claim.member_oop_accumulator ADD CONSTRAINT fk_claim_member_oop_accumulator_pbm_division_id FOREIGN KEY (pbm_division_id) REFERENCES pillarrx.division.division (division_id);
ALTER TABLE pillarrx.claim.member_oop_accumulator ADD CONSTRAINT fk_claim_member_oop_accumulator_program_savings_program_id FOREIGN KEY (program_savings_program_id) REFERENCES pillarrx.program.savings_program (savings_program_id);
ALTER TABLE pillarrx.claim.pbm_feed_batch ADD CONSTRAINT fk_claim_pbm_feed_batch_claim_pbm_id FOREIGN KEY (claim_pbm_id) REFERENCES pillarrx.claim.claim_pbm (claim_pbm_id);
ALTER TABLE pillarrx.claim.pbm_feed_batch ADD CONSTRAINT fk_claim_pbm_feed_batch_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.claim.pbm_feed_batch ADD CONSTRAINT fk_claim_pbm_feed_batch_original_batch_pbm_feed_batch_id FOREIGN KEY (original_batch_pbm_feed_batch_id) REFERENCES pillarrx.claim.pbm_feed_batch (pbm_feed_batch_id);
ALTER TABLE pillarrx.claim.pbm_feed_batch ADD CONSTRAINT fk_claim_pbm_feed_batch_pbm_batch_company_pbm_id FOREIGN KEY (pbm_batch_company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.claim.pbm_feed_batch ADD CONSTRAINT fk_claim_pbm_feed_batch_pbm_division_id FOREIGN KEY (pbm_division_id) REFERENCES pillarrx.division.division (division_id);
ALTER TABLE pillarrx.claim.pbm_feed_batch ADD CONSTRAINT fk_claim_pbm_feed_batch_pbm_sender_company_pbm_id FOREIGN KEY (pbm_sender_company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.claim.prior_auth ADD CONSTRAINT fk_claim_prior_auth_claim_prescriber_id FOREIGN KEY (claim_prescriber_id) REFERENCES pillarrx.claim.claim_prescriber (claim_prescriber_id);
ALTER TABLE pillarrx.claim.prior_auth ADD CONSTRAINT fk_claim_prior_auth_company_client_id FOREIGN KEY (company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.claim.prior_auth ADD CONSTRAINT fk_claim_prior_auth_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.claim.prior_auth ADD CONSTRAINT fk_claim_prior_auth_member_id FOREIGN KEY (member_id) REFERENCES pillarrx.company.member (member_id);
ALTER TABLE pillarrx.claim.prior_auth ADD CONSTRAINT fk_claim_prior_auth_pbm_assignment_id FOREIGN KEY (pbm_assignment_id) REFERENCES pillarrx.client.pbm_assignment (pbm_assignment_id);
ALTER TABLE pillarrx.claim.prior_auth ADD CONSTRAINT fk_claim_prior_auth_pbm_division_id FOREIGN KEY (pbm_division_id) REFERENCES pillarrx.division.division (division_id);
ALTER TABLE pillarrx.claim.prior_auth ADD CONSTRAINT fk_claim_prior_auth_prior_rx_claim_id FOREIGN KEY (prior_rx_claim_id) REFERENCES pillarrx.claim.rx_claim (rx_claim_id);
ALTER TABLE pillarrx.claim.prior_auth ADD CONSTRAINT fk_claim_prior_auth_rx_claim_id FOREIGN KEY (rx_claim_id) REFERENCES pillarrx.claim.rx_claim (rx_claim_id);
ALTER TABLE pillarrx.claim.prior_auth ADD CONSTRAINT fk_claim_prior_auth_to_rx_claim_id FOREIGN KEY (to_rx_claim_id) REFERENCES pillarrx.claim.rx_claim (rx_claim_id);
ALTER TABLE pillarrx.claim.rebate_record ADD CONSTRAINT fk_claim_rebate_record_claim_pbm_id FOREIGN KEY (claim_pbm_id) REFERENCES pillarrx.claim.claim_pbm (claim_pbm_id);
ALTER TABLE pillarrx.claim.rebate_record ADD CONSTRAINT fk_claim_rebate_record_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.claim.rebate_record ADD CONSTRAINT fk_claim_rebate_record_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.claim.rebate_record ADD CONSTRAINT fk_claim_rebate_record_pbm_assignment_id FOREIGN KEY (pbm_assignment_id) REFERENCES pillarrx.client.pbm_assignment (pbm_assignment_id);
ALTER TABLE pillarrx.claim.rebate_record ADD CONSTRAINT fk_claim_rebate_record_program_savings_program_id FOREIGN KEY (program_savings_program_id) REFERENCES pillarrx.program.savings_program (savings_program_id);
ALTER TABLE pillarrx.claim.rebate_record ADD CONSTRAINT fk_claim_rebate_record_rebate_contract_id FOREIGN KEY (rebate_contract_id) REFERENCES pillarrx.program.rebate_contract (rebate_contract_id);
ALTER TABLE pillarrx.claim.rebate_record ADD CONSTRAINT fk_claim_rebate_record_rebate_payment_id FOREIGN KEY (rebate_payment_id) REFERENCES pillarrx.program.rebate_payment (rebate_payment_id);
ALTER TABLE pillarrx.claim.rebate_record ADD CONSTRAINT fk_claim_rebate_record_rebate_rx_claim_id FOREIGN KEY (rebate_rx_claim_id) REFERENCES pillarrx.claim.rx_claim (rx_claim_id);
ALTER TABLE pillarrx.claim.rebate_record ADD CONSTRAINT fk_claim_rebate_record_to_rx_claim_id FOREIGN KEY (to_rx_claim_id) REFERENCES pillarrx.claim.rx_claim (rx_claim_id);
ALTER TABLE pillarrx.claim.rx_claim ADD CONSTRAINT fk_claim_rx_claim_claim_benefit_group_id FOREIGN KEY (claim_benefit_group_id) REFERENCES pillarrx.claim.claim_benefit_group (claim_benefit_group_id);
ALTER TABLE pillarrx.claim.rx_claim ADD CONSTRAINT fk_claim_rx_claim_claim_pbm_id FOREIGN KEY (claim_pbm_id) REFERENCES pillarrx.claim.claim_pbm (claim_pbm_id);
ALTER TABLE pillarrx.claim.rx_claim ADD CONSTRAINT fk_claim_rx_claim_claim_prescriber_id FOREIGN KEY (claim_prescriber_id) REFERENCES pillarrx.claim.claim_prescriber (claim_prescriber_id);
ALTER TABLE pillarrx.claim.rx_claim ADD CONSTRAINT fk_claim_rx_claim_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.claim.rx_claim ADD CONSTRAINT fk_claim_rx_claim_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.claim.rx_claim ADD CONSTRAINT fk_claim_rx_claim_member_id FOREIGN KEY (member_id) REFERENCES pillarrx.company.member (member_id);
ALTER TABLE pillarrx.claim.rx_claim ADD CONSTRAINT fk_claim_rx_claim_ncpdp_id FOREIGN KEY (ncpdp_id) REFERENCES pillarrx.drug.pharmacy (ncpdp_id);  -- natural key FK
ALTER TABLE pillarrx.claim.rx_claim ADD CONSTRAINT fk_claim_rx_claim_pbm_division_id FOREIGN KEY (pbm_division_id) REFERENCES pillarrx.division.division (division_id);
ALTER TABLE pillarrx.claim.rx_claim ADD CONSTRAINT fk_claim_rx_claim_rx_pbm_feed_batch_id FOREIGN KEY (rx_pbm_feed_batch_id) REFERENCES pillarrx.claim.pbm_feed_batch (pbm_feed_batch_id);
ALTER TABLE pillarrx.claim.rx_claim ADD CONSTRAINT fk_claim_rx_claim_source_pbm_feed_batch_id FOREIGN KEY (source_pbm_feed_batch_id) REFERENCES pillarrx.claim.pbm_feed_batch (pbm_feed_batch_id);
ALTER TABLE pillarrx.claim.rx_claim_line ADD CONSTRAINT fk_claim_rx_claim_line_primary_rx_claim_id FOREIGN KEY (primary_rx_claim_id) REFERENCES pillarrx.claim.rx_claim (rx_claim_id);
ALTER TABLE pillarrx.claim.rx_claim_line ADD CONSTRAINT fk_claim_rx_claim_line_to_rx_claim_id FOREIGN KEY (to_rx_claim_id) REFERENCES pillarrx.claim.rx_claim (rx_claim_id);

-- client schema FKs
ALTER TABLE pillarrx.client.audit_finding ADD CONSTRAINT fk_client_audit_finding_audit_client_consulting_engagement_id FOREIGN KEY (audit_client_consulting_engagement_id) REFERENCES pillarrx.client.client_consulting_engagement (client_consulting_engagement_id);
ALTER TABLE pillarrx.client.audit_finding ADD CONSTRAINT fk_client_audit_finding_audit_pbm_contract_id FOREIGN KEY (audit_pbm_contract_id) REFERENCES pillarrx.client.pbm_contract (pbm_contract_id);
ALTER TABLE pillarrx.client.audit_finding ADD CONSTRAINT fk_client_audit_finding_client_engagement_deliverable_id FOREIGN KEY (client_engagement_deliverable_id) REFERENCES pillarrx.client.client_engagement_deliverable (client_engagement_deliverable_id);
ALTER TABLE pillarrx.client.audit_finding ADD CONSTRAINT fk_client_audit_finding_client_pbm_contract_id FOREIGN KEY (client_pbm_contract_id) REFERENCES pillarrx.company.client_pbm_contract (client_pbm_contract_id);
ALTER TABLE pillarrx.client.audit_finding ADD CONSTRAINT fk_client_audit_finding_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.audit_finding ADD CONSTRAINT fk_client_audit_finding_finding_client_consulting_engagement_id FOREIGN KEY (finding_client_consulting_engagement_id) REFERENCES pillarrx.client.client_consulting_engagement (client_consulting_engagement_id);
ALTER TABLE pillarrx.client.audit_finding ADD CONSTRAINT fk_client_audit_finding_ncpdp_id FOREIGN KEY (ncpdp_id) REFERENCES pillarrx.drug.pharmacy (ncpdp_id);  -- natural key FK
ALTER TABLE pillarrx.client.audit_finding ADD CONSTRAINT fk_client_audit_finding_pbm_assignment_id FOREIGN KEY (pbm_assignment_id) REFERENCES pillarrx.client.pbm_assignment (pbm_assignment_id);
ALTER TABLE pillarrx.client.audit_finding ADD CONSTRAINT fk_client_audit_finding_pbm_contract_id FOREIGN KEY (pbm_contract_id) REFERENCES pillarrx.client.pbm_contract (pbm_contract_id);
ALTER TABLE pillarrx.client.benefit_plan ADD CONSTRAINT fk_client_benefit_plan_benefit_employer_id FOREIGN KEY (benefit_employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.benefit_plan ADD CONSTRAINT fk_client_benefit_plan_benefit_pbm_assignment_id FOREIGN KEY (benefit_pbm_assignment_id) REFERENCES pillarrx.client.pbm_assignment (pbm_assignment_id);
ALTER TABLE pillarrx.client.benefit_plan ADD CONSTRAINT fk_client_benefit_plan_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.client.benefit_plan ADD CONSTRAINT fk_client_benefit_plan_division_formulary_id FOREIGN KEY (division_formulary_id) REFERENCES pillarrx.division.division_formulary (division_formulary_id);
ALTER TABLE pillarrx.client.benefit_plan ADD CONSTRAINT fk_client_benefit_plan_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.benefit_plan ADD CONSTRAINT fk_client_benefit_plan_pbm_assignment_id FOREIGN KEY (pbm_assignment_id) REFERENCES pillarrx.client.pbm_assignment (pbm_assignment_id);
ALTER TABLE pillarrx.client.benefit_plan ADD CONSTRAINT fk_client_benefit_plan_plan_employer_id FOREIGN KEY (plan_employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.cap_program_enrollment ADD CONSTRAINT fk_client_cap_program_enrollment_benefit_plan_id FOREIGN KEY (benefit_plan_id) REFERENCES pillarrx.client.benefit_plan (benefit_plan_id);
ALTER TABLE pillarrx.client.cap_program_enrollment ADD CONSTRAINT fk_client_cap_program_enrollment_cap_employer_id FOREIGN KEY (cap_employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.cap_program_enrollment ADD CONSTRAINT fk_client_cap_program_enrollment_client_consulting_engagement_id FOREIGN KEY (client_consulting_engagement_id) REFERENCES pillarrx.client.client_consulting_engagement (client_consulting_engagement_id);
ALTER TABLE pillarrx.client.cap_program_enrollment ADD CONSTRAINT fk_client_cap_program_enrollment_member_id FOREIGN KEY (member_id) REFERENCES pillarrx.company.member (member_id);
ALTER TABLE pillarrx.client.cap_program_enrollment ADD CONSTRAINT fk_client_cap_program_enrollment_primary_employer_id FOREIGN KEY (primary_employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.client_benefit_group ADD CONSTRAINT fk_client_client_benefit_group_benefit_plan_id FOREIGN KEY (benefit_plan_id) REFERENCES pillarrx.client.benefit_plan (benefit_plan_id);
ALTER TABLE pillarrx.client.client_benefit_group ADD CONSTRAINT fk_client_client_benefit_group_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.client.client_benefit_group ADD CONSTRAINT fk_client_client_benefit_group_division_formulary_id FOREIGN KEY (division_formulary_id) REFERENCES pillarrx.division.division_formulary (division_formulary_id);
ALTER TABLE pillarrx.client.client_benefit_group ADD CONSTRAINT fk_client_client_benefit_group_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.client_benefit_group ADD CONSTRAINT fk_client_client_benefit_group_mac_list_id FOREIGN KEY (mac_list_id) REFERENCES pillarrx.drug.mac_list (mac_list_id);
ALTER TABLE pillarrx.client.client_benefit_group ADD CONSTRAINT fk_client_client_benefit_group_pbm_assignment_id FOREIGN KEY (pbm_assignment_id) REFERENCES pillarrx.client.pbm_assignment (pbm_assignment_id);
ALTER TABLE pillarrx.client.client_consulting_engagement ADD CONSTRAINT fk_client_client_consulting_engagement_client_employer_id FOREIGN KEY (client_employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.client_consulting_engagement ADD CONSTRAINT fk_client_client_consulting_engagement_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.client_consulting_engagement ADD CONSTRAINT fk_client_client_consulting_engagement_renewal_of_engagement_id FOREIGN KEY (renewal_of_engagement_id) REFERENCES pillarrx.division.engagement (engagement_id);
ALTER TABLE pillarrx.client.client_engagement_deliverable ADD CONSTRAINT fk_client_client_engagement_deliverable_client_consulting_engagement_id FOREIGN KEY (client_consulting_engagement_id) REFERENCES pillarrx.client.client_consulting_engagement (client_consulting_engagement_id);
ALTER TABLE pillarrx.client.client_engagement_deliverable ADD CONSTRAINT fk_client_client_engagement_deliverable_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.client_engagement_deliverable ADD CONSTRAINT fk_client_client_engagement_deliverable_primary_client_consulting_engagement_id FOREIGN KEY (primary_client_consulting_engagement_id) REFERENCES pillarrx.client.client_consulting_engagement (client_consulting_engagement_id);
ALTER TABLE pillarrx.client.consulting_fee_invoice ADD CONSTRAINT fk_client_consulting_fee_invoice_client_consulting_engagement_id FOREIGN KEY (client_consulting_engagement_id) REFERENCES pillarrx.client.client_consulting_engagement (client_consulting_engagement_id);
ALTER TABLE pillarrx.client.consulting_fee_invoice ADD CONSTRAINT fk_client_consulting_fee_invoice_client_engagement_deliverable_id FOREIGN KEY (client_engagement_deliverable_id) REFERENCES pillarrx.client.client_engagement_deliverable (client_engagement_deliverable_id);
ALTER TABLE pillarrx.client.consulting_fee_invoice ADD CONSTRAINT fk_client_consulting_fee_invoice_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.consulting_fee_invoice ADD CONSTRAINT fk_client_consulting_fee_invoice_primary_client_consulting_engagement_id FOREIGN KEY (primary_client_consulting_engagement_id) REFERENCES pillarrx.client.client_consulting_engagement (client_consulting_engagement_id);
ALTER TABLE pillarrx.client.contact ADD CONSTRAINT fk_client_contact_contact_employer_id FOREIGN KEY (contact_employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.contact ADD CONSTRAINT fk_client_contact_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.contact ADD CONSTRAINT fk_client_contact_salesforce_contact_id FOREIGN KEY (salesforce_contact_id) REFERENCES pillarrx.client.contact (contact_id);
ALTER TABLE pillarrx.client.data_feed_config ADD CONSTRAINT fk_client_data_feed_config_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.client.data_feed_config ADD CONSTRAINT fk_client_data_feed_config_data_assignment_fk FOREIGN KEY (data_assignment_fk) REFERENCES pillarrx.client.pbm_assignment (pbm_assignment_id);
ALTER TABLE pillarrx.client.data_feed_config ADD CONSTRAINT fk_client_data_feed_config_data_employer_id FOREIGN KEY (data_employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.data_feed_config ADD CONSTRAINT fk_client_data_feed_config_data_pbm_assignment_id FOREIGN KEY (data_pbm_assignment_id) REFERENCES pillarrx.client.pbm_assignment (pbm_assignment_id);
ALTER TABLE pillarrx.client.data_feed_config ADD CONSTRAINT fk_client_data_feed_config_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.data_feed_config ADD CONSTRAINT fk_client_data_feed_config_pbm_assignment_id FOREIGN KEY (pbm_assignment_id) REFERENCES pillarrx.client.pbm_assignment (pbm_assignment_id);
ALTER TABLE pillarrx.client.data_feed_config ADD CONSTRAINT fk_client_data_feed_config_primary_pbm_assignment_id FOREIGN KEY (primary_pbm_assignment_id) REFERENCES pillarrx.client.pbm_assignment (pbm_assignment_id);
ALTER TABLE pillarrx.client.document ADD CONSTRAINT fk_client_document_client_consulting_engagement_id FOREIGN KEY (client_consulting_engagement_id) REFERENCES pillarrx.client.client_consulting_engagement (client_consulting_engagement_id);
ALTER TABLE pillarrx.client.document ADD CONSTRAINT fk_client_document_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.client.document ADD CONSTRAINT fk_client_document_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.document ADD CONSTRAINT fk_client_document_pbm_contract_id FOREIGN KEY (pbm_contract_id) REFERENCES pillarrx.client.pbm_contract (pbm_contract_id);
ALTER TABLE pillarrx.client.document ADD CONSTRAINT fk_client_document_superseded_by_document_id FOREIGN KEY (superseded_by_document_id) REFERENCES pillarrx.client.document (document_id);
ALTER TABLE pillarrx.client.employer ADD CONSTRAINT fk_client_employer_division_id FOREIGN KEY (division_id) REFERENCES pillarrx.division.division (division_id);
ALTER TABLE pillarrx.client.employer ADD CONSTRAINT fk_client_employer_organization_id FOREIGN KEY (organization_id) REFERENCES pillarrx.company.organization (organization_id);
ALTER TABLE pillarrx.client.onboarding_event ADD CONSTRAINT fk_client_onboarding_event_client_consulting_engagement_id FOREIGN KEY (client_consulting_engagement_id) REFERENCES pillarrx.client.client_consulting_engagement (client_consulting_engagement_id);
ALTER TABLE pillarrx.client.onboarding_event ADD CONSTRAINT fk_client_onboarding_event_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.onboarding_event ADD CONSTRAINT fk_client_onboarding_event_onboarding_employer_id FOREIGN KEY (onboarding_employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.onboarding_event ADD CONSTRAINT fk_client_onboarding_event_primary_employer_id FOREIGN KEY (primary_employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.pbm_assignment ADD CONSTRAINT fk_client_pbm_assignment_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.client.pbm_assignment ADD CONSTRAINT fk_client_pbm_assignment_division_formulary_id FOREIGN KEY (division_formulary_id) REFERENCES pillarrx.division.division_formulary (division_formulary_id);
ALTER TABLE pillarrx.client.pbm_assignment ADD CONSTRAINT fk_client_pbm_assignment_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.pbm_assignment ADD CONSTRAINT fk_client_pbm_assignment_mac_list_id FOREIGN KEY (mac_list_id) REFERENCES pillarrx.drug.mac_list (mac_list_id);
ALTER TABLE pillarrx.client.pbm_assignment ADD CONSTRAINT fk_client_pbm_assignment_pbm_contract_id FOREIGN KEY (pbm_contract_id) REFERENCES pillarrx.client.pbm_contract (pbm_contract_id);
ALTER TABLE pillarrx.client.pbm_assignment ADD CONSTRAINT fk_client_pbm_assignment_pbm_employer_id FOREIGN KEY (pbm_employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.pbm_contract ADD CONSTRAINT fk_client_pbm_contract_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.client.pbm_contract ADD CONSTRAINT fk_client_pbm_contract_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.client.pbm_contract ADD CONSTRAINT fk_client_pbm_contract_pbm_employer_id FOREIGN KEY (pbm_employer_id) REFERENCES pillarrx.client.employer (employer_id);

-- company schema FKs
ALTER TABLE pillarrx.company.client_contact ADD CONSTRAINT fk_company_client_contact_linked_company_client_id FOREIGN KEY (linked_company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.client_contact ADD CONSTRAINT fk_company_client_contact_primary_company_client_id FOREIGN KEY (primary_company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.client_contact ADD CONSTRAINT fk_company_client_contact_salesforce_contact_id FOREIGN KEY (salesforce_contact_id) REFERENCES pillarrx.client.contact (contact_id);
ALTER TABLE pillarrx.company.client_contact ADD CONSTRAINT fk_company_client_contact_tertiary_company_client_id FOREIGN KEY (tertiary_company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.client_division_assignment ADD CONSTRAINT fk_company_client_division_assignment_assignment_org_division_id FOREIGN KEY (assignment_org_division_id) REFERENCES pillarrx.company.org_division (org_division_id);
ALTER TABLE pillarrx.company.client_division_assignment ADD CONSTRAINT fk_company_client_division_assignment_client_division_fk FOREIGN KEY (client_division_fk) REFERENCES pillarrx.company.org_division (org_division_id);
ALTER TABLE pillarrx.company.client_division_assignment ADD CONSTRAINT fk_company_client_division_assignment_client_division_org_division_id FOREIGN KEY (client_division_org_division_id) REFERENCES pillarrx.company.org_division (org_division_id);
ALTER TABLE pillarrx.company.client_division_assignment ADD CONSTRAINT fk_company_client_division_assignment_client_org_division_id FOREIGN KEY (client_org_division_id) REFERENCES pillarrx.company.org_division (org_division_id);
ALTER TABLE pillarrx.company.client_division_assignment ADD CONSTRAINT fk_company_client_division_assignment_company_client_id FOREIGN KEY (company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.client_division_assignment ADD CONSTRAINT fk_company_client_division_assignment_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.company.client_division_assignment ADD CONSTRAINT fk_company_client_division_assignment_division_pbm_contract_id FOREIGN KEY (division_pbm_contract_id) REFERENCES pillarrx.division.division_pbm_contract (division_pbm_contract_id);
ALTER TABLE pillarrx.company.client_division_assignment ADD CONSTRAINT fk_company_client_division_assignment_org_division_id FOREIGN KEY (org_division_id) REFERENCES pillarrx.company.org_division (org_division_id);
ALTER TABLE pillarrx.company.client_division_assignment ADD CONSTRAINT fk_company_client_division_assignment_primary_company_client_id FOREIGN KEY (primary_company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.client_division_assignment ADD CONSTRAINT fk_company_client_division_assignment_tertiary_company_client_id FOREIGN KEY (tertiary_company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.client_onboarding ADD CONSTRAINT fk_company_client_onboarding_company_client_id FOREIGN KEY (company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.client_onboarding ADD CONSTRAINT fk_company_client_onboarding_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.company.client_onboarding ADD CONSTRAINT fk_company_client_onboarding_org_division_id FOREIGN KEY (org_division_id) REFERENCES pillarrx.company.org_division (org_division_id);
ALTER TABLE pillarrx.company.client_onboarding ADD CONSTRAINT fk_company_client_onboarding_organization_id FOREIGN KEY (organization_id) REFERENCES pillarrx.company.organization (organization_id);
ALTER TABLE pillarrx.company.client_onboarding ADD CONSTRAINT fk_company_client_onboarding_primary_company_client_id FOREIGN KEY (primary_company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.client_onboarding ADD CONSTRAINT fk_company_client_onboarding_tertiary_company_client_id FOREIGN KEY (tertiary_company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.client_pbm_contract ADD CONSTRAINT fk_company_client_pbm_contract_claim_pbm_id FOREIGN KEY (claim_pbm_id) REFERENCES pillarrx.claim.claim_pbm (claim_pbm_id);
ALTER TABLE pillarrx.company.client_pbm_contract ADD CONSTRAINT fk_company_client_pbm_contract_company_client_id FOREIGN KEY (company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.client_pbm_contract ADD CONSTRAINT fk_company_client_pbm_contract_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.company.client_pbm_contract ADD CONSTRAINT fk_company_client_pbm_contract_primary_company_client_id FOREIGN KEY (primary_company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.client_pbm_contract ADD CONSTRAINT fk_company_client_pbm_contract_superseded_by_client_pbm_contract_id FOREIGN KEY (superseded_by_client_pbm_contract_id) REFERENCES pillarrx.company.client_pbm_contract (client_pbm_contract_id);
ALTER TABLE pillarrx.company.client_pbm_contract ADD CONSTRAINT fk_company_client_pbm_contract_tertiary_company_client_id FOREIGN KEY (tertiary_company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.company_benefit_group ADD CONSTRAINT fk_company_company_benefit_group_company_client_id FOREIGN KEY (company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.company_benefit_group ADD CONSTRAINT fk_company_company_benefit_group_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.company.company_benefit_group ADD CONSTRAINT fk_company_company_benefit_group_division_formulary_id FOREIGN KEY (division_formulary_id) REFERENCES pillarrx.division.division_formulary (division_formulary_id);
ALTER TABLE pillarrx.company.company_benefit_group ADD CONSTRAINT fk_company_company_benefit_group_primary_company_client_id FOREIGN KEY (primary_company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.company_client ADD CONSTRAINT fk_company_company_client_company_org_division_id FOREIGN KEY (company_org_division_id) REFERENCES pillarrx.company.org_division (org_division_id);
ALTER TABLE pillarrx.company.company_client ADD CONSTRAINT fk_company_company_client_org_division_id FOREIGN KEY (org_division_id) REFERENCES pillarrx.company.org_division (org_division_id);
ALTER TABLE pillarrx.company.company_consulting_engagement ADD CONSTRAINT fk_company_company_consulting_engagement_company_client_id FOREIGN KEY (company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.company_consulting_engagement ADD CONSTRAINT fk_company_company_consulting_engagement_org_division_id FOREIGN KEY (org_division_id) REFERENCES pillarrx.company.org_division (org_division_id);
ALTER TABLE pillarrx.company.company_consulting_engagement ADD CONSTRAINT fk_company_company_consulting_engagement_parent_engagement_company_consulting_engagement_id FOREIGN KEY (parent_engagement_company_consulting_engagement_id) REFERENCES pillarrx.company.company_consulting_engagement (company_consulting_engagement_id);
ALTER TABLE pillarrx.company.company_consulting_engagement ADD CONSTRAINT fk_company_company_consulting_engagement_primary_company_client_id FOREIGN KEY (primary_company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.company_engagement_deliverable ADD CONSTRAINT fk_company_company_engagement_deliverable_company_client_id FOREIGN KEY (company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.company_engagement_deliverable ADD CONSTRAINT fk_company_company_engagement_deliverable_company_consulting_engagement_id FOREIGN KEY (company_consulting_engagement_id) REFERENCES pillarrx.company.company_consulting_engagement (company_consulting_engagement_id);
ALTER TABLE pillarrx.company.company_engagement_deliverable ADD CONSTRAINT fk_company_company_engagement_deliverable_primary_company_consulting_engagement_id FOREIGN KEY (primary_company_consulting_engagement_id) REFERENCES pillarrx.company.company_consulting_engagement (company_consulting_engagement_id);
ALTER TABLE pillarrx.company.consulting_fee ADD CONSTRAINT fk_company_consulting_fee_company_client_id FOREIGN KEY (company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.consulting_fee ADD CONSTRAINT fk_company_consulting_fee_company_consulting_engagement_id FOREIGN KEY (company_consulting_engagement_id) REFERENCES pillarrx.company.company_consulting_engagement (company_consulting_engagement_id);
ALTER TABLE pillarrx.company.consulting_fee ADD CONSTRAINT fk_company_consulting_fee_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.company.consulting_fee ADD CONSTRAINT fk_company_consulting_fee_org_division_id FOREIGN KEY (org_division_id) REFERENCES pillarrx.company.org_division (org_division_id);
ALTER TABLE pillarrx.company.consulting_fee ADD CONSTRAINT fk_company_consulting_fee_primary_company_consulting_engagement_id FOREIGN KEY (primary_company_consulting_engagement_id) REFERENCES pillarrx.company.company_consulting_engagement (company_consulting_engagement_id);
ALTER TABLE pillarrx.company.consulting_fee ADD CONSTRAINT fk_company_consulting_fee_tertiary_company_consulting_engagement_id FOREIGN KEY (tertiary_company_consulting_engagement_id) REFERENCES pillarrx.company.company_consulting_engagement (company_consulting_engagement_id);
ALTER TABLE pillarrx.company.member ADD CONSTRAINT fk_company_member_company_client_id FOREIGN KEY (company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.member ADD CONSTRAINT fk_company_member_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.company.member ADD CONSTRAINT fk_company_member_pbm_member_id FOREIGN KEY (pbm_member_id) REFERENCES pillarrx.company.member (member_id);
ALTER TABLE pillarrx.company.member ADD CONSTRAINT fk_company_member_subscriber_id FOREIGN KEY (subscriber_id) REFERENCES pillarrx.company.subscriber (subscriber_id);
ALTER TABLE pillarrx.company.org_division ADD CONSTRAINT fk_company_org_division_division_formulary_id FOREIGN KEY (division_formulary_id) REFERENCES pillarrx.division.division_formulary (division_formulary_id);
ALTER TABLE pillarrx.company.org_division ADD CONSTRAINT fk_company_org_division_organization_id FOREIGN KEY (organization_id) REFERENCES pillarrx.company.organization (organization_id);
ALTER TABLE pillarrx.company.org_division ADD CONSTRAINT fk_company_org_division_parent_organization_id FOREIGN KEY (parent_organization_id) REFERENCES pillarrx.company.organization (organization_id);
ALTER TABLE pillarrx.company.org_division ADD CONSTRAINT fk_company_org_division_pbm_contract_id FOREIGN KEY (pbm_contract_id) REFERENCES pillarrx.client.pbm_contract (pbm_contract_id);
ALTER TABLE pillarrx.company.org_division ADD CONSTRAINT fk_company_org_division_primary_organization_id FOREIGN KEY (primary_organization_id) REFERENCES pillarrx.company.organization (organization_id);
ALTER TABLE pillarrx.company.org_division ADD CONSTRAINT fk_company_org_division_salesforce_division_id FOREIGN KEY (salesforce_division_id) REFERENCES pillarrx.division.division (division_id);
ALTER TABLE pillarrx.company.org_division ADD CONSTRAINT fk_company_org_division_tertiary_organization_id FOREIGN KEY (tertiary_organization_id) REFERENCES pillarrx.company.organization (organization_id);
ALTER TABLE pillarrx.company.organization ADD CONSTRAINT fk_company_organization_parent_organization_id FOREIGN KEY (parent_organization_id) REFERENCES pillarrx.company.organization (organization_id);
ALTER TABLE pillarrx.company.subscriber ADD CONSTRAINT fk_company_subscriber_company_client_id FOREIGN KEY (company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.subscriber ADD CONSTRAINT fk_company_subscriber_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.company.subscriber ADD CONSTRAINT fk_company_subscriber_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.company.subscriber ADD CONSTRAINT fk_company_subscriber_pbm_subscriber_id FOREIGN KEY (pbm_subscriber_id) REFERENCES pillarrx.company.subscriber (subscriber_id);
ALTER TABLE pillarrx.company.subscriber ADD CONSTRAINT fk_company_subscriber_primary_company_benefit_group_id FOREIGN KEY (primary_company_benefit_group_id) REFERENCES pillarrx.company.company_benefit_group (company_benefit_group_id);
ALTER TABLE pillarrx.company.subscriber ADD CONSTRAINT fk_company_subscriber_subscriber_company_benefit_group_id FOREIGN KEY (subscriber_company_benefit_group_id) REFERENCES pillarrx.company.company_benefit_group (company_benefit_group_id);
ALTER TABLE pillarrx.company.subscriber ADD CONSTRAINT fk_company_subscriber_subscriber_company_client_id FOREIGN KEY (subscriber_company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.company.tenant_change_log ADD CONSTRAINT fk_company_tenant_change_log_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.company.tenant_change_log ADD CONSTRAINT fk_company_tenant_change_log_division_id FOREIGN KEY (division_id) REFERENCES pillarrx.division.division (division_id);
ALTER TABLE pillarrx.company.tenant_change_log ADD CONSTRAINT fk_company_tenant_change_log_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.company.tenant_change_log ADD CONSTRAINT fk_company_tenant_change_log_organization_id FOREIGN KEY (organization_id) REFERENCES pillarrx.company.organization (organization_id);
ALTER TABLE pillarrx.company.tenant_change_log ADD CONSTRAINT fk_company_tenant_change_log_rolled_back_from_log_id FOREIGN KEY (rolled_back_from_log_id) REFERENCES pillarrx.company.tenant_change_log (tenant_change_log_id);

-- division schema FKs
ALTER TABLE pillarrx.division.division ADD CONSTRAINT fk_division_division_company_id FOREIGN KEY (company_id) REFERENCES pillarrx.company.organization (organization_id);
ALTER TABLE pillarrx.division.division ADD CONSTRAINT fk_division_division_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.division.division ADD CONSTRAINT fk_division_division_organization_id FOREIGN KEY (organization_id) REFERENCES pillarrx.company.organization (organization_id);
ALTER TABLE pillarrx.division.division_benefit_group ADD CONSTRAINT fk_division_division_benefit_group_benefit_plan_id FOREIGN KEY (benefit_plan_id) REFERENCES pillarrx.client.benefit_plan (benefit_plan_id);
ALTER TABLE pillarrx.division.division_benefit_group ADD CONSTRAINT fk_division_division_benefit_group_client_benefit_group_id FOREIGN KEY (client_benefit_group_id) REFERENCES pillarrx.client.client_benefit_group (client_benefit_group_id);
ALTER TABLE pillarrx.division.division_benefit_group ADD CONSTRAINT fk_division_division_benefit_group_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.division.division_benefit_group ADD CONSTRAINT fk_division_division_benefit_group_division_formulary_id FOREIGN KEY (division_formulary_id) REFERENCES pillarrx.division.division_formulary (division_formulary_id);
ALTER TABLE pillarrx.division.division_benefit_group ADD CONSTRAINT fk_division_division_benefit_group_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.division.division_benefit_group ADD CONSTRAINT fk_division_division_benefit_group_pbm_contract_id FOREIGN KEY (pbm_contract_id) REFERENCES pillarrx.client.pbm_contract (pbm_contract_id);
ALTER TABLE pillarrx.division.division_benefit_group ADD CONSTRAINT fk_division_division_benefit_group_pbm_division_id FOREIGN KEY (pbm_division_id) REFERENCES pillarrx.division.division (division_id);
ALTER TABLE pillarrx.division.division_benefit_group ADD CONSTRAINT fk_division_division_benefit_group_primary_division_id FOREIGN KEY (primary_division_id) REFERENCES pillarrx.division.division (division_id);
ALTER TABLE pillarrx.division.division_formulary ADD CONSTRAINT fk_division_division_formulary_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.division.division_formulary ADD CONSTRAINT fk_division_division_formulary_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.division.division_formulary ADD CONSTRAINT fk_division_division_formulary_pbm_contract_id FOREIGN KEY (pbm_contract_id) REFERENCES pillarrx.client.pbm_contract (pbm_contract_id);
ALTER TABLE pillarrx.division.division_formulary ADD CONSTRAINT fk_division_division_formulary_pbm_formulary_division_formulary_id FOREIGN KEY (pbm_formulary_division_formulary_id) REFERENCES pillarrx.division.division_formulary (division_formulary_id);
ALTER TABLE pillarrx.division.division_formulary_tier ADD CONSTRAINT fk_division_division_formulary_tier_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.division.division_formulary_tier ADD CONSTRAINT fk_division_division_formulary_tier_division_formulary_id FOREIGN KEY (division_formulary_id) REFERENCES pillarrx.division.division_formulary (division_formulary_id);
ALTER TABLE pillarrx.division.division_formulary_tier ADD CONSTRAINT fk_division_division_formulary_tier_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.division.division_pbm_contract ADD CONSTRAINT fk_division_division_pbm_contract_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.division.division_pbm_contract ADD CONSTRAINT fk_division_division_pbm_contract_division_id FOREIGN KEY (division_id) REFERENCES pillarrx.division.division (division_id);
ALTER TABLE pillarrx.division.division_pbm_contract ADD CONSTRAINT fk_division_division_pbm_contract_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.division.division_pbm_contract ADD CONSTRAINT fk_division_division_pbm_contract_pbm_division_id FOREIGN KEY (pbm_division_id) REFERENCES pillarrx.division.division (division_id);
ALTER TABLE pillarrx.division.engagement ADD CONSTRAINT fk_division_engagement_division_id FOREIGN KEY (division_id) REFERENCES pillarrx.division.division (division_id);
ALTER TABLE pillarrx.division.engagement ADD CONSTRAINT fk_division_engagement_division_pbm_contract_id FOREIGN KEY (division_pbm_contract_id) REFERENCES pillarrx.division.division_pbm_contract (division_pbm_contract_id);
ALTER TABLE pillarrx.division.formulary_drug_placement ADD CONSTRAINT fk_division_formulary_drug_placement_division_formulary_tier_id FOREIGN KEY (division_formulary_tier_id) REFERENCES pillarrx.division.division_formulary_tier (division_formulary_tier_id);
ALTER TABLE pillarrx.division.formulary_drug_placement ADD CONSTRAINT fk_division_formulary_drug_placement_formulary_tier_id FOREIGN KEY (formulary_tier_id) REFERENCES pillarrx.division.division_formulary_tier (division_formulary_tier_id);
ALTER TABLE pillarrx.division.formulary_drug_placement ADD CONSTRAINT fk_division_formulary_drug_placement_primary_division_formulary_id FOREIGN KEY (primary_division_formulary_id) REFERENCES pillarrx.division.division_formulary (division_formulary_id);
ALTER TABLE pillarrx.division.formulary_drug_placement ADD CONSTRAINT fk_division_formulary_drug_placement_primary_formulary_division_formulary_id FOREIGN KEY (primary_formulary_division_formulary_id) REFERENCES pillarrx.division.division_formulary (division_formulary_id);
ALTER TABLE pillarrx.division.formulary_drug_placement ADD CONSTRAINT fk_division_formulary_drug_placement_prior_auth_rule_id FOREIGN KEY (prior_auth_rule_id) REFERENCES pillarrx.division.prior_auth_rule (prior_auth_rule_id);
ALTER TABLE pillarrx.division.formulary_drug_placement ADD CONSTRAINT fk_division_formulary_drug_placement_source_pbm_formulary_division_formulary_id FOREIGN KEY (source_pbm_formulary_division_formulary_id) REFERENCES pillarrx.division.division_formulary (division_formulary_id);
ALTER TABLE pillarrx.division.pbm_feed ADD CONSTRAINT fk_division_pbm_feed_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.division.pbm_feed ADD CONSTRAINT fk_division_pbm_feed_division_id FOREIGN KEY (division_id) REFERENCES pillarrx.division.division (division_id);
ALTER TABLE pillarrx.division.pbm_feed ADD CONSTRAINT fk_division_pbm_feed_pbm_contract_id FOREIGN KEY (pbm_contract_id) REFERENCES pillarrx.client.pbm_contract (pbm_contract_id);
ALTER TABLE pillarrx.division.pbm_guarantee_period ADD CONSTRAINT fk_division_pbm_guarantee_period_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.division.pbm_guarantee_period ADD CONSTRAINT fk_division_pbm_guarantee_period_division_pbm_contract_id FOREIGN KEY (division_pbm_contract_id) REFERENCES pillarrx.division.division_pbm_contract (division_pbm_contract_id);
ALTER TABLE pillarrx.division.pbm_guarantee_period ADD CONSTRAINT fk_division_pbm_guarantee_period_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.division.pbm_guarantee_result ADD CONSTRAINT fk_division_pbm_guarantee_result_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.division.pbm_guarantee_result ADD CONSTRAINT fk_division_pbm_guarantee_result_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.division.pbm_guarantee_result ADD CONSTRAINT fk_division_pbm_guarantee_result_pbm_contract_id FOREIGN KEY (pbm_contract_id) REFERENCES pillarrx.client.pbm_contract (pbm_contract_id);
ALTER TABLE pillarrx.division.pbm_guarantee_result ADD CONSTRAINT fk_division_pbm_guarantee_result_pbm_guarantee_period_id FOREIGN KEY (pbm_guarantee_period_id) REFERENCES pillarrx.division.pbm_guarantee_period (pbm_guarantee_period_id);
ALTER TABLE pillarrx.division.pbm_guarantee_result ADD CONSTRAINT fk_division_pbm_guarantee_result_pbm_period_fk FOREIGN KEY (pbm_period_fk) REFERENCES pillarrx.division.pbm_guarantee_period (pbm_guarantee_period_id);
ALTER TABLE pillarrx.division.pbm_guarantee_result ADD CONSTRAINT fk_division_pbm_guarantee_result_primary_pbm_guarantee_period_id FOREIGN KEY (primary_pbm_guarantee_period_id) REFERENCES pillarrx.division.pbm_guarantee_period (pbm_guarantee_period_id);
ALTER TABLE pillarrx.division.prior_auth_request ADD CONSTRAINT fk_division_prior_auth_request_benefit_plan_id FOREIGN KEY (benefit_plan_id) REFERENCES pillarrx.client.benefit_plan (benefit_plan_id);
ALTER TABLE pillarrx.division.prior_auth_request ADD CONSTRAINT fk_division_prior_auth_request_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.division.prior_auth_request ADD CONSTRAINT fk_division_prior_auth_request_division_id FOREIGN KEY (division_id) REFERENCES pillarrx.division.division (division_id);
ALTER TABLE pillarrx.division.prior_auth_request ADD CONSTRAINT fk_division_prior_auth_request_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.division.prior_auth_request ADD CONSTRAINT fk_division_prior_auth_request_linked_rx_claim_id FOREIGN KEY (linked_rx_claim_id) REFERENCES pillarrx.claim.rx_claim (rx_claim_id);
ALTER TABLE pillarrx.division.prior_auth_request ADD CONSTRAINT fk_division_prior_auth_request_prior_auth_rule_id FOREIGN KEY (prior_auth_rule_id) REFERENCES pillarrx.division.prior_auth_rule (prior_auth_rule_id);
ALTER TABLE pillarrx.division.prior_auth_rule ADD CONSTRAINT fk_division_prior_auth_rule_client_benefit_group_id FOREIGN KEY (client_benefit_group_id) REFERENCES pillarrx.client.client_benefit_group (client_benefit_group_id);
ALTER TABLE pillarrx.division.prior_auth_rule ADD CONSTRAINT fk_division_prior_auth_rule_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.division.prior_auth_rule ADD CONSTRAINT fk_division_prior_auth_rule_division_benefit_group_id FOREIGN KEY (division_benefit_group_id) REFERENCES pillarrx.division.division_benefit_group (division_benefit_group_id);
ALTER TABLE pillarrx.division.prior_auth_rule ADD CONSTRAINT fk_division_prior_auth_rule_division_formulary_id FOREIGN KEY (division_formulary_id) REFERENCES pillarrx.division.division_formulary (division_formulary_id);
ALTER TABLE pillarrx.division.prior_auth_rule ADD CONSTRAINT fk_division_prior_auth_rule_prior_version_rule_prior_auth_rule_id FOREIGN KEY (prior_version_rule_prior_auth_rule_id) REFERENCES pillarrx.division.prior_auth_rule (prior_auth_rule_id);
ALTER TABLE pillarrx.division.rebate_payment ADD CONSTRAINT fk_division_rebate_payment_primary_rebate_contract_id FOREIGN KEY (primary_rebate_contract_id) REFERENCES pillarrx.program.rebate_contract (rebate_contract_id);
ALTER TABLE pillarrx.division.rebate_payment ADD CONSTRAINT fk_division_rebate_payment_secondary_rebate_contract_id FOREIGN KEY (secondary_rebate_contract_id) REFERENCES pillarrx.program.rebate_contract (rebate_contract_id);
ALTER TABLE pillarrx.division.reconciliation_deliverable ADD CONSTRAINT fk_division_reconciliation_deliverable_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.division.reconciliation_deliverable ADD CONSTRAINT fk_division_reconciliation_deliverable_consulting_fee_id FOREIGN KEY (consulting_fee_id) REFERENCES pillarrx.company.consulting_fee (consulting_fee_id);
ALTER TABLE pillarrx.division.reconciliation_deliverable ADD CONSTRAINT fk_division_reconciliation_deliverable_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.division.reconciliation_deliverable ADD CONSTRAINT fk_division_reconciliation_deliverable_engagement_id FOREIGN KEY (engagement_id) REFERENCES pillarrx.division.engagement (engagement_id);
ALTER TABLE pillarrx.division.reconciliation_deliverable ADD CONSTRAINT fk_division_reconciliation_deliverable_pbm_contract_id FOREIGN KEY (pbm_contract_id) REFERENCES pillarrx.client.pbm_contract (pbm_contract_id);
ALTER TABLE pillarrx.division.reconciliation_deliverable ADD CONSTRAINT fk_division_reconciliation_deliverable_pbm_guarantee_result_id FOREIGN KEY (pbm_guarantee_result_id) REFERENCES pillarrx.division.pbm_guarantee_result (pbm_guarantee_result_id);
ALTER TABLE pillarrx.division.reconciliation_deliverable ADD CONSTRAINT fk_division_reconciliation_deliverable_rebate_payment_id FOREIGN KEY (rebate_payment_id) REFERENCES pillarrx.program.rebate_payment (rebate_payment_id);

-- drug schema FKs
ALTER TABLE pillarrx.drug.drug_formulary ADD CONSTRAINT fk_drug_drug_formulary_primary_drug_division_formulary_id FOREIGN KEY (primary_drug_division_formulary_id) REFERENCES pillarrx.division.division_formulary (division_formulary_id);
ALTER TABLE pillarrx.drug.drug_formulary_tier ADD CONSTRAINT fk_drug_drug_formulary_tier_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.drug.drug_formulary_tier ADD CONSTRAINT fk_drug_drug_formulary_tier_division_formulary_id FOREIGN KEY (division_formulary_id) REFERENCES pillarrx.division.division_formulary (division_formulary_id);
ALTER TABLE pillarrx.drug.drug_formulary_tier ADD CONSTRAINT fk_drug_drug_formulary_tier_drug_formulary_id FOREIGN KEY (drug_formulary_id) REFERENCES pillarrx.drug.drug_formulary (drug_formulary_id);
ALTER TABLE pillarrx.drug.drug_formulary_tier ADD CONSTRAINT fk_drug_drug_formulary_tier_drug_formulary_tier_formulary_fk FOREIGN KEY (drug_formulary_tier_formulary_fk) REFERENCES pillarrx.drug.drug_formulary (drug_formulary_id);
ALTER TABLE pillarrx.drug.drug_formulary_tier ADD CONSTRAINT fk_drug_drug_formulary_tier_primary_drug_formulary_id FOREIGN KEY (primary_drug_formulary_id) REFERENCES pillarrx.drug.drug_formulary (drug_formulary_id);
ALTER TABLE pillarrx.drug.drug_prescriber ADD CONSTRAINT fk_drug_drug_prescriber_npi FOREIGN KEY (npi) REFERENCES pillarrx.reference.nppes_provider (npi);
ALTER TABLE pillarrx.drug.drug_prescriber ADD CONSTRAINT fk_drug_drug_prescriber_taxonomy_code FOREIGN KEY (taxonomy_code) REFERENCES pillarrx.reference.nucc_taxonomy (taxonomy_code);  -- natural key FK, corrected target table
ALTER TABLE pillarrx.drug.formulary_drug ADD CONSTRAINT fk_drug_formulary_drug_assigned_drug_formulary_tier_id FOREIGN KEY (assigned_drug_formulary_tier_id) REFERENCES pillarrx.drug.drug_formulary_tier (drug_formulary_tier_id);
ALTER TABLE pillarrx.drug.formulary_drug ADD CONSTRAINT fk_drug_formulary_drug_drug_prescriber_id FOREIGN KEY (drug_prescriber_id) REFERENCES pillarrx.drug.drug_prescriber (drug_prescriber_id);
ALTER TABLE pillarrx.drug.formulary_drug ADD CONSTRAINT fk_drug_formulary_drug_primary_drug_formulary_id FOREIGN KEY (primary_drug_formulary_id) REFERENCES pillarrx.drug.drug_formulary (drug_formulary_id);
ALTER TABLE pillarrx.drug.formulary_drug ADD CONSTRAINT fk_drug_formulary_drug_primary_drug_formulary_tier_id FOREIGN KEY (primary_drug_formulary_tier_id) REFERENCES pillarrx.drug.drug_formulary_tier (drug_formulary_tier_id);
ALTER TABLE pillarrx.drug.mac_pricing ADD CONSTRAINT fk_drug_mac_pricing_mac_list_id FOREIGN KEY (mac_list_id) REFERENCES pillarrx.drug.mac_list (mac_list_id);
ALTER TABLE pillarrx.drug.manufacturer ADD CONSTRAINT fk_drug_manufacturer_organization_id FOREIGN KEY (organization_id) REFERENCES pillarrx.company.organization (organization_id);
ALTER TABLE pillarrx.drug.ndc ADD CONSTRAINT fk_drug_ndc_fdb_drug_id FOREIGN KEY (fdb_drug_id) REFERENCES pillarrx.reference.fdb_drug (fdb_drug_id);
ALTER TABLE pillarrx.drug.ndc ADD CONSTRAINT fk_drug_ndc_manufacturer_id FOREIGN KEY (manufacturer_id) REFERENCES pillarrx.drug.manufacturer (manufacturer_id);
ALTER TABLE pillarrx.drug.ndc_price ADD CONSTRAINT fk_drug_ndc_price_mac_list_id FOREIGN KEY (mac_list_id) REFERENCES pillarrx.drug.mac_list (mac_list_id);
ALTER TABLE pillarrx.drug.ndc_price ADD CONSTRAINT fk_drug_ndc_price_ndc_mac_list_id FOREIGN KEY (ndc_mac_list_id) REFERENCES pillarrx.drug.mac_list (mac_list_id);
ALTER TABLE pillarrx.drug.ndc_price ADD CONSTRAINT fk_drug_ndc_price_primary_mac_list_id FOREIGN KEY (primary_mac_list_id) REFERENCES pillarrx.drug.mac_list (mac_list_id);
ALTER TABLE pillarrx.drug.pharmacy ADD CONSTRAINT fk_drug_pharmacy_ncpdp_number FOREIGN KEY (ncpdp_number) REFERENCES pillarrx.reference.ncpdp_pharmacy (ncpdp_number);
ALTER TABLE pillarrx.drug.pharmacy ADD CONSTRAINT fk_drug_pharmacy_pharmacy_network_id FOREIGN KEY (pharmacy_network_id) REFERENCES pillarrx.drug.pharmacy_network (pharmacy_network_id);
ALTER TABLE pillarrx.drug.pharmacy_network ADD CONSTRAINT fk_drug_pharmacy_network_company_client_id FOREIGN KEY (company_client_id) REFERENCES pillarrx.company.company_client (company_client_id);
ALTER TABLE pillarrx.drug.pharmacy_network ADD CONSTRAINT fk_drug_pharmacy_network_company_pbm_id FOREIGN KEY (company_pbm_id) REFERENCES pillarrx.company.company_pbm (company_pbm_id);
ALTER TABLE pillarrx.drug.pharmacy_network ADD CONSTRAINT fk_drug_pharmacy_network_mac_list_id FOREIGN KEY (mac_list_id) REFERENCES pillarrx.drug.mac_list (mac_list_id);
ALTER TABLE pillarrx.drug.pharmacy_network ADD CONSTRAINT fk_drug_pharmacy_network_pharmacy_mac_list_fk FOREIGN KEY (pharmacy_mac_list_fk) REFERENCES pillarrx.drug.mac_list (mac_list_id);
ALTER TABLE pillarrx.drug.pharmacy_network ADD CONSTRAINT fk_drug_pharmacy_network_pharmacy_mac_list_id FOREIGN KEY (pharmacy_mac_list_id) REFERENCES pillarrx.drug.mac_list (mac_list_id);
ALTER TABLE pillarrx.drug.pharmacy_network ADD CONSTRAINT fk_drug_pharmacy_network_pharmacy_network_mac_list_fk FOREIGN KEY (pharmacy_network_mac_list_fk) REFERENCES pillarrx.drug.mac_list (mac_list_id);

-- program schema FKs
ALTER TABLE pillarrx.program.accumulator_program ADD CONSTRAINT fk_program_accumulator_program_client_id FOREIGN KEY (client_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.program.accumulator_program ADD CONSTRAINT fk_program_accumulator_program_division_id FOREIGN KEY (division_id) REFERENCES pillarrx.division.division (division_id);
ALTER TABLE pillarrx.program.accumulator_program ADD CONSTRAINT fk_program_accumulator_program_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.program.accumulator_program ADD CONSTRAINT fk_program_accumulator_program_pbm_assignment_id FOREIGN KEY (pbm_assignment_id) REFERENCES pillarrx.client.pbm_assignment (pbm_assignment_id);
ALTER TABLE pillarrx.program.accumulator_program ADD CONSTRAINT fk_program_accumulator_program_savings_program_id FOREIGN KEY (savings_program_id) REFERENCES pillarrx.program.savings_program (savings_program_id);
ALTER TABLE pillarrx.program.alternative_funding_program ADD CONSTRAINT fk_program_alternative_funding_program_client_id FOREIGN KEY (client_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.program.alternative_funding_program ADD CONSTRAINT fk_program_alternative_funding_program_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.program.alternative_funding_program ADD CONSTRAINT fk_program_alternative_funding_program_savings_program_id FOREIGN KEY (savings_program_id) REFERENCES pillarrx.program.savings_program (savings_program_id);
ALTER TABLE pillarrx.program.charitable_assistance ADD CONSTRAINT fk_program_charitable_assistance_savings_program_id FOREIGN KEY (savings_program_id) REFERENCES pillarrx.program.savings_program (savings_program_id);
ALTER TABLE pillarrx.program.claim_savings_attribution ADD CONSTRAINT fk_program_claim_savings_attribution_member_id FOREIGN KEY (member_id) REFERENCES pillarrx.company.member (member_id);
ALTER TABLE pillarrx.program.claim_savings_attribution ADD CONSTRAINT fk_program_claim_savings_attribution_rx_claim_id FOREIGN KEY (rx_claim_id) REFERENCES pillarrx.claim.rx_claim (rx_claim_id);
ALTER TABLE pillarrx.program.claim_savings_attribution ADD CONSTRAINT fk_program_claim_savings_attribution_savings_program_id FOREIGN KEY (savings_program_id) REFERENCES pillarrx.program.savings_program (savings_program_id);
ALTER TABLE pillarrx.program.contract_pharmacy_340b ADD CONSTRAINT fk_program_contract_pharmacy_340b_covered_entity_340b_id FOREIGN KEY (covered_entity_340b_id) REFERENCES pillarrx.program.covered_entity_340b (covered_entity_340b_id);
ALTER TABLE pillarrx.program.copay_assistance_program ADD CONSTRAINT fk_program_copay_assistance_program_manufacturer_id FOREIGN KEY (manufacturer_id) REFERENCES pillarrx.drug.manufacturer (manufacturer_id);
ALTER TABLE pillarrx.program.copay_assistance_program ADD CONSTRAINT fk_program_copay_assistance_program_ndc_id FOREIGN KEY (ndc_id) REFERENCES pillarrx.drug.ndc (ndc_id);
ALTER TABLE pillarrx.program.copay_assistance_program ADD CONSTRAINT fk_program_copay_assistance_program_savings_program_id FOREIGN KEY (savings_program_id) REFERENCES pillarrx.program.savings_program (savings_program_id);
ALTER TABLE pillarrx.program.covered_entity_340b ADD CONSTRAINT fk_program_covered_entity_340b_employer_id FOREIGN KEY (employer_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.program.covered_entity_340b ADD CONSTRAINT fk_program_covered_entity_340b_savings_program_id FOREIGN KEY (savings_program_id) REFERENCES pillarrx.program.savings_program (savings_program_id);
ALTER TABLE pillarrx.program.government_benefit_rule ADD CONSTRAINT fk_program_government_benefit_rule_savings_program_id FOREIGN KEY (savings_program_id) REFERENCES pillarrx.program.savings_program (savings_program_id);
ALTER TABLE pillarrx.program.member_accumulator_impact ADD CONSTRAINT fk_program_member_accumulator_impact_accumulator_program_id FOREIGN KEY (accumulator_program_id) REFERENCES pillarrx.program.accumulator_program (accumulator_program_id);
ALTER TABLE pillarrx.program.member_accumulator_impact ADD CONSTRAINT fk_program_member_accumulator_impact_member_id FOREIGN KEY (member_id) REFERENCES pillarrx.company.member (member_id);
ALTER TABLE pillarrx.program.member_copay_enrollment ADD CONSTRAINT fk_program_member_copay_enrollment_copay_assistance_program_id FOREIGN KEY (copay_assistance_program_id) REFERENCES pillarrx.program.copay_assistance_program (copay_assistance_program_id);
ALTER TABLE pillarrx.program.member_copay_enrollment ADD CONSTRAINT fk_program_member_copay_enrollment_member_id FOREIGN KEY (member_id) REFERENCES pillarrx.company.member (member_id);
ALTER TABLE pillarrx.program.patient_assistance_program ADD CONSTRAINT fk_program_patient_assistance_program_manufacturer_id FOREIGN KEY (manufacturer_id) REFERENCES pillarrx.drug.manufacturer (manufacturer_id);
ALTER TABLE pillarrx.program.patient_assistance_program ADD CONSTRAINT fk_program_patient_assistance_program_ndc_id FOREIGN KEY (ndc_id) REFERENCES pillarrx.drug.ndc (ndc_id);
ALTER TABLE pillarrx.program.patient_assistance_program ADD CONSTRAINT fk_program_patient_assistance_program_savings_program_id FOREIGN KEY (savings_program_id) REFERENCES pillarrx.program.savings_program (savings_program_id);
ALTER TABLE pillarrx.program.program_type ADD CONSTRAINT fk_program_program_type_savings_program_id FOREIGN KEY (savings_program_id) REFERENCES pillarrx.program.savings_program (savings_program_id);
ALTER TABLE pillarrx.program.rebate_contract ADD CONSTRAINT fk_program_rebate_contract_client_id FOREIGN KEY (client_id) REFERENCES pillarrx.client.employer (employer_id);
ALTER TABLE pillarrx.program.rebate_contract ADD CONSTRAINT fk_program_rebate_contract_division_id FOREIGN KEY (division_id) REFERENCES pillarrx.division.division (division_id);
ALTER TABLE pillarrx.program.rebate_contract ADD CONSTRAINT fk_program_rebate_contract_manufacturer_id FOREIGN KEY (manufacturer_id) REFERENCES pillarrx.drug.manufacturer (manufacturer_id);
ALTER TABLE pillarrx.program.rebate_contract ADD CONSTRAINT fk_program_rebate_contract_pbm_assignment_id FOREIGN KEY (pbm_assignment_id) REFERENCES pillarrx.client.pbm_assignment (pbm_assignment_id);
ALTER TABLE pillarrx.program.rebate_contract ADD CONSTRAINT fk_program_rebate_contract_savings_program_id FOREIGN KEY (savings_program_id) REFERENCES pillarrx.program.savings_program (savings_program_id);
ALTER TABLE pillarrx.program.rebate_payment ADD CONSTRAINT fk_program_rebate_payment_rebate_contract_id FOREIGN KEY (rebate_contract_id) REFERENCES pillarrx.program.rebate_contract (rebate_contract_id);

-- reference schema FKs
ALTER TABLE pillarrx.reference.external_source_load ADD CONSTRAINT fk_reference_external_source_load_medispan_drug_id FOREIGN KEY (medispan_drug_id) REFERENCES pillarrx.reference.medispan_drug (medispan_drug_id);
ALTER TABLE pillarrx.reference.fdb_drug_interaction ADD CONSTRAINT fk_reference_fdb_drug_interaction_fdb_drug_id FOREIGN KEY (fdb_drug_id) REFERENCES pillarrx.reference.fdb_drug (fdb_drug_id);
ALTER TABLE pillarrx.reference.fdb_pricing ADD CONSTRAINT fk_reference_fdb_pricing_fdb_drug_id FOREIGN KEY (fdb_drug_id) REFERENCES pillarrx.reference.fdb_drug (fdb_drug_id);
ALTER TABLE pillarrx.reference.fdb_pricing ADD CONSTRAINT fk_reference_fdb_pricing_ndc_id FOREIGN KEY (ndc_id) REFERENCES pillarrx.drug.ndc (ndc_id);
ALTER TABLE pillarrx.reference.medispan_drug ADD CONSTRAINT fk_reference_medispan_drug_ndc_id FOREIGN KEY (ndc_id) REFERENCES pillarrx.drug.ndc (ndc_id);
ALTER TABLE pillarrx.reference.medispan_gpi_hierarchy ADD CONSTRAINT fk_reference_medispan_gpi_hierarchy_medispan_pricing_id FOREIGN KEY (medispan_pricing_id) REFERENCES pillarrx.reference.medispan_pricing (medispan_pricing_id);
ALTER TABLE pillarrx.reference.ncpdp_pharmacy ADD CONSTRAINT fk_reference_ncpdp_pharmacy_dispensing_class_id FOREIGN KEY (dispensing_class_id) REFERENCES pillarrx.reference.ncpdp_dispensing_class (ncpdp_dispensing_class_id);
ALTER TABLE pillarrx.reference.ncpdp_pharmacy_service ADD CONSTRAINT fk_reference_ncpdp_pharmacy_service_ncpdp_number FOREIGN KEY (ncpdp_number) REFERENCES pillarrx.reference.ncpdp_pharmacy (ncpdp_number);  -- natural key FK
ALTER TABLE pillarrx.reference.nppes_other_identifier ADD CONSTRAINT fk_reference_nppes_other_identifier_npi FOREIGN KEY (npi) REFERENCES pillarrx.reference.nppes_provider (npi);  -- natural key FK
ALTER TABLE pillarrx.reference.nppes_provider_taxonomy ADD CONSTRAINT fk_reference_nppes_provider_taxonomy_npi FOREIGN KEY (npi) REFERENCES pillarrx.reference.nppes_provider (npi);  -- natural key FK
ALTER TABLE pillarrx.reference.nppes_provider_taxonomy ADD CONSTRAINT fk_reference_nppes_provider_taxonomy_taxonomy_code FOREIGN KEY (taxonomy_code) REFERENCES pillarrx.reference.nucc_taxonomy (taxonomy_code);  -- natural key FK

-- =============================================================================
-- END OF SCRIPT
-- =============================================================================