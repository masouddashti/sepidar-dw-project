/*
===============================================================================
SEPIDAR Data Warehouse - Table Classification
===============================================================================
Document: Dimension & Fact Tables Identification
Version: 1.0
Date: January 2026

Legend:
  ⭐ = Key table (must have)
  📊 = Fact table
  📁 = Dimension table
  🔗 = Bridge/Link table
  ⚙️ = Reference/Lookup table
  📝 = Header table (parent of items)
  📋 = Item/Detail table (child)
===============================================================================
*/

-- ############################################################################
-- DIMENSION TABLES (جداول بُعد)
-- ############################################################################

/*
===============================================================================
DIM: Date (تاریخ) - External Excel File
===============================================================================
Source: External Excel file (not in SEPIDAR DB)
Target: dim.Date
Status: Will be created from Excel or T-SQL script
*/

/*
===============================================================================
DIM: Account & Financial Structure (حساب‌ها و ساختار مالی)
===============================================================================
*/

-- 📁 Account (حساب‌ها) ⭐
-- Main chart of accounts - CRITICAL for financial reporting
Account                     343 rows
    -- Fields: AccountID, Code, Title, Level, ParentID, AccountTypeID, ...
    -- Hierarchy: معین → کل → گروه
    -- Used by: VoucherItem, all financial transactions

-- 📁 AccountTopic (سرفصل حساب)
-- Account topic/header classification
AccountTopic                268 rows
    -- Parent grouping for accounts

-- ⚙️ AccountType (نوع حساب)
-- Account type lookup (Asset, Liability, Equity, Revenue, Expense)
AccountType                 10 rows

-- 📁 DL (تفصیلی - Detail Ledger) ⭐
-- Sub-ledger / detailed accounts
DL                          190 rows
    -- Used for detailed tracking (cost centers, projects, etc.)

-- ⚙️ Topic (سرفصل)
Topic                       29 rows

-- 📁 CostCenter (مرکز هزینه)
CostCenter                  4 rows

-- 📁 FiscalYear (سال مالی)
FiscalYear                  3 rows

/*
===============================================================================
DIM: Party (طرف حساب - مشتری/تامین‌کننده/سایر)
===============================================================================
*/

-- 📁 Party (طرف حساب) ⭐⭐ CRITICAL
-- Unified table for Customers, Suppliers, Employees, etc.
Party                       181 rows
    -- Contains: CustomerID, SupplierID, PersonnelID references
    -- Filter by PartyType to distinguish
    -- Fields: PartyID, Code, Name, NationalCode, EconomicCode, PartyType, ...

-- 🔗 PartyAddress (آدرس طرف حساب)
PartyAddress                56 rows

-- 🔗 PartyPhone (تلفن طرف حساب)  
PartyPhone                  5 rows

-- 🔗 PartyRelated (طرف حساب مرتبط)
PartyRelated                2 rows

/*
===============================================================================
DIM: Item & Product (کالا و محصول)
===============================================================================
*/

-- 📁 Item (کالا) ⭐
-- Product/Item master
Item                        20 rows
    -- Fields: ItemID, Code, Name, CategoryID, UnitID, ...

-- 📁 ItemCategory (گروه کالا) ⭐
-- Product category hierarchy
ItemCategory                42 rows
    -- Hierarchical grouping of items

-- ⚙️ Unit (واحد اندازه‌گیری)
Unit                        4 rows

-- 📁 ItemStock (موجودی کالا)
-- Current stock levels per item
ItemStock                   19 rows

-- 📁 ItemStockSummary (خلاصه موجودی)
ItemStockSummary            50 rows

/*
===============================================================================
DIM: Stock/Warehouse (انبار)
===============================================================================
*/

-- 📁 Stock (انبار) ⭐
-- Warehouse/Stock location master
Stock                       4 rows
    -- Fields: StockID, Code, Name, ...

/*
===============================================================================
DIM: Bank & Cash (بانک و صندوق)
===============================================================================
*/

-- 📁 Bank (بانک) ⭐
Bank                        33 rows

-- 📁 BankAccount (حساب بانکی)
BankAccount                 3 rows

-- 📁 BankBranch (شعبه بانک)
BankBranch                  3 rows

