/*
===============================================================================
SEPIDAR Data Warehouse Project
Phase 3: Dimension Tables
===============================================================================
Script: 01_Create_Dim_Tables.sql
Purpose: Create all dimension tables in DW
Author: BI Team
Version: 1.0
Date: January 2026
===============================================================================
*/

USE DW_DB;
GO

-- ============================================================================
-- dim.Date (تاریخ) - جدول تقویم
-- ============================================================================
IF OBJECT_ID('dim.Date', 'U') IS NOT NULL DROP TABLE dim.Date;

CREATE TABLE dim.Date (
    -- Keys
    DateKey             INT NOT NULL PRIMARY KEY,           -- YYYYMMDD format
    FullDate            DATE NOT NULL,
    
    -- Gregorian (میلادی)
    GYear               SMALLINT NOT NULL,
    GMonth              TINYINT NOT NULL,
    GDay                TINYINT NOT NULL,
    GQuarter            TINYINT NOT NULL,
    GMonthName          NVARCHAR(20) NOT NULL,
    GMonthNameFa        NVARCHAR(20) NOT NULL,
    GDayOfWeek          TINYINT NOT NULL,
    GDayName            NVARCHAR(20) NOT NULL,
    GDayNameFa          NVARCHAR(20) NOT NULL,
    GWeekOfYear         TINYINT NOT NULL,
    
    -- Jalali/Shamsi (شمسی)
    JYear               SMALLINT NOT NULL,
    JMonth              TINYINT NOT NULL,
    JDay                TINYINT NOT NULL,
    JQuarter            TINYINT NOT NULL,
    JMonthName          NVARCHAR(20) NOT NULL,
    JDayOfWeek          TINYINT NOT NULL,
    JDayName            NVARCHAR(20) NOT NULL,
    JWeekOfYear         TINYINT NOT NULL,
    JDateString         CHAR(10) NOT NULL,                  -- 1403/01/15
    JYearMonth          INT NOT NULL,                       -- 140301
    
    -- Flags
    IsWeekend           BIT NOT NULL,
    IsHoliday           BIT NOT NULL DEFAULT 0,
    HolidayName         NVARCHAR(100) NULL,
    
    -- Fiscal Year (سال مالی)
    FiscalYear          SMALLINT NULL,
    FiscalQuarter       TINYINT NULL,
    FiscalMonth         TINYINT NULL
);

CREATE INDEX IX_Date_FullDate ON dim.Date(FullDate);
CREATE INDEX IX_Date_JYear ON dim.Date(JYear, JMonth);
CREATE INDEX IX_Date_GYear ON dim.Date(GYear, GMonth);

PRINT 'dim.Date created.';
GO


-- ============================================================================
-- dim.Account (حساب‌ها)
-- ============================================================================
IF OBJECT_ID('dim.Account', 'U') IS NOT NULL DROP TABLE dim.Account;

CREATE TABLE dim.Account (
    -- Keys
    AccountKey          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    AccountId           INT NOT NULL,                       -- Natural Key
    
    -- Hierarchy
    ParentAccountId     INT NULL,
    AccountLevel        TINYINT NOT NULL,                   -- 1=گروه, 2=کل, 3=معین
    AccountPath         NVARCHAR(500) NULL,                 -- Full hierarchy path
    
    -- Level 1 (گروه)
    L1_AccountId        INT NULL,
    L1_Code             VARCHAR(20) NULL,
    L1_Title            NVARCHAR(200) NULL,
    
    -- Level 2 (کل)
    L2_AccountId        INT NULL,
    L2_Code             VARCHAR(20) NULL,
    L2_Title            NVARCHAR(200) NULL,
    
    -- Level 3 (معین)
    L3_AccountId        INT NULL,
    L3_Code             VARCHAR(20) NULL,
    L3_Title            NVARCHAR(200) NULL,
    
    -- Attributes
    Code                VARCHAR(40) NOT NULL,
    Title               NVARCHAR(500) NOT NULL,
    Title_En            NVARCHAR(500) NULL,
    FullCode            VARCHAR(50) NULL,                   -- Concatenated code
    FullTitle           NVARCHAR(500) NULL,                 -- Concatenated title
    
    -- Account Type
    AccountType         INT NOT NULL,
    AccountTypeName     NVARCHAR(100) NULL,                 -- دارایی، بدهی، ...
    
    -- Behavior
    BalanceType         INT NOT NULL,                       -- 0=بدهکار, 1=بستانکار, 2=هر دو
    BalanceTypeName     NVARCHAR(50) NULL,
    HasDL               BIT NOT NULL,
    HasCurrency         BIT NOT NULL,
    HasTracking         BIT NOT NULL,
    CashFlowCategory    INT NULL,
    
    -- Status
    IsActive            BIT NOT NULL,
    IsLeaf              BIT NOT NULL,                       -- آیا حساب معین است
    
    -- Audit
    CreatedDate         DATETIME NULL,
    ModifiedDate        DATETIME NULL,
    DW_LoadDate         DATETIME NOT NULL DEFAULT GETDATE(),
    DW_UpdateDate       DATETIME NULL,
    
    CONSTRAINT UQ_Account_AccountId UNIQUE (AccountId)
);

