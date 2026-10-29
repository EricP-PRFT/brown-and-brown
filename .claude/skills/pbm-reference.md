# PBM Industry Reference

Load this skill when working with pharmacy claims data, writing vibes for the modeling agent, reviewing data model output, or interpreting PBM source files. This is domain knowledge for the pharmacy benefit management consulting space -- not general insurance.

## Querying the Databricks Catalog

When you need to check the current state of tables, columns, or types in the
pillarrx catalog, query it directly rather than relying on local files. The
Databricks CLI (v0.288.0) does not have a `sql execute` command. Use the REST
API via PowerShell (not Git Bash -- Bash mangles `/api/...` paths).

1. Write the query payload to a temp JSON file:

```json
{
  "warehouse_id": "000000000000000d",
  "statement": "SELECT ... FROM pillarrx.information_schema.columns WHERE ...",
  "wait_timeout": "30s",
  "format": "JSON_ARRAY"
}
```

2. Execute via PowerShell:

```powershell
databricks api post /api/2.0/sql/statements --profile brown_and_brown --json "@tmp_query.json"
```

3. Clean up the temp file after use.

Key details:
- Warehouse `000000000000000d` (Reyden Warehouse) is usually RUNNING
- `"format": "JSON_ARRAY"` returns readable results; the default is Arrow binary
- Results come back in `result.data_array` as arrays of values
- Always use PowerShell for this command. Git Bash rewrites `/api/2.0/...` to
  `/Program Files/Git/api/2.0/...`

---

## What a PBM Does

A Pharmacy Benefit Manager (PBM) is the middleman between health plan sponsors (employers, unions, government programs) and the pharmacy supply chain. PBMs:

- Negotiate drug prices and rebates with manufacturers
- Build and manage formularies (which drugs are covered and at what tier)
- Process and adjudicate pharmacy claims at point of sale
- Contract with pharmacy networks (retail, mail-order, specialty)
- Administer prior authorization and step therapy programs
- Report utilization and cost data back to plan sponsors

B&B/PillarRx does **not** operate as a PBM. They are an independent consultant that audits PBM performance, analyzes claims data across multiple PBMs for a single employer client, and identifies cost savings opportunities.

---

## Standard Identifiers

### NDC (National Drug Code) -- 11-digit

The FDA's universal drug product identifier. Structure: `LLLLL-PPPP-SS`

| Segment | Name | Digits | Identifies |
|---------|------|--------|------------|
| L | Labeler | 5 | Manufacturer, repackager, or distributor |
| P | Product | 4 | Specific strength, dosage form, formulation |
| S | Package | 2 | Package size and type |

- FDA publishes NDCs in 4-4-2, 5-3-2, and 5-4-1 formats; the industry standard normalizes to 5-4-2 (11 digits, zero-padded)
- NDCs are recycled: a retired NDC can be reassigned to a different drug after 5 years
- Not all NDCs appear in claims; only dispensed products do

### NPI (National Provider Identifier) -- 10-digit

CMS-assigned identifier for healthcare providers (individuals and organizations).

| Type | Meaning |
|------|---------|
| Type 1 | Individual provider (physician, pharmacist, nurse practitioner) |
| Type 2 | Organization (hospital, pharmacy, group practice) |

- Luhn check digit (position 10)
- Always starts with `1` or `2`
- Source of truth: NPPES (National Plan and Provider Enumeration System)
- In pharmacy claims, two NPIs matter: **dispensing pharmacy NPI** (Type 2) and **prescriber NPI** (Type 1)

### NCPDP Provider ID -- 7-digit

National Council for Prescription Drug Programs identifier for pharmacies.

- Uniquely identifies a pharmacy location (not a chain -- each store has its own ID)
- Used as the primary pharmacy key in claims adjudication
- NCPDP also maintains the pharmacy database with address, type, specialty, chain affiliation
- Linked to but distinct from the pharmacy's NPI

### DEA Number

Drug Enforcement Administration registration number for controlled substance prescribing.

- Format: 2 letters + 6 digits + 1 check digit (e.g., `AB1234563`)
- First letter: registrant type (A/B = dispensers, F = manufacturers, M = mid-level practitioners)
- Second letter: first letter of registrant's last name
- Not all prescribers have one; only those who prescribe controlled substances

