/*
===============================================================================
SEPIDAR Database Analysis Report
===============================================================================
Database: SEPIDAR ERP
Total Tables: 387
Tables with Data: ~180
Total Rows: ~105,000+
Analysis Date: January 2026
===============================================================================
*/

-- ============================================================================
-- SUMMARY STATISTICS
-- ============================================================================
/*
Total Tables:           387
Empty Tables:           ~207 (53%)
Tables with Data:       ~180 (47%)
Large Tables (>10K):    3 (DimDate, Calculation, VoucherItem)

Top 10 Largest Tables:
1.  DimDate                 25,194 rows  (تقویم)
2.  Calculation             18,512 rows  (محاسبات حقوق)
3.  VoucherItem             13,441 rows  (اقلام سند)
4.  Location                 7,636 rows  (مکان‌ها)
5.  Voucher                  5,238 rows  (اسناد حسابداری)
6.  ExtraData                4,634 rows  (داده‌های اضافی)
7.  UserAccess               3,945 rows  (دسترسی کاربران)
8.  LookupLocale             3,574 rows  (ترجمه‌ها)
9.  FAQ                      2,203 rows  
10. PaymentDraft             2,140 rows  (پیش‌نویس پرداخت)
*/

-- ============================================================================
-- TABLE CLASSIFICATION BY MODULE
-- ============================================================================

/*
===============================================================================
MODULE: SYS - System & Configuration (سیستم و تنظیمات)
===============================================================================
Tables: 25
Purpose: System settings, users, access control, logs
-------------------------------------------------------------------------------
*/
-- Configuration & Settings
Configuration               287     -- تنظیمات سیستم
LightConfiguration          2       -- تنظیمات ساده
AutomaticBackupConfig       1       -- تنظیمات بک‌آپ
Backup                      715     -- لاگ بک‌آپ‌ها

-- Users & Access
User                        9       -- کاربران
UserAccess                  3945    -- دسترسی کاربران
UserConfiguration           12      -- تنظیمات کاربر
UserPhone                   0       -- تلفن کاربر
UserReports                 5       -- گزارشات کاربر
UserReportsInvisible        0       

-- System Objects
IDGeneration                179     -- تولید شناسه
Version                     16      -- نسخه‌ها
Lookup                      1487    -- لیست‌های انتخابی
LookupLocale                3574    -- ترجمه لوکاپ‌ها
Keyword                     234     -- کلمات کلیدی
KeywordLocale               234     -- ترجمه کلمات
ExtraColumnDescription      52      -- توضیح ستون‌های اضافی
ExtraData                   4634    -- داده‌های اضافی
StandardDescription         1       -- توضیحات استاندارد
Note                        2       -- یادداشت

-- Logs & Tracking
ApiLog                      0       -- لاگ API
ObjectDependency            16      -- وابستگی اشیاء
ObjectHash                  0       -- هش اشیاء

/*
===============================================================================
MODULE: BAS - Base & Master Data (اطلاعات پایه)
===============================================================================
Tables: 20
Purpose: Shared reference data across modules
-------------------------------------------------------------------------------
*/
-- Organization
Branch                      2       -- شعبه
Emplacement                 6       -- محل استقرار

-- Calendar & Time
DimDate                     25194   -- بُعد تاریخ (آماده!)
FiscalYear                  3       -- سال مالی
DailyHourMinute             15      -- ساعت/دقیقه روزانه
PayrollCalendar             180     -- تقویم حقوق

-- Location & Address
Location                    7636    -- مکان‌ها
DeliveryLocation            2       -- محل تحویل
AreaAndPath                 1       -- منطقه و مسیر

-- Currency
Currency                    6       -- ارز
CurrencyExchangeRate        0       -- نرخ ارز

-- Units & Measures
Unit                        4       -- واحد اندازه‌گیری
Coefficient                 7       -- ضرایب

