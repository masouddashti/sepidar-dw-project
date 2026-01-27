/*
===============================================================================
SEPIDAR Data Warehouse Project
Phase 2: Synonym Creation
===============================================================================
Script: 01_Create_Synonyms_All.sql
Purpose: Create synonyms for all Dimension and Fact source tables
Author: BI Team
Version: 1.0
Date: January 2026

Prerequisites:
  1. Run 00_Setup scripts first (Database, Schemas, Metadata tables)
  2. Update @SourceDB variable with actual SEPIDAR database name
  
Usage:
  1. Update configuration section
  2. Execute entire script
  3. Verify with: SELECT * FROM meta.SynonymRegistry
===============================================================================
*/

-- ============================================================================
-- CONFIGURATION - UPDATE THESE!
-- ============================================================================
DECLARE @SourceDB NVARCHAR(128) = 'SepidarDB';      -- << نام دیتابیس سپیدار
DECLARE @SourceServer NVARCHAR(128) = NULL;          -- NULL = همین سرور
DECLARE @TargetDB NVARCHAR(128) = 'DW_DB';           -- نام دیتابیس DW

-- ============================================================================
-- VARIABLES
-- ============================================================================
DECLARE @SQL NVARCHAR(MAX);
DECLARE @FullSourcePath NVARCHAR(500);
DECLARE @SynonymName NVARCHAR(256);
DECLARE @SourceTable NVARCHAR(256);
DECLARE @ErrorMessage NVARCHAR(4000);
DECLARE @RowCount INT = 0;
DECLARE @SuccessCount INT = 0;
DECLARE @ErrorCount INT = 0;

-- Build source path
IF @SourceServer IS NULL
    SET @FullSourcePath = QUOTENAME(@SourceDB) + '.dbo.';
ELSE
    SET @FullSourcePath = QUOTENAME(@SourceServer) + '.' + QUOTENAME(@SourceDB) + '.dbo.';

PRINT '===============================================================================';
PRINT 'SEPIDAR Data Warehouse - Synonym Creation';
PRINT '===============================================================================';
PRINT 'Source Database: ' + @SourceDB;
PRINT 'Target Database: ' + @TargetDB;
PRINT 'Source Path: ' + @FullSourcePath;
PRINT 'Started at: ' + CONVERT(VARCHAR(30), GETDATE(), 121);
PRINT '===============================================================================';
PRINT '';

-- ============================================================================
-- STEP 1: Create table with all synonyms to create
-- ============================================================================
IF OBJECT_ID('tempdb..#SynonymsToCreate') IS NOT NULL
    DROP TABLE #SynonymsToCreate;

CREATE TABLE #SynonymsToCreate (
    ID INT IDENTITY(1,1),
    ModuleCode VARCHAR(10),
    TableType VARCHAR(20),      -- 'Dimension' or 'Fact'
    SourceTable NVARCHAR(256),
    SynonymName NVARCHAR(256),
    Priority INT,               -- Lower = Higher priority
    IsProcessed BIT DEFAULT 0,
    ErrorMessage NVARCHAR(4000) NULL
);

-- ============================================================================
-- STEP 2: Insert Dimension Tables
-- ============================================================================
PRINT 'Loading Dimension tables...';

-- BAS - Base/Master Data
INSERT INTO #SynonymsToCreate (ModuleCode, TableType, SourceTable, SynonymName, Priority) VALUES
('BAS', 'Dimension', 'Party', 'src.Party', 10),
('BAS', 'Dimension', 'PartyAddress', 'src.PartyAddress', 11),
('BAS', 'Dimension', 'PartyPhone', 'src.PartyPhone', 12),
('BAS', 'Dimension', 'PartyRelated', 'src.PartyRelated', 13),
('BAS', 'Dimension', 'Currency', 'src.Currency', 15),
('BAS', 'Dimension', 'CurrencyExchangeRate', 'src.CurrencyExchangeRate', 16),
('BAS', 'Dimension', 'Branch', 'src.Branch', 17),
('BAS', 'Dimension', 'Emplacement', 'src.Emplacement', 18),
('BAS', 'Dimension', 'Location', 'src.Location', 19),
('BAS', 'Dimension', 'DeliveryLocation', 'src.DeliveryLocation', 20),
('BAS', 'Dimension', 'Coefficient', 'src.Coefficient', 21),
('BAS', 'Dimension', 'FiscalYear', 'src.FiscalYear', 5);

