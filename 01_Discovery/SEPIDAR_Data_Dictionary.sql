/*
===============================================================================
SEPIDAR Data Warehouse - Data Dictionary & Relationships
===============================================================================
Document: Complete Column Analysis & Foreign Key Relationships
Version: 1.0
Date: January 2026
===============================================================================
*/

-- ############################################################################
-- PART 1: DIMENSION TABLES - DETAILED STRUCTURE
-- ############################################################################

/*
===============================================================================
dim.Account (حساب‌ها) - 343 rows
===============================================================================
Source: Account
Primary Key: AccountId
Hierarchy: Self-referencing (ParentAccountRef → AccountId)
*/
CREATE TABLE dim.Account (
    -- Key
    AccountKey          INT IDENTITY(1,1) PRIMARY KEY,  -- Surrogate Key
    AccountId           INT NOT NULL,                    -- Natural Key
    
    -- Hierarchy
    ParentAccountRef    INT NULL,                        -- FK → Account.AccountId
    AccountLevel        INT NULL,                        -- Calculated: 1=Group, 2=Kol, 3=Moein
    AccountPath         NVARCHAR(500) NULL,              -- Calculated: Full path
    
    -- Attributes
    Code                VARCHAR(40) NOT NULL,
    Title               NVARCHAR(500) NOT NULL,
    Title_En            NVARCHAR(500) NULL,
    Type                INT NOT NULL,                    -- Account Type Code
    IsActive            BIT NOT NULL,
    
    -- Account Behavior
    BalanceType         INT NOT NULL,                    -- 0=Debit, 1=Credit, 2=Both
    HasDL               BIT NOT NULL,                    -- Has Detail Ledger
    HasCurrency         BIT NOT NULL,                    -- Multi-currency
    HasTracking         BIT NOT NULL,
    CashFlowCategory    INT NULL,                        -- For Cash Flow reporting
    
    -- Audit
    CreatedDate         DATETIME NULL,
    ModifiedDate        DATETIME NULL,
    
    -- SCD Type 2
    EffectiveDate       DATE NOT NULL,
    ExpiryDate          DATE NULL,
    IsCurrent           BIT NOT NULL DEFAULT 1
);

/*
===============================================================================
dim.Party (طرف حساب) - 181 rows
===============================================================================
Source: Party
Primary Key: PartyId
Note: Unified table for Customer, Supplier, Broker, Employee
*/
CREATE TABLE dim.Party (
    -- Key
    PartyKey            INT IDENTITY(1,1) PRIMARY KEY,
    PartyId             INT NOT NULL,
    
    -- Classification
    Type                INT NOT NULL,           -- 0=Legal, 1=Real
    SubType             INT NOT NULL,
    IsCustomer          BIT NOT NULL,
    IsVendor            BIT NOT NULL,           -- Supplier
    IsBroker            BIT NOT NULL,
    IsEmployee          BIT NOT NULL,
    
    -- Identity
    Name                NVARCHAR(500) NOT NULL,
    LastName            NVARCHAR(500) NULL,
    FullName            AS (Name + ISNULL(' ' + LastName, '')),  -- Computed
    Name_En             NVARCHAR(500) NULL,
    LastName_En         NVARCHAR(500) NULL,
    
    -- Tax & Legal
    EconomicCode        NVARCHAR(80) NULL,      -- کد اقتصادی
    IdentificationCode  NVARCHAR(80) NULL,      -- کد/شناسه ملی
    RegistrationCode    NVARCHAR(80) NULL,      -- شماره ثبت
    
    -- Contact
    Website             NVARCHAR(500) NULL,
    Email               NVARCHAR(500) NULL,
    
    -- Relations
    DLRef               INT NOT NULL,           -- FK → DL.DLId
    CustomerGroupingRef INT NULL,
    VendorGroupingRef   INT NULL,
    SalespersonPartyRef INT NULL,               -- FK → Party.PartyId
    
    -- Customer Specific
    DiscountRate        DECIMAL(18,4) NULL,
    MaximumCredit       DECIMAL(18,4) NULL,
    HasCredit           BIT NULL,
    CustomerRemaining   DECIMAL(18,4) NULL,
    
    -- Broker Specific
    CommissionRate      DECIMAL(18,4) NULL,
    
    -- Status
    IsInBlacklist       BIT NOT NULL,
    
    -- Audit
    CreatedDate         DATETIME NULL,
    ModifiedDate        DATETIME NULL,
    
    -- SCD
    EffectiveDate       DATE NOT NULL,
    ExpiryDate          DATE NULL,
    IsCurrent           BIT NOT NULL DEFAULT 1
);

