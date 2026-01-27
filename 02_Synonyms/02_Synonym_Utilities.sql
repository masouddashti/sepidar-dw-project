/*
===============================================================================
SEPIDAR Data Warehouse Project
Phase 2: Synonym Management Utilities
===============================================================================
Script: 02_Synonym_Utilities.sql
Purpose: Utilities for managing and verifying synonyms
Author: BI Team
Version: 1.0
Date: January 2026
===============================================================================
*/

-- ============================================================================
-- UTILITY 1: Verify All Synonyms
-- ============================================================================
/*
Purpose: Check if all synonyms are valid and point to existing tables
Usage: EXEC etl.usp_VerifyAllSynonyms
*/

CREATE OR ALTER PROCEDURE etl.usp_VerifyAllSynonyms
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SynonymName NVARCHAR(256);
    DECLARE @BaseObject NVARCHAR(500);
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @IsValid BIT;
    DECLARE @RowCount INT;
    DECLARE @ErrorMsg NVARCHAR(4000);
    
    -- Create temp results table
    IF OBJECT_ID('tempdb..#VerificationResults') IS NOT NULL
        DROP TABLE #VerificationResults;
    
    CREATE TABLE #VerificationResults (
        SynonymName NVARCHAR(256),
        BaseObject NVARCHAR(500),
        IsValid BIT,
        RowCount INT NULL,
        ErrorMessage NVARCHAR(4000) NULL
    );
    
    -- Check each synonym
    DECLARE syn_cursor CURSOR FOR
        SELECT s.name, s.base_object_name
        FROM sys.synonyms s
        INNER JOIN sys.schemas sc ON s.schema_id = sc.schema_id
        WHERE sc.name = 'src';
    
    OPEN syn_cursor;
    FETCH NEXT FROM syn_cursor INTO @SynonymName, @BaseObject;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            SET @SQL = N'SELECT @cnt = COUNT(*) FROM src.' + QUOTENAME(@SynonymName);
            EXEC sp_executesql @SQL, N'@cnt INT OUTPUT', @cnt = @RowCount OUTPUT;
            SET @IsValid = 1;
            SET @ErrorMsg = NULL;
        END TRY
        BEGIN CATCH
            SET @IsValid = 0;
            SET @RowCount = NULL;
            SET @ErrorMsg = ERROR_MESSAGE();
        END CATCH
        
        INSERT INTO #VerificationResults VALUES 
            (@SynonymName, @BaseObject, @IsValid, @RowCount, @ErrorMsg);
        
        -- Update metadata
        UPDATE meta.SynonymRegistry 
        SET LastVerifiedDate = GETDATE(),
            IsActive = @IsValid
        WHERE SynonymName = @SynonymName AND SchemaName = 'src';
        
        FETCH NEXT FROM syn_cursor INTO @SynonymName, @BaseObject;
    END
    
    CLOSE syn_cursor;
    DEALLOCATE syn_cursor;
    
    -- Return results
    SELECT 
        SynonymName,
        BaseObject,
        CASE WHEN IsValid = 1 THEN '✓ Valid' ELSE '✗ Invalid' END AS Status,
        RowCount,
        ErrorMessage
    FROM #VerificationResults
    ORDER BY IsValid, SynonymName;
    
    -- Summary
    SELECT 
        COUNT(*) AS TotalSynonyms,
        SUM(CASE WHEN IsValid = 1 THEN 1 ELSE 0 END) AS ValidCount,
        SUM(CASE WHEN IsValid = 0 THEN 1 ELSE 0 END) AS InvalidCount,
        SUM(ISNULL(RowCount, 0)) AS TotalRows
    FROM #VerificationResults;
    
    DROP TABLE #VerificationResults;
END;
GO


-- ============================================================================
-- UTILITY 2: Get Synonym Row Counts
-- ============================================================================
/*
Purpose: Get row counts for all source tables via synonyms
Usage: EXEC etl.usp_GetSynonymRowCounts
*/

