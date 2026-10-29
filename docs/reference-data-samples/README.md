# Reference Data Sample Files

Synthetic sample files representing the raw vendor-delivered format for each
external reference data source used in the pillarrx data platform. These files
informed the design of the `pillarrx.reference` schema.

All data is synthetic. Drug names, NDCs, NPIs, and other identifiers are
realistic but fabricated for design purposes.

## MediSpan (Wolters Kluwer MDDB)

| File | Format | Records | Maps To | Description |
|---|---|---|---|---|
| `medispan/MDDB_NDC_MASTER.txt` | Pipe-delimited, 39 columns | 10 | `reference.medispan_ndc` | NDC drug product master |
| `medispan/MDDB_GPI_CLASSIFICATION.txt` | Pipe-delimited, 7 columns | 45 | `reference.medispan_gpi` | GPI therapeutic hierarchy (7 levels) |
| `medispan/MDDB_PRICE_UPDATE.txt` | Pipe-delimited, 18 columns | 10 | `reference.medispan_price` | AWP/WAC periodic pricing |
| `medispan/MDDB_EQUIVALENCE.txt` | Pipe-delimited, 21 columns | 5 | `reference.medispan_equivalence` | Generic substitution crosswalk |

## First DataBank (FDB MedKnowledge)

| File | Format | Records | Maps To | Description |
|---|---|---|---|---|
| `fdb/FDB_NDC_PRODUCT.txt` | Pipe-delimited, 31 columns | 8 | `reference.fdb_ndc` | NDC with FDB identifiers |
| `fdb/FDB_THERAPEUTIC_CLASS.txt` | Pipe-delimited, 9 columns | 18 | `reference.fdb_therapeutic_class` | 3-level therapeutic classification |
| `fdb/FDB_DRUG_INTERACTION.txt` | Pipe-delimited, 15 columns | 8 | `reference.fdb_drug_interaction` | Drug-drug interaction screening |

## NCPDP

| File | Format | Records | Maps To | Description |
|---|---|---|---|---|
| `ncpdp/NCPDP_PHARMACY_FILE.txt` | Pipe-delimited, 45 columns | 10 | `reference.ncpdp_pharmacy` | Pharmacy master |

## NPPES (CMS)

| File | Format | Records | Maps To | Description |
|---|---|---|---|---|
| `nppes/npidata_pfile_sample.csv` | CSV, 52+ columns | 10 | `reference.nppes_provider` + `reference.nppes_provider_taxonomy` | NPI provider registry |

The NPPES file contains repeating taxonomy/license column groups. In the
`reference` schema these are normalized into the `nppes_provider` core table
and the `nppes_provider_taxonomy` child table.

## NUCC

| File | Format | Records | Maps To | Description |
|---|---|---|---|---|
| `nucc/nucc_taxonomy_250101.csv` | CSV, 6 columns | 20 | `reference.nucc_taxonomy` | Provider taxonomy code set |

## Cross-References Between Files

- **NDC11** links MediSpan and FDB drug files (same NDC appears in both)
- **NPI** links NPPES providers to NCPDP pharmacies
- **GPI14** links MediSpan NDC master to GPI classification hierarchy
- **HIC_CODE** links FDB NDC products to therapeutic classes and interactions
- **Taxonomy Code** links NPPES provider taxonomies to NUCC definitions
- **APPLICATION_NUM** (NDA/ANDA/BLA) matches across MediSpan and FDB
