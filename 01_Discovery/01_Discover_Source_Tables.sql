/*
===============================================================================
SEPIDAR Data Warehouse Project
Phase 1: Source Database Discovery
===============================================================================
Script: 01_Discover_Source_Tables.sql
Purpose: Extract complete information about all tables in SEPIDAR database
Author: BI Team
Version: 1.0
Date: January 2026

Instructions:
  1. Restore SEPIDAR backup to SQL Server
  2. Update @SourceDB variable with actual database name
  3. Execute this script
  4. Review results for table classification
===============================================================================
*/

-- ============================================================================
-- CONFIGURATION - UPDATE THIS!
-- ============================================================================
DECLARE @SourceDB NVARCHAR(128) = 'SourceDB';  -- << تغییر دهید به نام واقعی دیتابیس

-- ============================================================================
-- SECTION 1: ALL TABLES WITH ROW COUNTS
-- ============================================================================
PRINT '========================================';
PRINT 'SECTION 1: All Tables with Row Counts';
PRINT '========================================';

DECLARE @SQL NVARCHAR(MAX);

SET @SQL = N'
SELECT 
    ROW_NUMBER() OVER (ORDER BY t.name) AS RowNum,
    s.name AS SchemaName,
    t.name AS TableName,
    p.rows AS RowCount,
    (
        SELECT COUNT(*) 
        FROM ' + QUOTENAME(@SourceDB) + '.sys.columns c 
        WHERE c.object_id = t.object_id
    ) AS ColumnCount,
    t.create_date AS CreatedDate,
    t.modify_date AS ModifiedDate,
    CASE 
        WHEN t.name LIKE ''%Log%'' OR t.name LIKE ''%History%'' OR t.name LIKE ''%Archive%'' THEN ''Log/History''
        WHEN t.name LIKE ''%Config%'' OR t.name LIKE ''%Setting%'' OR t.name LIKE ''%Option%'' THEN ''Configuration''
        WHEN t.name LIKE ''%Temp%'' OR t.name LIKE ''%tmp%'' THEN ''Temporary''
        WHEN p.rows = 0 THEN ''Empty''
        WHEN p.rows < 100 THEN ''Master/Config''
        WHEN p.rows < 10000 THEN ''Medium''
        ELSE ''Large/Transaction''
    END AS TableSizeCategory
FROM ' + QUOTENAME(@SourceDB) + '.sys.tables t
INNER JOIN ' + QUOTENAME(@SourceDB) + '.sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN ' + QUOTENAME(@SourceDB) + '.sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
WHERE t.is_ms_shipped = 0
ORDER BY t.name;
';

EXEC sp_executesql @SQL;


-- ============================================================================
-- SECTION 2: TABLES GROUPED BY NAME PATTERN (Auto-Classification)
-- ============================================================================
PRINT '';
PRINT '========================================';
PRINT 'SECTION 2: Auto-Classification by Pattern';
PRINT '========================================';