/*
===============================================================================
dim.Item (کالا) - 20 rows
===============================================================================
Source: Item
Primary Key: ItemID
*/
CREATE TABLE dim.Item (
    -- Key
    ItemKey             INT IDENTITY(1,1) PRIMARY KEY,
    ItemID              INT NOT NULL,
    
    -- Identity
    Code                NVARCHAR(500) NOT NULL,
    Title               NVARCHAR(500) NOT NULL,
    Title_En            NVARCHAR(500) NULL,
    BarCode             NVARCHAR(500) NULL,
    IranCode            NVARCHAR(500) NULL,     -- کد ایران
    
    -- Classification
    Type                INT NOT NULL,
    ItemCategoryRef     INT NULL,               -- FK → ItemCategory
    
    -- Units
    UnitRef             INT NULL,               -- FK → Unit (Primary)
    SecondaryUnitRef    INT NULL,               -- FK → Unit (Secondary)
    SaleUnitRef         INT NULL,               -- FK → Unit (Sale)
    UnitsRatio          FLOAT NULL,
    IsUnitRatioConstant BIT NOT NULL,
    
    -- Inventory
    DefaultStockRef     INT NULL,               -- FK → Stock
    MinimumAmount       FLOAT NULL,
    MaximumAmount       FLOAT NULL,
    
    -- Tracking
    CanHaveTracing      BIT NOT NULL,
    SerialTracking      BIT NOT NULL,
    
    -- Tax
    TaxExempt           BIT NOT NULL,
    TaxExemptPurchase   BIT NOT NULL,
    TaxRate             DECIMAL(18,4) NULL,
    DutyRate            DECIMAL(18,4) NULL,
    
    -- Physical
    Weight              DECIMAL(18,4) NULL,
    Volume              DECIMAL(18,4) NULL,
    
    -- Status
    IsActive            BIT NOT NULL,
    Sellable            BIT NOT NULL,
    
    -- Audit
    CreatedDate         DATETIME NULL,
    ModifiedDate        DATETIME NULL
);

/*
===============================================================================
dim.Stock (انبار) - 4 rows
===============================================================================
Source: Stock
Primary Key: StockID
*/
CREATE TABLE dim.Stock (
    StockKey            INT IDENTITY(1,1) PRIMARY KEY,
    StockID             INT NOT NULL,
    Code                INT NOT NULL,
    Title               NVARCHAR(500) NOT NULL,
    Title_En            NVARCHAR(500) NULL,
    StockClerk          NVARCHAR(500) NULL,
    Phone               NVARCHAR(100) NULL,
    Address             NVARCHAR(500) NULL,
    AccountSLRef        INT NULL,               -- FK → Account
    IsActive            BIT NOT NULL
);

/*
===============================================================================
dim.Bank (بانک) - 33 rows
===============================================================================
Source: Bank
Primary Key: BankId
*/
CREATE TABLE dim.Bank (
    BankKey             INT IDENTITY(1,1) PRIMARY KEY,
    BankId              INT NOT NULL,
    Title               NVARCHAR(500) NOT NULL,
    Title_En            NVARCHAR(500) NULL,
    TaxFileCode         NVARCHAR(100) NULL
);

/*
===============================================================================
dim.BankAccount (حساب بانکی) - 3 rows
===============================================================================
Source: BankAccount
Primary Key: BankAccountId
*/
CREATE TABLE dim.BankAccount (
    BankAccountKey      INT IDENTITY(1,1) PRIMARY KEY,
    BankAccountId       INT NOT NULL,
    BankBranchRef       INT NOT NULL,           -- FK → BankBranch
    AccountNo           NVARCHAR(500) NOT NULL,
    AccountTypeRef      INT NOT NULL,
    DlRef               INT NOT NULL,           -- FK → DL
    CurrencyRef         INT NOT NULL,           -- FK → Currency
    ShebaNumber         NVARCHAR(60) NULL,
    Owner               NVARCHAR(8000) NULL,
    Balance             DECIMAL(18,4) NULL,
    IsActive            BIT NOT NULL DEFAULT 1
);