-- Party (طرف حساب - مشترک بین مشتری/تامین‌کننده)
Party                       181     -- طرف حساب ⭐ مهم
PartyAddress                56      -- آدرس طرف حساب
PartyPhone                  5       -- تلفن طرف حساب
PartyRelated                2       -- طرف حساب مرتبط
PartyOpeningBalance         596     -- مانده افتتاحیه طرف حساب
PartyAccountSettlement      31      -- تسویه حساب طرف
PartyAccountSettlementItem  224     -- اقلام تسویه

/*
===============================================================================
MODULE: FIN - Financial & Accounting (مالی و حسابداری)
===============================================================================
Tables: 18
Purpose: Chart of accounts, vouchers, GL transactions
-------------------------------------------------------------------------------
*/
-- Chart of Accounts
Account                     343     -- حساب‌ها ⭐ مهم
AccountTopic                268     -- سرفصل حساب
AccountType                 10      -- نوع حساب
DL                          190     -- تفصیلی (Detail Ledger)
Topic                       29      -- سرفصل

-- Vouchers (اسناد حسابداری)
Voucher                     5238    -- سند حسابداری ⭐ مهم - FACT
VoucherItem                 13441   -- اقلام سند ⭐ مهم - FACT
VoucherItemTracking         0       -- ردیابی اقلام سند
GLVoucher                   0       -- سند دفتر کل
GLVoucherItem               0       -- اقلام سند دفتر کل
MergedVoucherReferenceNumber 0      -- شماره سند ادغامی

-- Cost Center
CostCenter                  4       -- مرکز هزینه
Cost                        5       -- هزینه

-- Operations
OpeningOperation            1       -- عملیات افتتاحیه
OpeningOperationItem        0       -- اقلام افتتاحیه
ClosingOperation            6       -- عملیات اختتامیه

-- Fiscal
Grouping                    7       -- گروه‌بندی

/*
===============================================================================
MODULE: SAL - Sales & Distribution (فروش)
===============================================================================
Tables: 35
Purpose: Customers, invoices, quotations, returns
-------------------------------------------------------------------------------
*/
-- Sale Types & Config
SaleType                    3       -- نوع فروش
SaleTypeConstraint          0       -- محدودیت نوع فروش
SaleTypeConstraintItem      0       -- اقلام محدودیت

-- Invoices (فاکتور فروش)
Invoice                     150     -- فاکتور فروش ⭐ مهم - FACT
InvoiceItem                 201     -- اقلام فاکتور ⭐ مهم - FACT
InvoiceBroker               0       -- واسطه فاکتور
InvoiceCommissionBroker     105     -- کمیسیون واسطه

-- Quotations (پیش فاکتور)
Quotation                   42      -- پیش فاکتور
QuotationItem               74      -- اقلام پیش فاکتور
QuotationCommissionBroker   4       -- کمیسیون پیش فاکتور
Performa                    0       -- پروفرما
PerformaItem                0       -- اقلام پروفرما

-- Returns (برگشت از فروش)
ReturnedInvoice             3       -- برگشت از فروش
ReturnedInvoiceItem         5       -- اقلام برگشت از فروش
ReturnedInvoiceBroker       0       
ReturnedInvoiceCommissionBroker 0   
ReturnOrder                 0       -- سفارش برگشت
ReturnOrderItem             0       
ReturnReason                0       -- دلیل برگشت

-- Orders
Order                       0       -- سفارش فروش
OrderItem                   0       -- اقلام سفارش

-- Pricing
PriceNote                   1       -- یادداشت قیمت
PriceNoteItem               4       -- اقلام قیمت
PriceNoteItemDiscount       0       
PricingItemPrice            427     -- قیمت کالا

-- Discount
Discount                    0       -- تخفیف
DiscountItem                0       -- اقلام تخفیف

-- Commission
Commission                  2       -- کمیسیون
CommissionArea              0       -- منطقه کمیسیون
CommissionBroker            2       -- واسطه کمیسیون
CommissionItem              13      -- اقلام کمیسیون
CommissionStep              2       -- مراحل کمیسیون
CommissionCalculation       4       -- محاسبه کمیسیون
CommissionCalculationInvoice 144    
CommissionCalculationItem   16      
CommissionCalculationXMLResult 4    

