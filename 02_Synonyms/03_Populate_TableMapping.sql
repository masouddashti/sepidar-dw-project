/*
===============================================================================
SEPIDAR Data Warehouse Project
Phase 2: Populate Table Mapping Metadata
===============================================================================
Script: 03_Populate_TableMapping.sql
Purpose: Register all source tables in metadata for ETL management
Author: BI Team
Version: 1.0
Date: January 2026
===============================================================================
*/

-- ============================================================================
-- Clear existing mappings
-- ============================================================================
TRUNCATE TABLE meta.TableMapping;

PRINT 'Populating TableMapping metadata...';
PRINT '';

-- ============================================================================
-- DIMENSION TABLES
-- ============================================================================

-- BAS - Base/Master Data
INSERT INTO meta.TableMapping (SourceTableName, TargetSchemaName, TargetTableName, ModuleCode, TableType, LoadPriority, IsActive, IncrementalColumn) VALUES
('FiscalYear', 'dim', 'FiscalYear', 'BAS', 'Dimension', 5, 1, NULL),
('Party', 'dim', 'Party', 'BAS', 'Dimension', 10, 1, 'LastModificationDate'),
('PartyAddress', 'dim', 'PartyAddress', 'BAS', 'Dimension', 11, 1, NULL),
('PartyPhone', 'dim', 'PartyPhone', 'BAS', 'Dimension', 12, 1, NULL),
('Currency', 'dim', 'Currency', 'BAS', 'Dimension', 15, 1, NULL),
('Branch', 'dim', 'Branch', 'BAS', 'Dimension', 17, 1, NULL),
('Location', 'dim', 'Location', 'BAS', 'Dimension', 19, 1, NULL),
('DeliveryLocation', 'dim', 'DeliveryLocation', 'BAS', 'Dimension', 20, 1, NULL);

-- FIN - Financial
INSERT INTO meta.TableMapping (SourceTableName, TargetSchemaName, TargetTableName, ModuleCode, TableType, LoadPriority, IsActive, IncrementalColumn) VALUES
('Account', 'dim', 'Account', 'FIN', 'Dimension', 1, 1, 'LastModificationDate'),
('AccountTopic', 'dim', 'AccountTopic', 'FIN', 'Dimension', 2, 1, NULL),
('AccountType', 'dim', 'AccountType', 'FIN', 'Dimension', 3, 1, NULL),
('DL', 'dim', 'DL', 'FIN', 'Dimension', 4, 1, 'LastModificationDate'),
('Topic', 'dim', 'Topic', 'FIN', 'Dimension', 6, 1, NULL),
('CostCenter', 'dim', 'CostCenter', 'FIN', 'Dimension', 7, 1, NULL);

-- INV - Inventory
INSERT INTO meta.TableMapping (SourceTableName, TargetSchemaName, TargetTableName, ModuleCode, TableType, LoadPriority, IsActive, IncrementalColumn) VALUES
('Item', 'dim', 'Item', 'INV', 'Dimension', 25, 1, 'LastModificationDate'),
('ItemCategory', 'dim', 'ItemCategory', 'INV', 'Dimension', 26, 1, NULL),
('Stock', 'dim', 'Stock', 'INV', 'Dimension', 29, 1, NULL),
('Unit', 'dim', 'Unit', 'INV', 'Dimension', 30, 1, NULL);

-- CSH - Cash & Treasury
INSERT INTO meta.TableMapping (SourceTableName, TargetSchemaName, TargetTableName, ModuleCode, TableType, LoadPriority, IsActive, IncrementalColumn) VALUES
('Bank', 'dim', 'Bank', 'CSH', 'Dimension', 35, 1, NULL),
('BankAccount', 'dim', 'BankAccount', 'CSH', 'Dimension', 36, 1, NULL),
('BankBranch', 'dim', 'BankBranch', 'CSH', 'Dimension', 37, 1, NULL),
('Cash', 'dim', 'Cash', 'CSH', 'Dimension', 38, 1, NULL),
('PettyCash', 'dim', 'PettyCash', 'CSH', 'Dimension', 39, 1, NULL);

-- HR - Human Resources
INSERT INTO meta.TableMapping (SourceTableName, TargetSchemaName, TargetTableName, ModuleCode, TableType, LoadPriority, IsActive, IncrementalColumn) VALUES
('Personnel', 'dim', 'Personnel', 'HR', 'Dimension', 45, 1, NULL),
('Job', 'dim', 'Job', 'HR', 'Dimension', 46, 1, NULL),
('Element', 'dim', 'Element', 'HR', 'Dimension', 47, 1, NULL);

-- SAL - Sales
INSERT INTO meta.TableMapping (SourceTableName, TargetSchemaName, TargetTableName, ModuleCode, TableType, LoadPriority, IsActive, IncrementalColumn) VALUES
('SaleType', 'dim', 'SaleType', 'SAL', 'Dimension', 55, 1, NULL),
('Commission', 'dim', 'Commission', 'SAL', 'Dimension', 56, 1, NULL),
('CommissionBroker', 'dim', 'CommissionBroker', 'SAL', 'Dimension', 57, 1, NULL);