/*
===============================================================================
dim.Currency (ارز) - 6 rows
===============================================================================
Source: Currency
Primary Key: CurrencyID
*/
CREATE TABLE dim.Currency (
    CurrencyKey         INT IDENTITY(1,1) PRIMARY KEY,
    CurrencyID          INT NOT NULL,
    Title               NVARCHAR(80) NOT NULL,
    Title_En            NVARCHAR(80) NULL,
    ExchangeUnit        INT NOT NULL,
    PrecisionCount      INT NOT NULL,
    PrecisionName       NVARCHAR(80) NULL
);

/*
===============================================================================
dim.DL (تفصیلی) - 190 rows
===============================================================================
Source: DL (Detail Ledger)
Primary Key: DLId
*/
CREATE TABLE dim.DL (
    DLKey               INT IDENTITY(1,1) PRIMARY KEY,
    DLId                INT NOT NULL,
    Code                VARCHAR(40) NOT NULL,
    Title               NVARCHAR(500) NOT NULL,
    Title_En            NVARCHAR(500) NULL,
    Type                INT NOT NULL,
    IsActive            BIT NOT NULL
);

/*
===============================================================================
dim.FiscalYear (سال مالی) - 3 rows
===============================================================================
Source: FiscalYear
Primary Key: FiscalYearId
*/
CREATE TABLE dim.FiscalYear (
    FiscalYearKey       INT IDENTITY(1,1) PRIMARY KEY,
    FiscalYearId        INT NOT NULL,
    Title               NVARCHAR(20) NOT NULL,
    Title_En            NVARCHAR(20) NULL,
    StartDate           DATETIME NOT NULL,
    EndDate             DATETIME NOT NULL,
    Status              INT NOT NULL            -- 0=Open, 1=Closed
);

/*
===============================================================================
dim.Personnel (پرسنل) - 51 rows
===============================================================================
Source: Personnel + Party
Primary Key: PersonnelId
*/
CREATE TABLE dim.Personnel (
    PersonnelKey        INT IDENTITY(1,1) PRIMARY KEY,
    PersonnelId         INT NOT NULL,
    PartyRef            INT NOT NULL,           -- FK → Party
    
    -- From Party
    FullName            NVARCHAR(500) NULL,
    EconomicCode        NVARCHAR(80) NULL,
    IdentificationCode  NVARCHAR(80) NULL,
    
    -- Personnel Specific
    FatherName          NVARCHAR(500) NULL,
    Nationality         INT NOT NULL,
    MarriageStatus      INT NOT NULL,
    Sex                 INT NOT NULL,
    Children            INT NULL,
    EducationDegree     INT NOT NULL,
    EducationField      NVARCHAR(500) NULL,
    MilitaryStatus      INT NOT NULL,
    EmployeeStatus      INT NOT NULL,
    
    -- Insurance
    InsuranceNumber     VARCHAR(50) NULL,
    InsuranceDay        INT NULL,
    
    -- Bank Info
    BankRef             INT NULL,
    BankBranchRef       INT NULL,
    AccountNo           NVARCHAR(500) NULL
);

/*
===============================================================================
dim.Unit (واحد اندازه‌گیری) - 4 rows
===============================================================================
Source: Unit
Primary Key: UnitID
*/
CREATE TABLE dim.Unit (
    UnitKey             INT IDENTITY(1,1) PRIMARY KEY,
    UnitID              INT NOT NULL,
    Title               NVARCHAR(100) NOT NULL,
    Title_En            NVARCHAR(100) NULL
);

/*
===============================================================================
dim.ItemCategory (گروه کالا) - 42 rows
===============================================================================
Source: ItemCategory
Primary Key: ItemCategoryID
*/
CREATE TABLE dim.ItemCategory (
    ItemCategoryKey     INT IDENTITY(1,1) PRIMARY KEY,
    ItemCategoryID      INT NOT NULL,
    Code                INT NOT NULL,
    Title               NVARCHAR(8000) NOT NULL
);