SET @SQL = N'
SELECT 
    CASE 
        -- سیستم و تنظیمات
        WHEN t.name LIKE ''%User%'' OR t.name LIKE ''%Role%'' OR t.name LIKE ''%Permission%'' 
             OR t.name LIKE ''%Access%'' OR t.name LIKE ''%Login%'' THEN ''SYS-Users''
        WHEN t.name LIKE ''%Config%'' OR t.name LIKE ''%Setting%'' OR t.name LIKE ''%Option%''
             OR t.name LIKE ''%Parameter%'' OR t.name LIKE ''%Preference%'' THEN ''SYS-Config''
        WHEN t.name LIKE ''%Log%'' OR t.name LIKE ''%Audit%'' OR t.name LIKE ''%History%''
             OR t.name LIKE ''%Track%'' THEN ''SYS-Log''
        
        -- اطلاعات پایه
        WHEN t.name LIKE ''%Person%'' OR t.name LIKE ''%People%'' THEN ''BAS-Person''
        WHEN t.name LIKE ''%Company%'' OR t.name LIKE ''%Branch%'' OR t.name LIKE ''%Unit%'' THEN ''BAS-Organization''
        WHEN t.name LIKE ''%Currency%'' OR t.name LIKE ''%Exchange%'' THEN ''BAS-Currency''
        WHEN t.name LIKE ''%Region%'' OR t.name LIKE ''%City%'' OR t.name LIKE ''%Province%''
             OR t.name LIKE ''%Country%'' OR t.name LIKE ''%Address%'' THEN ''BAS-Location''
        WHEN t.name LIKE ''%Calendar%'' OR t.name LIKE ''%Holiday%'' OR t.name LIKE ''%Period%'' THEN ''BAS-Calendar''
        
        -- مالی و حسابداری
        WHEN t.name LIKE ''%Account%'' OR t.name LIKE ''%Chart%'' OR t.name LIKE ''%COA%'' THEN ''FIN-Accounts''
        WHEN t.name LIKE ''%Voucher%'' OR t.name LIKE ''%Journal%'' THEN ''FIN-Voucher''
        WHEN t.name LIKE ''%Ledger%'' OR t.name LIKE ''%GL%'' THEN ''FIN-Ledger''
        WHEN t.name LIKE ''%Budget%'' THEN ''FIN-Budget''
        WHEN t.name LIKE ''%Cost%Center%'' OR t.name LIKE ''%CostCenter%'' THEN ''FIN-CostCenter''
        WHEN t.name LIKE ''%Fiscal%'' THEN ''FIN-Fiscal''
        WHEN t.name LIKE ''%Tax%'' THEN ''FIN-Tax''
        
        -- فروش
        WHEN t.name LIKE ''%Customer%'' OR t.name LIKE ''%Client%'' THEN ''SAL-Customer''
        WHEN t.name LIKE ''%Sale%'' AND (t.name LIKE ''%Invoice%'' OR t.name LIKE ''%Bill%'') THEN ''SAL-Invoice''
        WHEN t.name LIKE ''%Sale%'' AND t.name LIKE ''%Order%'' THEN ''SAL-Order''
        WHEN t.name LIKE ''%Sale%'' AND t.name LIKE ''%Return%'' THEN ''SAL-Return''
        WHEN t.name LIKE ''%Quote%'' OR t.name LIKE ''%Quotation%'' OR t.name LIKE ''%Proforma%'' THEN ''SAL-Quote''
        WHEN t.name LIKE ''%Price%'' AND t.name LIKE ''%List%'' THEN ''SAL-PriceList''
        WHEN t.name LIKE ''%Discount%'' THEN ''SAL-Discount''
        WHEN t.name LIKE ''%Sale%'' THEN ''SAL-Other''
        
        -- انبار
        WHEN t.name LIKE ''%Product%'' OR t.name LIKE ''%Item%'' OR t.name LIKE ''%Good%''
             OR t.name LIKE ''%Material%'' OR t.name LIKE ''%Stuff%'' THEN ''INV-Product''
        WHEN t.name LIKE ''%Stock%'' OR t.name LIKE ''%Inventory%'' THEN ''INV-Stock''
        WHEN t.name LIKE ''%Warehouse%'' OR t.name LIKE ''%Store%'' OR t.name LIKE ''%Location%'' THEN ''INV-Warehouse''
        WHEN t.name LIKE ''%Batch%'' OR t.name LIKE ''%Lot%'' OR t.name LIKE ''%Serial%'' THEN ''INV-Tracking''
        WHEN t.name LIKE ''%Receipt%'' AND t.name LIKE ''%Good%'' THEN ''INV-Receipt''
        WHEN t.name LIKE ''%Transfer%'' THEN ''INV-Transfer''
        
        -- خرید
        WHEN t.name LIKE ''%Supplier%'' OR t.name LIKE ''%Vendor%'' THEN ''PRC-Supplier''
        WHEN t.name LIKE ''%Purchase%'' AND t.name LIKE ''%Invoice%'' THEN ''PRC-Invoice''
        WHEN t.name LIKE ''%Purchase%'' AND t.name LIKE ''%Order%'' THEN ''PRC-Order''
        WHEN t.name LIKE ''%Purchase%'' AND t.name LIKE ''%Return%'' THEN ''PRC-Return''
        WHEN t.name LIKE ''%Requisition%'' THEN ''PRC-Requisition''
        WHEN t.name LIKE ''%Purchase%'' THEN ''PRC-Other''
        
        -- خزانه و بانک
        WHEN t.name LIKE ''%Bank%'' THEN ''CSH-Bank''
        WHEN t.name LIKE ''%Cash%'' THEN ''CSH-Cash''
        WHEN t.name LIKE ''%Payment%'' THEN ''CSH-Payment''
        WHEN t.name LIKE ''%Receipt%'' AND NOT t.name LIKE ''%Good%'' THEN ''CSH-Receipt''
        WHEN t.name LIKE ''%Fund%'' OR t.name LIKE ''%Treasury%'' THEN ''CSH-Treasury''
        
        -- چک
        WHEN t.name LIKE ''%Cheque%'' OR t.name LIKE ''%Check%'' THEN ''CHQ-Cheque''
        
        -- تولید
        WHEN t.name LIKE ''%BOM%'' OR t.name LIKE ''%Bill%Material%'' THEN ''PRD-BOM''
        WHEN t.name LIKE ''%Production%'' OR t.name LIKE ''%Manufacture%'' THEN ''PRD-Production''
        WHEN t.name LIKE ''%Work%Order%'' THEN ''PRD-WorkOrder''
        
        -- منابع انسانی
        WHEN t.name LIKE ''%Employee%'' OR t.name LIKE ''%Staff%'' THEN ''HR-Employee''
        WHEN t.name LIKE ''%Payroll%'' OR t.name LIKE ''%Salary%'' THEN ''HR-Payroll''
        WHEN t.name LIKE ''%Leave%'' OR t.name LIKE ''%Absence%'' THEN ''HR-Leave''
        WHEN t.name LIKE ''%Attendance%'' THEN ''HR-Attendance''
        
        ELSE ''UNK-Unclassified''
    END AS ModuleCategory,
    COUNT(*) AS TableCount,
    SUM(p.rows) AS TotalRows
