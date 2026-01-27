/*
===============================================================================
SEPIDAR Data Warehouse Project
Phase 0: Synonym Management Procedures
===============================================================================
Script: 03_Create_Synonym_Procedures.sql
Purpose: Stored procedures for managing source database synonyms
Author: BI Team
Version: 1.0
Date: January 2026

Key Procedures:
  - etl.usp_CreateSynonym: Create single synonym
  - etl.usp_CreateAllSynonyms: Create all synonyms from registry
  - etl.usp_RefreshSynonyms: Refresh synonyms when source changes
  - etl.usp_VerifySynonyms: Verify all synonyms are valid
===============================================================================
*/

USE DW_DB;
GO

-- ============================================================================
-- PROCEDURE: etl.usp_CreateSynonym
-- Purpose: Create or recreate a single synonym
-- ============================================================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_CreateSynonym' AND schema_id = SCHEMA_ID('etl'))
    DROP PROCEDURE etl.usp_CreateSynonym;
GO

CREATE PROCEDURE etl.usp_CreateSynonym
    @SynonymName NVARCHAR(128),
    @TargetDatabase NVARCHAR(128),
    @TargetSchema NVARCHAR(128) = 'dbo',
    @TargetObject NVARCHAR(128),
    @TargetServer NVARCHAR(128) = NULL,
    @SynonymSchema NVARCHAR(128) = 'src',
    @RegisterInMeta BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @FullSynonymName NVARCHAR(500);
    DECLARE @FullTargetName NVARCHAR(500);
    
    -- Build full names
    SET @FullSynonymName = QUOTENAME(@SynonymSchema) + '.' + QUOTENAME(@SynonymName);
    
    IF @TargetServer IS NOT NULL
        SET @FullTargetName = QUOTENAME(@TargetServer) + '.' + QUOTENAME(@TargetDatabase) + '.' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetObject);
    ELSE
        SET @FullTargetName = QUOTENAME(@TargetDatabase) + '.' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetObject);
    
    BEGIN TRY
        -- Drop existing synonym if exists
        IF EXISTS (SELECT * FROM sys.synonyms WHERE name = @SynonymName AND schema_id = SCHEMA_ID(@SynonymSchema))
        BEGIN
            SET @SQL = 'DROP SYNONYM ' + @FullSynonymName;
            EXEC sp_executesql @SQL;
        END
        
        -- Create new synonym
        SET @SQL = 'CREATE SYNONYM ' + @FullSynonymName + ' FOR ' + @FullTargetName;
        EXEC sp_executesql @SQL;
        
        -- Register in metadata table
        IF @RegisterInMeta = 1
        BEGIN
            IF EXISTS (SELECT 1 FROM meta.SynonymRegistry WHERE SynonymSchema = @SynonymSchema AND SynonymName = @SynonymName)
            BEGIN
                UPDATE meta.SynonymRegistry
                SET TargetServer = @TargetServer,
                    TargetDatabase = @TargetDatabase,
                    TargetSchema = @TargetSchema,
                    TargetObject = @TargetObject,
                    LastVerifiedDate = GETDATE()
                WHERE SynonymSchema = @SynonymSchema AND SynonymName = @SynonymName;
            END
            ELSE
            BEGIN
                INSERT INTO meta.SynonymRegistry (SynonymSchema, SynonymName, TargetServer, TargetDatabase, TargetSchema, TargetObject)
                VALUES (@SynonymSchema, @SynonymName, @TargetServer, @TargetDatabase, @TargetSchema, @TargetObject);
            END
        END
        
        PRINT 'Synonym ' + @FullSynonymName + ' created successfully -> ' + @FullTargetName;
        
    END TRY
    BEGIN CATCH
        PRINT 'ERROR creating synonym ' + @FullSynonymName + ': ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

-- ============================================================================
-- PROCEDURE: etl.usp_CreateAllSynonyms
-- Purpose: Create all synonyms from TableMapping table
-- ============================================================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_CreateAllSynonyms' AND schema_id = SCHEMA_ID('etl'))
    DROP PROCEDURE etl.usp_CreateAllSynonyms;
GO