-- 📁 Cash (صندوق)
Cash                        2 rows

-- 📁 PettyCash (تنخواه‌گردان)
PettyCash                   7 rows

/*
===============================================================================
DIM: Currency (ارز)
===============================================================================
*/

-- 📁 Currency (ارز)
Currency                    6 rows

-- ⚙️ CurrencyExchangeRate (نرخ ارز)
CurrencyExchangeRate        0 rows  -- Empty but keep for future

/*
===============================================================================
DIM: Personnel & HR (پرسنل)
===============================================================================
*/

-- 📁 Personnel (پرسنل) ⭐
Personnel                   51 rows
    -- Employee master data

-- 📁 Job (شغل)
Job                         8 rows

-- ⚙️ Element (عناصر حقوقی)
Element                     237 rows
    -- Payroll elements (earnings, deductions)

-- 📁 ElementItem (اقلام عناصر)
ElementItem                 154 rows

/*
===============================================================================
DIM: Organization (سازمان)
===============================================================================
*/

-- 📁 Branch (شعبه)
Branch                      2 rows

-- 📁 Emplacement (محل استقرار)
Emplacement                 6 rows

/*
===============================================================================
DIM: Location (مکان)
===============================================================================
*/

-- 📁 Location (مکان)
Location                    7636 rows
    -- Geographic locations (cities, provinces, etc.)

-- 📁 DeliveryLocation (محل تحویل)
DeliveryLocation            2 rows

/*
===============================================================================
DIM: Sales Configuration (تنظیمات فروش)
===============================================================================
*/

-- ⚙️ SaleType (نوع فروش)
SaleType                    3 rows

-- 📁 Commission (کمیسیون)
Commission                  2 rows

-- 📁 CommissionBroker (واسطه کمیسیون)
CommissionBroker            2 rows

/*
===============================================================================
DIM: Tax (مالیات)
===============================================================================
*/

-- ⚙️ TaxGroup (گروه مالیاتی)
TaxGroup                    3 rows

-- 📁 TaxTable (جدول مالیات)
TaxTable                    63 rows

-- 📁 TaxTableItem (اقلام جدول مالیات)
TaxTableItem                217 rows

/*
===============================================================================
DIM: Asset (دارایی ثابت)
===============================================================================
*/

-- 📁 AssetClass (طبقه دارایی)
AssetClass                  6 rows

-- 📁 AssetGroup (گروه دارایی)
AssetGroup                  9 rows

-- ⚙️ DepreciationRule (قانون استهلاک)
DepreciationRule            169 rows

/*
===============================================================================
DIM: Contract (قرارداد)
===============================================================================
*/

-- 📁 Contract (قرارداد)
Contract                    51 rows

-- 📁 ContractElement (عناصر قرارداد)
ContractElement             213 rows

/*
===============================================================================
DIM: Other Reference Tables (سایر جداول مرجع)
===============================================================================
*/

-- ⚙️ Lookup (لیست‌های انتخابی)
Lookup                      1487 rows
    -- System lookups and dropdowns

-- ⚙️ Coefficient (ضرایب)
Coefficient                 7 rows

-- ⚙️ Property (ویژگی)
Property                    10 rows

-- ⚙️ Warranty (گارانتی)
Warranty                    6 rows


-- ############################################################################
-- FACT TABLES (جداول فکت)
-- ############################################################################

/*
===============================================================================
FACT: General Ledger / Vouchers (اسناد حسابداری) ⭐⭐ CRITICAL
===============================================================================
Module: FIN (Financial)
Grain: One row per voucher line item
*/

-- 📝 Voucher (سند حسابداری) - HEADER ⭐
Voucher                     5238 rows
    -- Fields: VoucherID, VoucherNo, Date, Description, Status, ...
    -- Status: 0=Draft, 1=Confirmed, 2=Posted, 3=Closed, 9=Cancelled
    -- Types: OV, PV, RV, JV, SV, PrV

-- 📋 VoucherItem (اقلام سند) - DETAIL ⭐⭐
VoucherItem                 13441 rows
    -- Fields: VoucherItemID, VoucherID, AccountID, DL_ID, Debit, Credit, Description, ...
    -- THIS IS THE MAIN FACT TABLE FOR FINANCIAL REPORTING
    -- Grain: One row per GL transaction line