FROM ' + QUOTENAME(@SourceDB) + '.sys.tables t
INNER JOIN ' + QUOTENAME(@SourceDB) + '.sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN ' + QUOTENAME(@SourceDB) + '.sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
WHERE t.is_ms_shipped = 0
GROUP BY 
    CASE 
        WHEN t.name LIKE ''%User%'' OR t.name LIKE ''%Role%'' OR t.name LIKE ''%Permission%'' 
             OR t.name LIKE ''%Access%'' OR t.name LIKE ''%Login%'' THEN ''SYS-Users''
        WHEN t.name LIKE ''%Config%'' OR t.name LIKE ''%Setting%'' OR t.name LIKE ''%Option%''
             OR t.name LIKE ''%Parameter%'' OR t.name LIKE ''%Preference%'' THEN ''SYS-Config''
        WHEN t.name LIKE ''%Log%'' OR t.name LIKE ''%Audit%'' OR t.name LIKE ''%History%''
             OR t.name LIKE ''%Track%'' THEN ''SYS-Log''
        WHEN t.name LIKE ''%Person%'' OR t.name LIKE ''%People%'' THEN ''BAS-Person''
        WHEN t.name LIKE ''%Company%'' OR t.name LIKE ''%Branch%'' OR t.name LIKE ''%Unit%'' THEN ''BAS-Organization''
        WHEN t.name LIKE ''%Currency%'' OR t.name LIKE ''%Exchange%'' THEN ''BAS-Currency''
        WHEN t.name LIKE ''%Region%'' OR t.name LIKE ''%City%'' OR t.name LIKE ''%Province%''
             OR t.name LIKE ''%Country%'' OR t.name LIKE ''%Address%'' THEN ''BAS-Location''
        WHEN t.name LIKE ''%Calendar%'' OR t.name LIKE ''%Holiday%'' OR t.name LIKE ''%Period%'' THEN ''BAS-Calendar''
        WHEN t.name LIKE ''%Account%'' OR t.name LIKE ''%Chart%'' OR t.name LIKE ''%COA%'' THEN ''FIN-Accounts''
        WHEN t.name LIKE ''%Voucher%'' OR t.name LIKE ''%Journal%'' THEN ''FIN-Voucher''
        WHEN t.name LIKE ''%Ledger%'' OR t.name LIKE ''%GL%'' THEN ''FIN-Ledger''
        WHEN t.name LIKE ''%Budget%'' THEN ''FIN-Budget''
        WHEN t.name LIKE ''%Cost%Center%'' OR t.name LIKE ''%CostCenter%'' THEN ''FIN-CostCenter''
        WHEN t.name LIKE ''%Fiscal%'' THEN ''FIN-Fiscal''
        WHEN t.name LIKE ''%Tax%'' THEN ''FIN-Tax''
        WHEN t.name LIKE ''%Customer%'' OR t.name LIKE ''%Client%'' THEN ''SAL-Customer''
        WHEN t.name LIKE ''%Sale%'' AND (t.name LIKE ''%Invoice%'' OR t.name LIKE ''%Bill%'') THEN ''SAL-Invoice''
        WHEN t.name LIKE ''%Sale%'' AND t.name LIKE ''%Order%'' THEN ''SAL-Order''
        WHEN t.name LIKE ''%Sale%'' AND t.name LIKE ''%Return%'' THEN ''SAL-Return''
        WHEN t.name LIKE ''%Quote%'' OR t.name LIKE ''%Quotation%'' OR t.name LIKE ''%Proforma%'' THEN ''SAL-Quote''
        WHEN t.name LIKE ''%Price%'' AND t.name LIKE ''%List%'' THEN ''SAL-PriceList''
        WHEN t.name LIKE ''%Discount%'' THEN ''SAL-Discount''
        WHEN t.name LIKE ''%Sale%'' THEN ''SAL-Other''
        WHEN t.name LIKE ''%Product%'' OR t.name LIKE ''%Item%'' OR t.name LIKE ''%Good%''
             OR t.name LIKE ''%Material%'' OR t.name LIKE ''%Stuff%'' THEN ''INV-Product''
        WHEN t.name LIKE ''%Stock%'' OR t.name LIKE ''%Inventory%'' THEN ''INV-Stock''
        WHEN t.name LIKE ''%Warehouse%'' OR t.name LIKE ''%Store%'' OR t.name LIKE ''%Location%'' THEN ''INV-Warehouse''
        WHEN t.name LIKE ''%Batch%'' OR t.name LIKE ''%Lot%'' OR t.name LIKE ''%Serial%'' THEN ''INV-Tracking''
        WHEN t.name LIKE ''%Receipt%'' AND t.name LIKE ''%Good%'' THEN ''INV-Receipt''
        WHEN t.name LIKE ''%Transfer%'' THEN ''INV-Transfer''
        WHEN t.name LIKE ''%Supplier%'' OR t.name LIKE ''%Vendor%'' THEN ''PRC-Supplier''
        WHEN t.name LIKE ''%Purchase%'' AND t.name LIKE ''%Invoice%'' THEN ''PRC-Invoice''
        WHEN t.name LIKE ''%Purchase%'' AND t.name LIKE ''%Order%'' THEN ''PRC-Order''
        WHEN t.name LIKE ''%Purchase%'' AND t.name LIKE ''%Return%'' THEN ''PRC-Return''
        WHEN t.name LIKE ''%Requisition%'' THEN ''PRC-Requisition''
        WHEN t.name LIKE ''%Purchase%'' THEN ''PRC-Other''
        WHEN t.name LIKE ''%Bank%'' THEN ''CSH-Bank''
        WHEN t.name LIKE ''%Cash%'' THEN ''CSH-Cash''
        WHEN t.name LIKE ''%Payment%'' THEN ''CSH-Payment''
        WHEN t.name LIKE ''%Receipt%'' AND NOT t.name LIKE ''%Good%'' THEN ''CSH-Receipt''
        WHEN t.name LIKE ''%Fund%'' OR t.name LIKE ''%Treasury%'' THEN ''CSH-Treasury''
        WHEN t.name LIKE ''%Cheque%'' OR t.name LIKE ''%Check%'' THEN ''CHQ-Cheque''
        WHEN t.name LIKE ''%BOM%'' OR t.name LIKE ''%Bill%Material%'' THEN ''PRD-BOM''
        WHEN t.name LIKE ''%Production%'' OR t.name LIKE ''%Manufacture%'' THEN ''PRD-Production''
        WHEN t.name LIKE ''%Work%Order%'' THEN ''PRD-WorkOrder''
        WHEN t.name LIKE ''%Employee%'' OR t.name LIKE ''%Staff%'' THEN ''HR-Employee''
        WHEN t.name LIKE ''%Payroll%'' OR t.name LIKE ''%Salary%'' THEN ''HR-Payroll''
        WHEN t.name LIKE ''%Leave%'' OR t.name LIKE ''%Absence%'' THEN ''HR-Leave''
        WHEN t.name LIKE ''%Attendance%'' THEN ''HR-Attendance''
        ELSE ''UNK-Unclassified''
    END
