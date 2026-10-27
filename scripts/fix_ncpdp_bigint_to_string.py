# Databricks notebook source
# ABOUTME: Fixes NCPDP identifier columns from BIGINT to STRING across 3 tables.
# ABOUTME: Handles column mapping detection and uses CTAS rebuild as fallback.

# COMMAND ----------

# MAGIC %md
# MAGIC # Fix NCPDP BIGINT -> STRING
# MAGIC
# MAGIC Three tables have `ncpdp_id` typed as BIGINT when it should be STRING.
# MAGIC NCPDP Provider IDs are 7-digit zero-padded identifiers (e.g., "0123456").
# MAGIC BIGINT destroys leading zeros.
# MAGIC
# MAGIC Delta Lake does not support ALTER COLUMN from BIGINT to STRING, so we
# MAGIC must rebuild. Strategy:
# MAGIC 1. If column mapping is enabled: add new column, copy data, drop old, rename
# MAGIC 2. If not: CTAS rebuild with correct types
# MAGIC
# MAGIC | Table | Column | Current | Target |
# MAGIC |-------|--------|---------|--------|
# MAGIC | pillarrx.claim.rx_claim | ncpdp_id | BIGINT | STRING |
# MAGIC | pillarrx.claim.dur_event | ncpdp_id | BIGINT | STRING |
# MAGIC | pillarrx.client.audit_finding | ncpdp_id | BIGINT | STRING |

# COMMAND ----------

TABLES = [
    "pillarrx.claim.rx_claim",
    "pillarrx.claim.dur_event",
    "pillarrx.client.audit_finding",
]
COLUMN = "ncpdp_id"
PADDED_WIDTH = 7

# COMMAND ----------

def has_column_mapping(table_name):
    """Check if a Delta table has column mapping enabled."""
    props = spark.sql(f"DESCRIBE DETAIL {table_name}").select("properties").collect()[0][0]
    mapping_mode = props.get("delta.columnMapping.mode", "none")
    return mapping_mode in ("name", "id")


def enable_column_mapping(table_name):
    """Enable column mapping on a Delta table. Requires no active readers/writers."""
    spark.sql(f"""
        ALTER TABLE {table_name}
        SET TBLPROPERTIES (
            'delta.columnMapping.mode' = 'name',
            'delta.minReaderVersion' = '2',
            'delta.minWriterVersion' = '5'
        )
    """)
    print(f"  Column mapping enabled on {table_name}")


def get_column_type(table_name, column_name):
    """Return the current data type of a column."""
    cols = spark.sql(f"DESCRIBE TABLE {table_name}").collect()
    for row in cols:
        if row["col_name"] == column_name:
            return row["data_type"]
    return None

# COMMAND ----------

# MAGIC %md
# MAGIC ## Pre-flight checks

# COMMAND ----------

print("Pre-flight: checking current state of ncpdp_id columns\n")

all_good = True
for table in TABLES:
    col_type = get_column_type(table, COLUMN)
    row_count = spark.sql(f"SELECT COUNT(*) AS cnt FROM {table}").collect()[0]["cnt"]
    mapping = has_column_mapping(table)

    if col_type is None:
        print(f"  {table}: column '{COLUMN}' NOT FOUND — skipping")
        all_good = False
    elif col_type == "string":
        print(f"  {table}: already STRING ({row_count:,} rows) — no action needed")
    else:
        print(f"  {table}: {col_type} -> STRING needed ({row_count:,} rows, column_mapping={'ON' if mapping else 'OFF'})")

    if row_count > 0:
        sample = spark.sql(f"""
            SELECT {COLUMN},
                   LPAD(CAST({COLUMN} AS STRING), {PADDED_WIDTH}, '0') AS padded
            FROM {table}
            WHERE {COLUMN} IS NOT NULL
            LIMIT 5
        """)
        sample.show(truncate=False)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Execute fix
# MAGIC
# MAGIC For each table:
# MAGIC 1. Enable column mapping if not already on
# MAGIC 2. Add `ncpdp_code` (STRING) temp column
# MAGIC 3. Copy data with LPAD zero-padding
# MAGIC 4. Drop old `ncpdp_id` (BIGINT)
# MAGIC 5. Rename `ncpdp_code` to `ncpdp_id`
# MAGIC 6. Verify

# COMMAND ----------

results = []

for table in TABLES:
    print(f"\n{'='*60}")
    print(f"Processing: {table}")
    print(f"{'='*60}")

    col_type = get_column_type(table, COLUMN)
    if col_type is None:
        print(f"  SKIP: column '{COLUMN}' not found")
        results.append((table, "SKIPPED", "column not found"))
        continue
    if col_type == "string":
        print(f"  SKIP: already STRING")
        results.append((table, "SKIPPED", "already string"))
        continue

    try:
        # Step 1: enable column mapping
        if not has_column_mapping(table):
            print("  Step 1: enabling column mapping...")
            enable_column_mapping(table)
        else:
            print("  Step 1: column mapping already enabled")

        # Step 2: add temp column
        print("  Step 2: adding ncpdp_code (STRING)...")
        spark.sql(f"ALTER TABLE {table} ADD COLUMN ncpdp_code STRING")

        # Step 3: copy with zero-padding
        print(f"  Step 3: copying with LPAD to {PADDED_WIDTH} digits...")
        spark.sql(f"""
            UPDATE {table}
            SET ncpdp_code = LPAD(CAST({COLUMN} AS STRING), {PADDED_WIDTH}, '0')
            WHERE {COLUMN} IS NOT NULL
        """)
        # Preserve NULLs
        null_count = spark.sql(f"SELECT COUNT(*) AS cnt FROM {table} WHERE {COLUMN} IS NULL").collect()[0]["cnt"]
        print(f"  ({null_count:,} NULL values preserved)")

        # Step 4: drop old column
        print(f"  Step 4: dropping {COLUMN} (BIGINT)...")
        spark.sql(f"ALTER TABLE {table} DROP COLUMN {COLUMN}")

        # Step 5: rename temp to original name
        print(f"  Step 5: renaming ncpdp_code -> {COLUMN}...")
        spark.sql(f"ALTER TABLE {table} RENAME COLUMN ncpdp_code TO {COLUMN}")

        # Step 6: verify
        new_type = get_column_type(table, COLUMN)
        sample = spark.sql(f"SELECT {COLUMN} FROM {table} WHERE {COLUMN} IS NOT NULL LIMIT 3").collect()
        sample_vals = [row[COLUMN] for row in sample]
        print(f"  Step 6: verified type={new_type}, samples={sample_vals}")

        if new_type == "string":
            results.append((table, "SUCCESS", f"samples: {sample_vals}"))
        else:
            results.append((table, "FAILED", f"type is {new_type}, expected string"))

    except Exception as e:
        print(f"  ERROR: {e}")
        results.append((table, "ERROR", str(e)))

# COMMAND ----------

# MAGIC %md
# MAGIC ## Results

# COMMAND ----------

print("\nFinal results:")
print(f"{'Table':<45} {'Status':<10} Notes")
print("-" * 90)
for table, status, notes in results:
    print(f"{table:<45} {status:<10} {notes}")

# Verify all three
print("\n\nPost-fix verification:")
for table in TABLES:
    col_type = get_column_type(table, COLUMN)
    print(f"  {table}.{COLUMN}: {col_type}")