CREATE INDEX IX_Account_Code ON dim.Account(Code);
CREATE INDEX IX_Account_ParentAccountId ON dim.Account(ParentAccountId);
CREATE INDEX IX_Account_Level ON dim.Account(AccountLevel);

PRINT 'dim.Account created.';
GO


-- ============================================================================
-- dim.DL (تفصیلی)
-- ============================================================================
IF OBJECT_ID('dim.DL', 'U') IS NOT NULL DROP TABLE dim.DL;

CREATE TABLE dim.DL (
    -- Keys
    DLKey               INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    DLId                INT NOT NULL,
    
    -- Attributes
    Code                VARCHAR(40) NOT NULL,
    Title               NVARCHAR(500) NOT NULL,
    Title_En            NVARCHAR(500) NULL,
    
    -- Type
    DLType              INT NOT NULL,
    DLTypeName          NVARCHAR(100) NULL,
    
    -- Status
    IsActive            BIT NOT NULL,
    
    -- Audit
    DW_LoadDate         DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT UQ_DL_DLId UNIQUE (DLId)
);

PRINT 'dim.DL created.';
GO


-- ============================================================================
-- dim.Party (طرف حساب)
-- ============================================================================
IF OBJECT_ID('dim.Party', 'U') IS NOT NULL DROP TABLE dim.Party;

CREATE TABLE dim.Party (
    -- Keys
    PartyKey            INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PartyId             INT NOT NULL,
    DLId                INT NULL,                           -- FK to DL
    
    -- Type Classification
    PartyType           INT NOT NULL,                       -- 0=حقوقی, 1=حقیقی
    PartyTypeName       NVARCHAR(50) NULL,
    SubType             INT NULL,
    
    -- Roles (یک طرف حساب می‌تواند چند نقش داشته باشد)
    IsCustomer          BIT NOT NULL,
    IsVendor            BIT NOT NULL,
    IsBroker            BIT NOT NULL,
    IsEmployee          BIT NOT NULL,
    
    -- Identity
    Name                NVARCHAR(500) NOT NULL,
    LastName            NVARCHAR(500) NULL,
    FullName            AS (Name + ISNULL(N' ' + LastName, N'')),
    Name_En             NVARCHAR(500) NULL,
    LastName_En         NVARCHAR(500) NULL,
    
    -- Legal/Tax Info
    EconomicCode        NVARCHAR(80) NULL,                  -- کد اقتصادی
    NationalCode        NVARCHAR(80) NULL,                  -- کد ملی / شناسه ملی
    RegistrationCode    NVARCHAR(80) NULL,                  -- شماره ثبت
    
    -- Contact
    Website             NVARCHAR(500) NULL,
    Email               NVARCHAR(500) NULL,
    
    -- Customer Attributes
    CustomerGroupId     INT NULL,
    CustomerGroupName   NVARCHAR(200) NULL,
    DiscountRate        DECIMAL(5,2) NULL,
    MaximumCredit       DECIMAL(18,2) NULL,
    HasCredit           BIT NULL,
    SalespersonId       INT NULL,
    SalespersonName     NVARCHAR(200) NULL,
    
    -- Vendor Attributes
    VendorGroupId       INT NULL,
    VendorGroupName     NVARCHAR(200) NULL,
    
    -- Broker Attributes
    CommissionRate      DECIMAL(5,2) NULL,
    
    -- Status
    IsInBlacklist       BIT NOT NULL,
    IsActive            BIT NOT NULL DEFAULT 1,
    
    -- Audit
    CreatedDate         DATETIME NULL,
    ModifiedDate        DATETIME NULL,
    DW_LoadDate         DATETIME NOT NULL DEFAULT GETDATE(),
    DW_UpdateDate       DATETIME NULL,
    
    CONSTRAINT UQ_Party_PartyId UNIQUE (PartyId)
);

