# ABOUTME: Generates DBML schema files from physical pillarrx catalog query results.
# ABOUTME: Reads JSON query outputs and produces per-schema + cross-domain DBML.

import json
import os
from collections import defaultdict

BASE = r"C:\Users\eric.pedrotty\Documents\Code\BrownAndBrown"
OUT_DIR = os.path.join(BASE, "docs", "data-models", "schemas")

def load_result(path):
    with open(path, 'r', encoding='utf-8-sig') as f:
        data = json.load(f)
    cols = [c['name'] for c in data['manifest']['schema']['columns']]
    rows = data['result'].get('data_array', [])
    return [dict(zip(cols, row)) for row in rows]

def trunc(s, n=200):
    if not s:
        return ''
    s = s.replace("'", "").replace("\n", " ").replace("\r", " ")
    if len(s) > n:
        s = s[:n-3] + '...'
    return s

# Load data
columns = load_result(os.path.join(BASE, "tmp_columns.json"))
constraints = load_result(os.path.join(BASE, "tmp_constraints.json"))
refs = load_result(os.path.join(BASE, "tmp_refs.json"))
key_usage = load_result(os.path.join(BASE, "tmp_key_usage.json"))
col_usage = load_result(os.path.join(BASE, "tmp_column_usage.json"))

# Build PK map: constraint_name -> set of columns
pk_columns = defaultdict(set)
unique_columns = defaultdict(set)
constraint_type_map = {}
for c in constraints:
    constraint_type_map[c['constraint_name']] = c['constraint_type']

for ku in key_usage:
    cname = ku['constraint_name']
    ctype = constraint_type_map.get(cname, '')
    if ctype == 'PRIMARY KEY':
        pk_columns[(ku['table_schema'], ku['table_name'])].add(ku['column_name'])
    elif ctype == 'UNIQUE':
        unique_columns[(ku['table_schema'], ku['table_name'])].add(ku['column_name'])

# Build FK map: (child_schema, child_table, child_column) -> (parent_schema, parent_table, parent_column)
# From referential_constraints: fk_constraint_name -> pk_constraint_name
fk_to_pk = {}
for r in refs:
    fk_to_pk[r['constraint_name']] = r['unique_constraint_name']

# From key_column_usage: constraint_name -> (schema, table, column)
constraint_col_map = {}
for ku in key_usage:
    constraint_col_map[ku['constraint_name']] = (ku['table_schema'], ku['table_name'], ku['column_name'])

# From constraint_column_usage: for PK/UNIQUE constraints, maps constraint_name -> (schema, table, column)
# This gives the PARENT side column for FKs
parent_col_map = {}
for cu in col_usage:
    parent_col_map[cu['constraint_name']] = (cu['table_schema'], cu['table_name'], cu['column_name'])

# Build FK lookup
fk_map = {}  # (child_schema, child_table, child_col) -> (parent_schema, parent_table, parent_col)
for fk_name, pk_name in fk_to_pk.items():
    child = constraint_col_map.get(fk_name)
    parent = parent_col_map.get(pk_name)
    if child and parent:
        fk_map[(child[0], child[1], child[2])] = (parent[0], parent[1], parent[2])

# Group columns by schema.table
tables = defaultdict(list)
schemas = set()
for col in columns:
    schema = col['table_schema']
    table = col['table_name']
    schemas.add(schema)
    tables[(schema, table)].append(col)

# Sort schemas
schemas = sorted(schemas)