CREATE OR ALTER PROCEDURE etl.usp_GetSynonymRowCounts
    @ModuleCode VARCHAR(10) = NULL  -- NULL = all modules
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SynonymName NVARCHAR(256);
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @RowCount INT;
    
    -- Create temp results table
    IF OBJECT_ID('tempdb..#RowCounts') IS NOT NULL
        DROP TABLE #RowCounts;
    
    CREATE TABLE #RowCounts (
        SynonymName NVARCHAR(256),
        TargetTable NVARCHAR(256),
        RowCount INT,
        ModuleCode VARCHAR(10)
    );
    
    -- Get all synonyms with their module codes
    DECLARE syn_cursor CURSOR FOR
        SELECT 
            sr.SynonymName,
            sr.TargetTable,
            COALESCE(tm.ModuleCode, 'UNK') AS ModuleCode
        FROM meta.SynonymRegistry sr
        LEFT JOIN meta.TableMapping tm ON sr.TargetTable = tm.SourceTableName
        WHERE sr.SchemaName = 'src'
          AND sr.IsActive = 1
          AND (@ModuleCode IS NULL OR tm.ModuleCode = @ModuleCode);
    
    OPEN syn_cursor;
    FETCH NEXT FROM syn_cursor INTO @SynonymName, @SQL, @ModuleCode;
    
    DECLARE @Module VARCHAR(10);
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            SET @SQL = N'SELECT @cnt = COUNT(*) FROM src.' + QUOTENAME(@SynonymName);
            EXEC sp_executesql @SQL, N'@cnt INT OUTPUT', @cnt = @RowCount OUTPUT;
        END TRY
        BEGIN CATCH
            SET @RowCount = -1;  -- Indicates error
        END CATCH
        
        INSERT INTO #RowCounts (SynonymName, TargetTable, RowCount, ModuleCode)
        SELECT @SynonymName, @SQL, @RowCount, @ModuleCode;
        
        FETCH NEXT FROM syn_cursor INTO @SynonymName, @SQL, @ModuleCode;
    END
    
    CLOSE syn_cursor;
    DEALLOCATE syn_cursor;
    
    -- Return results grouped by module
    SELECT 
        ModuleCode,
        SynonymName,
        TargetTable,
        RowCount,
        CASE 
            WHEN RowCount = 0 THEN 'Empty'
            WHEN RowCount < 100 THEN 'Small'
            WHEN RowCount < 10000 THEN 'Medium'
            ELSE 'Large'
        END AS SizeCategory
    FROM #RowCounts
    ORDER BY ModuleCode, RowCount DESC;
    
    -- Summary by module
    SELECT 
        ModuleCode,
        COUNT(*) AS TableCount,
        SUM(CASE WHEN RowCount > 0 THEN 1 ELSE 0 END) AS TablesWithData,
        SUM(RowCount) AS TotalRows
    FROM #RowCounts
    GROUP BY ModuleCode
    ORDER BY ModuleCode;
    
    DROP TABLE #RowCounts;
END;
GO


-- ============================================================================
-- UTILITY 3: Refresh Single Synonym
-- ============================================================================
/*
Purpose: Recreate a single synonym (useful when source changes)
Usage: EXEC etl.usp_RefreshSynonym 'Account', 'NewSepidarDB'
*/

