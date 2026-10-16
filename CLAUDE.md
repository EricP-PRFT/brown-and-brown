# Brown and Brown - Databricks Project

## Overview

Databricks workspace project for Brown and Brown. Includes notebooks synced from
Databricks, data modeling documentation, and project management.

## Databricks

- Workspace: `https://dbc-0f581a4e-f824.cloud.databricks.com`
- CLI profile: `brown_and_brown`
- Notebooks are stored as `.py` files in Databricks `# COMMAND` format

## Project Structure

- `notebooks/` — Databricks notebooks synced from the workspace
- `docs/project/` — Project management notes and decisions
- `docs/data-models/` — Data model documentation and ERDs
- `sql/` — Standalone SQL files
- `tasks/` — Lessons learned and task tracking

## Commands

```bash
# Sync a notebook from Databricks
databricks workspace export /path/to/notebook notebooks/name.py --profile brown_and_brown --format SOURCE

# List workspace contents
databricks workspace ls /path --profile brown_and_brown
```