CREATE INDEX IX_Party_DLId ON dim.Party(DLId);
CREATE INDEX IX_Party_IsCustomer ON dim.Party(IsCustomer) WHERE IsCustomer = 1;
CREATE INDEX IX_Party_IsVendor ON dim.Party(IsVendor) WHERE IsVendor = 1;
CREATE INDEX IX_Party_NationalCode ON dim.Party(NationalCode) WHERE NationalCode IS NOT NULL;

PRINT 'dim.Party created.';
GO


-- ============================================================================
-- dim.Item (کالا)
-- ============================================================================
IF OBJECT_ID('dim.Item', 'U') IS NOT NULL DROP TABLE dim.Item;

CREATE TABLE dim.Item (
    -- Keys
    ItemKey             INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ItemId              INT NOT NULL,
    
    -- Identity
    Code                NVARCHAR(500) NOT NULL,
    Title               NVARCHAR(500) NOT NULL,
    Title_En            NVARCHAR(500) NULL,
    Barcode             NVARCHAR(500) NULL,
    IranCode            NVARCHAR(500) NULL,
    
    -- Classification
    ItemType            INT NOT NULL,
    ItemTypeName        NVARCHAR(100) NULL,
    CategoryId          INT NULL,
    CategoryCode        INT NULL,
    CategoryName        NVARCHAR(500) NULL,
    
    -- Units
    UnitId              INT NULL,
    UnitName            NVARCHAR(100) NULL,
    SecondaryUnitId     INT NULL,
    SecondaryUnitName   NVARCHAR(100) NULL,
    SaleUnitId          INT NULL,
    SaleUnitName        NVARCHAR(100) NULL,
    UnitsRatio          FLOAT NULL,
    
    -- Stock
    DefaultStockId      INT NULL,
    DefaultStockName    NVARCHAR(200) NULL,
    
    -- Tax
    TaxExempt           BIT NOT NULL,
    TaxRate             DECIMAL(5,2) NULL,
    DutyRate            DECIMAL(5,2) NULL,
    
    -- Tracking
    CanHaveTracing      BIT NOT NULL,
    SerialTracking      BIT NOT NULL,
    
    -- Physical
    Weight              DECIMAL(18,4) NULL,
    Volume              DECIMAL(18,4) NULL,
    
    -- Status
    IsActive            BIT NOT NULL,
    Sellable            BIT NOT NULL,
    
    -- Audit
    CreatedDate         DATETIME NULL,
    ModifiedDate        DATETIME NULL,
    DW_LoadDate         DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT UQ_Item_ItemId UNIQUE (ItemId)
);

CREATE INDEX IX_Item_Code ON dim.Item(Code);
CREATE INDEX IX_Item_CategoryId ON dim.Item(CategoryId);
CREATE INDEX IX_Item_Barcode ON dim.Item(Barcode) WHERE Barcode IS NOT NULL;

PRINT 'dim.Item created.';
GO


-- ============================================================================
-- dim.ItemCategory (گروه کالا)
-- ============================================================================
IF OBJECT_ID('dim.ItemCategory', 'U') IS NOT NULL DROP TABLE dim.ItemCategory;

CREATE TABLE dim.ItemCategory (
    CategoryKey         INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CategoryId          INT NOT NULL,
    Code                INT NOT NULL,
    Title               NVARCHAR(500) NOT NULL,
    DW_LoadDate         DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT UQ_ItemCategory_CategoryId UNIQUE (CategoryId)
);

PRINT 'dim.ItemCategory created.';
GO


-- ============================================================================
-- dim.Stock (انبار)
-- ============================================================================
IF OBJECT_ID('dim.Stock', 'U') IS NOT NULL DROP TABLE dim.Stock;

CREATE TABLE dim.Stock (
    -- Keys
    StockKey            INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    StockId             INT NOT NULL,
    
    -- Attributes
    Code                INT NOT NULL,
    Title               NVARCHAR(500) NOT NULL,
    Title_En            NVARCHAR(500) NULL,
    StockClerk          NVARCHAR(500) NULL,
    Phone               NVARCHAR(100) NULL,
    Address             NVARCHAR(500) NULL,
    
    -- Status
    IsActive            BIT NOT NULL,
    
    -- Audit
    DW_LoadDate         DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT UQ_Stock_StockId UNIQUE (StockId)
);

