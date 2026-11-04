"""Generate pillarrx_create_catalog.sql from metamodel data."""
import json
import re
import sys

# --- Load attributes from API response ---
with open(r"C:\Users\eric.pedrotty\Documents\Code\BrownAndBrown\tmp_attrs_raw.json", "r", encoding="utf-8-sig") as f:
    attrs_resp = json.load(f)

rows = attrs_resp["result"]["data_array"]
# columns: domain, product, column_name, type, foreign_key_to, tags, description

# --- Load FK links from v40 session result ---
with open(
    r"C:\Users\eric.pedrotty\.claude\projects\c--Users-eric-pedrotty-Documents-Code-BrownAndBrown"
    r"\fefe40f2-029c-4f04-84fe-34e557585ad3\tool-results\bitc5quke.txt",
    "r", encoding="utf-8",
) as f:
    session_resp = json.load(f)

# Find the session ended event (has fk_links in result_json)
fk_links = []
for row in session_resp["result"]["data_array"]:
    event_seq, message, result_json_str = row[0], row[1], row[2]
    if "Pipeline completed" in str(message):
        result = json.loads(result_json_str) if isinstance(result_json_str, str) else result_json_str
        fk_links = result.get("fk_links", [])
        break

# --- Products with PKs (hardcoded from the query we already ran) ---
products = {
    ("claim", "adjustment"): "adjustment_id",
    ("claim", "claim_benefit_group"): "claim_benefit_group_id",
    ("claim", "claim_pbm"): "claim_pbm_id",
    ("claim", "claim_prescriber"): "claim_prescriber_id",
    ("claim", "cob"): "cob_id",
    ("claim", "dur_event"): "dur_event_id",
    ("claim", "medical_claim"): "medical_claim_id",
    ("claim", "member_oop_accumulator"): "member_oop_accumulator_id",
    ("claim", "pbm_feed_batch"): "pbm_feed_batch_id",
    ("claim", "prior_auth"): "prior_auth_id",
    ("claim", "rebate_record"): "rebate_record_id",
    ("claim", "rx_claim"): "rx_claim_id",
    ("claim", "rx_claim_line"): "rx_claim_line_id",
    ("client", "audit_finding"): "audit_finding_id",
    ("client", "benefit_plan"): "benefit_plan_id",
    ("client", "cap_program_enrollment"): "cap_program_enrollment_id",
    ("client", "client_benefit_group"): "client_benefit_group_id",
    ("client", "client_consulting_engagement"): "client_consulting_engagement_id",
    ("client", "client_engagement_deliverable"): "client_engagement_deliverable_id",
    ("client", "consulting_fee_invoice"): "consulting_fee_invoice_id",
    ("client", "contact"): "contact_id",
    ("client", "data_feed_config"): "data_feed_config_id",
    ("client", "document"): "document_id",
    ("client", "employer"): "employer_id",
    ("client", "onboarding_event"): "onboarding_event_id",
    ("client", "pbm_assignment"): "pbm_assignment_id",
    ("client", "pbm_contract"): "pbm_contract_id",
    ("company", "client_contact"): "client_contact_id",
    ("company", "client_division_assignment"): "client_division_assignment_id",
    ("company", "client_onboarding"): "client_onboarding_id",
    ("company", "client_pbm_contract"): "client_pbm_contract_id",
    ("company", "company_benefit_group"): "company_benefit_group_id",
    ("company", "company_client"): "company_client_id",
    ("company", "company_consulting_engagement"): "company_consulting_engagement_id",
    ("company", "company_engagement_deliverable"): "company_engagement_deliverable_id",
    ("company", "company_pbm"): "company_pbm_id",
    ("company", "consulting_fee"): "consulting_fee_id",
    ("company", "member"): "member_id",
    ("company", "org_division"): "org_division_id",
    ("company", "organization"): "organization_id",
    ("company", "subscriber"): "subscriber_id",
    ("company", "tenant_change_log"): "tenant_change_log_id",
    ("division", "division"): "division_id",
    ("division", "division_benefit_group"): "division_benefit_group_id",
    ("division", "division_formulary"): "division_formulary_id",
    ("division", "division_formulary_tier"): "division_formulary_tier_id",
    ("division", "division_pbm_contract"): "division_pbm_contract_id",
    ("division", "engagement"): "engagement_id",
    ("division", "formulary_drug_placement"): "formulary_drug_placement_id",
    ("division", "pbm_feed"): "pbm_feed_id",
    ("division", "pbm_guarantee_period"): "pbm_guarantee_period_id",
    ("division", "pbm_guarantee_result"): "pbm_guarantee_result_id",
    ("division", "prior_auth_request"): "prior_auth_request_id",
    ("division", "prior_auth_rule"): "prior_auth_rule_id",
    ("division", "rebate_contract"): "rebate_contract_id",
    ("division", "rebate_payment"): "rebate_payment_id",
    ("division", "reconciliation_deliverable"): "reconciliation_deliverable_id",
    ("drug", "classification"): "classification_id",
    ("drug", "drug_formulary"): "drug_formulary_id",
    ("drug", "drug_formulary_tier"): "drug_formulary_tier_id",
    ("drug", "drug_prescriber"): "drug_prescriber_id",
    ("drug", "equivalence"): "equivalence_id",
    ("drug", "formulary_drug"): "formulary_drug_id",
    ("drug", "mac_list"): "mac_list_id",
    ("drug", "mac_pricing"): "mac_pricing_id",
    ("drug", "manufacturer"): "manufacturer_id",
    ("drug", "ndc"): "ndc_id",
    ("drug", "ndc_price"): "ndc_price_id",
    ("drug", "pharmacy"): "pharmacy_id",
    ("drug", "pharmacy_network"): "pharmacy_network_id",
    ("program", "accumulator_program"): "accumulator_program_id",
    ("program", "alternative_funding_program"): "alternative_funding_program_id",
    ("program", "charitable_assistance"): "charitable_assistance_id",
    ("program", "claim_savings_attribution"): "claim_savings_attribution_id",
    ("program", "contract_pharmacy_340b"): "contract_pharmacy_340b_id",
    ("program", "copay_assistance_program"): "copay_assistance_program_id",
    ("program", "covered_entity_340b"): "covered_entity_340b_id",
    ("program", "government_benefit_rule"): "government_benefit_rule_id",
    ("program", "member_accumulator_impact"): "member_accumulator_impact_id",
    ("program", "member_copay_enrollment"): "member_copay_enrollment_id",
    ("program", "patient_assistance_program"): "patient_assistance_program_id",
    ("program", "program_type"): "program_type_id",
    ("program", "rebate_contract"): "rebate_contract_id",
    ("program", "rebate_payment"): "rebate_payment_id",
    ("program", "savings_program"): "savings_program_id",
    ("reference", "external_source_load"): "external_source_load_id",
    ("reference", "fdb_drug"): "fdb_drug_id",
    ("reference", "fdb_drug_interaction"): "fdb_drug_interaction_id",
    ("reference", "fdb_pricing"): "fdb_pricing_id",
    ("reference", "medispan_drug"): "medispan_drug_id",
    ("reference", "medispan_gpi_hierarchy"): "medispan_gpi_hierarchy_id",
    ("reference", "medispan_pricing"): "medispan_pricing_id",
    ("reference", "ncpdp_dispensing_class"): "ncpdp_dispensing_class_id",
    ("reference", "ncpdp_pharmacy"): "ncpdp_pharmacy_id",
    ("reference", "ncpdp_pharmacy_service"): "ncpdp_pharmacy_service_id",
    ("reference", "nppes_other_identifier"): "nppes_other_identifier_id",
    ("reference", "nppes_provider"): "nppes_provider_id",
    ("reference", "nppes_provider_taxonomy"): "nppes_provider_taxonomy_id",
    ("reference", "nucc_taxonomy"): "nucc_taxonomy_id",
}