-- TAX - Tax
INSERT INTO meta.TableMapping (SourceTableName, TargetSchemaName, TargetTableName, ModuleCode, TableType, LoadPriority, IsActive, IncrementalColumn) VALUES
('TaxGroup', 'dim', 'TaxGroup', 'TAX', 'Dimension', 60, 1, NULL),
('TaxTable', 'dim', 'TaxTable', 'TAX', 'Dimension', 61, 1, NULL);

-- AST - Assets
INSERT INTO meta.TableMapping (SourceTableName, TargetSchemaName, TargetTableName, ModuleCode, TableType, LoadPriority, IsActive, IncrementalColumn) VALUES
('AssetClass', 'dim', 'AssetClass', 'AST', 'Dimension', 65, 1, NULL),
('AssetGroup', 'dim', 'AssetGroup', 'AST', 'Dimension', 66, 1, NULL);

-- CNT - Contracts
INSERT INTO meta.TableMapping (SourceTableName, TargetSchemaName, TargetTableName, ModuleCode, TableType, LoadPriority, IsActive, IncrementalColumn) VALUES
('Contract', 'dim', 'Contract', 'CNT', 'Dimension', 70, 1, NULL);

PRINT 'Dimension tables registered: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ============================================================================
-- FACT TABLES
-- ============================================================================

-- FIN - Financial Facts
INSERT INTO meta.TableMapping (SourceTableName, TargetSchemaName, TargetTableName, ModuleCode, TableType, LoadPriority, IsActive, IncrementalColumn) VALUES
('Voucher', 'stg', 'Voucher', 'FIN', 'Fact', 100, 1, 'LastModificationDate'),
('VoucherItem', 'stg', 'VoucherItem', 'FIN', 'Fact', 101, 1, NULL),
('PartyAccountSettlement', 'stg', 'PartyAccountSettlement', 'FIN', 'Fact', 102, 1, NULL),
('PartyAccountSettlementItem', 'stg', 'PartyAccountSettlementItem', 'FIN', 'Fact', 103, 1, NULL),
('PartyOpeningBalance', 'stg', 'PartyOpeningBalance', 'FIN', 'Fact', 104, 1, NULL),
('DebitCreditNote', 'stg', 'DebitCreditNote', 'FIN', 'Fact', 105, 1, NULL),
('DebitCreditNoteItem', 'stg', 'DebitCreditNoteItem', 'FIN', 'Fact', 106, 1, NULL);

-- SAL - Sales Facts
INSERT INTO meta.TableMapping (SourceTableName, TargetSchemaName, TargetTableName, ModuleCode, TableType, LoadPriority, IsActive, IncrementalColumn) VALUES
('Invoice', 'stg', 'Invoice', 'SAL', 'Fact', 110, 1, 'LastModificationDate'),
('InvoiceItem', 'stg', 'InvoiceItem', 'SAL', 'Fact', 111, 1, NULL),
('InvoiceCommissionBroker', 'stg', 'InvoiceCommissionBroker', 'SAL', 'Fact', 112, 1, NULL),
('Quotation', 'stg', 'Quotation', 'SAL', 'Fact', 115, 1, NULL),
('QuotationItem', 'stg', 'QuotationItem', 'SAL', 'Fact', 116, 1, NULL),
('ReturnedInvoice', 'stg', 'ReturnedInvoice', 'SAL', 'Fact', 120, 1, NULL),
('ReturnedInvoiceItem', 'stg', 'ReturnedInvoiceItem', 'SAL', 'Fact', 121, 1, NULL),
('PricingItemPrice', 'stg', 'PricingItemPrice', 'SAL', 'Fact', 132, 1, NULL);

-- INV - Inventory Facts
INSERT INTO meta.TableMapping (SourceTableName, TargetSchemaName, TargetTableName, ModuleCode, TableType, LoadPriority, IsActive, IncrementalColumn) VALUES
('InventoryReceipt', 'stg', 'InventoryReceipt', 'INV', 'Fact', 140, 1, 'LastModificationDate'),
('InventoryReceiptItem', 'stg', 'InventoryReceiptItem', 'INV', 'Fact', 141, 1, NULL),
('InventoryDelivery', 'stg', 'InventoryDelivery', 'INV', 'Fact', 145, 1, 'LastModificationDate'),
('InventoryDeliveryItem', 'stg', 'InventoryDeliveryItem', 'INV', 'Fact', 146, 1, NULL),
('InventoryPricingVoucher', 'stg', 'InventoryPricingVoucher', 'INV', 'Fact', 151, 1, NULL);