/*
===============================================================================
dim.CostCenter (مرکز هزینه) - 4 rows
===============================================================================
Source: CostCenter
Primary Key: CostCenterId
*/
CREATE TABLE dim.CostCenter (
    CostCenterKey       INT IDENTITY(1,1) PRIMARY KEY,
    CostCenterId        INT NOT NULL,
    DLRef               INT NOT NULL,           -- FK → DL
    Type                INT NOT NULL
);


-- ############################################################################
-- PART 2: FACT TABLES - DETAILED STRUCTURE
-- ############################################################################

/*
===============================================================================
fact.GLTransaction (تراکنش‌های دفتر کل) - Main Financial Fact
===============================================================================
Source: Voucher + VoucherItem
Grain: One row per voucher line item
*/
CREATE TABLE fact.GLTransaction (
    -- Keys
    GLTransactionKey    BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Dimension Keys
    DateKey             INT NOT NULL,           -- FK → dim.Date
    AccountKey          INT NOT NULL,           -- FK → dim.Account
    DLKey               INT NULL,               -- FK → dim.DL
    CurrencyKey         INT NULL,               -- FK → dim.Currency
    FiscalYearKey       INT NOT NULL,           -- FK → dim.FiscalYear
    
    -- Degenerate Dimensions (from Voucher header)
    VoucherId           INT NOT NULL,
    VoucherNumber       INT NOT NULL,
    VoucherDate         DATETIME NOT NULL,
    VoucherType         INT NOT NULL,           -- OV, PV, RV, JV, SV, PrV
    VoucherState        INT NOT NULL,           -- 0=Draft, 1=Confirmed, 2=Posted
    DailyNumber         INT NULL,
    
    -- Degenerate Dimensions (from VoucherItem)
    VoucherItemId       INT NOT NULL,
    RowNumber           INT NOT NULL,
    
    -- Measures
    Debit               DECIMAL(18,4) NULL,
    Credit              DECIMAL(18,4) NULL,
    Amount              AS (ISNULL(Debit,0) - ISNULL(Credit,0)),  -- Net Amount
    
    -- Currency Measures
    CurrencyRate        DECIMAL(18,6) NULL,
    CurrencyDebit       DECIMAL(18,4) NULL,
    CurrencyCredit      DECIMAL(18,4) NULL,
    
    -- Tracking
    TrackingNumber      NVARCHAR(80) NULL,
    TrackingDate        DATETIME NULL,
    IssuerEntityName    VARCHAR(400) NULL,      -- Source document type
    IssuerEntityRef     INT NULL,               -- Source document ID
    
    -- Description
    Description         NVARCHAR(500) NULL
);

/*
===============================================================================
fact.Sales (فروش)
===============================================================================
Source: Invoice + InvoiceItem
Grain: One row per invoice line item
*/
CREATE TABLE fact.Sales (
    -- Keys
    SalesKey            BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Dimension Keys
    DateKey             INT NOT NULL,           -- FK → dim.Date
    CustomerKey         INT NOT NULL,           -- FK → dim.Party
    ItemKey             INT NOT NULL,           -- FK → dim.Item
    StockKey            INT NULL,               -- FK → dim.Stock
    CurrencyKey         INT NOT NULL,           -- FK → dim.Currency
    FiscalYearKey       INT NOT NULL,           -- FK → dim.FiscalYear
    SaleTypeKey         INT NULL,               -- FK → dim.SaleType
    
    -- Degenerate Dimensions (from Invoice header)
    InvoiceId           INT NOT NULL,
    InvoiceNumber       INT NOT NULL,
    InvoiceDate         DATETIME NOT NULL,
    InvoiceState        INT NOT NULL,           -- State
    
    -- Degenerate Dimensions (from InvoiceItem)
    InvoiceItemID       INT NOT NULL,
    RowNumber           INT NOT NULL,
    
    -- Quantity Measures
    Quantity            DECIMAL(18,4) NOT NULL,
    SecondaryQuantity   DECIMAL(18,4) NULL,
    
    -- Price Measures (Item Level)
    Fee                 DECIMAL(18,4) NOT NULL,     -- Unit Price
    Price               DECIMAL(18,4) NOT NULL,     -- Quantity × Fee
    Discount            DECIMAL(18,4) NULL,
    Addition            DECIMAL(18,4) NULL,
    Tax                 DECIMAL(18,4) NULL,
    Duty                DECIMAL(18,4) NULL,
    NetPrice            DECIMAL(18,4) NULL,
    
    -- Base Currency Measures
    PriceInBaseCurrency         DECIMAL(18,4) NULL,
    DiscountInBaseCurrency      DECIMAL(18,4) NULL,
    NetPriceInBaseCurrency      DECIMAL(18,4) NULL,
    
    -- Currency
    CurrencyRate        DECIMAL(18,6) NULL,
    
    -- Description
    Description         NVARCHAR(510) NULL
);

