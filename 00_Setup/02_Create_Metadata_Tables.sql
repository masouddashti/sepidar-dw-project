/*
===============================================================================
SEPIDAR Data Warehouse Project
Phase 0: Metadata Configuration Tables
===============================================================================
Script: 02_Create_Metadata_Tables.sql
Purpose: Create configuration tables for managing source connections and ETL
Author: BI Team
Version: 1.0
Date: January 2026
===============================================================================
*/

USE DW_DB;
GO

-- ============================================================================
-- TABLE: meta.SourceConfig
-- Purpose: Store source database connection info for Synonym creation
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SourceConfig' AND schema_id = SCHEMA_ID('meta'))
BEGIN
    CREATE TABLE meta.SourceConfig (
        ConfigID INT IDENTITY(1,1) PRIMARY KEY,
        ConfigKey NVARCHAR(100) NOT NULL UNIQUE,
        ConfigValue NVARCHAR(500) NOT NULL,
        Description NVARCHAR(500) NULL,
        IsActive BIT DEFAULT 1,
        CreatedDate DATETIME DEFAULT GETDATE(),
        ModifiedDate DATETIME DEFAULT GETDATE()
    );

    -- Insert default configuration
    INSERT INTO meta.SourceConfig (ConfigKey, ConfigValue, Description)
    VALUES 
        ('SourceServerName', '.',  'Source database server name (. for local)'),
        ('SourceDatabaseName', 'SourceDB', 'SEPIDAR source database name'),
        ('DW_DatabaseName', 'DW_DB', 'Data Warehouse database name'),
        ('ETL_BatchSize', '10000', 'Default batch size for ETL operations'),
        ('ETL_Timeout', '3600', 'Default timeout in seconds for ETL procedures');

    PRINT 'Table [meta].[SourceConfig] created with default values.';
END
GO

-- ============================================================================
-- TABLE: meta.TableMapping
-- Purpose: Map source tables to DW objects with module classification
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TableMapping' AND schema_id = SCHEMA_ID('meta'))
BEGIN
    CREATE TABLE meta.TableMapping (
        MappingID INT IDENTITY(1,1) PRIMARY KEY,
        
        -- Source Information
        SourceSchema NVARCHAR(128) DEFAULT 'dbo',
        SourceTableName NVARCHAR(128) NOT NULL,
        
        -- Target Information
        SynonymName NVARCHAR(128) NOT NULL,
        TargetSchema NVARCHAR(128) NULL,
        TargetTableName NVARCHAR(128) NULL,
        
        -- Classification
        ModuleCode NVARCHAR(20) NOT NULL,  -- FIN, SAL, INV, PRC, CSH, SYS, etc.
        ModuleName NVARCHAR(100) NOT NULL,
        TableType NVARCHAR(50) NULL,       -- Master, Transaction, Config, Log, etc.
        
        -- ETL Settings
        IsActive BIT DEFAULT 1,
        LoadPriority INT DEFAULT 100,      -- Lower = Higher priority
        IncrementalColumn NVARCHAR(128) NULL,
        
        -- Metadata
        TableDescription NVARCHAR(500) NULL,
        RowCountEstimate BIGINT NULL,
        LastAnalyzedDate DATETIME NULL,
        
        CreatedDate DATETIME DEFAULT GETDATE(),
        ModifiedDate DATETIME DEFAULT GETDATE()
    );

    -- Create index for faster lookups
    CREATE NONCLUSTERED INDEX IX_TableMapping_Module ON meta.TableMapping(ModuleCode);
    CREATE NONCLUSTERED INDEX IX_TableMapping_Active ON meta.TableMapping(IsActive);

    PRINT 'Table [meta].[TableMapping] created.';
END
GO

