-- ABOUTME: SQL statements to register the reference domain and its products in the pillarrx._metamodel tables.
-- ABOUTME: Execute manually after the reference schema is created in the Databricks catalog.

-- ============================================================
-- Register the reference domain
-- ============================================================

INSERT INTO pillarrx._metamodel.domain
(business, version, model_scope, domain, division, description, database_name, catalog, reference, tags)
VALUES
(
  'Pillarrx',
  '23',
  'mvm',
  'reference',
  'operations',
  'Authoritative source-of-record for external vendor-supplied reference data used across the PillarRx data platform. Holds drug, pharmacy, provider, and classification data as delivered by Wolters Kluwer Medi-Span, First DataBank (FDB), NCPDP, CMS NPPES, and NUCC in vendor-native form with full SCD Type-2 history.',
  'reference',
  NULL,
  'Medi-Span MDDB / First DataBank MedKnowledge / NCPDP dataQ / CMS NPPES NPI / NUCC Taxonomy',
  NULL
);

-- ============================================================
-- Register each product (table) in the reference domain
-- ============================================================

-- MediSpan tables

INSERT INTO pillarrx._metamodel.product
(business, version, model_scope, domain, subdomain, product, description, type, division, function, data_type, source_domains, association_edges, primary_key, reference, table_name, sample_path, tags)
VALUES
('Pillarrx', '23', 'mvm', 'reference', 'medispan', 'medispan_ndc',
 'NDC drug product master as delivered by Wolters Kluwer Medi-Span MDDB. Contains the 11-digit NDC, drug names, GPI-14 classification, AWP/WAC pricing, labeler, DEA schedule, and clinical flags (specialty, maintenance, LDD, biosimilar, REMS, OTC).',
 'Reference', 'operations', 'drug_reference', 'dimension', NULL, NULL, 'medispan_ndc_id', 'Wolters Kluwer Medi-Span MDDB', 'medispan_ndc', 'docs/reference-data-samples/medispan/MDDB_NDC_MASTER.txt', NULL);

INSERT INTO pillarrx._metamodel.product
(business, version, model_scope, domain, subdomain, product, description, type, division, function, data_type, source_domains, association_edges, primary_key, reference, table_name, sample_path, tags)
VALUES
('Pillarrx', '23', 'mvm', 'reference', 'medispan', 'medispan_gpi',
 'Medi-Span Generic Product Identifier (GPI) therapeutic classification hierarchy. Self-referential 7-level structure from drug group (2-digit) through strength (14-digit).',
 'Reference', 'operations', 'drug_reference', 'dimension', NULL, NULL, 'medispan_gpi_id', 'Wolters Kluwer Medi-Span MDDB', 'medispan_gpi', 'docs/reference-data-samples/medispan/MDDB_GPI_CLASSIFICATION.txt', NULL);

INSERT INTO pillarrx._metamodel.product
(business, version, model_scope, domain, subdomain, product, description, type, division, function, data_type, source_domains, association_edges, primary_key, reference, table_name, sample_path, tags)
VALUES
('Pillarrx', '23', 'mvm', 'reference', 'medispan', 'medispan_price',
 'Time-versioned AWP and WAC pricing records for each NDC as published by Wolters Kluwer Medi-Span. Captures current and prior prices, change type, and change percentage for drug price trend monitoring.',
 'Reference', 'operations', 'drug_reference', 'fact', NULL, NULL, 'medispan_price_id', 'Wolters Kluwer Medi-Span MDDB', 'medispan_price', 'docs/reference-data-samples/medispan/MDDB_PRICE_UPDATE.txt', NULL);

INSERT INTO pillarrx._metamodel.product
(business, version, model_scope, domain, subdomain, product, description, type, division, function, data_type, source_domains, association_edges, primary_key, reference, table_name, sample_path, tags)
VALUES
('Pillarrx', '23', 'mvm', 'reference', 'medispan', 'medispan_equivalence',
 'Brand-to-generic and biosimilar-interchangeable substitution crosswalk from Medi-Span. Maps source NDCs to therapeutically equivalent NDCs with Orange Book codes and match flags for dosage form, strength, and route.',
 'Reference', 'operations', 'drug_reference', 'association', NULL, NULL, 'medispan_equivalence_id', 'Wolters Kluwer Medi-Span MDDB', 'medispan_equivalence', 'docs/reference-data-samples/medispan/MDDB_EQUIVALENCE.txt', NULL);

-- FDB tables

INSERT INTO pillarrx._metamodel.product
(business, version, model_scope, domain, subdomain, product, description, type, division, function, data_type, source_domains, association_edges, primary_key, reference, table_name, sample_path, tags)
VALUES
('Pillarrx', '23', 'mvm', 'reference', 'fdb', 'fdb_ndc',
 'NDC drug product record from First DataBank MedKnowledge. Contains FDB-specific identifiers (FDB Drug ID, HIC, HICL, MEDID, Routed Med ID) alongside standard NDC, drug names, and clinical attributes.',
 'Reference', 'operations', 'drug_reference', 'dimension', NULL, NULL, 'fdb_ndc_id', 'First DataBank MedKnowledge', 'fdb_ndc', 'docs/reference-data-samples/fdb/FDB_NDC_PRODUCT.txt', NULL);

