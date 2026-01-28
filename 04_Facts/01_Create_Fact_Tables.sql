/*
===============================================================================
SEPIDAR Data Warehouse Project
Phase 4: Fact Tables
===============================================================================
Script: 01_Create_Fact_Tables.sql
Purpose: Create all fact tables in DW
Author: BI Team
Version: 1.0
Date: January 2026
===============================================================================
*/

USE DW_DB;
GO

-- ============================================================================
-- fact.GLTransaction (تراکنش‌های دفتر کل)
-- ============================================================================
-- Source: Voucher + VoucherItem
-- Grain: One row per voucher line item
-- ============================================================================
IF OBJECT_ID('fact.GLTransaction', 'U') IS NOT NULL DROP TABLE fact.GLTransaction;

CREATE TABLE fact.GLTransaction (
    -- Surrogate Key
    GLTransactionKey    BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    
    -- Dimension Keys
    DateKey             INT NOT NULL,                       -- FK → dim.Date
    AccountKey          INT NOT NULL,                       -- FK → dim.Account
    DLKey               INT NULL,                           -- FK → dim.DL
    CurrencyKey         INT NULL,                           -- FK → dim.Currency
    FiscalYearKey       INT NOT NULL,                       -- FK → dim.FiscalYear
    
    -- Degenerate Dimensions (Voucher Header)
    VoucherId           INT NOT NULL,
    VoucherNumber       INT NOT NULL,
    VoucherDate         DATE NOT NULL,
    VoucherType         TINYINT NOT NULL,                   -- 0=عادی, 1=افتتاحیه, 2=اختتامیه, ...
    VoucherTypeName     NVARCHAR(50) NULL,
    VoucherState        TINYINT NOT NULL,                   -- 0=موقت, 1=دائم, 2=قطعی
    VoucherStateName    NVARCHAR(50) NULL,
    DailyNumber         INT NULL,
    
    -- Degenerate Dimensions (Voucher Item)
    VoucherItemId       INT NOT NULL,
    RowNumber           INT NOT NULL,
    
    -- Measures
    Debit               DECIMAL(18,4) NULL,                 -- بدهکار
    Credit              DECIMAL(18,4) NULL,                 -- بستانکار
    Amount              AS (ISNULL(Debit,0) - ISNULL(Credit,0)),  -- مانده (محاسباتی)
    
    -- Currency Measures
    CurrencyRate        DECIMAL(18,6) NULL,
    CurrencyDebit       DECIMAL(18,4) NULL,
    CurrencyCredit      DECIMAL(18,4) NULL,
    
    -- Tracking
    TrackingNumber      NVARCHAR(80) NULL,
    TrackingDate        DATE NULL,
    
    -- Source Reference
    IssuerEntityName    VARCHAR(100) NULL,                  -- نام سند مبدا (Invoice, Receipt, ...)
    IssuerEntityId      INT NULL,                           -- شناسه سند مبدا
    
    -- Description
    Description         NVARCHAR(500) NULL,
    
    -- Audit
    DW_LoadDate         DATETIME NOT NULL DEFAULT GETDATE()
);

-- Indexes
CREATE NONCLUSTERED INDEX IX_GLTransaction_DateKey ON fact.GLTransaction(DateKey);
CREATE NONCLUSTERED INDEX IX_GLTransaction_AccountKey ON fact.GLTransaction(AccountKey);
CREATE NONCLUSTERED INDEX IX_GLTransaction_VoucherId ON fact.GLTransaction(VoucherId);
CREATE NONCLUSTERED INDEX IX_GLTransaction_FiscalYearKey ON fact.GLTransaction(FiscalYearKey);

PRINT 'fact.GLTransaction created.';
GO


-- ============================================================================
-- fact.Sales (فروش)
-- ============================================================================
-- Source: Invoice + InvoiceItem
-- Grain: One row per invoice line item
-- ============================================================================
IF OBJECT_ID('fact.Sales', 'U') IS NOT NULL DROP TABLE fact.Sales;