/*
===============================================================================
FACT: Sales Invoice (فاکتور فروش) ⭐
===============================================================================
Module: SAL (Sales)
Grain: One row per invoice line item
*/

-- 📝 Invoice (فاکتور فروش) - HEADER ⭐
Invoice                     150 rows
    -- Fields: InvoiceID, InvoiceNo, Date, PartyID (Customer), TotalAmount, ...

-- 📋 InvoiceItem (اقلام فاکتور) - DETAIL ⭐
InvoiceItem                 201 rows
    -- Fields: InvoiceItemID, InvoiceID, ItemID, Quantity, UnitPrice, Amount, ...
    -- Grain: One row per sold item

-- 🔗 InvoiceCommissionBroker (کمیسیون واسطه فاکتور)
InvoiceCommissionBroker     105 rows

/*
===============================================================================
FACT: Sales Quotation (پیش فاکتور)
===============================================================================
Module: SAL (Sales)
Grain: One row per quotation line item
*/

-- 📝 Quotation (پیش فاکتور) - HEADER
Quotation                   42 rows

-- 📋 QuotationItem (اقلام پیش فاکتور) - DETAIL
QuotationItem               74 rows

-- 🔗 QuotationCommissionBroker
QuotationCommissionBroker   4 rows

/*
===============================================================================
FACT: Sales Return (برگشت از فروش)
===============================================================================
Module: SAL (Sales)
*/

-- 📝 ReturnedInvoice (برگشت از فروش) - HEADER
ReturnedInvoice             3 rows

-- 📋 ReturnedInvoiceItem (اقلام برگشت) - DETAIL
ReturnedInvoiceItem         5 rows

/*
===============================================================================
FACT: Inventory Receipt (رسید انبار) ⭐
===============================================================================
Module: INV (Inventory)
Grain: One row per receipt line item
*/

-- 📝 InventoryReceipt (رسید انبار) - HEADER ⭐
InventoryReceipt            1882 rows
    -- Fields: ReceiptID, ReceiptNo, Date, StockID, ...
    -- Types: Purchase receipt, Production receipt, Transfer receipt, ...

-- 📋 InventoryReceiptItem (اقلام رسید) - DETAIL ⭐
InventoryReceiptItem        2046 rows
    -- Fields: ReceiptItemID, ReceiptID, ItemID, Quantity, UnitPrice, ...
    -- Grain: One row per received item

/*
===============================================================================
FACT: Inventory Delivery (حواله انبار) ⭐
===============================================================================
Module: INV (Inventory)
Grain: One row per delivery line item
*/

-- 📝 InventoryDelivery (حواله انبار) - HEADER ⭐
InventoryDelivery           162 rows
    -- Types: Sales delivery, Production consumption, Transfer out, ...

-- 📋 InventoryDeliveryItem (اقلام حواله) - DETAIL ⭐
InventoryDeliveryItem       240 rows

/*
===============================================================================
FACT: Inventory Pricing (قیمت‌گذاری انبار)
===============================================================================
Module: INV (Inventory)
*/

-- 📝 InventoryPricing (قیمت‌گذاری)
InventoryPricing            5 rows

-- 📝 InventoryPricingVoucher (سند قیمت‌گذاری)
InventoryPricingVoucher     805 rows

-- 📋 InventoryPricingVoucherItem (اقلام سند قیمت‌گذاری)
InventoryPricingVoucherItem 88 rows

/*
===============================================================================
FACT: Purchase Invoice (فاکتور خرید)
===============================================================================
Module: PRC (Procurement)
Note: Mostly empty in this database
*/

-- 📝 InventoryPurchaseInvoice (فاکتور خرید انبار)
InventoryPurchaseInvoice    4 rows

-- 📋 InventoryPurchaseInvoiceItem (اقلام فاکتور خرید)
InventoryPurchaseInvoiceItem 6 rows

/*
===============================================================================
FACT: Payment (پرداخت) ⭐
===============================================================================
Module: CSH (Cash & Treasury)
Grain: One row per payment transaction
*/