# Columns to drop from drug.ndc (duplicate manufacturer FKs)
NDC_DROP_COLS = {"labeler_manufacturer_id", "ndc_labeler_code_fk", "ndc_labeler_fk", "ndc_manufacturer_id"}

# Type overrides: these columns must be STRING regardless of metamodel type
TYPE_OVERRIDES = set()
def should_override_to_string(domain, product, col_name):
    cn = col_name.lower()
    if cn in ("npi", "prescriber_npi", "billing_provider_npi", "rendering_provider_npi", "entity_npi"):
        return True
    if "ncpdp_id" in cn or cn == "ncpdp_number" or cn == "pharmacy_ncpdp_id":
        return True
    if cn == "taxonomy_code" or cn == "nppes_taxonomy_assignment_code":
        return True
    if cn.endswith("_ndc_code") or cn == "ndc_code":
        return True
    return False

def normalize_type(raw_type):
    t = raw_type.strip().upper()
    mapping = {
        "VARCHAR": "STRING",
        "TEXT": "STRING",
        "INT": "INT",
        "INTEGER": "INT",
        "NUMERIC": "DECIMAL(18,4)",
        "FLOAT": "DOUBLE",
        "DOUBLE": "DOUBLE",
    }
    return mapping.get(t, t)

def escape_comment(text, max_len=256):
    """Escape single quotes and truncate for SQL COMMENT."""
    if not text:
        return None
    text = text.replace("'", "''")
    if len(text) > max_len:
        text = text[:max_len - 3] + "..."
    return text