CREATE OR ALTER PROCEDURE etl.usp_RefreshSynonym
    @TableName NVARCHAR(256),
    @NewSourceDB NVARCHAR(128) = NULL,  -- NULL = use existing
    @NewSourceServer NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentDB NVARCHAR(128);
    DECLARE @CurrentServer NVARCHAR(128);
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @FullPath NVARCHAR(500);
    
    -- Get current settings
    SELECT 
        @CurrentDB = TargetDatabase,
        @CurrentServer = TargetServer
    FROM meta.SynonymRegistry
    WHERE SynonymName = @TableName AND SchemaName = 'src';
    
    IF @CurrentDB IS NULL
    BEGIN
        RAISERROR('Synonym not found: %s', 16, 1, @TableName);
        RETURN;
    END
    
    -- Use new values or existing
    SET @CurrentDB = ISNULL(@NewSourceDB, @CurrentDB);
    SET @CurrentServer = ISNULL(@NewSourceServer, @CurrentServer);
    
    -- Build path
    IF @CurrentServer IS NULL
        SET @FullPath = QUOTENAME(@CurrentDB) + '.dbo.' + QUOTENAME(@TableName);
    ELSE
        SET @FullPath = QUOTENAME(@CurrentServer) + '.' + QUOTENAME(@CurrentDB) + '.dbo.' + QUOTENAME(@TableName);
    
    -- Drop and recreate
    SET @SQL = 'DROP SYNONYM IF EXISTS src.' + QUOTENAME(@TableName) + ';';
    EXEC sp_executesql @SQL;
    
    SET @SQL = 'CREATE SYNONYM src.' + QUOTENAME(@TableName) + ' FOR ' + @FullPath + ';';
    EXEC sp_executesql @SQL;
    
    -- Update metadata
    UPDATE meta.SynonymRegistry
    SET TargetDatabase = @CurrentDB,
        TargetServer = @CurrentServer,
        LastVerifiedDate = GETDATE()
    WHERE SynonymName = @TableName AND SchemaName = 'src';
    
    PRINT 'Synonym refreshed: src.' + @TableName + ' → ' + @FullPath;
END;
GO


-- ============================================================================
-- UTILITY 4: Change Source Database for All Synonyms
-- ============================================================================
/*
Purpose: Point all synonyms to a different source database
         (Useful for switching between dev/test/prod)
Usage: EXEC etl.usp_ChangeSourceDatabase 'SepidarDB_Test'
*/

CREATE OR ALTER PROCEDURE etl.usp_ChangeSourceDatabase
    @NewSourceDB NVARCHAR(128),
    @NewSourceServer NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SynonymName NVARCHAR(256);
    DECLARE @TargetTable NVARCHAR(256);
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @FullPath NVARCHAR(500);
    DECLARE @SuccessCount INT = 0;
    DECLARE @ErrorCount INT = 0;
    
    PRINT '===============================================================================';
    PRINT 'Changing source database to: ' + @NewSourceDB;
    IF @NewSourceServer IS NOT NULL
        PRINT 'Server: ' + @NewSourceServer;
    PRINT '===============================================================================';
    
    DECLARE syn_cursor CURSOR FOR
        SELECT SynonymName, TargetTable
        FROM meta.SynonymRegistry
        WHERE SchemaName = 'src' AND IsActive = 1;
    
    OPEN syn_cursor;
    FETCH NEXT FROM syn_cursor INTO @SynonymName, @TargetTable;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            -- Build new path
            IF @NewSourceServer IS NULL
                SET @FullPath = QUOTENAME(@NewSourceDB) + '.dbo.' + QUOTENAME(@TargetTable);
            ELSE
                SET @FullPath = QUOTENAME(@NewSourceServer) + '.' + QUOTENAME(@NewSourceDB) + '.dbo.' + QUOTENAME(@TargetTable);
            
            -- Drop and recreate
            SET @SQL = 'DROP SYNONYM IF EXISTS src.' + QUOTENAME(@SynonymName) + ';';
            EXEC sp_executesql @SQL;
            
            SET @SQL = 'CREATE SYNONYM src.' + QUOTENAME(@SynonymName) + ' FOR ' + @FullPath + ';';
            EXEC sp_executesql @SQL;
            
            -- Update metadata
            UPDATE meta.SynonymRegistry
            SET TargetDatabase = @NewSourceDB,
                TargetServer = @NewSourceServer,
                LastVerifiedDate = GETDATE()
            WHERE SynonymName = @SynonymName AND SchemaName = 'src';
            
            SET @SuccessCount = @SuccessCount + 1;
            PRINT '  ✓ ' + @SynonymName;
            
        END TRY
        BEGIN CATCH
            SET @ErrorCount = @ErrorCount + 1;
            PRINT '  ✗ ' + @SynonymName + ' - ' + ERROR_MESSAGE();
        END CATCH
        
        FETCH NEXT FROM syn_cursor INTO @SynonymName, @TargetTable;
    END
    
    CLOSE syn_cursor;
    DEALLOCATE syn_cursor;
    
    -- Update source config
    UPDATE meta.SourceConfig
    SET SourceDatabase = @NewSourceDB,
        SourceServer = ISNULL(@NewSourceServer, SourceServer),
        LastModifiedDate = GETDATE()
    WHERE IsActive = 1;
    
    PRINT '';
    PRINT '===============================================================================';
    PRINT 'Complete. Success: ' + CAST(@SuccessCount AS VARCHAR(10)) + 
          ', Errors: ' + CAST(@ErrorCount AS VARCHAR(10));
    PRINT '===============================================================================';