### GPI (Generic Product Identifier) -- 14-digit

Medi-Span's hierarchical drug classification code.

| Positions | Level | Example |
|-----------|-------|---------|
| 1-2 | Drug group | `39` = Antihyperlipidemic |
| 3-4 | Drug class | `3940` = HMG CoA Reductase Inhibitors |
| 5-6 | Drug subclass | `394000` = HMG CoA Reductase Inhibitors |
| 7-8 | Drug name | `39400010` = Atorvastatin Calcium |
| 9-10 | Drug name extension | `3940001000` = Atorvastatin Calcium |
| 11-12 | Dosage form | `394000100020` = Tablet |
| 13-14 | Strength | `39400010002010` = 10mg |

### AHFS (American Hospital Formulary Service) Therapeutic Classification

Alternative to GPI, published by ASHP. 6-digit hierarchical code.

### MBI (Medicare Beneficiary Identifier) -- 11-character

CMS-assigned Medicare ID (replaced the old SSN-based HICN in 2019).

- Format: `XAXXAXXXXAX` where X=digit (0-9), A=uppercase letter (excluding S, L, O, I, B, Z)
- Position 1 is always numeric (not 0, 8, or 9)
- Used in Medicare Part D pharmacy claims

---

## Pharmacy Claim Anatomy

A pharmacy claim transaction represents a single dispensing event at a pharmacy. Every claim contains these conceptual groups:

### Identification

| Field | Purpose |
|-------|---------|
| Claim number | PBM-assigned unique claim identifier |
| Rx number | Prescription number from the pharmacy |
| Fill number | 0 = new, 1+ = refill |
| Date of service | When the drug was dispensed |
| Adjudication date | When the PBM processed/paid the claim |

### Patient / Member

| Field | Purpose |
|-------|---------|
| Member ID | PBM-assigned member identifier (varies by PBM) |
| Cardholder/Subscriber ID | The policyholder on the employer plan |
| Patient name, DOB, gender | Demographics |
| Relationship code | Subscriber (01), Spouse (02), Child (03), Other (04+) |
| Person code | Distinguishes family members under one subscriber |

### Drug

| Field | Purpose |
|-------|---------|
| NDC | 11-digit National Drug Code |
| Drug name | Brand or generic product name |
| GPI | Medi-Span classification |
| DAW code | Dispense As Written (0-9, per NCPDP standard) |
| Quantity dispensed | Metric units (tablets, mL, grams) |
| Days supply | Duration the dispensed quantity should last |
| Brand/generic indicator | B, G, or specialty/biosimilar variants |
| Compound flag | Whether the Rx is a compounded preparation |

### DAW (Dispense As Written) Codes

| Code | Meaning |
|------|---------|
| 0 | No product selection indicated (substitution permitted) |
| 1 | Substitution not allowed by prescriber |
| 2 | Substitution allowed -- patient requested brand |
| 3 | Substitution allowed -- pharmacist selected brand |
| 4 | Substitution allowed -- generic not in stock |
| 5 | Substitution allowed -- brand dispensed as generic |
| 6 | Override |
| 7 | Substitution not allowed -- brand mandated by law |
| 8 | Substitution allowed -- generic not available |
| 9 | Other |

### Provider / Pharmacy

| Field | Purpose |
|-------|---------|
| Prescriber NPI | Who wrote the prescription |
| Prescriber name, specialty | Prescriber demographics |
| Pharmacy NCPDP ID | Where the drug was dispensed |
| Pharmacy NPI | Pharmacy's NPI (distinct from NCPDP) |
| Pharmacy name, type | Retail, mail-order, specialty |
| Network indicator | In-network vs. out-of-network |

### Financials