-- ============================================================================
-- TABLE: meta.ModuleDefinition
-- Purpose: Define modules and their descriptions
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ModuleDefinition' AND schema_id = SCHEMA_ID('meta'))
BEGIN
    CREATE TABLE meta.ModuleDefinition (
        ModuleCode NVARCHAR(20) PRIMARY KEY,
        ModuleName NVARCHAR(100) NOT NULL,
        ModuleNameFA NVARCHAR(100) NULL,  -- Persian name
        Description NVARCHAR(500) NULL,
        SortOrder INT DEFAULT 100,
        IsActive BIT DEFAULT 1,
        CreatedDate DATETIME DEFAULT GETDATE()
    );

    -- Insert module definitions
    INSERT INTO meta.ModuleDefinition (ModuleCode, ModuleName, ModuleNameFA, Description, SortOrder)
    VALUES 
        ('SYS', 'System & Configuration', N'سیستم و تنظیمات', 'System tables, users, settings', 10),
        ('BAS', 'Base & Master Data', N'اطلاعات پایه', 'Shared master data across modules', 20),
        ('FIN', 'Financial & Accounting', N'مالی و حسابداری', 'General ledger, accounts, vouchers', 30),
        ('SAL', 'Sales & Distribution', N'فروش و توزیع', 'Sales orders, customers, invoices', 40),
        ('INV', 'Inventory & Warehouse', N'انبار و موجودی', 'Stock, warehouses, inventory transactions', 50),
        ('PRC', 'Procurement & Purchasing', N'خرید و تدارکات', 'Purchase orders, suppliers', 60),
        ('CSH', 'Cash & Treasury', N'خزانه‌داری', 'Cash, bank, payments, receipts', 70),
        ('CHQ', 'Cheque Management', N'مدیریت چک', 'Cheques received and issued', 75),
        ('PRD', 'Production', N'تولید', 'BOM, production orders', 80),
        ('HR', 'Human Resources', N'منابع انسانی', 'Employees, payroll', 90),
        ('UNK', 'Unknown/Unclassified', N'دسته‌بندی نشده', 'Tables not yet classified', 999);

    PRINT 'Table [meta].[ModuleDefinition] created with module definitions.';
END
GO

-- ============================================================================
-- TABLE: meta.ETLLog
-- Purpose: Log ETL execution history
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ETLLog' AND schema_id = SCHEMA_ID('meta'))
BEGIN
    CREATE TABLE meta.ETLLog (
        LogID BIGINT IDENTITY(1,1) PRIMARY KEY,
        
        -- Execution Info
        ProcedureName NVARCHAR(256) NOT NULL,
        PackageName NVARCHAR(256) NULL,
        ExecutionGUID UNIQUEIDENTIFIER DEFAULT NEWID(),
        
        -- Timing
        StartTime DATETIME NOT NULL DEFAULT GETDATE(),
        EndTime DATETIME NULL,
        DurationSeconds AS DATEDIFF(SECOND, StartTime, EndTime),
        
        -- Results
        Status NVARCHAR(20) DEFAULT 'Running',  -- Running, Success, Failed, Warning
        RowsRead BIGINT NULL,
        RowsInserted BIGINT NULL,
        RowsUpdated BIGINT NULL,
        RowsDeleted BIGINT NULL,
        
        -- Error Handling
        ErrorNumber INT NULL,
        ErrorMessage NVARCHAR(MAX) NULL,
        
        -- Additional Info
        Notes NVARCHAR(MAX) NULL
    );

    -- Create index for querying recent logs
    CREATE NONCLUSTERED INDEX IX_ETLLog_StartTime ON meta.ETLLog(StartTime DESC);
    CREATE NONCLUSTERED INDEX IX_ETLLog_Status ON meta.ETLLog(Status);

    PRINT 'Table [meta].[ETLLog] created.';
END
GO

-- ============================================================================
-- TABLE: meta.SynonymRegistry
-- Purpose: Track all synonyms and their targets
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SynonymRegistry' AND schema_id = SCHEMA_ID('meta'))
BEGIN
    CREATE TABLE meta.SynonymRegistry (
        RegistryID INT IDENTITY(1,1) PRIMARY KEY,
        SynonymSchema NVARCHAR(128) DEFAULT 'src',
        SynonymName NVARCHAR(128) NOT NULL,
        TargetServer NVARCHAR(128) NULL,      -- NULL for local
        TargetDatabase NVARCHAR(128) NOT NULL,
        TargetSchema NVARCHAR(128) DEFAULT 'dbo',
        TargetObject NVARCHAR(128) NOT NULL,
        ObjectType NVARCHAR(50) DEFAULT 'TABLE',  -- TABLE, VIEW, FUNCTION
        IsActive BIT DEFAULT 1,
        LastVerifiedDate DATETIME NULL,
        CreatedDate DATETIME DEFAULT GETDATE(),
        
        CONSTRAINT UQ_SynonymRegistry UNIQUE (SynonymSchema, SynonymName)
    );

    PRINT 'Table [meta].[SynonymRegistry] created.';
END
GO

PRINT '========================================';
PRINT 'All metadata tables created successfully!';
PRINT '========================================';
GO