ORDER BY ModuleCategory;
';

EXEC sp_executesql @SQL;


-- ============================================================================
-- SECTION 3: SUMMARY STATISTICS
-- ============================================================================
PRINT '';
PRINT '========================================';
PRINT 'SECTION 3: Summary Statistics';
PRINT '========================================';

SET @SQL = N'
SELECT 
    ''Total Tables'' AS Metric,
    CAST(COUNT(*) AS NVARCHAR(20)) AS Value
FROM ' + QUOTENAME(@SourceDB) + '.sys.tables t
WHERE t.is_ms_shipped = 0

UNION ALL

SELECT 
    ''Empty Tables'',
    CAST(COUNT(*) AS NVARCHAR(20))
FROM ' + QUOTENAME(@SourceDB) + '.sys.tables t
INNER JOIN ' + QUOTENAME(@SourceDB) + '.sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
WHERE t.is_ms_shipped = 0 AND p.rows = 0

UNION ALL

SELECT 
    ''Tables with Data'',
    CAST(COUNT(*) AS NVARCHAR(20))
FROM ' + QUOTENAME(@SourceDB) + '.sys.tables t
INNER JOIN ' + QUOTENAME(@SourceDB) + '.sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
WHERE t.is_ms_shipped = 0 AND p.rows > 0