| Field | Meaning | Typical Range |
|-------|---------|---------------|
| Ingredient cost | Drug acquisition cost as adjudicated | $1 - $50,000+ |
| Dispensing fee | Pharmacy service fee | $0 - $15 |
| Sales tax | Where applicable | $0 - $5 |
| Total cost | Ingredient + dispensing + tax | Sum |
| Plan paid | Amount the health plan pays | Bulk of cost |
| Member copay | Fixed dollar cost share | $0 - $100 |
| Member coinsurance | Percentage-based cost share | $0 - $500+ |
| Deductible applied | Amount applied to annual deductible | $0 - $2,000 |
| Deductible remaining | Remaining deductible balance | Decreasing |
| OOP applied | Applied to out-of-pocket maximum | $0 - $5,000 |
| OOP remaining | Remaining before catastrophic coverage | Decreasing |
| Other payer amount | Secondary insurance, copay card, manufacturer coupon | $0 - $1,000+ |

**Key relationship:** `Total cost = Plan paid + Member copay + Member coinsurance + Deductible applied + Other payer`

### Claim Status and Lifecycle

| Status | rx_count | Meaning |
|--------|----------|---------|
| Paid | +1 | Adjudicated and paid normally |
| Reversed | -1 | Cancelled a prior paid claim |
| Adjusted | 0 | Correction (reversal + re-adjudication pair) |
| Rejected | 0 | Denied at point of sale; not paid |

- A **complete reversal** has a matching paid claim
- An **orphaned reversal** has no matching paid claim in the dataset
- The **adjusted view** nets adjustments into related payment records for cleaner analytics

---

## Drug Pricing Benchmarks

| Benchmark | Full Name | Source | Purpose |
|-----------|-----------|--------|---------|
| AWP | Average Wholesale Price | Medi-Span, FDB | Industry list price benchmark; PBM contracts often expressed as "AWP minus X%" |
| WAC | Wholesale Acquisition Cost | Medi-Span, FDB | Manufacturer's published list price to wholesalers; lower than AWP |
| MAC | Maximum Allowable Cost | PBM-specific | PBM's ceiling price for generic drugs; each PBM maintains its own MAC list |
| NADAC | National Average Drug Acquisition Cost | CMS | Survey-based actual pharmacy acquisition cost |
| U&C | Usual and Customary | Pharmacy | Pharmacy's cash price without insurance |
| 340B | 340B ceiling price | HRSA | Deeply discounted price for eligible covered entities |

**AWP spread:** AWP is typically 20-25% above WAC. PBM contract discounts (e.g., "AWP - 17% brand, AWP - 85% generic") are measured against AWP.

**GER/BER (Generic/Brand Effective Rate):** PBM contract guarantee metrics. GER = average generic discount off AWP across all generic claims. BER = same for brand.

---

## Formulary and Benefit Design

### Formulary Tiers (typical)

| Tier | Contents | Member Cost Share |
|------|----------|-------------------|
| Tier 1 | Preferred generics | Lowest ($5-$15 copay) |
| Tier 2 | Non-preferred generics, preferred brands | Moderate ($25-$50) |
| Tier 3 | Non-preferred brands | Higher ($50-$100) |
| Tier 4 | Specialty drugs | Highest (20-33% coinsurance, $100-$500+) |
| Tier 5 | Specialty/biosimilar (some plans) | Varies |

### Utilization Management (UM) Controls

| Control | Abbreviation | Meaning |
|---------|--------------|---------|
| Prior Authorization | PA | PBM must approve before dispensing |
| Step Therapy | ST | Must try cheaper drug first before coverage of expensive one |
| Quantity Limit | QL | Cap on units or days supply per fill or per time period |

### Benefit Accumulators

- **Deductible**: Amount member pays before plan coverage begins
- **Out-of-Pocket Maximum (MOOP)**: Annual cap on member cost-sharing; plan pays 100% after
- **True Out-of-Pocket (TrOOP)**: Medicare Part D-specific; counts toward catastrophic coverage threshold
- Accumulators track at **member** and/or **family/subscriber** level
- Reset annually per the plan's benefit period (calendar year or fiscal year)

---

## Cost-Saving and Cost-Sharing Programs

The PBM ecosystem has dozens of programs that reduce drug costs for patients, plan sponsors, or both. Understanding these is essential for PillarRx's consulting work: auditing whether savings are reaching the client, identifying missed opportunities, and modeling benefit design changes.

### Manufacturer Rebates

Rebates are post-adjudication payments from manufacturers to PBMs/plan sponsors in exchange for formulary access and market share. They are the single largest cost-reduction lever in commercial pharmacy benefits.