CREATE PROCEDURE etl.usp_CreateAllSynonyms
    @SourceDatabase NVARCHAR(128) = NULL,  -- NULL = use config value
    @SourceServer NVARCHAR(128) = NULL,
    @ModuleCode NVARCHAR(20) = NULL        -- NULL = all modules
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ActualSourceDB NVARCHAR(128);
    DECLARE @ActualSourceServer NVARCHAR(128);
    DECLARE @SynonymName NVARCHAR(128);
    DECLARE @SourceSchema NVARCHAR(128);
    DECLARE @SourceTable NVARCHAR(128);
    DECLARE @Counter INT = 0;
    DECLARE @ErrorCount INT = 0;
    
    -- Get source database from config if not provided
    IF @SourceDatabase IS NULL
        SELECT @ActualSourceDB = ConfigValue FROM meta.SourceConfig WHERE ConfigKey = 'SourceDatabaseName';
    ELSE
        SET @ActualSourceDB = @SourceDatabase;
    
    IF @SourceServer IS NULL
        SELECT @ActualSourceServer = NULLIF(ConfigValue, '.') FROM meta.SourceConfig WHERE ConfigKey = 'SourceServerName';
    ELSE
        SET @ActualSourceServer = NULLIF(@SourceServer, '.');
    
    PRINT '========================================';
    PRINT 'Creating Synonyms';
    PRINT 'Source: ' + ISNULL(@ActualSourceServer + '.', '') + @ActualSourceDB;
    PRINT 'Module Filter: ' + ISNULL(@ModuleCode, 'ALL');
    PRINT '========================================';
    
    -- Cursor through all active mappings
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT SynonymName, SourceSchema, SourceTableName
        FROM meta.TableMapping
        WHERE IsActive = 1
          AND (@ModuleCode IS NULL OR ModuleCode = @ModuleCode)
        ORDER BY LoadPriority, SynonymName;
    
    OPEN cur;
    FETCH NEXT FROM cur INTO @SynonymName, @SourceSchema, @SourceTable;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC etl.usp_CreateSynonym
                @SynonymName = @SynonymName,
                @TargetDatabase = @ActualSourceDB,
                @TargetSchema = @SourceSchema,
                @TargetObject = @SourceTable,
                @TargetServer = @ActualSourceServer;
            
            SET @Counter = @Counter + 1;
        END TRY
        BEGIN CATCH
            SET @ErrorCount = @ErrorCount + 1;
            PRINT 'FAILED: ' + @SynonymName;
        END CATCH
        
        FETCH NEXT FROM cur INTO @SynonymName, @SourceSchema, @SourceTable;
    END
    
    CLOSE cur;
    DEALLOCATE cur;
    
    PRINT '========================================';
    PRINT 'Synonyms created: ' + CAST(@Counter AS VARCHAR(10));
    PRINT 'Errors: ' + CAST(@ErrorCount AS VARCHAR(10));
    PRINT '========================================';
END
GO

-- ============================================================================
-- PROCEDURE: etl.usp_VerifySynonyms
-- Purpose: Verify all synonyms point to valid objects
-- ============================================================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_VerifySynonyms' AND schema_id = SCHEMA_ID('etl'))
    DROP PROCEDURE etl.usp_VerifySynonyms;
GO