-- FIN - Financial
INSERT INTO #SynonymsToCreate (ModuleCode, TableType, SourceTable, SynonymName, Priority) VALUES
('FIN', 'Dimension', 'Account', 'src.Account', 1),
('FIN', 'Dimension', 'AccountTopic', 'src.AccountTopic', 2),
('FIN', 'Dimension', 'AccountType', 'src.AccountType', 3),
('FIN', 'Dimension', 'DL', 'src.DL', 4),
('FIN', 'Dimension', 'Topic', 'src.Topic', 6),
('FIN', 'Dimension', 'CostCenter', 'src.CostCenter', 7);

-- INV - Inventory
INSERT INTO #SynonymsToCreate (ModuleCode, TableType, SourceTable, SynonymName, Priority) VALUES
('INV', 'Dimension', 'Item', 'src.Item', 25),
('INV', 'Dimension', 'ItemCategory', 'src.ItemCategory', 26),
('INV', 'Dimension', 'ItemStock', 'src.ItemStock', 27),
('INV', 'Dimension', 'ItemStockSummary', 'src.ItemStockSummary', 28),
('INV', 'Dimension', 'Stock', 'src.Stock', 29),
('INV', 'Dimension', 'Unit', 'src.Unit', 30);

-- CSH - Cash & Treasury
INSERT INTO #SynonymsToCreate (ModuleCode, TableType, SourceTable, SynonymName, Priority) VALUES
('CSH', 'Dimension', 'Bank', 'src.Bank', 35),
('CSH', 'Dimension', 'BankAccount', 'src.BankAccount', 36),
('CSH', 'Dimension', 'BankBranch', 'src.BankBranch', 37),
('CSH', 'Dimension', 'Cash', 'src.Cash', 38),
('CSH', 'Dimension', 'PettyCash', 'src.PettyCash', 39);

-- CHQ - Cheque
INSERT INTO #SynonymsToCreate (ModuleCode, TableType, SourceTable, SynonymName, Priority) VALUES
('CHQ', 'Dimension', 'ChequeBook', 'src.ChequeBook', 40);

-- HR - Human Resources
INSERT INTO #SynonymsToCreate (ModuleCode, TableType, SourceTable, SynonymName, Priority) VALUES
('HR', 'Dimension', 'Personnel', 'src.Personnel', 45),
('HR', 'Dimension', 'Job', 'src.Job', 46),
('HR', 'Dimension', 'Element', 'src.Element', 47),
('HR', 'Dimension', 'ElementItem', 'src.ElementItem', 48),
('HR', 'Dimension', 'PayrollCalendar', 'src.PayrollCalendar', 49),
('HR', 'Dimension', 'PayrollConfiguration', 'src.PayrollConfiguration', 50),
('HR', 'Dimension', 'PayrollConfigurationElement', 'src.PayrollConfigurationElement', 51);

-- SAL - Sales
INSERT INTO #SynonymsToCreate (ModuleCode, TableType, SourceTable, SynonymName, Priority) VALUES
('SAL', 'Dimension', 'SaleType', 'src.SaleType', 55),
('SAL', 'Dimension', 'Commission', 'src.Commission', 56),
('SAL', 'Dimension', 'CommissionBroker', 'src.CommissionBroker', 57),
('SAL', 'Dimension', 'CommissionItem', 'src.CommissionItem', 58),
('SAL', 'Dimension', 'CommissionStep', 'src.CommissionStep', 59);

-- TAX - Tax
INSERT INTO #SynonymsToCreate (ModuleCode, TableType, SourceTable, SynonymName, Priority) VALUES
('TAX', 'Dimension', 'TaxGroup', 'src.TaxGroup', 60),
('TAX', 'Dimension', 'TaxTable', 'src.TaxTable', 61),
('TAX', 'Dimension', 'TaxTableItem', 'src.TaxTableItem', 62);

-- AST - Assets
INSERT INTO #SynonymsToCreate (ModuleCode, TableType, SourceTable, SynonymName, Priority) VALUES
('AST', 'Dimension', 'AssetClass', 'src.AssetClass', 65),
('AST', 'Dimension', 'AssetGroup', 'src.AssetGroup', 66),
('AST', 'Dimension', 'DepreciationRule', 'src.DepreciationRule', 67);

-- CNT - Contracts
INSERT INTO #SynonymsToCreate (ModuleCode, TableType, SourceTable, SynonymName, Priority) VALUES
('CNT', 'Dimension', 'Contract', 'src.Contract', 70),
('CNT', 'Dimension', 'ContractElement', 'src.ContractElement', 71);

