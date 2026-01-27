/*
===============================================================================
SEPIDAR Data Warehouse Project
Phase 0: Database Structure Setup
===============================================================================
Script: 01_Create_Database_Structure.sql
Purpose: Create DW database with required schemas
Author: BI Team
Version: 1.0
Date: January 2026

Usage:
  1. Update @DW_DatabaseName variable if needed
  2. Execute on target SQL Server instance
===============================================================================
*/

USE master;
GO

-- ============================================================================
-- CONFIGURATION
-- ============================================================================
DECLARE @DW_DatabaseName NVARCHAR(128) = 'DW_DB';  -- Change per project

-- ============================================================================
-- CREATE DATABASE (if not exists)
-- ============================================================================
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = @DW_DatabaseName)
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = N'CREATE DATABASE ' + QUOTENAME(@DW_DatabaseName);
    EXEC sp_executesql @SQL;
    PRINT 'Database ' + @DW_DatabaseName + ' created successfully.';
END
ELSE
BEGIN
    PRINT 'Database ' + @DW_DatabaseName + ' already exists.';
END
GO

-- ============================================================================
-- USE DW DATABASE & CREATE SCHEMAS
-- ============================================================================
USE DW_DB;  -- Change this if using different DB name
GO

-- Schema: src (Source Synonyms)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'src')
BEGIN
    EXEC('CREATE SCHEMA src');
    PRINT 'Schema [src] created.';
END
GO

-- Schema: stg (Staging)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'stg')
BEGIN
    EXEC('CREATE SCHEMA stg');
    PRINT 'Schema [stg] created.';
END
GO

-- Schema: dim (Dimensions)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dim')
BEGIN
    EXEC('CREATE SCHEMA dim');
    PRINT 'Schema [dim] created.';
END
GO

-- Schema: fact (Facts)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'fact')
BEGIN
    EXEC('CREATE SCHEMA fact');
    PRINT 'Schema [fact] created.';
END
GO

-- Schema: mart (Data Marts / Aggregated Views)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'mart')
BEGIN
    EXEC('CREATE SCHEMA mart');
    PRINT 'Schema [mart] created.';
END
GO

-- Schema: etl (ETL Procedures & Functions)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'etl')
BEGIN
    EXEC('CREATE SCHEMA etl');
    PRINT 'Schema [etl] created.';
END
GO

-- Schema: meta (Metadata & Configuration)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'meta')
BEGIN
    EXEC('CREATE SCHEMA meta');
    PRINT 'Schema [meta] created.';
END
GO

-- Schema: rpt (Reporting Views for Power BI)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'rpt')
BEGIN
    EXEC('CREATE SCHEMA rpt');
    PRINT 'Schema [rpt] created.';
END
GO

PRINT '========================================';
PRINT 'All schemas created successfully!';
PRINT '========================================';
PRINT '';
PRINT 'Schema Structure:';
PRINT '  [src]  - Source Synonyms (pointing to SourceDB)';
PRINT '  [stg]  - Staging Tables';
PRINT '  [dim]  - Dimension Tables';
PRINT '  [fact] - Fact Tables';
PRINT '  [mart] - Data Mart Views & Aggregations';
PRINT '  [etl]  - ETL Stored Procedures';
PRINT '  [meta] - Metadata & Configuration Tables';
PRINT '  [rpt]  - Reporting Views for Power BI';
GO