CREATE TABLE fact.Sales (
    -- Surrogate Key
    SalesKey            BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    
    -- Dimension Keys
    DateKey             INT NOT NULL,                       -- FK → dim.Date
    CustomerKey         INT NOT NULL,                       -- FK → dim.Party (Customer)
    ItemKey             INT NOT NULL,                       -- FK → dim.Item
    StockKey            INT NULL,                           -- FK → dim.Stock
    CurrencyKey         INT NOT NULL,                       -- FK → dim.Currency
    FiscalYearKey       INT NOT NULL,                       -- FK → dim.FiscalYear
    SalespersonKey      INT NULL,                           -- FK → dim.Party (Salesperson)
    
    -- Degenerate Dimensions (Invoice Header)
    InvoiceId           INT NOT NULL,
    InvoiceNumber       INT NOT NULL,
    InvoiceDate         DATE NOT NULL,
    InvoiceState        TINYINT NOT NULL,
    InvoiceStateName    NVARCHAR(50) NULL,
    SaleType            INT NULL,
    
    -- Degenerate Dimensions (Invoice Item)
    InvoiceItemId       INT NOT NULL,
    RowNumber           INT NOT NULL,
    
    -- Quantity Measures
    Quantity            DECIMAL(18,4) NOT NULL,
    SecondaryQuantity   DECIMAL(18,4) NULL,
    
    -- Price Measures
    UnitPrice           DECIMAL(18,4) NOT NULL,             -- فی (Fee)
    GrossAmount         DECIMAL(18,4) NOT NULL,             -- مبلغ کل (Price)
    DiscountAmount      DECIMAL(18,4) NULL,                 -- تخفیف
    AdditionAmount      DECIMAL(18,4) NULL,                 -- اضافات
    TaxAmount           DECIMAL(18,4) NULL,                 -- مالیات
    DutyAmount          DECIMAL(18,4) NULL,                 -- عوارض
    NetAmount           DECIMAL(18,4) NULL,                 -- مبلغ خالص
    
    -- Base Currency Measures
    GrossAmountBase     DECIMAL(18,4) NULL,
    DiscountAmountBase  DECIMAL(18,4) NULL,
    NetAmountBase       DECIMAL(18,4) NULL,
    
    -- Currency
    CurrencyRate        DECIMAL(18,6) NULL,
    
    -- Description
    Description         NVARCHAR(500) NULL,
    
    -- Audit
    DW_LoadDate         DATETIME NOT NULL DEFAULT GETDATE()
);

-- Indexes
CREATE NONCLUSTERED INDEX IX_Sales_DateKey ON fact.Sales(DateKey);
CREATE NONCLUSTERED INDEX IX_Sales_CustomerKey ON fact.Sales(CustomerKey);
CREATE NONCLUSTERED INDEX IX_Sales_ItemKey ON fact.Sales(ItemKey);
CREATE NONCLUSTERED INDEX IX_Sales_InvoiceId ON fact.Sales(InvoiceId);

PRINT 'fact.Sales created.';
GO


-- ============================================================================
-- fact.Inventory (موجودی انبار)
-- ============================================================================
-- Source: InventoryReceipt + InventoryDelivery (combined)
-- Grain: One row per receipt/delivery line item
-- Note: Quantity positive = Receipt, negative = Delivery
-- ============================================================================
IF OBJECT_ID('fact.Inventory', 'U') IS NOT NULL DROP TABLE fact.Inventory;

CREATE TABLE fact.Inventory (
    -- Surrogate Key
    InventoryKey        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    
    -- Dimension Keys
    DateKey             INT NOT NULL,                       -- FK → dim.Date
    ItemKey             INT NOT NULL,                       -- FK → dim.Item
    StockKey            INT NOT NULL,                       -- FK → dim.Stock (Source)
    DestStockKey        INT NULL,                           -- FK → dim.Stock (Destination - for transfers)
    PartyKey            INT NULL,                           -- FK → dim.Party (Deliverer/Receiver)
    CurrencyKey         INT NULL,                           -- FK → dim.Currency
    FiscalYearKey       INT NOT NULL,                       -- FK → dim.FiscalYear
    
    -- Movement Type
    MovementType        VARCHAR(20) NOT NULL,               -- 'Receipt' / 'Delivery'
    MovementSign        SMALLINT NOT NULL,                  -- +1 = Receipt, -1 = Delivery
    
    -- Degenerate Dimensions (Header)
    DocumentId          INT NOT NULL,                       -- InventoryReceiptID or InventoryDeliveryID
    DocumentNumber      INT NOT NULL,
    DocumentDate        DATE NOT NULL,
    DocumentType        INT NOT NULL,                       -- نوع سند
    IsReturn            BIT NOT NULL,                       -- برگشتی
    IsTransfer          BIT NOT NULL DEFAULT 0,             -- انتقالی بین انبار
    
    -- Degenerate Dimensions (Item)
    DocumentItemId      INT NOT NULL,
    RowNumber           INT NOT NULL,
    
    -- Quantity Measures (با علامت)
    Quantity            DECIMAL(18,4) NOT NULL,             -- + رسید / - حواله
    SecondaryQuantity   DECIMAL(18,4) NULL,
    AbsQuantity         AS ABS(Quantity),                   -- مقدار مطلق
    
    -- Price Measures
    UnitPrice           DECIMAL(18,4) NULL,                 -- فی
    Amount              DECIMAL(18,4) NULL,                 -- مبلغ (با علامت)
    TaxAmount           DECIMAL(18,4) NULL,
    DutyAmount          DECIMAL(18,4) NULL,
    TransportAmount     DECIMAL(18,4) NULL,
    NetAmount           DECIMAL(18,4) NULL,
    
    -- Currency
    CurrencyRate        DECIMAL(18,6) NULL,
    
    -- Description
    Description         NVARCHAR(500) NULL,
    
    -- Audit
    DW_LoadDate         DATETIME NOT NULL DEFAULT GETDATE()
);