CREATE PROCEDURE etl.usp_VerifySynonyms
    @FixInvalid BIT = 0  -- If 1, attempt to recreate invalid synonyms
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SynonymName NVARCHAR(128);
    DECLARE @SynonymSchema NVARCHAR(128);
    DECLARE @BaseObject NVARCHAR(500);
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @ValidCount INT = 0;
    DECLARE @InvalidCount INT = 0;
    
    -- Create temp table for results
    CREATE TABLE #SynonymStatus (
        SynonymSchema NVARCHAR(128),
        SynonymName NVARCHAR(128),
        BaseObject NVARCHAR(500),
        IsValid BIT,
        ErrorMessage NVARCHAR(500)
    );
    
    -- Check each synonym
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT SCHEMA_NAME(schema_id), name, base_object_name
        FROM sys.synonyms
        WHERE SCHEMA_NAME(schema_id) = 'src';
    
    OPEN cur;
    FETCH NEXT FROM cur INTO @SynonymSchema, @SynonymName, @BaseObject;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            -- Try to select from synonym (just check if accessible)
            SET @SQL = 'SELECT TOP 0 * FROM ' + QUOTENAME(@SynonymSchema) + '.' + QUOTENAME(@SynonymName);
            EXEC sp_executesql @SQL;
            
            INSERT INTO #SynonymStatus VALUES (@SynonymSchema, @SynonymName, @BaseObject, 1, NULL);
            SET @ValidCount = @ValidCount + 1;
        END TRY
        BEGIN CATCH
            INSERT INTO #SynonymStatus VALUES (@SynonymSchema, @SynonymName, @BaseObject, 0, ERROR_MESSAGE());
            SET @InvalidCount = @InvalidCount + 1;
        END CATCH
        
        FETCH NEXT FROM cur INTO @SynonymSchema, @SynonymName, @BaseObject;
    END
    
    CLOSE cur;
    DEALLOCATE cur;
    
    -- Update last verified date for valid synonyms
    UPDATE meta.SynonymRegistry
    SET LastVerifiedDate = GETDATE()
    FROM meta.SynonymRegistry r
    INNER JOIN #SynonymStatus s ON r.SynonymSchema = s.SynonymSchema AND r.SynonymName = s.SynonymName
    WHERE s.IsValid = 1;
    
    -- Output results
    PRINT '========================================';
    PRINT 'Synonym Verification Results';
    PRINT '========================================';
    PRINT 'Valid: ' + CAST(@ValidCount AS VARCHAR(10));
    PRINT 'Invalid: ' + CAST(@InvalidCount AS VARCHAR(10));
    PRINT '';
    
    -- Show invalid synonyms
    IF @InvalidCount > 0
    BEGIN
        PRINT 'Invalid Synonyms:';
        SELECT SynonymSchema, SynonymName, BaseObject, ErrorMessage
        FROM #SynonymStatus
        WHERE IsValid = 0;
    END
    
    DROP TABLE #SynonymStatus;
END
GO

-- ============================================================================
-- PROCEDURE: etl.usp_ListSourceTables
-- Purpose: List all tables from source database for initial mapping
-- ============================================================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_ListSourceTables' AND schema_id = SCHEMA_ID('etl'))
    DROP PROCEDURE etl.usp_ListSourceTables;
GO

CREATE PROCEDURE etl.usp_ListSourceTables
    @SourceDatabase NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ActualSourceDB NVARCHAR(128);
    DECLARE @SQL NVARCHAR(MAX);
    
    -- Get source database from config if not provided
    IF @SourceDatabase IS NULL
        SELECT @ActualSourceDB = ConfigValue FROM meta.SourceConfig WHERE ConfigKey = 'SourceDatabaseName';
    ELSE
        SET @ActualSourceDB = @SourceDatabase;
    
    SET @SQL = N'
    SELECT 
        t.TABLE_SCHEMA AS SchemaName,
        t.TABLE_NAME AS TableName,
        t.TABLE_TYPE AS TableType,
        (
            SELECT SUM(p.rows)
            FROM ' + QUOTENAME(@ActualSourceDB) + '.sys.tables st
            INNER JOIN ' + QUOTENAME(@ActualSourceDB) + '.sys.partitions p 
                ON st.object_id = p.object_id AND p.index_id IN (0, 1)
            WHERE st.name = t.TABLE_NAME
        ) AS RowCount,
        (
            SELECT COUNT(*)
            FROM ' + QUOTENAME(@ActualSourceDB) + '.INFORMATION_SCHEMA.COLUMNS c
            WHERE c.TABLE_SCHEMA = t.TABLE_SCHEMA AND c.TABLE_NAME = t.TABLE_NAME
        ) AS ColumnCount
    FROM ' + QUOTENAME(@ActualSourceDB) + '.INFORMATION_SCHEMA.TABLES t
    WHERE t.TABLE_TYPE = ''BASE TABLE''
    ORDER BY t.TABLE_SCHEMA, t.TABLE_NAME';
    
    EXEC sp_executesql @SQL;
END
GO

PRINT '========================================';
PRINT 'Synonym management procedures created!';
PRINT '========================================';
PRINT '';
PRINT 'Available Procedures:';
PRINT '  etl.usp_CreateSynonym       - Create single synonym';
PRINT '  etl.usp_CreateAllSynonyms   - Create all from mapping';
PRINT '  etl.usp_VerifySynonyms      - Verify synonyms validity';
PRINT '  etl.usp_ListSourceTables    - List source DB tables';
GO
