USE ROLE ENGINEER_ROLE;
USE WAREHOUSE TRANSFORM_WH;

-- ── Main database ─────────────────────────────────────────────

CREATE DATABASE IF NOT EXISTS SUPPLY_CHAIN_DB
    COMMENT = 'Main database for Olist supply chain analytics project';

-- ── Schemas (one per Medallion layer) ────────────────────────

CREATE SCHEMA IF NOT EXISTS SUPPLY_CHAIN_DB.BRONZE
    COMMENT = 'Raw data as-landed from source systems. No transformations.';

CREATE SCHEMA IF NOT EXISTS SUPPLY_CHAIN_DB.SILVER
    COMMENT = 'Cleaned, validated, and conformed data. Incremental + SCD Type 2.';

CREATE SCHEMA IF NOT EXISTS SUPPLY_CHAIN_DB.GOLD
    COMMENT = 'Star schema. Fact and dimension tables ready for analytics.';

-- Extra schema for dbt internal state
CREATE SCHEMA IF NOT EXISTS SUPPLY_CHAIN_DB.DBT_METADATA
    COMMENT = 'Used by dbt for storing snapshots state and audit logs.';

-- ── Schema-level permissions ──────────────────────────────────

-- Engineer gets full access to everything
GRANT ALL PRIVILEGES ON DATABASE SUPPLY_CHAIN_DB TO ROLE ENGINEER_ROLE;
GRANT ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE SUPPLY_CHAIN_DB TO ROLE ENGINEER_ROLE;

-- Analyst gets read-only on Gold only
GRANT USAGE  ON DATABASE SUPPLY_CHAIN_DB          TO ROLE ANALYST_ROLE;
GRANT USAGE  ON SCHEMA SUPPLY_CHAIN_DB.GOLD        TO ROLE ANALYST_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA SUPPLY_CHAIN_DB.GOLD TO ROLE ANALYST_ROLE;

-- Future grant — any new table in GOLD also auto-grants to ANALYST_ROLE
GRANT SELECT ON FUTURE TABLES IN SCHEMA SUPPLY_CHAIN_DB.GOLD TO ROLE ANALYST_ROLE;


------------------

-- Verify warehouses
SHOW WAREHOUSES LIKE '%_WH';

-- Verify database and schemas
SHOW SCHEMAS IN DATABASE SUPPLY_CHAIN_DB;

-- Verify roles
SHOW ROLES LIKE '%_ROLE';