-- Debt Collection
DebtCollectionList          0       -- لیست وصول مطالبات
DebtCollectionListInvoice   0       

/*
===============================================================================
MODULE: INV - Inventory & Warehouse (انبار و موجودی)
===============================================================================
Tables: 30
Purpose: Items, stock, warehouse transactions
-------------------------------------------------------------------------------
*/
-- Items (کالاها)
Item                        20      -- کالا ⭐ مهم - DIM
ItemCategory                42      -- گروه کالا
ItemImage                   0       -- تصویر کالا
ItemStock                   19      -- موجودی کالا
ItemStockSummary            50      -- خلاصه موجودی
ItemAdditionFactor          0       -- عوامل افزایشی کالا
ItemPropertyAmount          0       -- مقدار ویژگی کالا
ItemDiscount                0       -- تخفیف کالا

-- Stock (انبار)
Stock                       4       -- انبار ⭐ مهم - DIM

-- Inventory Receipts (رسید انبار)
InventoryReceipt            1882    -- رسید انبار ⭐ مهم - FACT
InventoryReceiptItem        2046    -- اقلام رسید ⭐ مهم - FACT
InventoryReceiptOtherCostItem 0     -- سایر هزینه‌ها

-- Inventory Delivery (حواله انبار)
InventoryDelivery           162     -- حواله انبار ⭐ مهم - FACT
InventoryDeliveryItem       240     -- اقلام حواله ⭐ مهم - FACT

-- Inventory Pricing (قیمت‌گذاری)
InventoryPricing            5       -- قیمت‌گذاری انبار
InventoryPricingVoucher     805     -- سند قیمت‌گذاری
InventoryPricingVoucherItem 88      -- اقلام سند قیمت‌گذاری

-- Inventory Balancing
InventoryBalancing          0       -- موازنه انبار
InventoryBalancingItem      0       

-- Transfer (انتقال)
Transfer                    0       -- انتقال بین انبار
TransferItem                0       

-- Tracking
CompoundBarcode             0       -- بارکد ترکیبی

/*
===============================================================================
MODULE: PRC - Procurement & Purchasing (خرید و تدارکات)
===============================================================================
Tables: 15
Purpose: Purchase orders, suppliers, purchase invoices
-------------------------------------------------------------------------------
*/
-- Purchase Invoices (فاکتور خرید)
PurchaseInvoice             0       -- فاکتور خرید
PurchaseInvoiceItem         0       -- اقلام فاکتور خرید
InventoryPurchaseInvoice    4       -- فاکتور خرید انبار
InventoryPurchaseInvoiceItem 6      -- اقلام فاکتور

-- Purchase Orders
PurchaseOrder               0       -- سفارش خرید
PurchaseOrderItem           0       

-- Purchase Requests
PurchaseRequest             0       -- درخواست خرید
PurchaseRequestItem         0       
PurchaseRequestItemVendor   0       

-- Purchase Costs
PurchaseCost                0       -- هزینه خرید
PurchaseCostItem            0       
PurchaseOtherCostItem       0       

-- Item Requests
ItemRequest                 0       -- درخواست کالا
ItemRequestItem             0       

/*
===============================================================================
MODULE: CSH - Cash & Treasury (خزانه‌داری)
===============================================================================
Tables: 20
Purpose: Cash, bank accounts, payments, receipts
-------------------------------------------------------------------------------
*/
-- Cash
Cash                        2       -- صندوق
CashBalance                 1       -- مانده صندوق
Cashier                     0       -- صندوق‌دار

-- Bank
Bank                        33      -- بانک ⭐ مهم - DIM
BankAccount                 3       -- حساب بانکی
BankAccountBalance          3       -- مانده حساب بانکی
BankBranch                  3       -- شعبه بانک
BankBill                    0       -- صورتحساب بانکی
BankBillItem                0       

-- Petty Cash (تنخواه)
PettyCash                   7       -- تنخواه‌گردان
PettyCashBill               80      -- صورتحساب تنخواه
PettyCashBillItem           1104    -- اقلام صورتحساب