-- Indexes
CREATE NONCLUSTERED INDEX IX_Inventory_DateKey ON fact.Inventory(DateKey);
CREATE NONCLUSTERED INDEX IX_Inventory_ItemKey ON fact.Inventory(ItemKey);
CREATE NONCLUSTERED INDEX IX_Inventory_StockKey ON fact.Inventory(StockKey);
CREATE NONCLUSTERED INDEX IX_Inventory_MovementType ON fact.Inventory(MovementType);
CREATE NONCLUSTERED INDEX IX_Inventory_DocumentId ON fact.Inventory(DocumentId, MovementType);

PRINT 'fact.Inventory created.';
GO


-- ============================================================================
-- fact.CashFlow (جریان نقدی)
-- ============================================================================
-- Source: PaymentHeader + ReceiptHeader (combined)
-- Grain: One row per payment/receipt header
-- Note: Amount positive = Receipt, negative = Payment
-- ============================================================================
IF OBJECT_ID('fact.CashFlow', 'U') IS NOT NULL DROP TABLE fact.CashFlow;

CREATE TABLE fact.CashFlow (
    -- Surrogate Key
    CashFlowKey         BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    
    -- Dimension Keys
    DateKey             INT NOT NULL,                       -- FK → dim.Date
    PartyKey            INT NOT NULL,                       -- FK → dim.Party
    AccountKey          INT NULL,                           -- FK → dim.Account
    DLKey               INT NOT NULL,                       -- FK → dim.DL
    CurrencyKey         INT NOT NULL,                       -- FK → dim.Currency
    FiscalYearKey       INT NOT NULL,                       -- FK → dim.FiscalYear
    CashKey             INT NULL,                           -- FK → dim.Cash (صندوق)
    
    -- Flow Type
    FlowType            VARCHAR(20) NOT NULL,               -- 'Receipt' / 'Payment'
    FlowSign            SMALLINT NOT NULL,                  -- +1 = Receipt, -1 = Payment
    
    -- Degenerate Dimensions
    DocumentId          INT NOT NULL,                       -- PaymentHeaderId or ReceiptHeaderId
    DocumentNumber      INT NOT NULL,
    DocumentDate        DATE NOT NULL,
    DocumentType        INT NOT NULL,                       -- نوع سند
    DocumentState       INT NOT NULL,                       -- وضعیت
    DocumentStateName   NVARCHAR(50) NULL,
    
    -- Item Type (روش پرداخت/دریافت)
    ItemType            INT NOT NULL,
    ItemTypeName        NVARCHAR(50) NULL,                  -- نقد، چک، کارت، انتقال
    
    -- Measures (با علامت)
    Amount              DECIMAL(18,4) NULL,                 -- مبلغ اصلی (+ دریافت / - پرداخت)
    DiscountAmount      DECIMAL(18,4) NULL,                 -- تخفیف
    TotalAmount         DECIMAL(18,4) NULL,                 -- جمع کل
    AbsAmount           AS ABS(Amount),                     -- مبلغ مطلق
    
    -- Base Currency
    AmountBase          DECIMAL(18,4) NULL,
    TotalAmountBase     DECIMAL(18,4) NULL,
    
    -- Currency
    CurrencyRate        DECIMAL(18,6) NULL,
    
    -- Linked Voucher
    VoucherId           INT NULL,
    
    -- Description
    Description         NVARCHAR(500) NULL,
    
    -- Audit
    DW_LoadDate         DATETIME NOT NULL DEFAULT GETDATE()
);

-- Indexes
CREATE NONCLUSTERED INDEX IX_CashFlow_DateKey ON fact.CashFlow(DateKey);
CREATE NONCLUSTERED INDEX IX_CashFlow_PartyKey ON fact.CashFlow(PartyKey);
CREATE NONCLUSTERED INDEX IX_CashFlow_FlowType ON fact.CashFlow(FlowType);
CREATE NONCLUSTERED INDEX IX_CashFlow_DocumentId ON fact.CashFlow(DocumentId, FlowType);

PRINT 'fact.CashFlow created.';
GO