-- 📝📊 PaymentHeader (سرتیتر پرداخت) ⭐
PaymentHeader               2194 rows
    -- Fields: PaymentID, PaymentNo, Date, PartyID, Amount, PaymentType, ...
    -- Types: Cash, Bank Transfer, Cheque, ...

-- 📋 PaymentDraft (پیش‌نویس پرداخت)
PaymentDraft                2140 rows

/*
===============================================================================
FACT: Receipt (دریافت) ⭐
===============================================================================
Module: CSH (Cash & Treasury)
Grain: One row per receipt transaction
*/

-- 📝📊 ReceiptHeader (سرتیتر دریافت) ⭐
ReceiptHeader               345 rows
    -- Fields: ReceiptID, ReceiptNo, Date, PartyID, Amount, ReceiptType, ...

-- 📋 ReceiptDraft (پیش‌نویس دریافت)
ReceiptDraft                261 rows

-- 📋 ReceiptPettyCash (دریافت تنخواه)
ReceiptPettyCash            143 rows

/*
===============================================================================
FACT: Payment Cheque (چک پرداختی) ⭐
===============================================================================
Module: CHQ (Cheque)
Grain: One row per issued cheque
*/

-- 📊 PaymentCheque (چک پرداختی) ⭐
PaymentCheque               213 rows
    -- Fields: ChequeID, ChequeNo, Date, PartyID, Amount, DueDate, Status, ...

-- 🔗 PaymentChequeBanking (عملیات بانکی چک پرداختی)
PaymentChequeBanking        97 rows

-- 📋 PaymentChequeBankingItem
PaymentChequeBankingItem    107 rows

-- 📋 PaymentChequeHistory (تاریخچه چک پرداختی)
PaymentChequeHistory        367 rows

-- 🔗 PaymentChequeOther
PaymentChequeOther          33 rows

/*
===============================================================================
FACT: Receipt Cheque (چک دریافتی) ⭐
===============================================================================
Module: CHQ (Cheque)
Grain: One row per received cheque
*/

-- 📊 ReceiptCheque (چک دریافتی) ⭐
ReceiptCheque               210 rows
    -- Fields: ChequeID, ChequeNo, Date, PartyID, Amount, DueDate, Status, ...

-- 🔗 ReceiptChequeBanking (عملیات بانکی چک دریافتی)
ReceiptChequeBanking        175 rows

-- 📋 ReceiptChequeBankingItem
ReceiptChequeBankingItem    264 rows

-- 📋 ReceiptChequeHistory (تاریخچه چک دریافتی)
ReceiptChequeHistory        511 rows

/*
===============================================================================
FACT: Refund Cheque (چک برگشتی)
===============================================================================
Module: CHQ (Cheque)
*/

-- 📊 RefundCheque (چک برگشتی)
RefundCheque                29 rows

-- 📋 RefundChequeItem
RefundChequeItem            51 rows

/*
===============================================================================
FACT: Petty Cash (تنخواه)
===============================================================================
Module: CSH (Cash & Treasury)
*/

-- 📝 PettyCashBill (صورتحساب تنخواه)
PettyCashBill               80 rows

-- 📋 PettyCashBillItem (اقلام صورتحساب تنخواه)
PettyCashBillItem           1104 rows

/*
===============================================================================
FACT: Payroll Calculation (محاسبات حقوق) ⭐
===============================================================================
Module: HR (Human Resources)
Grain: One row per employee per period calculation
*/

-- 📊 Calculation (محاسبات حقوق) ⭐
Calculation                 18512 rows
    -- Fields: CalculationID, PersonnelID, PeriodID, GrossPay, NetPay, ...
    -- Largest transaction table!

-- 🔗 MonthlyDataPersonnel
MonthlyDataPersonnel        187 rows

-- 📋 MonthlyDataPersonnelElement
MonthlyDataPersonnelElement 1683 rows

/*
===============================================================================
FACT: Commission Calculation (محاسبه کمیسیون)
===============================================================================
Module: SAL (Sales)
*/

-- 📊 CommissionCalculation
CommissionCalculation       4 rows

-- 📋 CommissionCalculationInvoice
CommissionCalculationInvoice 144 rows