/*
===============================================================================
fact.InventoryReceipt (رسید انبار)
===============================================================================
Source: InventoryReceipt + InventoryReceiptItem
Grain: One row per receipt line item
*/
CREATE TABLE fact.InventoryReceipt (
    -- Keys
    ReceiptKey          BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Dimension Keys
    DateKey             INT NOT NULL,           -- FK → dim.Date
    ItemKey             INT NOT NULL,           -- FK → dim.Item
    StockKey            INT NOT NULL,           -- FK → dim.Stock
    PartyKey            INT NULL,               -- FK → dim.Party (Deliverer)
    CurrencyKey         INT NULL,               -- FK → dim.Currency
    FiscalYearKey       INT NOT NULL,           -- FK → dim.FiscalYear
    
    -- Degenerate Dimensions (Header)
    InventoryReceiptID  INT NOT NULL,
    ReceiptNumber       INT NOT NULL,
    ReceiptDate         DATETIME NOT NULL,
    ReceiptType         INT NOT NULL,           -- Type of receipt
    PurchaseType        INT NOT NULL,
    IsReturn            BIT NOT NULL,
    
    -- Degenerate Dimensions (Item)
    InventoryReceiptItemID INT NOT NULL,
    RowNumber           INT NOT NULL,
    
    -- Quantity Measures
    Quantity            DECIMAL(18,4) NOT NULL,
    SecondaryQuantity   DECIMAL(18,4) NULL,
    RemainingQuantity   DECIMAL(18,4) NULL,
    
    -- Price Measures
    Price               DECIMAL(18,4) NULL,
    Tax                 DECIMAL(18,4) NULL,
    Duty                DECIMAL(18,4) NULL,
    TransportPrice      DECIMAL(18,4) NULL,
    OtherCostsAmount    DECIMAL(18,4) NULL,
    NetPrice            DECIMAL(18,4) NULL,
    Fee                 DECIMAL(18,4) NULL,
    
    -- Currency
    CurrencyRate        DECIMAL(18,6) NULL,
    CurrencyValue       DECIMAL(18,4) NULL,
    
    -- Description
    Description         NVARCHAR(8000) NULL
);

/*
===============================================================================
fact.InventoryDelivery (حواله انبار)
===============================================================================
Source: InventoryDelivery + InventoryDeliveryItem
Grain: One row per delivery line item
*/
CREATE TABLE fact.InventoryDelivery (
    -- Keys
    DeliveryKey         BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Dimension Keys
    DateKey             INT NOT NULL,           -- FK → dim.Date
    ItemKey             INT NOT NULL,           -- FK → dim.Item
    StockKey            INT NOT NULL,           -- FK → dim.Stock (Source)
    DestStockKey        INT NULL,               -- FK → dim.Stock (Destination)
    PartyKey            INT NULL,               -- FK → dim.Party (Receiver)
    FiscalYearKey       INT NOT NULL,           -- FK → dim.FiscalYear
    
    -- Degenerate Dimensions (Header)
    InventoryDeliveryID INT NOT NULL,
    DeliveryNumber      INT NOT NULL,
    DeliveryDate        DATETIME NOT NULL,
    DeliveryType        INT NOT NULL,
    IsReturn            BIT NOT NULL,
    
    -- Degenerate Dimensions (Item)
    InventoryDeliveryItemID INT NOT NULL,
    RowNumber           INT NOT NULL,
    
    -- Quantity Measures
    Quantity            DECIMAL(18,4) NOT NULL,
    SecondaryQuantity   DECIMAL(18,4) NULL,
    RemainingQuantity   DECIMAL(18,4) NULL,
    
    -- Price Measures
    Price               DECIMAL(18,4) NULL,
    Fee                 DECIMAL(18,4) NULL,
    
    -- Description
    Description         NVARCHAR(8000) NULL
);