PRINT 'dim.Stock created.';
GO


-- ============================================================================
-- dim.Bank (بانک)
-- ============================================================================
IF OBJECT_ID('dim.Bank', 'U') IS NOT NULL DROP TABLE dim.Bank;

CREATE TABLE dim.Bank (
    BankKey             INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    BankId              INT NOT NULL,
    Title               NVARCHAR(500) NOT NULL,
    Title_En            NVARCHAR(500) NULL,
    TaxFileCode         NVARCHAR(100) NULL,
    DW_LoadDate         DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT UQ_Bank_BankId UNIQUE (BankId)
);

PRINT 'dim.Bank created.';
GO


-- ============================================================================
-- dim.BankAccount (حساب بانکی)
-- ============================================================================
IF OBJECT_ID('dim.BankAccount', 'U') IS NOT NULL DROP TABLE dim.BankAccount;

CREATE TABLE dim.BankAccount (
    BankAccountKey      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    BankAccountId       INT NOT NULL,
    
    -- Bank Info
    BankId              INT NULL,
    BankName            NVARCHAR(500) NULL,
    BranchId            INT NULL,
    BranchName          NVARCHAR(500) NULL,
    
    -- Account Info
    AccountNo           NVARCHAR(500) NOT NULL,
    ShebaNumber         NVARCHAR(60) NULL,
    Owner               NVARCHAR(500) NULL,
    
    -- Currency
    CurrencyId          INT NULL,
    CurrencyName        NVARCHAR(100) NULL,
    
    -- Status
    IsActive            BIT NOT NULL DEFAULT 1,
    
    -- Audit
    DW_LoadDate         DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT UQ_BankAccount_BankAccountId UNIQUE (BankAccountId)
);

PRINT 'dim.BankAccount created.';
GO


-- ============================================================================
-- dim.Currency (ارز)
-- ============================================================================
IF OBJECT_ID('dim.Currency', 'U') IS NOT NULL DROP TABLE dim.Currency;

CREATE TABLE dim.Currency (
    CurrencyKey         INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CurrencyId          INT NOT NULL,
    Title               NVARCHAR(80) NOT NULL,
    Title_En            NVARCHAR(80) NULL,
    ExchangeUnit        INT NOT NULL,
    PrecisionCount      INT NOT NULL,
    PrecisionName       NVARCHAR(80) NULL,
    IsBaseCurrency      BIT NOT NULL DEFAULT 0,
    DW_LoadDate         DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT UQ_Currency_CurrencyId UNIQUE (CurrencyId)
);

PRINT 'dim.Currency created.';
GO


-- ============================================================================
-- dim.FiscalYear (سال مالی)
-- ============================================================================
IF OBJECT_ID('dim.FiscalYear', 'U') IS NOT NULL DROP TABLE dim.FiscalYear;

CREATE TABLE dim.FiscalYear (
    FiscalYearKey       INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    FiscalYearId        INT NOT NULL,
    Title               NVARCHAR(50) NOT NULL,
    Title_En            NVARCHAR(50) NULL,
    StartDate           DATE NOT NULL,
    EndDate             DATE NOT NULL,
    Status              INT NOT NULL,                       -- 0=باز, 1=بسته
    StatusName          NVARCHAR(50) NULL,
    IsCurrent           BIT NOT NULL DEFAULT 0,
    DW_LoadDate         DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT UQ_FiscalYear_FiscalYearId UNIQUE (FiscalYearId)
);

PRINT 'dim.FiscalYear created.';
GO


-- ============================================================================
-- dim.Personnel (پرسنل)
-- ============================================================================
IF OBJECT_ID('dim.Personnel', 'U') IS NOT NULL DROP TABLE dim.Personnel;

CREATE TABLE dim.Personnel (
    PersonnelKey        INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PersonnelId         INT NOT NULL,
    PartyId             INT NULL,
    
    -- Name (from Party)
    FullName            NVARCHAR(500) NULL,
    NationalCode        NVARCHAR(80) NULL,
    
    -- Personnel Info
    FatherName          NVARCHAR(500) NULL,
    Sex                 INT NULL,
    SexName             NVARCHAR(20) NULL,
    MarriageStatus      INT NULL,
    MarriageStatusName  NVARCHAR(50) NULL,
    EducationDegree     INT NULL,
    EducationDegreeName NVARCHAR(100) NULL,
    EducationField      NVARCHAR(500) NULL,
    
    -- Employment
    EmployeeStatus      INT NULL,
    EmployeeStatusName  NVARCHAR(100) NULL,
    
    -- Insurance
    InsuranceNumber     VARCHAR(50) NULL,
    
    -- Bank
    BankId              INT NULL,
    BankName            NVARCHAR(200) NULL,
    AccountNo           NVARCHAR(500) NULL,
    
    -- Status
    IsActive            BIT NOT NULL DEFAULT 1,
    
    -- Audit
    DW_LoadDate         DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT UQ_Personnel_PersonnelId UNIQUE (PersonnelId)
);