-- 📋 CommissionCalculationItem
CommissionCalculationItem   16 rows

/*
===============================================================================
FACT: Party Account Settlement (تسویه حساب)
===============================================================================
Module: BAS/FIN
*/

-- 📝 PartyAccountSettlement (تسویه حساب طرف)
PartyAccountSettlement      31 rows

-- 📋 PartyAccountSettlementItem (اقلام تسویه)
PartyAccountSettlementItem  224 rows

/*
===============================================================================
FACT: Party Opening Balance (مانده افتتاحیه)
===============================================================================
Module: BAS/FIN
*/

-- 📊 PartyOpeningBalance (مانده افتتاحیه طرف حساب)
PartyOpeningBalance         596 rows

/*
===============================================================================
FACT: Debit/Credit Note (اعلامیه بدهکار/بستانکار)
===============================================================================
Module: FIN
*/

-- 📝 DebitCreditNote (اعلامیه)
DebitCreditNote             194 rows

-- 📋 DebitCreditNoteItem (اقلام اعلامیه)
DebitCreditNoteItem         291 rows

/*
===============================================================================
FACT: Tax Payer (سامانه مودیان)
===============================================================================
Module: TAX
*/

-- 📊 TaxPayerBill (صورتحساب مودیان)
TaxPayerBill                107 rows

-- 📋 TaxPayerBillItem
TaxPayerBillItem            115 rows

-- 📋 TaxPayerBillSubmitLog (لاگ ارسال)
TaxPayerBillSubmitLog       414 rows

/*
===============================================================================
FACT: Price (قیمت‌گذاری)
===============================================================================
Module: SAL
*/

-- 📝 PriceNote (یادداشت قیمت)
PriceNote                   1 row

-- 📋 PriceNoteItem
PriceNoteItem               4 rows

-- 📊 PricingItemPrice (قیمت کالا)
PricingItemPrice            427 rows


-- ############################################################################
-- SUMMARY TABLE
-- ############################################################################