-- ============================================================================
-- fact.Cheque (چک‌ها)
-- ============================================================================
-- Source: PaymentCheque + ReceiptCheque (combined)
-- Grain: One row per cheque
-- ============================================================================
IF OBJECT_ID('fact.Cheque', 'U') IS NOT NULL DROP TABLE fact.Cheque;

CREATE TABLE fact.Cheque (
    -- Surrogate Key
    ChequeKey           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    
    -- Dimension Keys
    IssueDateKey        INT NOT NULL,                       -- FK → dim.Date (تاریخ صدور)
    DueDateKey          INT NULL,                           -- FK → dim.Date (تاریخ سررسید)
    PartyKey            INT NOT NULL,                       -- FK → dim.Party
    DLKey               INT NOT NULL,                       -- FK → dim.DL
    BankKey             INT NULL,                           -- FK → dim.Bank
    BankAccountKey      INT NULL,                           -- FK → dim.BankAccount
    CurrencyKey         INT NOT NULL,                       -- FK → dim.Currency
    FiscalYearKey       INT NOT NULL,                       -- FK → dim.FiscalYear
    
    -- Cheque Type
    ChequeType          VARCHAR(20) NOT NULL,               -- 'Receipt' / 'Payment'
    ChequeSign          SMALLINT NOT NULL,                  -- +1 = Receipt, -1 = Payment
    
    -- Cheque Info
    ChequeId            INT NOT NULL,                       -- PaymentChequeId or ReceiptChequeId
    ChequeNumber        NVARCHAR(100) NOT NULL,
    SecondNumber        NVARCHAR(100) NULL,
    SayadCode           NVARCHAR(20) NULL,                  -- کد صیاد
    AccountNo           NVARCHAR(100) NULL,                 -- شماره حساب
    
    -- Dates
    IssueDate           DATE NOT NULL,                      -- تاریخ صدور
    DueDate             DATE NULL,                          -- تاریخ سررسید
    
    -- Status
    ChequeState         INT NOT NULL,                       -- وضعیت فعلی
    ChequeStateName     NVARCHAR(50) NULL,
    InitialState        INT NULL,                           -- وضعیت اولیه
    IsGuarantee         BIT NOT NULL,                       -- تضمینی
    
    -- Related Document
    HeaderId            INT NOT NULL,                       -- PaymentHeaderId or ReceiptHeaderId
    HeaderNumber        INT NOT NULL,
    HeaderDate          DATE NOT NULL,
    
    -- Measures
    Amount              DECIMAL(18,4) NOT NULL,             -- مبلغ (با علامت)
    AmountBase          DECIMAL(18,4) NULL,                 -- مبلغ به ارز پایه
    AbsAmount           AS ABS(Amount),                     -- مبلغ مطلق
    
    -- Currency
    CurrencyRate        DECIMAL(18,6) NULL,
    
    -- Additional Info
    ChequeOwner         NVARCHAR(500) NULL,                 -- صاحب چک
    BranchCode          NVARCHAR(100) NULL,
    BranchName          NVARCHAR(500) NULL,
    
    -- Description
    Description         NVARCHAR(500) NULL,
    
    -- Audit
    DW_LoadDate         DATETIME NOT NULL DEFAULT GETDATE()
);

-- Indexes
CREATE NONCLUSTERED INDEX IX_Cheque_IssueDateKey ON fact.Cheque(IssueDateKey);
CREATE NONCLUSTERED INDEX IX_Cheque_DueDateKey ON fact.Cheque(DueDateKey);
CREATE NONCLUSTERED INDEX IX_Cheque_PartyKey ON fact.Cheque(PartyKey);
CREATE NONCLUSTERED INDEX IX_Cheque_ChequeType ON fact.Cheque(ChequeType);
CREATE NONCLUSTERED INDEX IX_Cheque_ChequeState ON fact.Cheque(ChequeState);
CREATE NONCLUSTERED INDEX IX_Cheque_ChequeNumber ON fact.Cheque(ChequeNumber);

PRINT 'fact.Cheque created.';
GO


-- ============================================================================
-- Summary
-- ============================================================================
SELECT 
    t.TABLE_SCHEMA + '.' + t.TABLE_NAME AS TableName,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS c 
     WHERE c.TABLE_SCHEMA = t.TABLE_SCHEMA AND c.TABLE_NAME = t.TABLE_NAME) AS ColumnCount
FROM INFORMATION_SCHEMA.TABLES t
WHERE t.TABLE_SCHEMA = 'fact' AND t.TABLE_TYPE = 'BASE TABLE'
ORDER BY t.TABLE_NAME;

PRINT '';
PRINT 'All fact tables created successfully!';
GO