END;
GO


-- ============================================================================
-- UTILITY 5: List All Synonyms with Details
-- ============================================================================
/*
Purpose: Show all synonyms with their status and metadata
Usage: EXEC etl.usp_ListSynonyms
*/

CREATE OR ALTER PROCEDURE etl.usp_ListSynonyms
    @SchemaName NVARCHAR(128) = 'src',
    @ShowOnlyActive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        sr.SynonymName,
        sr.TargetServer,
        sr.TargetDatabase,
        sr.TargetTable,
        CASE WHEN sr.IsActive = 1 THEN 'Active' ELSE 'Inactive' END AS Status,
        sr.LastVerifiedDate,
        COALESCE(tm.ModuleCode, 'N/A') AS ModuleCode,
        COALESCE(tm.TableType, 'N/A') AS TableType,
        s.base_object_name AS ActualTarget
    FROM meta.SynonymRegistry sr
    LEFT JOIN meta.TableMapping tm ON sr.TargetTable = tm.SourceTableName
    LEFT JOIN sys.synonyms s ON sr.SynonymName = s.name
    LEFT JOIN sys.schemas sc ON s.schema_id = sc.schema_id AND sc.name = @SchemaName
    WHERE sr.SchemaName = @SchemaName
      AND (@ShowOnlyActive = 0 OR sr.IsActive = 1)
    ORDER BY sr.SynonymName;
END;
GO


-- ============================================================================
-- UTILITY 6: Generate Synonym Script for Backup/Migration
-- ============================================================================
/*
Purpose: Generate CREATE SYNONYM statements for migration
Usage: EXEC etl.usp_GenerateSynonymScript
*/

CREATE OR ALTER PROCEDURE etl.usp_GenerateSynonymScript
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX) = '';
    
    SELECT @SQL = @SQL + 
        'CREATE SYNONYM src.' + QUOTENAME(SynonymName) + 
        ' FOR ' + 
        CASE 
            WHEN TargetServer IS NOT NULL 
            THEN QUOTENAME(TargetServer) + '.' 
            ELSE '' 
        END +
        QUOTENAME(TargetDatabase) + '.dbo.' + QUOTENAME(TargetTable) + 
        ';' + CHAR(13) + CHAR(10)
    FROM meta.SynonymRegistry
    WHERE SchemaName = 'src' AND IsActive = 1
    ORDER BY SynonymName;
    
    PRINT '-- Generated Synonym Script';
    PRINT '-- Date: ' + CONVERT(VARCHAR(30), GETDATE(), 121);
    PRINT '-- ============================================';
    PRINT '';
    PRINT @SQL;
END;
GO


PRINT 'Synonym utility procedures created successfully.';
GO