# --- Load product descriptions ---
try:
    with open(r"C:\Users\eric.pedrotty\Documents\Code\BrownAndBrown\tmp_product_descriptions.json", "r", encoding="utf-8-sig") as f:
        prod_resp = json.load(f)
    product_descs = {}
    for row in prod_resp["result"]["data_array"]:
        domain, product, desc = row
        if desc:
            product_descs[(domain, product)] = desc
except FileNotFoundError:
    product_descs = {}

# --- Build table structures ---
# tables[(domain, product)] = [(col_name, data_type, is_pk, comment)]
tables = {}
for r in rows:
    domain, product, col_name, dtype, fk_to, tags = r[0], r[1], r[2], r[3], r[4], r[5]
    description = r[6] if len(r) > 6 else None
    if domain == "drug" and product == "ndc" and col_name in NDC_DROP_COLS:
        continue

    key = (domain, product)
    if key not in tables:
        tables[key] = []

    final_type = normalize_type(dtype)
    if should_override_to_string(domain, product, col_name):
        final_type = "STRING"

    pk_col = products.get(key, "")
    is_pk = (col_name == pk_col)

    tables[key].append((col_name, final_type, is_pk, description))

# --- Build FK constraint list ---
fk_constraints = []
fk_seen = set()

for link in fk_links:
    src = link["source"]  # e.g. "claim.rx_claim.claim_benefit_group_id"
    tgt = link["target"]  # e.g. "claim.claim_benefit_group.claim_benefit_group_id"

    src_parts = src.split(".")
    tgt_parts = tgt.split(".")
    if len(src_parts) != 3 or len(tgt_parts) != 3:
        continue

    src_schema, src_table, src_col = src_parts
    tgt_schema, tgt_table, tgt_col = tgt_parts

    # Skip dropped columns
    if src_schema == "drug" and src_table == "ndc" and src_col in NDC_DROP_COLS:
        continue

    fk_name = f"fk_{src_schema}_{src_table}_{src_col}"
    if len(fk_name) > 128:
        fk_name = fk_name[:128]

    if fk_name in fk_seen:
        continue
    fk_seen.add(fk_name)

    fk_constraints.append((fk_name, src_schema, src_table, src_col, tgt_schema, tgt_table, tgt_col))

# Override agent FKs with manually-applied natural-key FKs
manual_fks = [
    ("fk_claim_claim_prescriber_npi", "claim", "claim_prescriber", "npi", "reference", "nppes_provider", "npi"),
    ("fk_drug_drug_prescriber_npi", "drug", "drug_prescriber", "npi", "reference", "nppes_provider", "npi"),
    ("fk_drug_pharmacy_ncpdp_number", "drug", "pharmacy", "ncpdp_number", "reference", "ncpdp_pharmacy", "ncpdp_number"),
]
for mfk in manual_fks:
    # Replace any existing FK with the same name (agent version points to surrogate PK)
    fk_constraints = [fk for fk in fk_constraints if fk[0] != mfk[0]]
    fk_seen.discard(mfk[0])
    fk_seen.add(mfk[0])
    fk_constraints.append(mfk)

# --- Generate DDL ---
schemas = sorted(set(k[0] for k in tables.keys()))

lines = []
lines.append("-- pillarrx_create_catalog.sql")
lines.append("-- Standalone DDL to recreate all pillarrx business schemas, tables, PKs, FKs,")
lines.append("-- and unique constraints from the v40 metamodel.")
lines.append("--")
lines.append("-- Generated from pillarrx._metamodel (version 40) with type corrections applied.")
lines.append("-- Includes manually-applied FK constraints the vibe agent cannot create.")
lines.append("--")
lines.append("-- Run on Databricks SQL against the pillarrx catalog.")
lines.append("")
lines.append("-- =============================================================================")
lines.append("-- SECTION 1: CREATE SCHEMAS")
lines.append("-- =============================================================================")
lines.append("")