| Rebate Type | Description | Who Benefits |
|-------------|-------------|--------------|
| Formulary placement rebates | Manufacturer pays PBM/plan for preferred formulary position (Tier 1/2 vs Tier 3) | Plan sponsor (reduced net cost) |
| Market share rebates | Volume-based rebates triggered when a drug hits utilization thresholds | Plan sponsor |
| Admin fees | Fees manufacturers pay PBMs for formulary management services; often bundled with rebates | PBM / plan sponsor |
| Inflation rebates (Medicaid MDRP) | Medicaid Drug Rebate Program: manufacturers pay unit rebate amount (URA) + additional rebate if price rises faster than CPI | Medicaid programs |
| Medicare inflation rebates (IRA) | Under the Inflation Reduction Act, manufacturers pay rebates to Medicare if drug prices rise faster than inflation | Medicare program |

**Rebate pass-through vs. retention:** Whether the PBM passes 100% of manufacturer rebates to the plan sponsor or retains a share. Increasingly, plans demand full pass-through contracts. PillarRx audits rebate guarantees (GER/BER) and pass-through rates.

### Manufacturer Patient Assistance Programs (PAPs)

| Program | Description | Eligibility |
|---------|-------------|-------------|
| Copay cards / copay coupons | Manufacturer subsidizes patient's copay/coinsurance for brand drugs, reducing OOP to $0-$25 | Commercial insurance only (prohibited for Medicare/Medicaid under Anti-Kickback Statute) |
| eVouchers | Electronic point-of-sale copay coupons processed automatically at the pharmacy | Commercial insurance |
| Free drug / PAP programs | Manufacturer provides drug at no cost to income-qualified uninsured/underinsured patients | Income-qualified, typically < 200-400% FPL |
| Bridge / starter programs | Free drug supply (typically 30 days) while patient's coverage is being determined | Patients awaiting PA or coverage determination |
| Hub / support programs | Specialty drug support: enrollment, benefits investigation, financial assistance, adherence coaching, nurse support | Specialty drug patients |
| Buy-and-bill replacement programs | Manufacturer provides physician-administered drugs at reduced or no cost for qualifying patients | Provider-administered specialty drugs |

### Copay Accumulator and Maximizer Programs

These programs govern how manufacturer copay assistance interacts with the patient's benefit accumulators (deductible, OOP max). They are a major audit and consulting focus for PillarRx.

| Program | How It Works | Patient Impact | Plan Sponsor Impact |
|---------|--------------|----------------|---------------------|
| Copay accumulator (CAAP) | Manufacturer copay assistance does NOT count toward the patient's deductible or OOP max | Patient hits a "cliff" when the copay card maxes out -- suddenly owes full cost-sharing | Plan retains full cost-sharing credit; lower net cost |
| Copay maximizer | PBM calibrates the patient's copay each fill to stretch manufacturer assistance across the full year | Patient pays $0 OOP all year, but the manufacturer card is drained evenly | Plan benefits from manufacturer subsidy all 12 months |
| Alternative funding programs (AFP) | Third-party vendors route high-cost specialty patients to manufacturer PAPs or charitable foundations to shift cost off the plan | Patient gets drug free or at reduced cost | Plan avoids the claim cost entirely |

**Regulatory note:** Several states have passed copay accumulator reform laws requiring manufacturer assistance to count toward deductible/OOP. Federal rules remain in flux. PillarRx tracks accumulator/maximizer rules per PBM and per plan.

### 340B Drug Pricing Program

HRSA-administered federal program requiring manufacturers to sell outpatient drugs to eligible covered entities at deep discounts (typically 25-50% below AWP) as a condition of participating in Medicaid.

| Aspect | Description |
|--------|-------------|
| Covered entities | DSH hospitals, children's hospitals, cancer hospitals, sole community hospitals, FQHCs, Ryan White grantees, hemophilia centers, TB/STD clinics, family planning clinics, and others |
| Contract pharmacy | Covered entities contract with external retail/specialty pharmacies to dispense 340B drugs, extending reach beyond the entity's own pharmacy |
| 340B savings margin | Entity buys at 340B ceiling price, bills insurer at standard rate; margin funds care for indigent/uninsured patients |
| Duplicate discount prohibition | A drug cannot receive both a 340B discount and a Medicaid rebate on the same claim |
| Scale | Covered entities purchase ~$54B+ in 340B drugs annually; DSH hospitals account for the majority |

