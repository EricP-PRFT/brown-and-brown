# PillarRx Vibe Modelling Agent -- v1 MVM Dry Run

## Widget Values

| Widget | Value |
|--------|-------|
| business_name | `pillarrx` |
| operation | `new base model` |
| run_type | `Dry Run` |
| data_model_scopes | `Minimum Viable Model - MVM` |
| business_domains | *(leave blank -- let agent infer)* |
| business_description | *(see below)* |
| model_vibes | *(see below)* |
| org_divisions | `Operations` |
| naming_convention | `snake_case` |
| primary_key_suffix | `_id` |
| table_id_type | `BIGINT` |

All other widgets: leave at defaults.

---

## business_description

```
PillarRx is a pharmacy benefit management (PBM) consulting firm operating as a division of Brown & Brown Insurance. PillarRx provides customized pharmacy solutions for employer-sponsored health plans, analyzing pharmacy spend across multiple PBMs on behalf of approximately 300 employer clients.

The business operates on a multi-tenant Company > Division > Client hierarchy. Each client is an employer whose health plan members fill prescriptions through one or more PBMs (CVS Caremark, Optum Rx, Express Scripts, Navitus, EmpiRx Health, BCBS Michigan, Rightway Healthcare, Prime Therapeutics, ServeYou, Carelon). PillarRx aggregates, normalizes, and analyzes pharmacy claims data across these PBMs to deliver consulting insights, copay assistance program management, PBM audit services, and affordability intelligence.

Core business functions:
- Pharmacy claims analysis and consulting (audit, benchmarking, trend analysis)
- Copay assistance program (CAP) management via the PAX application
- Member eligibility and benefits administration
- Drug reference and formulary analysis
- Manufacturer program management (copay cards, rebates, coupons, 340B)
- Prior authorization analysis
- Medical claims integration for total cost of care

Revenue comes from consulting fees, not insurance premiums. PillarRx does not adjudicate claims or manage formularies -- it audits and advises on PBM performance for its employer clients.
```

---

## model_vibes

```
PHARMACY CLAIMS ARE THE CORE. The central fact is the pharmacy claim transaction at the individual fill/reversal/adjustment grain. Every claim ties to a member, a drug (by NDC), a dispensing pharmacy (by NCPDP ID), a prescribing provider (by NPI), and a PBM. Claims carry financial amounts: ingredient cost, dispensing fee, plan paid, member copay, member coinsurance, deductible applied/remaining, out-of-pocket applied/remaining, other payer amount, and total cost.

MULTI-TENANT HIERARCHY IS FUNDAMENTAL. Company > Division > Client is the organizational grain. A company has divisions, a division has clients. Every claim, member, and benefit group is scoped to this hierarchy. Members are scoped to Company/Client (not Division). Some clients span multiple divisions and get separate division-specific data.

MEMBERS ARE HUMANS, NOT CLAIM RECORDS. A member is a real person (patient) who fills prescriptions. The same member may appear across multiple PBMs with different identifiers. Member 360 -- a unified view of a member across all data sources -- is a primary business objective. Members have demographics: name, gender, date of birth, address, phone, relationship to subscriber (subscriber/spouse/child/other), and a Medicare Beneficiary Identifier when applicable.

SUBSCRIBERS ARE DISTINCT FROM MEMBERS. A subscriber is the primary policyholder on the employer's plan. Members (dependents) are linked to subscribers. Subscriber data is often sparse from PBM sources.

DRUGS ARE KEYED BY NDC. The National Drug Code (11-digit) is the primary drug identifier. Drug reference data comes from external sources (Wolters Kluwer Medi-Span, First DataBank) and includes pricing (AWP, WAC), classification (therapeutic class, generic indicator), and package information. Drug dimensions should support Type-2 slowly changing history.

PHARMACIES ARE KEYED BY NCPDP ID. Pharmacy reference data comes from NCPDP and includes pharmacy type, chain/independent status, specialty designation, and NPI. Pharmacy dimensions should support Type-2 history.

PROVIDERS ARE KEYED BY NPI. Provider reference data comes from NPPES. The prescribing provider is the primary provider role on a claim. Provider taxonomy comes from NUCC.

PBMs ARE A CRITICAL DIMENSION. Each PBM (CVS, Optum, ESI, Navitus, etc.) has different file formats, field names, and business rules. The model must normalize across PBM formats into a canonical structure. PBM is an attribute of every claim.

BENEFIT GROUPS DRIVE CLIENT ANALYTICS. A benefit group represents a benefits configuration within a client. Benefit groups have history (Type-2 SCD) and carry the client's line of business classification. Client fiscal year/month is based on fill date aligned to client-specific fiscal calendars.

COPAY ASSISTANCE PROGRAMS (CAP) ARE A KEY DIFFERENTIATOR. PillarRx manages copay assistance programs that help members reduce out-of-pocket costs through manufacturer copay cards, coupons, and 340B programs. CAP has its own drug type classification, program tracking, and inclusion/exclusion logic. Daily claim-level and accumulator-level inclusion indicators drive program eligibility.

CLAIM STATUS MATTERS. Claims have statuses: paid, reversed, adjusted, rejected. Paid claims count as +1, reversed as -1, adjusted/rejected as 0 in transaction counts. Complete reversals and orphaned reversals are tracked. An adjusted transaction view nets adjustments into the related payment transaction for cleaner analytics.

PRIOR AUTHORIZATION is a data domain. PA data comes from sources like FMH, Agadia, and SureScripts.

MANUFACTURER PROGRAMS beyond copay cards include rebate programs and 340B federal drug discount programs.

MEDICAL CLAIMS are a secondary domain for total cost of care analysis, integrating medical and pharmacy spend.

DATE DIMENSIONS should be role-playing: fill date (date of service), submit date (adjudication/processing date), and load date (warehouse load date) all reference the same base date dimension.

LINEAGE AND AUDITABILITY ARE NON-NEGOTIABLE. Every record must trace back to its source PBM, source file, and original format. Durable business keys enable navigation from presentation layer back to raw acquisition records.
```