-- SYS - System
INSERT INTO #SynonymsToCreate (ModuleCode, TableType, SourceTable, SynonymName, Priority) VALUES
('SYS', 'Dimension', 'Lookup', 'src.Lookup', 80),
('SYS', 'Dimension', 'LookupLocale', 'src.LookupLocale', 81);

PRINT '  Dimension tables loaded: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ============================================================================
-- STEP 3: Insert Fact Tables
-- ============================================================================
PRINT 'Loading Fact tables...';

-- FIN - Financial Facts
INSERT INTO #SynonymsToCreate (ModuleCode, TableType, SourceTable, SynonymName, Priority) VALUES
('FIN', 'Fact', 'Voucher', 'src.Voucher', 100),
('FIN', 'Fact', 'VoucherItem', 'src.VoucherItem', 101),
('FIN', 'Fact', 'PartyAccountSettlement', 'src.PartyAccountSettlement', 102),
('FIN', 'Fact', 'PartyAccountSettlementItem', 'src.PartyAccountSettlementItem', 103),
('FIN', 'Fact', 'PartyOpeningBalance', 'src.PartyOpeningBalance', 104),
('FIN', 'Fact', 'DebitCreditNote', 'src.DebitCreditNote', 105),
('FIN', 'Fact', 'DebitCreditNoteItem', 'src.DebitCreditNoteItem', 106),
('FIN', 'Fact', 'OpeningOperation', 'src.OpeningOperation', 107),
('FIN', 'Fact', 'ClosingOperation', 'src.ClosingOperation', 108);

-- SAL - Sales Facts
INSERT INTO #SynonymsToCreate (ModuleCode, TableType, SourceTable, SynonymName, Priority) VALUES
('SAL', 'Fact', 'Invoice', 'src.Invoice', 110),
('SAL', 'Fact', 'InvoiceItem', 'src.InvoiceItem', 111),
('SAL', 'Fact', 'InvoiceCommissionBroker', 'src.InvoiceCommissionBroker', 112),
('SAL', 'Fact', 'Quotation', 'src.Quotation', 115),
('SAL', 'Fact', 'QuotationItem', 'src.QuotationItem', 116),
('SAL', 'Fact', 'QuotationCommissionBroker', 'src.QuotationCommissionBroker', 117),
('SAL', 'Fact', 'ReturnedInvoice', 'src.ReturnedInvoice', 120),
('SAL', 'Fact', 'ReturnedInvoiceItem', 'src.ReturnedInvoiceItem', 121),
('SAL', 'Fact', 'CommissionCalculation', 'src.CommissionCalculation', 125),
('SAL', 'Fact', 'CommissionCalculationInvoice', 'src.CommissionCalculationInvoice', 126),
('SAL', 'Fact', 'CommissionCalculationItem', 'src.CommissionCalculationItem', 127),
('SAL', 'Fact', 'PriceNote', 'src.PriceNote', 130),
('SAL', 'Fact', 'PriceNoteItem', 'src.PriceNoteItem', 131),
('SAL', 'Fact', 'PricingItemPrice', 'src.PricingItemPrice', 132);

-- INV - Inventory Facts
INSERT INTO #SynonymsToCreate (ModuleCode, TableType, SourceTable, SynonymName, Priority) VALUES
('INV', 'Fact', 'InventoryReceipt', 'src.InventoryReceipt', 140),
('INV', 'Fact', 'InventoryReceiptItem', 'src.InventoryReceiptItem', 141),
('INV', 'Fact', 'InventoryDelivery', 'src.InventoryDelivery', 145),
('INV', 'Fact', 'InventoryDeliveryItem', 'src.InventoryDeliveryItem', 146),
('INV', 'Fact', 'InventoryPricing', 'src.InventoryPricing', 150),
('INV', 'Fact', 'InventoryPricingVoucher', 'src.InventoryPricingVoucher', 151),
('INV', 'Fact', 'InventoryPricingVoucherItem', 'src.InventoryPricingVoucherItem', 152);

-- PRC - Procurement Facts
INSERT INTO #SynonymsToCreate (ModuleCode, TableType, SourceTable, SynonymName, Priority) VALUES
('PRC', 'Fact', 'InventoryPurchaseInvoice', 'src.InventoryPurchaseInvoice', 160),
('PRC', 'Fact', 'InventoryPurchaseInvoiceItem', 'src.InventoryPurchaseInvoiceItem', 161);