### Government and Regulatory Programs

| Program | Description |
|---------|-------------|
| Medicare Part D standard benefit | Four phases: deductible, initial coverage, coverage gap, catastrophic coverage |
| Part D $2,000 OOP cap (IRA) | Annual Part D beneficiary OOP capped at $2,000 starting 2025 |
| Part D manufacturer discount program | Post-IRA redesign: manufacturers pay 10% discount in initial coverage phase, 20% in catastrophic phase |
| Low-Income Subsidy (LIS / "Extra Help") | Federal subsidy covering Part D premiums, deductibles, and copays for low-income Medicare beneficiaries |
| Medicare drug price negotiation (IRA) | CMS negotiates maximum fair prices for select high-spend, single-source Part D and Part B drugs |
| Medicaid Drug Rebate Program (MDRP) | Statutory rebates: 23.1% of AMP for brands, 13% for generics, plus additional rebates for price increases above CPI |
| Medicaid best price | Lowest price manufacturer offers any commercial buyer (with exceptions) -- floor for Medicaid rebate calculation |
| Medicaid supplemental rebates | States negotiate additional rebates beyond the federal minimum, often via preferred drug lists |
| State Pharmaceutical Assistance Programs (SPAPs) | State-funded programs providing additional drug cost assistance (e.g., NJ PAAD, NY EPIC) |
| VA Federal Supply Schedule (FSS) | VA negotiates prices at least 24% below non-federal AMP; often deeper discounts than 340B |
| $35 insulin cap (IRA) | Insulin cost-sharing limited to $35/month for Medicare; many commercial plans adopted voluntarily |
| Part D vaccine cost elimination (IRA) | All adult vaccines covered under Part D at $0 cost-sharing |

### PBM-Administered Cost Management Tools

| Tool | Description |
|------|-------------|
| Formulary tiering | Drugs assigned to cost-sharing tiers; preferred drugs = lower copays to steer utilization |
| Formulary exclusion lists | Drugs removed from coverage entirely, forcing switch to covered alternatives |
| Mandatory generic substitution | Plan requires generic when available; DAW 0 overrides brand dispensing |
| Step therapy (ST) | Patient must try/fail on cheaper drug before plan covers more expensive alternative |
| Prior authorization (PA) | PBM must approve drug before dispensing; controls access to high-cost or clinically sensitive drugs |
| Quantity limits (QL) | Caps on units or days supply per fill or per time period |
| Mail-order incentives | Lower copays or mandatory use of mail-order for maintenance drugs (typically 90-day supply) |
| Preferred pharmacy networks | Lower copays at network pharmacies; narrow networks drive volume to pharmacies with better PBM contract terms |
| MAC (Maximum Allowable Cost) lists | PBM-maintained ceiling price for generic drugs; controls generic reimbursement to pharmacies |
| Specialty pharmacy management | Mandatory use of PBM-owned or preferred specialty pharmacies for high-cost drugs |
| Biosimilar substitution programs | Incentives or mandates to use biosimilars over reference biologics |
| Point-of-sale rebate pass-through | Rebate applied at time of dispensing, directly reducing patient copay (vs. traditional post-adjudication rebates) |
| Drug utilization review (DUR) | Clinical screening at point of sale for interactions, duplicates, dose issues -- prevents unnecessary fills |
| Medication therapy management (MTM) | Pharmacist-led review programs to optimize therapy and reduce waste |

### Third-Party and Charitable Programs

| Program | Description |
|---------|-------------|
| Pharmacy discount cards | GoodRx, SingleCare, RxSaver -- negotiated cash prices, not insurance; often cheaper than copay for generics |
| Charitable foundations | PAN Foundation, HealthWell Foundation, Patient Access Network, Good Days -- copay/premium assistance for specific diseases, funded by manufacturer donations (under OIG scrutiny for Anti-Kickback concerns) |
| Pharmacy loyalty/savings programs | Retailer programs (CVS ExtraCare, Walgreens Rx Savings) offering discounts on select generics |