-- Payments (پرداخت)
PaymentHeader               2194    -- سرتیتر پرداخت ⭐ مهم - FACT
PaymentDraft                2140    -- پیش‌نویس پرداخت

-- Receipts (دریافت)
ReceiptHeader               345     -- سرتیتر دریافت ⭐ مهم - FACT
ReceiptDraft                261     -- پیش‌نویس دریافت
ReceiptPettyCash            143     -- دریافت تنخواه
ReceiptPos                  0       -- دریافت کارتخوان

-- Reconciliation
Reconciliation              0       -- مغایرت بانکی
ReconciliationItem          0       
ReconciliationBankItem      0       

/*
===============================================================================
MODULE: CHQ - Cheque Management (مدیریت چک)
===============================================================================
Tables: 15
Purpose: Cheques received and issued
-------------------------------------------------------------------------------
*/
-- Cheque Book
ChequeBook                  1       -- دسته چک

-- Payment Cheques (چک پرداختی)
PaymentCheque               213     -- چک پرداختی ⭐ مهم - FACT
PaymentChequeBanking        97      -- عملیات بانکی چک پرداختی
PaymentChequeBankingItem    107     
PaymentChequeHistory        367     -- تاریخچه چک پرداختی
PaymentChequeOther          33      -- سایر چک‌های پرداختی

-- Receipt Cheques (چک دریافتی)
ReceiptCheque               210     -- چک دریافتی ⭐ مهم - FACT
ReceiptChequeBanking        175     -- عملیات بانکی چک دریافتی
ReceiptChequeBankingItem    264     
ReceiptChequeHistory        511     -- تاریخچه چک دریافتی

-- Refund Cheques
RefundCheque                29      -- چک برگشتی
RefundChequeItem            51      

/*
===============================================================================
MODULE: TAX - Tax & Legal (مالیات)
===============================================================================
Tables: 18
Purpose: Tax tables, VAT, tax payer integration
-------------------------------------------------------------------------------
*/
-- Tax Tables
TaxGroup                    3       -- گروه مالیاتی
TaxTable                    63      -- جدول مالیات
TaxTableItem                217     -- اقلام جدول مالیات

-- VAT
Vat                         0       -- مالیات بر ارزش افزوده
VatItem                     0       

-- Tax Payer Integration (سامانه مودیان)
TaxPayerBill                107     -- صورتحساب مودیان
TaxPayerBillItem            115     
TaxPayerBillSubmitLog       414     -- لاگ ارسال
TaxPayerCurrency            142     
TaxPayerCurrencyMapper      6       
TaxPayerGeneralLog          1       
TaxPayerItemMapping         14      
TaxPayerPartyMapping        30      
TaxPayerUnit                98      
TaxPayerUnitMapper          3       

/*
===============================================================================
MODULE: HR - Human Resources & Payroll (منابع انسانی)
===============================================================================
Tables: 20
Purpose: Personnel, payroll, calculations
-------------------------------------------------------------------------------
*/
-- Personnel
Personnel                   51      -- پرسنل ⭐ مهم - DIM
PersonnelInitiate           0       
PersonnelInitiateElement    0       
PersonnelTaxFileInfoChangeLog 51    

-- Payroll Configuration
PayrollConfiguration        1       -- تنظیمات حقوق
PayrollConfigurationElement 34      -- عناصر تنظیمات

-- Calculation (محاسبات حقوق)
Calculation                 18512   -- محاسبات ⭐ مهم - FACT
CalculationElement          4       -- عناصر محاسبه
CalculationFormula          1       -- فرمول محاسبه

-- Elements
Element                     237     -- عناصر حقوقی
ElementItem                 154     -- اقلام عناصر
ElementSavedValue           0       

-- Monthly Data
MonthlyData                 9       -- داده ماهانه
MonthlyDataPersonnel        187     
MonthlyDataPersonnelElement 1683    

-- Jobs
Job                         8       -- شغل
WorkExperience              0       -- سابقه کار

-- Leave
Leave                       0       -- مرخصی