/*
===============================================================================
SUMMARY: Tables for Synonym Creation
===============================================================================

DIMENSION TABLES (38 tables):
-----------------------------
Module  | Table                 | Rows    | Priority
--------|----------------------|---------|----------
BAS     | DimDate (External)   | 25,194  | ⭐⭐⭐
FIN     | Account              | 343     | ⭐⭐⭐
FIN     | AccountTopic         | 268     | ⭐⭐
FIN     | AccountType          | 10      | ⭐⭐
FIN     | DL                   | 190     | ⭐⭐
FIN     | Topic                | 29      | ⭐
FIN     | CostCenter           | 4       | ⭐
FIN     | FiscalYear           | 3       | ⭐⭐
BAS     | Party                | 181     | ⭐⭐⭐
BAS     | PartyAddress         | 56      | ⭐
BAS     | PartyPhone           | 5       | ⭐
INV     | Item                 | 20      | ⭐⭐⭐
INV     | ItemCategory         | 42      | ⭐⭐
INV     | ItemStock            | 19      | ⭐
INV     | ItemStockSummary     | 50      | ⭐
INV     | Stock                | 4       | ⭐⭐
INV     | Unit                 | 4       | ⭐⭐
CSH     | Bank                 | 33      | ⭐⭐
CSH     | BankAccount          | 3       | ⭐⭐
CSH     | BankBranch           | 3       | ⭐
CSH     | Cash                 | 2       | ⭐
CSH     | PettyCash            | 7       | ⭐
BAS     | Currency             | 6       | ⭐⭐
BAS     | Branch               | 2       | ⭐
BAS     | Emplacement          | 6       | ⭐
BAS     | Location             | 7,636   | ⭐
BAS     | DeliveryLocation     | 2       | ⭐
HR      | Personnel            | 51      | ⭐⭐
HR      | Job                  | 8       | ⭐
HR      | Element              | 237     | ⭐
HR      | ElementItem          | 154     | ⭐
SAL     | SaleType             | 3       | ⭐
SAL     | Commission           | 2       | ⭐
SAL     | CommissionBroker     | 2       | ⭐
TAX     | TaxGroup             | 3       | ⭐
TAX     | TaxTable             | 63      | ⭐
TAX     | TaxTableItem         | 217     | ⭐
AST     | AssetClass           | 6       | ⭐
AST     | AssetGroup           | 9       | ⭐
AST     | DepreciationRule     | 169     | ⭐
CNT     | Contract             | 51      | ⭐
CNT     | ContractElement      | 213     | ⭐
SYS     | Lookup               | 1,487   | ⭐
BAS     | Coefficient          | 7       | ⭐


FACT TABLES (28 tables):
------------------------
Module  | Table                      | Rows    | Priority
--------|---------------------------|---------|----------
FIN     | Voucher                   | 5,238   | ⭐⭐⭐
FIN     | VoucherItem               | 13,441  | ⭐⭐⭐
SAL     | Invoice                   | 150     | ⭐⭐⭐
SAL     | InvoiceItem               | 201     | ⭐⭐⭐
SAL     | InvoiceCommissionBroker   | 105     | ⭐
SAL     | Quotation                 | 42      | ⭐⭐
SAL     | QuotationItem             | 74      | ⭐⭐
SAL     | ReturnedInvoice           | 3       | ⭐
SAL     | ReturnedInvoiceItem       | 5       | ⭐
INV     | InventoryReceipt          | 1,882   | ⭐⭐⭐
INV     | InventoryReceiptItem      | 2,046   | ⭐⭐⭐
INV     | InventoryDelivery         | 162     | ⭐⭐⭐
INV     | InventoryDeliveryItem     | 240     | ⭐⭐⭐
INV     | InventoryPricingVoucher   | 805     | ⭐⭐
INV     | InventoryPricingVoucherItem| 88     | ⭐⭐
PRC     | InventoryPurchaseInvoice  | 4       | ⭐
PRC     | InventoryPurchaseInvoiceItem| 6     | ⭐
CSH     | PaymentHeader             | 2,194   | ⭐⭐⭐
CSH     | PaymentDraft              | 2,140   | ⭐⭐
CSH     | ReceiptHeader             | 345     | ⭐⭐⭐
CSH     | ReceiptDraft              | 261     | ⭐⭐
CSH     | ReceiptPettyCash          | 143     | ⭐
CSH     | PettyCashBill             | 80      | ⭐
CSH     | PettyCashBillItem         | 1,104   | ⭐
CHQ     | PaymentCheque             | 213     | ⭐⭐⭐
CHQ     | PaymentChequeBanking      | 97      | ⭐⭐
CHQ     | PaymentChequeBankingItem  | 107     | ⭐
CHQ     | PaymentChequeHistory      | 367     | ⭐⭐
CHQ     | PaymentChequeOther        | 33      | ⭐
CHQ     | ReceiptCheque             | 210     | ⭐⭐⭐
CHQ     | ReceiptChequeBanking      | 175     | ⭐⭐
CHQ     | ReceiptChequeBankingItem  | 264     | ⭐
CHQ     | ReceiptChequeHistory      | 511     | ⭐⭐
CHQ     | RefundCheque              | 29      | ⭐
CHQ     | RefundChequeItem          | 51      | ⭐
HR      | Calculation               | 18,512  | ⭐⭐⭐
HR      | MonthlyDataPersonnel      | 187     | ⭐⭐
HR      | MonthlyDataPersonnelElement| 1,683  | ⭐⭐
FIN     | PartyAccountSettlement    | 31      | ⭐⭐
FIN     | PartyAccountSettlementItem| 224     | ⭐⭐
FIN     | PartyOpeningBalance       | 596     | ⭐⭐
FIN     | DebitCreditNote           | 194     | ⭐⭐
FIN     | DebitCreditNoteItem       | 291     | ⭐⭐
TAX     | TaxPayerBill              | 107     | ⭐
TAX     | TaxPayerBillItem          | 115     | ⭐
SAL     | CommissionCalculation     | 4       | ⭐
SAL     | CommissionCalculationInvoice| 144   | ⭐
SAL     | PricingItemPrice          | 427     | ⭐⭐

===============================================================================
TOTAL: 
  - Dimension Tables: ~40 tables
  - Fact Tables: ~45 tables  
  - Total for Synonym: ~85 tables
===============================================================================
*/