INSERT INTO pillarrx._metamodel.product
(business, version, model_scope, domain, subdomain, product, description, type, division, function, data_type, source_domains, association_edges, primary_key, reference, table_name, sample_path, tags)
VALUES
('Pillarrx', '23', 'mvm', 'reference', 'fdb', 'fdb_therapeutic_class',
 'First DataBank 3-level therapeutic classification hierarchy. Colon-delimited code structure from major therapeutic area through specific drug subclass, linked to HIC ingredient codes.',
 'Reference', 'operations', 'drug_reference', 'dimension', NULL, NULL, 'fdb_therapeutic_class_id', 'First DataBank MedKnowledge', 'fdb_therapeutic_class', 'docs/reference-data-samples/fdb/FDB_THERAPEUTIC_CLASS.txt', NULL);

INSERT INTO pillarrx._metamodel.product
(business, version, model_scope, domain, subdomain, product, description, type, division, function, data_type, source_domains, association_edges, primary_key, reference, table_name, sample_path, tags)
VALUES
('Pillarrx', '23', 'mvm', 'reference', 'fdb', 'fdb_drug_interaction',
 'Drug-drug interaction screening data from First DataBank MedKnowledge. Pairs of drugs identified by HIC code with severity level, clinical effect narrative, pharmacological mechanism, management guidance, and monograph references.',
 'Reference', 'operations', 'drug_reference', 'fact', NULL, NULL, 'fdb_drug_interaction_id', 'First DataBank MedKnowledge', 'fdb_drug_interaction', 'docs/reference-data-samples/fdb/FDB_DRUG_INTERACTION.txt', NULL);

-- NCPDP table

INSERT INTO pillarrx._metamodel.product
(business, version, model_scope, domain, subdomain, product, description, type, division, function, data_type, source_domains, association_edges, primary_key, reference, table_name, sample_path, tags)
VALUES
('Pillarrx', '23', 'mvm', 'reference', 'ncpdp', 'ncpdp_pharmacy',
 'Dispensing pharmacy master from NCPDP dataQ and the NCPDP Pharmacy File. Contains NCPDP provider ID, NPI crossref, pharmacy name, chain affiliation, type and dispensing class codes, specialty and accreditation flags, geographic coordinates, and hours of operation.',
 'Reference', 'operations', 'pharmacy_reference', 'dimension', NULL, NULL, 'ncpdp_pharmacy_id', 'NCPDP dataQ / NCPDP Pharmacy File', 'ncpdp_pharmacy', 'docs/reference-data-samples/ncpdp/NCPDP_PHARMACY_FILE.txt', NULL);

-- NPPES tables

INSERT INTO pillarrx._metamodel.product
(business, version, model_scope, domain, subdomain, product, description, type, division, function, data_type, source_domains, association_edges, primary_key, reference, table_name, sample_path, tags)
VALUES
('Pillarrx', '23', 'mvm', 'reference', 'nppes', 'nppes_provider',
 'Healthcare provider master from CMS NPPES NPI data dissemination. Contains NPI, entity type (individual or organization), provider names, credentials, mailing and practice addresses, enumeration and deactivation dates, gender, and authorized official details for organizations.',
 'Reference', 'operations', 'provider_reference', 'dimension', NULL, NULL, 'nppes_provider_id', 'CMS NPPES NPI Data Dissemination', 'nppes_provider', 'docs/reference-data-samples/nppes/npidata_pfile_sample.csv', NULL);

INSERT INTO pillarrx._metamodel.product
(business, version, model_scope, domain, subdomain, product, description, type, division, function, data_type, source_domains, association_edges, primary_key, reference, table_name, sample_path, tags)
VALUES
('Pillarrx', '23', 'mvm', 'reference', 'nppes', 'nppes_provider_taxonomy',
 'Normalized taxonomy and license assignments per provider, extracted from the repeating taxonomy groups in the CMS NPPES NPI dissemination file. Each row represents one taxonomy code assignment for a provider, with associated license number and primary taxonomy flag.',
 'Reference', 'operations', 'provider_reference', 'association', NULL, NULL, 'nppes_provider_taxonomy_id', 'CMS NPPES NPI Data Dissemination', 'nppes_provider_taxonomy', 'docs/reference-data-samples/nppes/npidata_pfile_sample.csv', NULL);

-- NUCC table

INSERT INTO pillarrx._metamodel.product
(business, version, model_scope, domain, subdomain, product, description, type, division, function, data_type, source_domains, association_edges, primary_key, reference, table_name, sample_path, tags)
VALUES
('Pillarrx', '23', 'mvm', 'reference', 'nucc', 'nucc_taxonomy',
 'NUCC Health Care Provider Taxonomy Code Set. Defines provider specialty classifications used across NPPES, PBM claims, and prescriber records. Contains grouping, classification, specialization, and definition for each 10-character taxonomy code.',
 'Reference', 'operations', 'provider_reference', 'dimension', NULL, NULL, 'nucc_taxonomy_id', 'NUCC Health Care Provider Taxonomy', 'nucc_taxonomy', 'docs/reference-data-samples/nucc/nucc_taxonomy_250101.csv', NULL);