/*
===============================================================================
fact.Payment (پرداخت)
===============================================================================
Source: PaymentHeader
Grain: One row per payment
*/
CREATE TABLE fact.Payment (
    -- Keys
    PaymentKey          BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Dimension Keys
    DateKey             INT NOT NULL,           -- FK → dim.Date
    PartyKey            INT NOT NULL,           -- FK → dim.Party
    CurrencyKey         INT NOT NULL,           -- FK → dim.Currency
    CashKey             INT NULL,               -- FK → dim.Cash
    FiscalYearKey       INT NOT NULL,           -- FK → dim.FiscalYear
    AccountKey          INT NULL,               -- FK → dim.Account
    
    -- Degenerate Dimensions
    PaymentHeaderId     INT NOT NULL,
    PaymentNumber       INT NOT NULL,
    PaymentDate         DATETIME NOT NULL,
    PaymentType         INT NOT NULL,           -- Type
    PaymentState        INT NOT NULL,           -- State
    ItemType            INT NOT NULL,           -- Payment method
    
    -- Measures
    Amount              DECIMAL(18,4) NULL,
    TotalAmount         DECIMAL(18,4) NULL,
    Discount            DECIMAL(18,4) NULL,
    PaymentAmount       DECIMAL(18,4) NULL,
    
    -- Base Currency
    AmountInBaseCurrency        DECIMAL(18,4) NULL,
    TotalAmountInBaseCurrency   DECIMAL(18,4) NULL,
    DiscountInBaseCurrency      DECIMAL(18,4) NULL,
    
    -- Currency
    CurrencyRate        DECIMAL(18,6) NULL,
    
    -- Description
    Description         NVARCHAR(8000) NULL
);

/*
===============================================================================
fact.Receipt (دریافت)
===============================================================================
Source: ReceiptHeader
Grain: One row per receipt
*/
CREATE TABLE fact.Receipt (
    -- Keys
    ReceiptKey          BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Dimension Keys
    DateKey             INT NOT NULL,           -- FK → dim.Date
    PartyKey            INT NOT NULL,           -- FK → dim.Party
    CurrencyKey         INT NOT NULL,           -- FK → dim.Currency
    CashKey             INT NULL,               -- FK → dim.Cash
    FiscalYearKey       INT NOT NULL,           -- FK → dim.FiscalYear
    AccountKey          INT NULL,               -- FK → dim.Account
    
    -- Degenerate Dimensions
    ReceiptHeaderId     INT NOT NULL,
    ReceiptNumber       INT NOT NULL,
    ReceiptDate         DATETIME NOT NULL,
    ReceiptType         INT NOT NULL,
    ReceiptState        INT NOT NULL,
    ItemType            INT NOT NULL,
    
    -- Measures
    Amount              DECIMAL(18,4) NULL,
    TotalAmount         DECIMAL(18,4) NULL,
    Discount            DECIMAL(18,4) NULL,
    ReceiptAmount       DECIMAL(18,4) NULL,
    
    -- Base Currency
    AmountInBaseCurrency        DECIMAL(18,4) NULL,
    TotalAmountInBaseCurrency   DECIMAL(18,4) NULL,
    
    -- Currency
    CurrencyRate        DECIMAL(18,6) NULL,
    
    -- Description
    Description         NVARCHAR(8000) NULL
);