for schema in schemas:
    lines.append(f"CREATE SCHEMA IF NOT EXISTS pillarrx.{schema};")
lines.append("")

lines.append("-- =============================================================================")
lines.append("-- SECTION 2: CREATE TABLES")
lines.append("-- =============================================================================")

for schema in schemas:
    lines.append("")
    lines.append(f"-- ---------------------------------------------------------------------------")
    lines.append(f"-- Schema: {schema}")
    lines.append(f"-- ---------------------------------------------------------------------------")

    schema_tables = sorted(
        [(k, v) for k, v in tables.items() if k[0] == schema],
        key=lambda x: x[0][1]
    )

    for (domain, product), cols in schema_tables:
        pk_col = products.get((domain, product), "")
        lines.append("")
        lines.append(f"CREATE TABLE IF NOT EXISTS pillarrx.{domain}.{product} (")

        col_lines = []
        for i, (col_name, col_type, is_pk, description) in enumerate(cols):
            not_null = " NOT NULL" if is_pk else ""
            comment_clause = ""
            escaped = escape_comment(description)
            if escaped:
                comment_clause = f" COMMENT '{escaped}'"
            col_lines.append(f"  {col_name} {col_type}{not_null}{comment_clause}")

        # Add PK constraint
        if pk_col:
            col_lines.append(f"  CONSTRAINT pk_{product} PRIMARY KEY ({pk_col})")

        # Add unique constraints for reference tables
        if domain == "reference" and product == "nppes_provider":
            col_lines.append(f"  CONSTRAINT uq_nppes_provider_npi UNIQUE (npi)")
        if domain == "reference" and product == "ncpdp_pharmacy":
            col_lines.append(f"  CONSTRAINT uq_ncpdp_pharmacy_ncpdp_number UNIQUE (ncpdp_number)")

        for i, cl in enumerate(col_lines):
            if i < len(col_lines) - 1:
                lines.append(cl + ",")
            else:
                lines.append(cl)

        lines.append(")")
        # Add table-level COMMENT
        table_desc = product_descs.get((domain, product))
        if table_desc:
            escaped_table = escape_comment(table_desc, 1024)
            lines.append(f"COMMENT '{escaped_table}'")
        lines.append("USING DELTA")
        lines.append(f"TBLPROPERTIES ('delta.columnMapping.mode' = 'name');")

lines.append("")
lines.append("-- =============================================================================")
lines.append("-- SECTION 3: FOREIGN KEY CONSTRAINTS")
lines.append("-- =============================================================================")
lines.append("")

# Sort FKs by source schema/table for readability
fk_constraints.sort(key=lambda x: (x[1], x[2], x[3]))

current_schema = ""
for fk_name, src_s, src_t, src_c, tgt_s, tgt_t, tgt_c in fk_constraints:
    if src_s != current_schema:
        lines.append("")
        lines.append(f"-- {src_s} schema FKs")
        current_schema = src_s

    lines.append(
        f"ALTER TABLE pillarrx.{src_s}.{src_t} "
        f"ADD CONSTRAINT {fk_name} "
        f"FOREIGN KEY ({src_c}) REFERENCES pillarrx.{tgt_s}.{tgt_t} ({tgt_c});"
    )

lines.append("")
lines.append("-- =============================================================================")
lines.append("-- END OF SCRIPT")
lines.append("-- =============================================================================")

# --- Write output ---
output_path = r"C:\Users\eric.pedrotty\Documents\Code\BrownAndBrown\sql\pillarrx_create_catalog.sql"
with open(output_path, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

# Summary
n_tables = len(tables)
n_cols = sum(len(v) for v in tables.values())
n_fks = len(fk_constraints)
print(f"Generated: {output_path}")
print(f"  Schemas: {len(schemas)}")
print(f"  Tables: {n_tables}")
print(f"  Columns: {n_cols}")
print(f"  FK constraints: {n_fks}")
print(f"  Unique constraints: 2 (nppes_provider.npi, ncpdp_pharmacy.ncpdp_number)")
