# Data Strategy Summary

**Source:** Data Strategy.pdf (1-page steering committee overview)
**Classification:** FOR INTERNAL USE ONLY
**Context:** PillarRx 3.0 Steering Committee

## Overall Strategy

"A governed data foundation to accelerate client onboarding, Member 360, affordability intelligence, workflow automation and AI."

## Data Ecosystem (Source Systems)

Five source categories feed the platform:

1. **PBM / Client** — Claims, eligibility, benefits
2. **Prior Authorization** — FMH, Agadia, SureScripts
3. **Reference** — NCPDP, NPPES, drug data
4. **Manufacturer** — Copay, rebates, coupons, 340B
5. **Medical / Network** — Medical claims and pharmacy networks

## Modern Data Platform — Databricks Lakehouse

Five-stage pipeline:

1. **Ingest** — Reusable pipelines
2. **Standardize** — Quality and validation
3. **Integrate** — Canonical data model
4. **Govern** — Lineage and security
5. **Publish** — Gold data products

## Lakehouse Tiers

- **Bronze** — Raw / ingested
- **Silver** — Standardized / canonical
- **Gold** — Curated business data products

## Consumption Layer

- Member 360
- Affordability intelligence
- Reporting
- AI / ML
- Workflow automation
- APIs

## Priority Data Domains

1. Pharmacy claims & history
2. Member eligibility & benefits
3. Prior authorization data
4. Drug & reference data
5. Manufacturer programs
6. Medical claims & network data

## Strategic Outcomes

- Unified, trusted data foundation
- Faster partner and client onboarding
- AI-ready data for decisioning
- Improved quality and governance
- Scalable analytics and operations

## Steering Committee Takeaway

"Prioritize the highest-value data sources and establish scalable ingestion, governance and Gold-layer data products to accelerate Member 360 and future AI capabilities."

## Key Observations

- This is **PBM (Pharmacy Benefit Management)** focused — not the full B&B insurance brokerage. The engagement appears to be for B&B's PBM/pharmacy benefits consulting arm.
- "PillarRx 3.0" is the initiative name.
- The canonical data model is at the Silver tier — the vibe modelling agent would be relevant here.
- Member 360 is a primary consumption use case — implies a unified member/patient view across pharmacy, medical, and eligibility data.
- "Affordability intelligence" is a key differentiator — likely analyzing copay programs, manufacturer rebates, and 340B to optimize member costs.
