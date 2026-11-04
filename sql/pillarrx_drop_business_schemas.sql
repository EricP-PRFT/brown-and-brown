-- pillarrx_drop_business_schemas.sql
-- Drops all 7 business schemas and their contents (tables, FKs, views, etc.)
-- Does NOT touch _metamodel, _metrics, default, or information_schema.
--
-- Run this BEFORE pillarrx_create_catalog.sql to do a clean rebuild.

DROP SCHEMA IF EXISTS pillarrx.claim CASCADE;
DROP SCHEMA IF EXISTS pillarrx.client CASCADE;
DROP SCHEMA IF EXISTS pillarrx.company CASCADE;
DROP SCHEMA IF EXISTS pillarrx.division CASCADE;
DROP SCHEMA IF EXISTS pillarrx.drug CASCADE;
DROP SCHEMA IF EXISTS pillarrx.program CASCADE;
DROP SCHEMA IF EXISTS pillarrx.reference CASCADE;