-- CSH - Cash Facts
INSERT INTO #SynonymsToCreate (ModuleCode, TableType, SourceTable, SynonymName, Priority) VALUES
('CSH', 'Fact', 'PaymentHeader', 'src.PaymentHeader', 170),
('CSH', 'Fact', 'PaymentDraft', 'src.PaymentDraft', 171),
('CSH', 'Fact', 'ReceiptHeader', 'src.ReceiptHeader', 175),
('CSH', 'Fact', 'ReceiptDraft', 'src.ReceiptDraft', 176),
('CSH', 'Fact', 'ReceiptPettyCash', 'src.ReceiptPettyCash', 177),
('CSH', 'Fact', 'PettyCashBill', 'src.PettyCashBill', 180),
('CSH', 'Fact', 'PettyCashBillItem', 'src.PettyCashBillItem', 181),
('CSH', 'Fact', 'CashBalance', 'src.CashBalance', 182),
('CSH', 'Fact', 'BankAccountBalance', 'src.BankAccountBalance', 183);

-- CHQ - Cheque Facts
INSERT INTO #SynonymsToCreate (ModuleCode, TableType, SourceTable, SynonymName, Priority) VALUES
('CHQ', 'Fact', 'PaymentCheque', 'src.PaymentCheque', 190),
('CHQ', 'Fact', 'PaymentChequeBanking', 'src.PaymentChequeBanking', 191),
('CHQ', 'Fact', 'PaymentChequeBankingItem', 'src.PaymentChequeBankingItem', 192),
('CHQ', 'Fact', 'PaymentChequeHistory', 'src.PaymentChequeHistory', 193),
('CHQ', 'Fact', 'PaymentChequeOther', 'src.PaymentChequeOther', 194),
('CHQ', 'Fact', 'ReceiptCheque', 'src.ReceiptCheque', 195),
('CHQ', 'Fact', 'ReceiptChequeBanking', 'src.ReceiptChequeBanking', 196),
('CHQ', 'Fact', 'ReceiptChequeBankingItem', 'src.ReceiptChequeBankingItem', 197),
('CHQ', 'Fact', 'ReceiptChequeHistory', 'src.ReceiptChequeHistory', 198),
('CHQ', 'Fact', 'RefundCheque', 'src.RefundCheque', 199),
('CHQ', 'Fact', 'RefundChequeItem', 'src.RefundChequeItem', 200);

-- HR - Payroll Facts
INSERT INTO #SynonymsToCreate (ModuleCode, TableType, SourceTable, SynonymName, Priority) VALUES
('HR', 'Fact', 'Calculation', 'src.Calculation', 210),
('HR', 'Fact', 'MonthlyData', 'src.MonthlyData', 211),
('HR', 'Fact', 'MonthlyDataPersonnel', 'src.MonthlyDataPersonnel', 212),
('HR', 'Fact', 'MonthlyDataPersonnelElement', 'src.MonthlyDataPersonnelElement', 213);

-- TAX - Tax Facts
INSERT INTO #SynonymsToCreate (ModuleCode, TableType, SourceTable, SynonymName, Priority) VALUES
('TAX', 'Fact', 'TaxPayerBill', 'src.TaxPayerBill', 220),
('TAX', 'Fact', 'TaxPayerBillItem', 'src.TaxPayerBillItem', 221),
('TAX', 'Fact', 'TaxPayerBillSubmitLog', 'src.TaxPayerBillSubmitLog', 222);

PRINT '  Fact tables loaded: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ============================================================================
-- STEP 4: Show Summary Before Creation
-- ============================================================================
PRINT '';
PRINT '-------------------------------------------------------------------------------';
PRINT 'SUMMARY - Tables to Process:';
PRINT '-------------------------------------------------------------------------------';

SELECT 
    ModuleCode,
    TableType,
    COUNT(*) AS TableCount
FROM #SynonymsToCreate
GROUP BY ModuleCode, TableType
ORDER BY TableType, ModuleCode;

SELECT 
    @RowCount = COUNT(*) 
FROM #SynonymsToCreate;

PRINT '';
PRINT 'Total synonyms to create: ' + CAST(@RowCount AS VARCHAR(10));
PRINT '-------------------------------------------------------------------------------';
PRINT '';

-- ============================================================================
-- STEP 5: Create Synonyms
-- ============================================================================
PRINT 'Creating synonyms...';
PRINT '';