### Plan Sponsor Benefit Design Strategies

| Strategy | Description |
|----------|-------------|
| Value-based insurance design (VBID) | Lower cost-sharing for high-value drugs (e.g., $0 copay for diabetes/heart meds) to improve adherence |
| Reference-based pricing | Plan pays up to a benchmark price for a drug class; patient pays the difference for costlier options |
| Outcomes-based contracts | Manufacturer rebates tied to clinical outcomes (e.g., rebate if drug doesn't achieve target A1c) |
| Specialty carve-out | Separate specialty drug management from the primary PBM to a specialty-focused vendor |
| Employer-funded Rx assistance | Employer directly subsidizes high-cost prescriptions for employees beyond standard benefit |
| Stop-loss / reinsurance | Self-insured plans purchase reinsurance to cap exposure on high-cost claims |

### PBM Revenue and Financial Flow Mechanisms

Not "cost-saving programs" for patients or plans, but essential to understanding where money moves in the system. PillarRx audits for these when evaluating PBM contract performance.

| Mechanism | Description |
|-----------|-------------|
| Spread pricing | PBM charges plan more than it reimburses the pharmacy, retaining the spread |
| DIR fees (Direct and Indirect Remuneration) | Post-adjudication fees PBMs charge pharmacies; reduce effective reimbursement after the fact (moving to point-of-sale under CMS rules) |
| Chargebacks | Wholesaler charges manufacturer the difference between WAC and contract price when a pharmacy buys through distribution |
| Administrative fees | Fees PBMs charge manufacturers for rebate processing, formulary management, data services |
| Rebate aggregation / GPO fees | Fees for group purchasing organization services in rebate contracting |

---

## PBM-Specific Considerations

Each PBM sends data in different formats. Key variations:

| Dimension | Variation Across PBMs |
|-----------|-----------------------|
| File format | Pipe-delimited, fixed-width, CSV; varying column counts (52 to 256) |
| Column names | Same concept, different names (e.g., `DATE_OF_SERVICE` vs `SVC_DT` vs `FILL_DATE`) |
| Member ID format | Numeric, alphanumeric, varying lengths |
| Claim number format | Different structures and lengths |
| Status codes | P/R/A vs 01/02/03 vs PAID/VOID vs custom |
| Gender codes | M/F vs 1/2 vs MALE/FEMALE |
| Relationship codes | 01-04 vs 1-4 vs SUBSCRIBER/SPOUSE/CHILD |
| Benefit group derivation | Different rules per PBM for which field carries the benefit group |
| Financial field naming | INGREDIENT_COST vs ING_COST vs IC_AMT |

**This is why the canonical model matters**: 891 raw columns across 10+ PBMs normalize into ~113 canonical columns.

---

## Regulatory and Compliance

| Regulation | Relevance |
|------------|-----------|
| HIPAA | PHI/PII protection; member demographics, claims data |
| Medicare Part D | Federal pharmacy benefit; CMS reporting, PDE (Prescription Drug Event) files |
| Medicaid | State pharmacy benefit; rebate program (MDRP) |
| 340B Drug Pricing Program | HRSA-administered; covered entities get discounted drugs |
| ERISA | Federal law governing employer-sponsored health plans |
| State PBM transparency laws | Varying by state; audit rights, spread pricing disclosure |
| DIR fees (Direct and Indirect Remuneration) | Post-adjudication pharmacy fees/clawbacks; moving to point-of-sale under CMS rules |

---

## External Reference Data Sources

These are the external standards bodies and data vendors that supply the reference data PBMs, pharmacies, and consultants like PillarRx depend on. Understanding what each source provides -- and where their data shows up in claims -- is essential for data modeling, mapping, and auditing.

### NCPDP (National Council for Prescription Drug Programs)

**Website:** https://www.ncpdp.org/

**What it is:** Industry standards body and pharmacy database operator. NCPDP defines the electronic formats used to transmit pharmacy claims and prescriptions across the US supply chain.

**Standards (transaction formats):**

| Standard | Purpose |
|----------|---------|
| Telecom (D.0) | Real-time pharmacy claim submission and adjudication at point of sale |
| SCRIPT | Electronic prescribing (NewRx, RxRenewal, CancelRx, RxTransfer) between prescribers and pharmacies |
| Batch | Bulk claim submission/response for non-real-time processing |
| Post-Adjudication | Remittance advice, explanation of benefits, and post-payment adjustments |
| Formulary & Benefit (F&B) | Formulary status, copay tiers, PA/ST/QL requirements communicated to prescriber systems |
| Specialty | Standards for specialty pharmacy workflows |

**NCPDP Provider Database:** The authoritative pharmacy directory. Each pharmacy location gets a unique 7-digit NCPDP Provider ID. The database includes:

- NCPDP ID, NPI, DEA number
- Physical address and contact information
- Chain code and affiliation
- Pharmacy type (community, institutional, mail-order, specialty, long-term care)
- Dispensing class (retail, mail, specialty)
- Services offered (compounding, DME, immunizations, MTM)
- Operational status (active, closed, change of ownership)
- Provider taxonomy code (from NUCC)

**DataQ:** NCPDP's data quality and analytics product for pharmacy network management and credentialing.

**Where NCPDP data appears in claims:** The NCPDP Provider ID is the primary pharmacy identifier on every pharmacy claim. The Telecom standard defines the field layout for claim submission. Column names like `NCPDP_PROVIDER_ID`, `PHARMACY_NCPDP`, and `SERVICE_PROVIDER_ID` all trace back to this source.

### FDB (First DataBank)

**Website:** https://www.fdbhealth.com/

**What it is:** Drug data compendia publisher owned by Hearst Health. One of the two dominant sources of drug reference data in the US (the other being Medi-Span). FDB data underpins clinical decision support, claims adjudication, and drug pricing across hospitals, pharmacies, health plans, and PBMs.

**Key products:**

| Product | Purpose |
|---------|---------|
| MedKnowledge / NDDF | Flagship integrated drug database: NDC-level attributes, clinical modules, pricing |
| Enhanced Therapeutic Classification (ETC) | Hierarchical drug classification by therapeutic use (analogous to Medi-Span GPI) |
| AnalySource | Drug pricing analytics: AWP, WAC, FUL, state MAC lists, historical trending |
| AlertSpace | Clinical alerting engine that filters low-value drug interaction alerts (addresses alert fatigue) |
| FDB Vela | ePrescribing network connecting prescribers, pharmacies, and payers |

**MedKnowledge NDC-level attributes:**

- Identifiers: NDC (5-4-2), labeler code, product code, package code, UPC/UPN
- Drug description: proprietary name, generic name, strength, dosage form, route
- Classification: ETC code, AHFS code, DEA schedule, brand/generic indicator, OTC/Rx status
- Package: size, quantity, unit of measure
- Pricing: AWP, WAC, federal upper limit (FUL), suggested wholesale price
- Therapeutic equivalence: FDA Orange Book TE codes, AB-rated generics
- Manufacturer: labeler name, repackager flag

**Clinical modules (power DUR screening at point of sale):**

- Drug-drug interactions
- Drug-allergy screening
- Duplicate therapy detection
- Dose range checking
- Drug-disease contraindications
- IV compatibility

**FDB vs. Medi-Span in PBM consulting:** Medi-Span GPI is more common on PBM claims files. FDB's ETC appears when a PBM or health plan uses FDB as their drug database vendor. Both publish AWP/WAC pricing; discrepancies between them are a known audit finding.

### Medi-Span (Wolters Kluwer)

**Website:** https://www.wolterskluwer.com/en/solutions/medi-span/medi-span/drug-data

**What it is:** Drug data compendia publisher and the dominant drug classification/pricing source in PBM claims adjudication. Medi-Span's GPI code appears on most PBM claims files.

**Key products:**

| Product | Purpose |
|---------|---------|
| Master Drug Database (MDDB) | Comprehensive NDC-level drug file: identifiers, descriptions, classifications, pricing |
| GPI (Generic Product Identifier) | 14-digit hierarchical drug classification (see Standard Identifiers section above) |
| Price Alert / Price Rx | AWP, WAC, FUL pricing with update frequency and historical data |
| Clinical modules | Drug interactions, duplicate therapy, dose range checking (bundled with MDDB) |

**GPI hierarchy (14-digit, 7 levels):**

| Positions | Level |
|-----------|-------|
| 1-2 | Drug group (e.g., 39 = Antihyperlipidemic) |
| 3-4 | Drug class |
| 5-6 | Drug subclass |
| 7-8 | Drug name (generic entity) |
| 9-10 | Drug name extension |
| 11-12 | Dosage form |
| 13-14 | Strength |

**Where Medi-Span data appears in claims:** GPI codes, AWP/WAC pricing, brand/generic indicators, therapeutic class groupings. Column names like `GPI`, `GPI_14`, `DRUG_GROUP`, `AWP_UNIT_PRICE`, `WAC_UNIT_PRICE` trace to Medi-Span. The GPI is the primary drug classification used in formulary analysis and therapeutic reporting across PBMs.

### NUCC (National Uniform Claim Committee)

**Website:** https://www.nucc.org/

**What it is:** Standards body that maintains the Healthcare Provider Taxonomy Code Set -- the standard classification for healthcare provider types and specialties.

**Taxonomy code structure:** 10-character alphanumeric code with 3 hierarchical levels:

| Level | Description | Example |
|-------|-------------|---------|
| Type (Level 1) | Broad provider category | Individual, Group, Facility |
| Classification (Level 2) | Provider specialty | Internal Medicine, Pharmacy |
| Specialization (Level 3) | Sub-specialty | Cardiology, Oncology Pharmacy |

Example: `207RC0000X` = Allopathic physician (207R) / Internal Medicine (C0000) / General (X)

**Where NUCC data appears in claims:** Provider taxonomy codes on prescriber and pharmacy records. The taxonomy code links to NPI records in NPPES. Column names like `PROVIDER_TAXONOMY`, `PRESCRIBER_SPECIALTY_CODE`, `PHARMACY_TYPE_CODE` may carry NUCC taxonomy values.

### NPPES (National Plan and Provider Enumeration System)

**Website:** https://nppes.cms.hhs.gov/

**What it is:** CMS-operated registry and source of truth for NPI (National Provider Identifier) assignments. Every healthcare provider (individual or organization) that transmits HIPAA transactions must have an NPI from NPPES.

**Data available:**

| Field | Description |
|-------|-------------|
| NPI | 10-digit unique identifier |
| Entity type | Type 1 (individual) or Type 2 (organization) |
| Provider name | Legal name, authorized official |
| Taxonomy codes | Primary and secondary NUCC taxonomy codes |
| Addresses | Practice location and mailing address |
| Identifiers | State license numbers, DEA number (when reported) |
| Enumeration date | When the NPI was assigned |
| Deactivation info | Whether the NPI has been deactivated and when |

**Downloadable files:**

- Monthly full dissemination (~8GB compressed): complete NPI registry
- Weekly incremental updates: changes since last full file
- Available from CMS at no cost

**Where NPPES data appears in claims:** Every pharmacy claim has at least two NPIs -- the dispensing pharmacy NPI (Type 2) and the prescriber NPI (Type 1). NPPES is the lookup source for resolving NPI to provider name, specialty, and address. Column names like `PRESCRIBER_NPI`, `PHARMACY_NPI`, `SERVICE_PROVIDER_NPI`, `PRESCRIBER_LAST_NAME` ultimately trace back to NPPES-registered data.

---

## Key Metrics in PBM Consulting

| Metric | Formula / Meaning |
|--------|-------------------|
| PMPM (Per Member Per Month) | Total cost / member-months |
| PMPY (Per Member Per Year) | PMPM * 12 |
| Generic Dispensing Rate (GDR) | Generic claims / total claims |
| Generic Fill Rate (GFR) | Generic fills / (generic + multi-source brand fills) |
| AWP Discount % | 1 - (ingredient cost / AWP) |
| Mail-order penetration | Mail claims / total claims |
| Specialty % of spend | Specialty cost / total cost (often 50%+) |
| Adherence (PDC) | Proportion of Days Covered over measurement period |
| 30-day equivalent | Normalizes 90-day fills to 30-day units for utilization counts |
| Rebate per claim | Total rebates / paid claim count |