PRINT 'dim.Personnel created.';
GO


-- ============================================================================
-- dim.SaleType (نوع فروش)
-- ============================================================================
IF OBJECT_ID('dim.SaleType', 'U') IS NOT NULL DROP TABLE dim.SaleType;

CREATE TABLE dim.SaleType (
    SaleTypeKey         INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SaleTypeId          INT NOT NULL,
    Title               NVARCHAR(200) NOT NULL,
    Title_En            NVARCHAR(200) NULL,
    DW_LoadDate         DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT UQ_SaleType_SaleTypeId UNIQUE (SaleTypeId)
);

PRINT 'dim.SaleType created.';
GO


-- ============================================================================
-- Unknown Members (اعضای ناشناخته)
-- ============================================================================
-- Insert unknown/default members for handling NULL foreign keys

SET IDENTITY_INSERT dim.Account ON;
INSERT INTO dim.Account (AccountKey, AccountId, AccountLevel, Code, Title, AccountType, BalanceType, HasDL, HasCurrency, HasTracking, IsActive, IsLeaf)
VALUES (-1, -1, 0, 'N/A', N'نامشخص', 0, 0, 0, 0, 0, 1, 0);
SET IDENTITY_INSERT dim.Account OFF;

SET IDENTITY_INSERT dim.Party ON;
INSERT INTO dim.Party (PartyKey, PartyId, PartyType, IsCustomer, IsVendor, IsBroker, IsEmployee, Name, IsInBlacklist)
VALUES (-1, -1, 0, 0, 0, 0, 0, N'نامشخص', 0);
SET IDENTITY_INSERT dim.Party OFF;

SET IDENTITY_INSERT dim.Item ON;
INSERT INTO dim.Item (ItemKey, ItemId, Code, Title, ItemType, TaxExempt, CanHaveTracing, SerialTracking, IsActive, Sellable)
VALUES (-1, -1, 'N/A', N'نامشخص', 0, 0, 0, 0, 1, 0);
SET IDENTITY_INSERT dim.Item OFF;

SET IDENTITY_INSERT dim.Stock ON;
INSERT INTO dim.Stock (StockKey, StockId, Code, Title, IsActive)
VALUES (-1, -1, 0, N'نامشخص', 1);
SET IDENTITY_INSERT dim.Stock OFF;

SET IDENTITY_INSERT dim.Currency ON;
INSERT INTO dim.Currency (CurrencyKey, CurrencyId, Title, ExchangeUnit, PrecisionCount)
VALUES (-1, -1, N'نامشخص', 1, 0);
SET IDENTITY_INSERT dim.Currency OFF;

SET IDENTITY_INSERT dim.DL ON;
INSERT INTO dim.DL (DLKey, DLId, Code, Title, DLType, IsActive)
VALUES (-1, -1, 'N/A', N'نامشخص', 0, 1);
SET IDENTITY_INSERT dim.DL OFF;

SET IDENTITY_INSERT dim.FiscalYear ON;
INSERT INTO dim.FiscalYear (FiscalYearKey, FiscalYearId, Title, StartDate, EndDate, Status)
VALUES (-1, -1, N'نامشخص', '1900-01-01', '1900-12-31', 0);
SET IDENTITY_INSERT dim.FiscalYear OFF;

PRINT 'Unknown members inserted.';
GO


-- ============================================================================
-- Summary
-- ============================================================================
SELECT 
    t.TABLE_SCHEMA + '.' + t.TABLE_NAME AS TableName,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS c WHERE c.TABLE_SCHEMA = t.TABLE_SCHEMA AND c.TABLE_NAME = t.TABLE_NAME) AS ColumnCount
FROM INFORMATION_SCHEMA.TABLES t
WHERE t.TABLE_SCHEMA = 'dim' AND t.TABLE_TYPE = 'BASE TABLE'
ORDER BY t.TABLE_NAME;

PRINT '';
PRINT 'All dimension tables created successfully!';
GO