DECLARE @ID INT, @ModuleCode VARCHAR(10), @TableType VARCHAR(20);

DECLARE synonym_cursor CURSOR FOR
    SELECT ID, ModuleCode, TableType, SourceTable, SynonymName
    FROM #SynonymsToCreate
    ORDER BY Priority;

OPEN synonym_cursor;
FETCH NEXT FROM synonym_cursor INTO @ID, @ModuleCode, @TableType, @SourceTable, @SynonymName;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        -- Drop existing synonym if exists
        SET @SQL = 'IF EXISTS (SELECT 1 FROM sys.synonyms WHERE name = ''' + 
                   REPLACE(@SynonymName, 'src.', '') + ''' AND schema_id = SCHEMA_ID(''src''))
                    DROP SYNONYM ' + @SynonymName + ';';
        EXEC sp_executesql @SQL;
        
        -- Create new synonym
        SET @SQL = 'CREATE SYNONYM ' + @SynonymName + ' FOR ' + @FullSourcePath + @SourceTable + ';';
        EXEC sp_executesql @SQL;
        
        -- Update as processed
        UPDATE #SynonymsToCreate SET IsProcessed = 1 WHERE ID = @ID;
        SET @SuccessCount = @SuccessCount + 1;
        
        PRINT '  ✓ ' + @SynonymName + ' → ' + @SourceTable;
        
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        UPDATE #SynonymsToCreate 
        SET IsProcessed = 0, ErrorMessage = @ErrorMessage 
        WHERE ID = @ID;
        SET @ErrorCount = @ErrorCount + 1;
        
        PRINT '  ✗ ' + @SynonymName + ' → ERROR: ' + @ErrorMessage;
    END CATCH
    
    FETCH NEXT FROM synonym_cursor INTO @ID, @ModuleCode, @TableType, @SourceTable, @SynonymName;
END

CLOSE synonym_cursor;
DEALLOCATE synonym_cursor;

-- ============================================================================
-- STEP 6: Register in Metadata
-- ============================================================================
PRINT '';
PRINT 'Registering synonyms in metadata...';

-- Clear existing entries for src schema
DELETE FROM meta.SynonymRegistry WHERE SchemaName = 'src';

-- Insert new entries
INSERT INTO meta.SynonymRegistry (
    SynonymName,
    SchemaName,
    TargetServer,
    TargetDatabase,
    TargetSchema,
    TargetTable,
    IsActive,
    CreatedDate,
    LastVerifiedDate
)
SELECT 
    REPLACE(SynonymName, 'src.', ''),
    'src',
    @SourceServer,
    @SourceDB,
    'dbo',
    SourceTable,
    CASE WHEN IsProcessed = 1 THEN 1 ELSE 0 END,
    GETDATE(),
    CASE WHEN IsProcessed = 1 THEN GETDATE() ELSE NULL END
FROM #SynonymsToCreate;

PRINT '  Metadata registration complete.';

-- ============================================================================
-- STEP 7: Final Summary
-- ============================================================================
PRINT '';
PRINT '===============================================================================';
PRINT 'SYNONYM CREATION COMPLETE';
PRINT '===============================================================================';
PRINT 'Total Processed:  ' + CAST(@RowCount AS VARCHAR(10));
PRINT 'Successful:       ' + CAST(@SuccessCount AS VARCHAR(10));
PRINT 'Failed:           ' + CAST(@ErrorCount AS VARCHAR(10));
PRINT 'Completed at:     ' + CONVERT(VARCHAR(30), GETDATE(), 121);
PRINT '===============================================================================';

-- Show errors if any
IF @ErrorCount > 0
BEGIN
    PRINT '';
    PRINT 'ERRORS:';
    PRINT '-------';
    SELECT SourceTable, SynonymName, ErrorMessage
    FROM #SynonymsToCreate
    WHERE IsProcessed = 0 AND ErrorMessage IS NOT NULL;
END

-- ============================================================================
-- STEP 8: Verification Query
-- ============================================================================
PRINT '';
PRINT 'Verification - Created Synonyms:';
PRINT '---------------------------------';

SELECT 
    s.name AS SynonymName,
    'src' AS SchemaName,
    s.base_object_name AS TargetObject
FROM sys.synonyms s
INNER JOIN sys.schemas sc ON s.schema_id = sc.schema_id
WHERE sc.name = 'src'
ORDER BY s.name;

-- Cleanup
DROP TABLE #SynonymsToCreate;

PRINT '';
PRINT 'Script execution complete.';
GO