def make_dbml_table(schema, table, cols, pk_set, uq_set, fk_map, comment_cross_refs, target_schema=None):
    lines = []
    lines.append(f"Table {schema}.{table} {{")
    for col in cols:
        cname = col['column_name']
        dtype = col['data_type'] or 'STRING'
        # Simplify types for DBML
        dtype_lower = dtype.lower()
        if dtype_lower.startswith('decimal'):
            dtype_dbml = dtype.lower()
        elif dtype_lower == 'bigint' or dtype_lower == 'long':
            dtype_dbml = 'bigint'
        elif dtype_lower == 'int' or dtype_lower == 'integer':
            dtype_dbml = 'int'
        elif dtype_lower == 'string':
            dtype_dbml = 'varchar'
        elif dtype_lower == 'boolean':
            dtype_dbml = 'boolean'
        elif dtype_lower == 'date':
            dtype_dbml = 'date'
        elif dtype_lower == 'timestamp':
            dtype_dbml = 'timestamp'
        elif dtype_lower == 'double' or dtype_lower == 'float':
            dtype_dbml = dtype_lower
        else:
            dtype_dbml = dtype.lower()

        tags = []
        is_pk = cname in pk_set
        is_uq = cname in uq_set
        if is_pk:
            tags.append('pk')
        if is_uq:
            tags.append('unique')

        # Check FK
        fk_key = (schema, table, cname)
        fk_ref = None
        is_cross = False
        if fk_key in fk_map:
            ps, pt, pc = fk_map[fk_key]
            is_cross = ps != schema
            if target_schema is None:
                # cross-domain file: always include
                fk_ref = f"ref: > {ps}.{pt}.{pc}"
            elif is_cross and comment_cross_refs:
                fk_ref = None  # will add as comment below
            else:
                fk_ref = f"ref: > {ps}.{pt}.{pc}"

        if fk_ref:
            tags.append(fk_ref)

        note = trunc(col['comment'])
        if note:
            tags.append(f"note: '{note}'")

        tag_str = ''
        if tags:
            tag_str = f" [{', '.join(tags)}]"

        line = f"  {cname} {dtype_dbml}{tag_str}"
        lines.append(line)

        # Add commented cross-ref if needed
        if target_schema and comment_cross_refs and fk_key in fk_map:
            ps, pt, pc = fk_map[fk_key]
            if ps != schema:
                lines.append(f"  // cross-domain ref: {cname} -> {ps}.{pt}.{pc}")

    lines.append("}")
    return lines


def generate_schema_dbml(schema, comment_cross_refs=True):
    lines = []
    lines.append(f"// ABOUTME: DBML schema for the {schema} domain of the pillarrx catalog.")
    lines.append(f"// ABOUTME: Generated from physical Databricks catalog on 2026-11-03.")
    lines.append("")

    schema_tables = sorted([k for k in tables.keys() if k[0] == schema], key=lambda x: x[1])
    for s, t in schema_tables:
        cols = tables[(s, t)]
        pk_set = pk_columns.get((s, t), set())
        uq_set = unique_columns.get((s, t), set())
        tbl_lines = make_dbml_table(s, t, cols, pk_set, uq_set, fk_map, comment_cross_refs, target_schema=schema)
        lines.extend(tbl_lines)
        lines.append("")

    return '\n'.join(lines)


def generate_cross_domain_dbml():
    lines = []
    lines.append("// ABOUTME: Cross-domain DBML for the entire pillarrx catalog (all business schemas).")
    lines.append("// ABOUTME: Generated from physical Databricks catalog on 2026-11-03.")
    lines.append("")

    for schema in schemas:
        lines.append(f"// ---------------------------------------------------------------------------")
        lines.append(f"// Schema: {schema}")
        lines.append(f"// ---------------------------------------------------------------------------")
        lines.append("")
        schema_tables = sorted([k for k in tables.keys() if k[0] == schema], key=lambda x: x[1])
        for s, t in schema_tables:
            cols = tables[(s, t)]
            pk_set = pk_columns.get((s, t), set())
            uq_set = unique_columns.get((s, t), set())
            tbl_lines = make_dbml_table(s, t, cols, pk_set, uq_set, fk_map, comment_cross_refs=False, target_schema=None)
            lines.extend(tbl_lines)
            lines.append("")

    return '\n'.join(lines)


# Generate per-schema files
for schema in schemas:
    content = generate_schema_dbml(schema)
    path = os.path.join(OUT_DIR, f"{schema}.dbml")
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Wrote {path}")

# Generate cross-domain file
content = generate_cross_domain_dbml()
path = os.path.join(OUT_DIR, "pillarrx.dbml")
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print(f"Wrote {path}")

print("Done.")
