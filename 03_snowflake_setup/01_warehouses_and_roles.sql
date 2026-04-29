-- ============================================================
-- SCRIPT 01: Warehouses, Roles, and Permissions
-- Project : Snowflake Supply Chain Analytics
-- Author  : Sameer Nayak
-- ============================================================

USE ROLE ACCOUNTADMIN;

-- ── Warehouses ───────────────────────────────────────────────

-- For Databricks ingestion and dbt transformations
CREATE WAREHOUSE IF NOT EXISTS TRANSFORM_WH
    WAREHOUSE_SIZE    = 'X-SMALL'
    AUTO_SUSPEND      = 60       
    AUTO_RESUME       = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Used by Databricks and dbt for ETL workloads';

-- For analysts querying the Gold layer
CREATE WAREHOUSE IF NOT EXISTS ANALYST_WH
    WAREHOUSE_SIZE    = 'X-SMALL'
    AUTO_SUSPEND      = 60
    AUTO_RESUME       = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Used by analysts for reporting queries on Gold layer';


CREATE ROLE IF NOT EXISTS ENGINEER_ROLE
    COMMENT = 'Full access role for data engineers';

CREATE ROLE IF NOT EXISTS ANALYST_ROLE
    COMMENT = 'Read-only access on Gold layer for analysts';


GRANT ROLE ENGINEER_ROLE TO USER SAMNAYAK;
GRANT ROLE ANALYST_ROLE  TO USER SAMNAYAK;

-- Grant warehouse usage
GRANT USAGE ON WAREHOUSE TRANSFORM_WH TO ROLE ENGINEER_ROLE;
GRANT USAGE ON WAREHOUSE ANALYST_WH   TO ROLE ANALYST_ROLE;

-- Also allow SYSADMIN to manage objects we create
GRANT ROLE ENGINEER_ROLE TO ROLE SYSADMIN;