-- PRC - Procurement Facts
INSERT INTO meta.TableMapping (SourceTableName, TargetSchemaName, TargetTableName, ModuleCode, TableType, LoadPriority, IsActive, IncrementalColumn) VALUES
('InventoryPurchaseInvoice', 'stg', 'InventoryPurchaseInvoice', 'PRC', 'Fact', 160, 1, NULL),
('InventoryPurchaseInvoiceItem', 'stg', 'InventoryPurchaseInvoiceItem', 'PRC', 'Fact', 161, 1, NULL);

-- CSH - Cash Facts
INSERT INTO meta.TableMapping (SourceTableName, TargetSchemaName, TargetTableName, ModuleCode, TableType, LoadPriority, IsActive, IncrementalColumn) VALUES
('PaymentHeader', 'stg', 'PaymentHeader', 'CSH', 'Fact', 170, 1, 'LastModificationDate'),
('PaymentDraft', 'stg', 'PaymentDraft', 'CSH', 'Fact', 171, 1, NULL),
('ReceiptHeader', 'stg', 'ReceiptHeader', 'CSH', 'Fact', 175, 1, 'LastModificationDate'),
('ReceiptDraft', 'stg', 'ReceiptDraft', 'CSH', 'Fact', 176, 1, NULL),
('ReceiptPettyCash', 'stg', 'ReceiptPettyCash', 'CSH', 'Fact', 177, 1, NULL),
('PettyCashBill', 'stg', 'PettyCashBill', 'CSH', 'Fact', 180, 1, NULL),
('PettyCashBillItem', 'stg', 'PettyCashBillItem', 'CSH', 'Fact', 181, 1, NULL);

-- CHQ - Cheque Facts
INSERT INTO meta.TableMapping (SourceTableName, TargetSchemaName, TargetTableName, ModuleCode, TableType, LoadPriority, IsActive, IncrementalColumn) VALUES
('PaymentCheque', 'stg', 'PaymentCheque', 'CHQ', 'Fact', 190, 1, NULL),
('PaymentChequeBanking', 'stg', 'PaymentChequeBanking', 'CHQ', 'Fact', 191, 1, NULL),
('PaymentChequeHistory', 'stg', 'PaymentChequeHistory', 'CHQ', 'Fact', 193, 1, NULL),
('ReceiptCheque', 'stg', 'ReceiptCheque', 'CHQ', 'Fact', 195, 1, NULL),
('ReceiptChequeBanking', 'stg', 'ReceiptChequeBanking', 'CHQ', 'Fact', 196, 1, NULL),
('ReceiptChequeHistory', 'stg', 'ReceiptChequeHistory', 'CHQ', 'Fact', 198, 1, NULL),
('RefundCheque', 'stg', 'RefundCheque', 'CHQ', 'Fact', 199, 1, NULL),
('RefundChequeItem', 'stg', 'RefundChequeItem', 'CHQ', 'Fact', 200, 1, NULL);

-- HR - Payroll Facts
INSERT INTO meta.TableMapping (SourceTableName, TargetSchemaName, TargetTableName, ModuleCode, TableType, LoadPriority, IsActive, IncrementalColumn) VALUES
('Calculation', 'stg', 'Calculation', 'HR', 'Fact', 210, 1, NULL),
('MonthlyDataPersonnel', 'stg', 'MonthlyDataPersonnel', 'HR', 'Fact', 212, 1, NULL),
('MonthlyDataPersonnelElement', 'stg', 'MonthlyDataPersonnelElement', 'HR', 'Fact', 213, 1, NULL);

-- TAX - Tax Facts
INSERT INTO meta.TableMapping (SourceTableName, TargetSchemaName, TargetTableName, ModuleCode, TableType, LoadPriority, IsActive, IncrementalColumn) VALUES
('TaxPayerBill', 'stg', 'TaxPayerBill', 'TAX', 'Fact', 220, 1, NULL),
('TaxPayerBillItem', 'stg', 'TaxPayerBillItem', 'TAX', 'Fact', 221, 1, NULL);

PRINT 'Fact tables registered.';
PRINT '';

-- ============================================================================
-- SUMMARY
-- ============================================================================
PRINT '===============================================================================';
PRINT 'TABLE MAPPING SUMMARY';
PRINT '===============================================================================';

SELECT 
    ModuleCode,
    TableType,
    COUNT(*) AS TableCount
FROM meta.TableMapping
GROUP BY ModuleCode, TableType
ORDER BY TableType, ModuleCode;

SELECT 
    'Total Tables' AS Metric,
    COUNT(*) AS Value
FROM meta.TableMapping
UNION ALL
SELECT 'Dimension Tables', COUNT(*) FROM meta.TableMapping WHERE TableType = 'Dimension'
UNION ALL
SELECT 'Fact Tables', COUNT(*) FROM meta.TableMapping WHERE TableType = 'Fact'
UNION ALL
SELECT 'Active Tables', COUNT(*) FROM meta.TableMapping WHERE IsActive = 1;

PRINT '';
PRINT 'TableMapping population complete.';
GO