UNION ALL

SELECT 
    ''Large Tables (>10K rows)'',
    CAST(COUNT(*) AS NVARCHAR(20))
FROM ' + QUOTENAME(@SourceDB) + '.sys.tables t
INNER JOIN ' + QUOTENAME(@SourceDB) + '.sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
WHERE t.is_ms_shipped = 0 AND p.rows > 10000

UNION ALL

SELECT 
    ''Total Rows (All Tables)'',
    FORMAT(SUM(p.rows), ''N0'')
FROM ' + QUOTENAME(@SourceDB) + '.sys.tables t
INNER JOIN ' + QUOTENAME(@SourceDB) + '.sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
WHERE t.is_ms_shipped = 0;
';

EXEC sp_executesql @SQL;


-- ============================================================================
-- SECTION 4: TOP 20 LARGEST TABLES
-- ============================================================================
PRINT '';
PRINT '========================================';
PRINT 'SECTION 4: Top 20 Largest Tables';
PRINT '========================================';

SET @SQL = N'
SELECT TOP 20
    t.name AS TableName,
    p.rows AS RowCount,
    (
        SELECT COUNT(*) 
        FROM ' + QUOTENAME(@SourceDB) + '.sys.columns c 
        WHERE c.object_id = t.object_id
    ) AS ColumnCount,
    CAST(
        (SUM(a.total_pages) * 8.0 / 1024) AS DECIMAL(18,2)
    ) AS SizeMB
FROM ' + QUOTENAME(@SourceDB) + '.sys.tables t
INNER JOIN ' + QUOTENAME(@SourceDB) + '.sys.indexes i ON t.object_id = i.object_id
INNER JOIN ' + QUOTENAME(@SourceDB) + '.sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN ' + QUOTENAME(@SourceDB) + '.sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0
GROUP BY t.name, t.object_id, p.rows
ORDER BY p.rows DESC;
';

EXEC sp_executesql @SQL;


-- ============================================================================
-- SECTION 5: VIEWS LIST
-- ============================================================================
PRINT '';
PRINT '========================================';
PRINT 'SECTION 5: Views in Database';
PRINT '========================================';

SET @SQL = N'
SELECT 
    s.name AS SchemaName,
    v.name AS ViewName,
    v.create_date AS CreatedDate
FROM ' + QUOTENAME(@SourceDB) + '.sys.views v
INNER JOIN ' + QUOTENAME(@SourceDB) + '.sys.schemas s ON v.schema_id = s.schema_id
WHERE v.is_ms_shipped = 0
ORDER BY v.name;
';

EXEC sp_executesql @SQL;


-- ============================================================================
-- SECTION 6: STORED PROCEDURES LIST
-- ============================================================================
PRINT '';
PRINT '========================================';
PRINT 'SECTION 6: Stored Procedures';
PRINT '========================================';

SET @SQL = N'
SELECT 
    s.name AS SchemaName,
    p.name AS ProcedureName,
    p.create_date AS CreatedDate
FROM ' + QUOTENAME(@SourceDB) + '.sys.procedures p
INNER JOIN ' + QUOTENAME(@SourceDB) + '.sys.schemas s ON p.schema_id = s.schema_id
WHERE p.is_ms_shipped = 0
ORDER BY p.name;
';

EXEC sp_executesql @SQL;


PRINT '';
PRINT '========================================';
PRINT 'Discovery Complete!';
PRINT '========================================';
PRINT 'Next Steps:';
PRINT '1. Review table classifications';
PRINT '2. Identify key tables for each module';
PRINT '3. Create TableMapping entries';
PRINT '4. Generate Synonyms';
GO