/*
===============================================================================
MODULE: AST - Assets (دارایی‌های ثابت)
===============================================================================
Tables: 15
Purpose: Fixed assets, depreciation
-------------------------------------------------------------------------------
*/
Asset                       0       -- دارایی
AssetClass                  6       -- طبقه دارایی
AssetGroup                  9       -- گروه دارایی
AssetRelatedPurchaseInvoice 0       
AssetTransaction            0       -- تراکنش دارایی
Depreciation                0       -- استهلاک
DepreciationItem            0       
DepreciationRule            169     -- قانون استهلاک
ChangeDepreciationMethod    0       -- تغییر روش استهلاک
ChangeDepreciationMethodItem 0      
AcquisitionReceipt          0       -- رسید تملک
AcquisitionReceiptItem      0       
Salvage                     0       -- اسقاط
SalvageItem                 0       
Unuseable                   0       -- غیرقابل استفاده
UnuseableItem               0       
Useable                     0       -- قابل استفاده
UseableItem                 0       

/*
===============================================================================
MODULE: CNT - Contracts (قراردادها)
===============================================================================
Tables: 12
Purpose: Contracts management
-------------------------------------------------------------------------------
*/
Contract                    51      -- قرارداد
ContractType                0       -- نوع قرارداد
ContractElement             213     -- عناصر قرارداد
ContractAgreementItem       0       
ContractCoefficientItem     0       
ContractCompromiseItem      0       
ContractEmployerMaterialsItem 0     
ContractPreReceiptItem      0       
ContractPriceList           0       
ContractRelatedPurchaseInvoice 0    
ContractSupportingInsurance 0       
ContractWarrantyItem        0       
ContractWorkshopItem        0       

/*
===============================================================================
MODULE: PRD - Production (تولید)
===============================================================================
Tables: 10
Purpose: BOM, production orders
-------------------------------------------------------------------------------
*/
ProductFormula              0       -- فرمول تولید
ProductOrder                0       -- سفارش تولید
ProductOrderBOMItem         0       -- BOM سفارش
FormulaBomItem              0       -- اقلام BOM
FormulaBomItemAlternative   0       -- جایگزین BOM
FormulaElement              4       -- عناصر فرمول
ProducedItemPrice           8       -- قیمت تولیدی

/*
===============================================================================
MODULE: DST - Distribution (توزیع)
===============================================================================
Tables: 15
Purpose: Cold/Hot distribution
-------------------------------------------------------------------------------
*/
-- Cold Distribution
ColdDistribution            0       
ColdDistributionInvoice     0       
ColdDistributionReturnedInvoice 0   

-- Hot Distribution
HotDistribution             0       
HotDistributionInventoryDelivery 0  
HotDistributionItem         0       
HotDistributionPath         0       
HotDistributionSaleDocument 0       
HotDistributionUnexecutedAct 0      

-- Commercial
CommercialOrder             0       
CommercialOrderItem         0       

-- Bill of Loading
BillOfLoading               0       
BillOfLoadingItem           0       

/*
===============================================================================
MODULE: OTH - Other/Misc (سایر)
===============================================================================
Tables: Remaining uncategorized
-------------------------------------------------------------------------------
*/
-- Debit/Credit Notes
DebitCreditNote             194     -- اعلامیه بدهکار/بستانکار
DebitCreditNoteItem         291     

-- Warranty & Guarantee
Warranty                    6       -- گارانتی
Guarantee                   0       
GuaranteeOperation          0       
GuaranteeRelated            0       

-- Property
Property                    10      -- ویژگی
PropertyDetail              0       

-- Communication
Communication               0       
CommunicationConfiguration  0       
EstablishmentCommunication  0       

-- Messaging
Message                     0       
MessageContact              0       
OutgoingMessage             0       
Inbox                       0       

-- Templates
Template                    0       
TemplateContact             0       
TemplateEvent               0       
TemplateFilter              0       
TemplateScheduling          0       

-- FAQ & Help
FAQ                         2203    

-- Reminders
Reminder                    26      
RemovedReminder             0       

-- Numbered Entity
NumberedEntity              87      

-- Shred (خردکردن)
Shred                       1       
ShredInfo                   1       
ShredItem                   15      