/*
===============================================================================
fact.PaymentCheque (چک پرداختی)
===============================================================================
Source: PaymentCheque
Grain: One row per cheque
*/
CREATE TABLE fact.PaymentCheque (
    -- Keys
    ChequeKey           BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Dimension Keys
    DateKey             INT NOT NULL,           -- Cheque Date
    DueDateKey          INT NULL,               -- Due Date
    PartyKey            INT NOT NULL,           -- FK → dim.Party
    BankAccountKey      INT NOT NULL,           -- FK → dim.BankAccount
    CurrencyKey         INT NOT NULL,           -- FK → dim.Currency
    
    -- Degenerate Dimensions
    PaymentChequeId     INT NOT NULL,
    ChequeNumber        NVARCHAR(100) NOT NULL,
    SecondNumber        NVARCHAR(100) NULL,
    SayadCode           CHAR(16) NULL,
    PaymentHeaderRef    INT NOT NULL,
    HeaderNumber        INT NOT NULL,
    HeaderDate          DATETIME NOT NULL,
    
    -- Status
    ChequeState         INT NOT NULL,           -- State (issued, cashed, returned, etc.)
    IsGuarantee         BIT NOT NULL,
    ChequeType          INT NOT NULL,
    DurationType        INT NOT NULL,
    
    -- Measures
    Amount              DECIMAL(18,4) NOT NULL,
    AmountInBaseCurrency DECIMAL(18,4) NULL,
    CurrencyRate        DECIMAL(18,6) NULL,
    
    -- Description
    Description         NVARCHAR(8000) NULL
);

/*
===============================================================================
fact.ReceiptCheque (چک دریافتی)
===============================================================================
Source: ReceiptCheque
Grain: One row per cheque
*/
CREATE TABLE fact.ReceiptCheque (
    -- Keys
    ChequeKey           BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Dimension Keys
    DateKey             INT NOT NULL,           -- Cheque Date
    DueDateKey          INT NULL,               -- Due Date
    PartyKey            INT NOT NULL,           -- FK → dim.Party
    BankKey             INT NULL,               -- FK → dim.Bank
    CurrencyKey         INT NOT NULL,           -- FK → dim.Currency
    
    -- Degenerate Dimensions
    ReceiptChequeId     INT NOT NULL,
    ChequeNumber        NVARCHAR(100) NOT NULL,
    SecondNumber        NVARCHAR(100) NULL,
    SayadCode           CHAR(16) NULL,
    AccountNo           NVARCHAR(100) NOT NULL,
    ReceiptHeaderRef    INT NOT NULL,
    HeaderNumber        INT NOT NULL,
    HeaderDate          DATETIME NOT NULL,
    
    -- Status
    ChequeState         INT NOT NULL,
    InitState           INT NULL,
    IsGuarantee         BIT NOT NULL,
    ChequeType          INT NOT NULL,
    
    -- Bank Info
    BranchCode          NVARCHAR(500) NULL,
    BranchTitle         NVARCHAR(500) NULL,
    ChequeOwner         NVARCHAR(500) NULL,
    
    -- Measures
    Amount              DECIMAL(18,4) NOT NULL,
    AmountInBaseCurrency DECIMAL(18,4) NULL,
    CurrencyRate        DECIMAL(18,6) NULL,
    
    -- Description
    Description         NVARCHAR(8000) NULL
);

/*
===============================================================================
fact.PayrollCalculation (محاسبات حقوق)
===============================================================================
Source: Calculation
Grain: One row per employee per element per period
*/
CREATE TABLE fact.PayrollCalculation (
    -- Keys
    CalculationKey      BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Dimension Keys
    DateKey             INT NOT NULL,           -- FK → dim.Date
    PersonnelKey        INT NULL,               -- FK → dim.Personnel
    ElementKey          INT NOT NULL,           -- FK → dim.Element
    BranchKey           INT NULL,               -- FK → dim.Branch
    ContractKey         INT NULL,               -- FK → dim.Contract
    
    -- Degenerate Dimensions
    CalculationId       INT NOT NULL,
    Year                INT NOT NULL,
    Month               INT NOT NULL,
    CalculationType     INT NOT NULL,
    VoucherRef          INT NULL,
    
    -- Measures
    Value               DECIMAL(18,4) NOT NULL
);


-- ############################################################################
-- PART 3: RELATIONSHIP MAP
-- ############################################################################

/*
===============================================================================
FOREIGN KEY RELATIONSHIPS DISCOVERED
===============================================================================

VOUCHER/FINANCIAL:
------------------
VoucherItem.VoucherRef          → Voucher.VoucherId
VoucherItem.AccountSLRef        → Account.AccountId
VoucherItem.DLRef               → DL.DLId
VoucherItem.CurrencyRef         → Currency.CurrencyID
Voucher.FiscalYearRef           → FiscalYear.FiscalYearId

SALES:
------
Invoice.CustomerPartyRef        → Party.PartyId
Invoice.SaleTypeRef             → SaleType.SaleTypeId
Invoice.StockRef                → Stock.StockID
Invoice.CurrencyRef             → Currency.CurrencyID
Invoice.FiscalYearRef           → FiscalYear.FiscalYearId
Invoice.VoucherRef              → Voucher.VoucherId
InvoiceItem.InvoiceRef          → Invoice.InvoiceId
InvoiceItem.ItemRef             → Item.ItemID
InvoiceItem.StockRef            → Stock.StockID

INVENTORY:
----------
InventoryReceipt.StockRef           → Stock.StockID
InventoryReceipt.DelivererDLRef     → DL.DLId
InventoryReceipt.FiscalYearRef      → FiscalYear.FiscalYearId
InventoryReceipt.AccountingVoucherRef → Voucher.VoucherId
InventoryReceiptItem.InventoryReceiptRef → InventoryReceipt.InventoryReceiptID
InventoryReceiptItem.ItemRef        → Item.ItemID
InventoryReceiptItem.CurrencyRef    → Currency.CurrencyID

InventoryDelivery.StockRef          → Stock.StockID
InventoryDelivery.DestinationStockRef → Stock.StockID
InventoryDelivery.FiscalYearRef     → FiscalYear.FiscalYearId
InventoryDeliveryItem.InventoryDeliveryRef → InventoryDelivery.InventoryDeliveryID
InventoryDeliveryItem.ItemRef       → Item.ItemID

CASH/TREASURY:
--------------
PaymentHeader.DlRef             → DL.DLId (Party's DL)
PaymentHeader.CurrencyRef       → Currency.CurrencyID
PaymentHeader.CashRef           → Cash.CashId
PaymentHeader.FiscalYearRef     → FiscalYear.FiscalYearId
PaymentHeader.VoucherRef        → Voucher.VoucherId

ReceiptHeader.DlRef             → DL.DLId
ReceiptHeader.CurrencyRef       → Currency.CurrencyID
ReceiptHeader.CashRef           → Cash.CashId
ReceiptHeader.FiscalYearRef     → FiscalYear.FiscalYearId
ReceiptHeader.VoucherRef        → Voucher.VoucherId

CHEQUE:
-------
PaymentCheque.PaymentHeaderRef  → PaymentHeader.PaymentHeaderId
PaymentCheque.BankAccountRef    → BankAccount.BankAccountId
PaymentCheque.CurrencyRef       → Currency.CurrencyID
PaymentCheque.DlRef             → DL.DLId

ReceiptCheque.ReceiptHeaderRef  → ReceiptHeader.ReceiptHeaderId
ReceiptCheque.BankRef           → Bank.BankId
ReceiptCheque.CurrencyRef       → Currency.CurrencyID
ReceiptCheque.DlRef             → DL.DLId

PARTY:
------
Party.DLRef                     → DL.DLId
PartyAddress.PartyRef           → Party.PartyId
PartyAddress.LocationRef        → Location.LocationId

ITEM:
-----
Item.UnitRef                    → Unit.UnitID
Item.SecondaryUnitRef           → Unit.UnitID
Item.ItemCategoryRef            → ItemCategory.ItemCategoryID
Item.DefaultStockRef            → Stock.StockID

BANK:
-----
BankAccount.BankBranchRef       → BankBranch.BankBranchId
BankAccount.DlRef               → DL.DLId
BankAccount.CurrencyRef         → Currency.CurrencyID

PERSONNEL:
----------
Personnel.PartyRef              → Party.PartyId
Personnel.BankRef               → Bank.BankId
Personnel.BankBranchRef         → BankBranch.BankBranchId
Calculation.PersonnelRef        → Personnel.PersonnelId
Calculation.ElementRef          → Element.ElementId
Calculation.VoucherRef          → Voucher.VoucherId

===============================================================================
*/
