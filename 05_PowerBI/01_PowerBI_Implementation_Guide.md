/*
================================================================================
SEPIDAR Data Warehouse - Power BI Implementation Guide
راهنمای پیاده‌سازی Power BI برای انبار داده سپیدار
================================================================================
Version: 1.0
Date: January 2026
Author: BI Team
================================================================================
*/

# فهرست مطالب

1. [اتصال به دیتابیس](#1-اتصال-به-دیتابیس)
2. [مدل داده (Data Model)](#2-مدل-داده)
3. [روابط (Relationships)](#3-روابط)
4. [DAX Measures](#4-dax-measures)
5. [داشبوردها](#5-داشبوردها)
6. [نکات بهینه‌سازی](#6-نکات-بهینه‌سازی)

---

# 1. اتصال به دیتابیس

## 1.1 مراحل اتصال

1. Power BI Desktop را باز کنید
2. **Get Data** → **SQL Server**
3. تنظیمات:
   - Server: `نام_سرور` یا `localhost`
   - Database: `DW_DB`
   - Data Connectivity Mode: **Import** (پیشنهادی)

## 1.2 جداول مورد نیاز

### Dimension Tables (جداول بُعد):
| جدول | توضیح | تعداد تقریبی |
|------|-------|--------------|
| dim.Date | تقویم شمسی/میلادی | 5,114 |
| dim.Account | حساب‌ها (سلسله‌مراتبی) | 343 |
| dim.Party | طرف حساب (مشتری/تأمین‌کننده) | 181 |
| dim.DL | تفصیلی | 190 |
| dim.Item | کالا | 20 |
| dim.ItemCategory | گروه کالا | 42 |
| dim.Stock | انبار | 4 |
| dim.Currency | ارز | 6 |
| dim.FiscalYear | سال مالی | 3 |
| dim.Bank | بانک | 33 |
| dim.BankAccount | حساب بانکی | - |

### Fact Tables (جداول واقعیت):
| جدول | توضیح | تعداد تقریبی |
|------|-------|--------------|
| fact.GLTransaction | تراکنش‌های دفتر کل | 13,441 |
| fact.Sales | فروش | 201 |
| fact.Inventory | موجودی انبار | 2,286 |
| fact.CashFlow | جریان نقدی | 2,539 |
| fact.Cheque | چک‌ها | 423 |

---

# 2. مدل داده

## 2.1 Star Schema

```
                         ┌─────────────────┐
                         │    dim.Date     │
                         │  (تقویم)        │
                         └────────┬────────┘
                                  │
     ┌─────────────┐              │              ┌─────────────┐
     │ dim.Account │              │              │  dim.Item   │
     │  (حساب)     │              │              │   (کالا)    │
     └──────┬──────┘              │              └──────┬──────┘
            │                     │                     │
            │    ┌────────────────┼────────────────┐    │
            │    │                │                │    │
            ├────┤ fact.GLTransaction              ├────┤
            │    │ fact.Sales                      │    │
            │    │ fact.Inventory                  │    │
            │    │ fact.CashFlow                   │    │
            │    │ fact.Cheque                     │    │
            │    │                                 │    │
            │    └────────────────┬────────────────┘    │
            │                     │                     │
     ┌──────┴──────┐              │              ┌──────┴──────┐
     │  dim.Party  │              │              │  dim.Stock  │
     │ (طرف حساب)  │              │              │   (انبار)   │
     └─────────────┘              │              └─────────────┘
                                  │
                         ┌────────┴────────┐
                         │  dim.Currency   │
                         │    (ارز)        │
                         └─────────────────┘
```

## 2.2 تنظیمات جداول در Power BI

### dim.Date:
- Mark as Date Table: ✅
- Date Column: `FullDate`
- این جدول برای Time Intelligence ضروری است

### dim.Account:
- حساب‌ها سلسله‌مراتبی هستند (4 سطح)
- Hierarchy بسازید: L1_Title → L2_Title → L3_Title → Title

### dim.Party:
- فیلترهای مفید: IsCustomer, IsVendor, IsBroker

---

# 3. روابط (Relationships)

## 3.1 روابط اصلی

### fact.GLTransaction:
| از ستون | به جدول | به ستون | نوع |
|---------|---------|---------|-----|
| DateKey | dim.Date | DateKey | Many-to-One |
| AccountKey | dim.Account | AccountKey | Many-to-One |
| DLKey | dim.DL | DLKey | Many-to-One |
| CurrencyKey | dim.Currency | CurrencyKey | Many-to-One |
| FiscalYearKey | dim.FiscalYear | FiscalYearKey | Many-to-One |

### fact.Sales:
| از ستون | به جدول | به ستون | نوع |
|---------|---------|---------|-----|
| DateKey | dim.Date | DateKey | Many-to-One |
| CustomerKey | dim.Party | PartyKey | Many-to-One |
| ItemKey | dim.Item | ItemKey | Many-to-One |
| StockKey | dim.Stock | StockKey | Many-to-One |
| CurrencyKey | dim.Currency | CurrencyKey | Many-to-One |
| FiscalYearKey | dim.FiscalYear | FiscalYearKey | Many-to-One |

### fact.Inventory:
| از ستون | به جدول | به ستون | نوع |
|---------|---------|---------|-----|
| DateKey | dim.Date | DateKey | Many-to-One |
| ItemKey | dim.Item | ItemKey | Many-to-One |
| StockKey | dim.Stock | StockKey | Many-to-One |
| PartyKey | dim.Party | PartyKey | Many-to-One |
| FiscalYearKey | dim.FiscalYear | FiscalYearKey | Many-to-One |

### fact.CashFlow:
| از ستون | به جدول | به ستون | نوع |
|---------|---------|---------|-----|
| DateKey | dim.Date | DateKey | Many-to-One |
| PartyKey | dim.Party | PartyKey | Many-to-One |
| AccountKey | dim.Account | AccountKey | Many-to-One |
| DLKey | dim.DL | DLKey | Many-to-One |
| CurrencyKey | dim.Currency | CurrencyKey | Many-to-One |
| FiscalYearKey | dim.FiscalYear | FiscalYearKey | Many-to-One |

### fact.Cheque:
| از ستون | به جدول | به ستون | نوع |
|---------|---------|---------|-----|
| IssueDateKey | dim.Date | DateKey | Many-to-One |
| DueDateKey | dim.Date | DateKey | Many-to-One (غیرفعال) |
| PartyKey | dim.Party | PartyKey | Many-to-One |
| BankKey | dim.Bank | BankKey | Many-to-One |
| CurrencyKey | dim.Currency | CurrencyKey | Many-to-One |
| FiscalYearKey | dim.FiscalYear | FiscalYearKey | Many-to-One |

## 3.2 نکات مهم روابط

1. **Cross-filter direction**: همه روابط Single باشند
2. **رابطه غیرفعال**: fact.Cheque با dim.Date دو رابطه دارد (صدور و سررسید)
   - برای استفاده از DueDateKey از USERELATIONSHIP استفاده کنید

---

# 4. DAX Measures

## 4.1 Measures پایه - مالی (Financial)

```dax
// ═══════════════════════════════════════════════════════════════
// مجموع بدهکار
// ═══════════════════════════════════════════════════════════════
Total Debit = 
SUM(fact.GLTransaction[Debit])

// ═══════════════════════════════════════════════════════════════
// مجموع بستانکار
// ═══════════════════════════════════════════════════════════════
Total Credit = 
SUM(fact.GLTransaction[Credit])

// ═══════════════════════════════════════════════════════════════
// مانده (بدهکار - بستانکار)
// ═══════════════════════════════════════════════════════════════
Balance = 
[Total Debit] - [Total Credit]

// ═══════════════════════════════════════════════════════════════
// مانده بدهکار (اگر مثبت)
// ═══════════════════════════════════════════════════════════════
Debit Balance = 
IF([Balance] > 0, [Balance], 0)

// ═══════════════════════════════════════════════════════════════
// مانده بستانکار (اگر منفی)
// ═══════════════════════════════════════════════════════════════
Credit Balance = 
IF([Balance] < 0, -[Balance], 0)

// ═══════════════════════════════════════════════════════════════
// تعداد اسناد
// ═══════════════════════════════════════════════════════════════
Voucher Count = 
DISTINCTCOUNT(fact.GLTransaction[VoucherId])

// ═══════════════════════════════════════════════════════════════
// تعداد آرتیکل‌ها
// ═══════════════════════════════════════════════════════════════
Transaction Count = 
COUNTROWS(fact.GLTransaction)
```

## 4.2 Measures فروش (Sales)

```dax
// ═══════════════════════════════════════════════════════════════
// فروش کل (ناخالص)
// ═══════════════════════════════════════════════════════════════
Gross Sales = 
SUM(fact.Sales[GrossAmount])

// ═══════════════════════════════════════════════════════════════
// تخفیفات
// ═══════════════════════════════════════════════════════════════
Total Discount = 
SUM(fact.Sales[DiscountAmount])

// ═══════════════════════════════════════════════════════════════
// فروش خالص
// ═══════════════════════════════════════════════════════════════
Net Sales = 
SUM(fact.Sales[NetAmount])

// ═══════════════════════════════════════════════════════════════
// مالیات فروش
// ═══════════════════════════════════════════════════════════════
Sales Tax = 
SUM(fact.Sales[TaxAmount])

// ═══════════════════════════════════════════════════════════════
// تعداد فاکتور
// ═══════════════════════════════════════════════════════════════
Invoice Count = 
DISTINCTCOUNT(fact.Sales[InvoiceId])

// ═══════════════════════════════════════════════════════════════
// تعداد اقلام فروخته شده
// ═══════════════════════════════════════════════════════════════
Items Sold = 
SUM(fact.Sales[Quantity])

// ═══════════════════════════════════════════════════════════════
// میانگین ارزش فاکتور
// ═══════════════════════════════════════════════════════════════
Avg Invoice Value = 
DIVIDE([Net Sales], [Invoice Count], 0)

// ═══════════════════════════════════════════════════════════════
// تعداد مشتریان فعال
// ═══════════════════════════════════════════════════════════════
Active Customers = 
DISTINCTCOUNT(fact.Sales[CustomerKey])

// ═══════════════════════════════════════════════════════════════
// درصد تخفیف
// ═══════════════════════════════════════════════════════════════
Discount % = 
DIVIDE([Total Discount], [Gross Sales], 0)
```

## 4.3 Measures انبار (Inventory)

```dax
// ═══════════════════════════════════════════════════════════════
// موجودی (مقدار) - رسید منهای حواله
// ═══════════════════════════════════════════════════════════════
Stock Quantity = 
SUM(fact.Inventory[Quantity])

// ═══════════════════════════════════════════════════════════════
// موجودی (مبلغ)
// ═══════════════════════════════════════════════════════════════
Stock Value = 
SUM(fact.Inventory[Amount])

// ═══════════════════════════════════════════════════════════════
// مقدار رسید
// ═══════════════════════════════════════════════════════════════
Receipt Quantity = 
CALCULATE(
    SUM(fact.Inventory[AbsQuantity]),
    fact.Inventory[MovementType] = "Receipt"
)

// ═══════════════════════════════════════════════════════════════
// مقدار حواله
// ═══════════════════════════════════════════════════════════════
Delivery Quantity = 
CALCULATE(
    SUM(fact.Inventory[AbsQuantity]),
    fact.Inventory[MovementType] = "Delivery"
)

// ═══════════════════════════════════════════════════════════════
// تعداد رسیدها
// ═══════════════════════════════════════════════════════════════
Receipt Count = 
CALCULATE(
    DISTINCTCOUNT(fact.Inventory[DocumentId]),
    fact.Inventory[MovementType] = "Receipt"
)

// ═══════════════════════════════════════════════════════════════
// تعداد حواله‌ها
// ═══════════════════════════════════════════════════════════════
Delivery Count = 
CALCULATE(
    DISTINCTCOUNT(fact.Inventory[DocumentId]),
    fact.Inventory[MovementType] = "Delivery"
)

// ═══════════════════════════════════════════════════════════════
// نرخ گردش موجودی
// ═══════════════════════════════════════════════════════════════
Inventory Turnover = 
DIVIDE([Delivery Quantity], [Stock Quantity], 0)
```

## 4.4 Measures جریان نقدی (Cash Flow)

```dax
// ═══════════════════════════════════════════════════════════════
// جریان نقدی خالص (دریافت - پرداخت)
// ═══════════════════════════════════════════════════════════════
Net Cash Flow = 
SUM(fact.CashFlow[Amount])

// ═══════════════════════════════════════════════════════════════
// دریافت‌ها
// ═══════════════════════════════════════════════════════════════
Total Receipts = 
CALCULATE(
    SUM(fact.CashFlow[AbsAmount]),
    fact.CashFlow[FlowType] = "Receipt"
)

// ═══════════════════════════════════════════════════════════════
// پرداخت‌ها
// ═══════════════════════════════════════════════════════════════
Total Payments = 
CALCULATE(
    SUM(fact.CashFlow[AbsAmount]),
    fact.CashFlow[FlowType] = "Payment"
)

// ═══════════════════════════════════════════════════════════════
// دریافت نقدی
// ═══════════════════════════════════════════════════════════════
Cash Receipts = 
CALCULATE(
    SUM(fact.CashFlow[AbsAmount]),
    fact.CashFlow[FlowType] = "Receipt",
    fact.CashFlow[ItemType] = 0  -- نقد
)

// ═══════════════════════════════════════════════════════════════
// پرداخت نقدی
// ═══════════════════════════════════════════════════════════════
Cash Payments = 
CALCULATE(
    SUM(fact.CashFlow[AbsAmount]),
    fact.CashFlow[FlowType] = "Payment",
    fact.CashFlow[ItemType] = 0  -- نقد
)

// ═══════════════════════════════════════════════════════════════
// تعداد تراکنش دریافت
// ═══════════════════════════════════════════════════════════════
Receipt Transaction Count = 
CALCULATE(
    COUNTROWS(fact.CashFlow),
    fact.CashFlow[FlowType] = "Receipt"
)

// ═══════════════════════════════════════════════════════════════
// تعداد تراکنش پرداخت
// ═══════════════════════════════════════════════════════════════
Payment Transaction Count = 
CALCULATE(
    COUNTROWS(fact.CashFlow),
    fact.CashFlow[FlowType] = "Payment"
)
```

## 4.5 Measures چک (Cheque)

```dax
// ═══════════════════════════════════════════════════════════════
// مانده چک (دریافتی - پرداختی)
// ═══════════════════════════════════════════════════════════════
Net Cheque = 
SUM(fact.Cheque[Amount])

// ═══════════════════════════════════════════════════════════════
// چک‌های دریافتی
// ═══════════════════════════════════════════════════════════════
Receipt Cheques = 
CALCULATE(
    SUM(fact.Cheque[AbsAmount]),
    fact.Cheque[ChequeType] = "Receipt"
)

// ═══════════════════════════════════════════════════════════════
// چک‌های پرداختی
// ═══════════════════════════════════════════════════════════════
Payment Cheques = 
CALCULATE(
    SUM(fact.Cheque[AbsAmount]),
    fact.Cheque[ChequeType] = "Payment"
)

// ═══════════════════════════════════════════════════════════════
// چک‌های در جریان وصول
// ═══════════════════════════════════════════════════════════════
Pending Cheques = 
CALCULATE(
    SUM(fact.Cheque[AbsAmount]),
    fact.Cheque[ChequeType] = "Receipt",
    fact.Cheque[ChequeState] = 0  -- در جریان
)

// ═══════════════════════════════════════════════════════════════
// چک‌های وصول شده
// ═══════════════════════════════════════════════════════════════
Collected Cheques = 
CALCULATE(
    SUM(fact.Cheque[AbsAmount]),
    fact.Cheque[ChequeType] = "Receipt",
    fact.Cheque[ChequeState] = 1  -- وصول شده
)

// ═══════════════════════════════════════════════════════════════
// چک‌های برگشتی
// ═══════════════════════════════════════════════════════════════
Returned Cheques = 
CALCULATE(
    SUM(fact.Cheque[AbsAmount]),
    fact.Cheque[ChequeState] = 2  -- برگشتی
)

// ═══════════════════════════════════════════════════════════════
// تعداد چک دریافتی
// ═══════════════════════════════════════════════════════════════
Receipt Cheque Count = 
CALCULATE(
    COUNTROWS(fact.Cheque),
    fact.Cheque[ChequeType] = "Receipt"
)

// ═══════════════════════════════════════════════════════════════
// تعداد چک پرداختی
// ═══════════════════════════════════════════════════════════════
Payment Cheque Count = 
CALCULATE(
    COUNTROWS(fact.Cheque),
    fact.Cheque[ChequeType] = "Payment"
)

// ═══════════════════════════════════════════════════════════════
// چک‌های سررسید شده (با استفاده از رابطه غیرفعال)
// ═══════════════════════════════════════════════════════════════
Due Cheques Today = 
CALCULATE(
    SUM(fact.Cheque[AbsAmount]),
    USERELATIONSHIP(fact.Cheque[DueDateKey], 'dim.Date'[DateKey]),
    'dim.Date'[FullDate] = TODAY(),
    fact.Cheque[ChequeState] = 0
)

// ═══════════════════════════════════════════════════════════════
// چک‌های سررسید 7 روز آینده
// ═══════════════════════════════════════════════════════════════
Cheques Due Next 7 Days = 
CALCULATE(
    SUM(fact.Cheque[AbsAmount]),
    USERELATIONSHIP(fact.Cheque[DueDateKey], 'dim.Date'[DateKey]),
    'dim.Date'[FullDate] >= TODAY(),
    'dim.Date'[FullDate] <= TODAY() + 7,
    fact.Cheque[ChequeState] = 0
)
```

## 4.6 Time Intelligence Measures

```dax
// ═══════════════════════════════════════════════════════════════
// فروش ماه جاری
// ═══════════════════════════════════════════════════════════════
Sales MTD = 
TOTALMTD([Net Sales], 'dim.Date'[FullDate])

// ═══════════════════════════════════════════════════════════════
// فروش سال جاری
// ═══════════════════════════════════════════════════════════════
Sales YTD = 
TOTALYTD([Net Sales], 'dim.Date'[FullDate])

// ═══════════════════════════════════════════════════════════════
// فروش ماه قبل
// ═══════════════════════════════════════════════════════════════
Sales PM = 
CALCULATE(
    [Net Sales],
    PREVIOUSMONTH('dim.Date'[FullDate])
)

// ═══════════════════════════════════════════════════════════════
// فروش سال قبل
// ═══════════════════════════════════════════════════════════════
Sales PY = 
CALCULATE(
    [Net Sales],
    SAMEPERIODLASTYEAR('dim.Date'[FullDate])
)

// ═══════════════════════════════════════════════════════════════
// رشد فروش نسبت به ماه قبل
// ═══════════════════════════════════════════════════════════════
Sales MoM Growth = 
DIVIDE([Net Sales] - [Sales PM], [Sales PM], 0)

// ═══════════════════════════════════════════════════════════════
// رشد فروش نسبت به سال قبل
// ═══════════════════════════════════════════════════════════════
Sales YoY Growth = 
DIVIDE([Net Sales] - [Sales PY], [Sales PY], 0)

// ═══════════════════════════════════════════════════════════════
// میانگین متحرک 3 ماهه فروش
// ═══════════════════════════════════════════════════════════════
Sales 3M Avg = 
AVERAGEX(
    DATESINPERIOD('dim.Date'[FullDate], MAX('dim.Date'[FullDate]), -3, MONTH),
    [Net Sales]
)
```

## 4.7 Measures شمسی (Jalali)

```dax
// ═══════════════════════════════════════════════════════════════
// فروش ماه شمسی جاری
// ═══════════════════════════════════════════════════════════════
Sales JMonth = 
CALCULATE(
    [Net Sales],
    FILTER(
        ALL('dim.Date'),
        'dim.Date'[JYear] = MAX('dim.Date'[JYear]) &&
        'dim.Date'[JMonth] = MAX('dim.Date'[JMonth])
    )
)

// ═══════════════════════════════════════════════════════════════
// فروش سال شمسی جاری
// ═══════════════════════════════════════════════════════════════
Sales JYear = 
CALCULATE(
    [Net Sales],
    FILTER(
        ALL('dim.Date'),
        'dim.Date'[JYear] = MAX('dim.Date'[JYear])
    )
)

// ═══════════════════════════════════════════════════════════════
// فروش فصل شمسی جاری
// ═══════════════════════════════════════════════════════════════
Sales JQuarter = 
CALCULATE(
    [Net Sales],
    FILTER(
        ALL('dim.Date'),
        'dim.Date'[JYear] = MAX('dim.Date'[JYear]) &&
        'dim.Date'[JQuarter] = MAX('dim.Date'[JQuarter])
    )
)
```

---

# 5. داشبوردها

## 5.1 داشبورد مدیریتی (Executive Dashboard)

### KPI Cards:
- فروش خالص (Net Sales)
- سود ناخالص (اگر داده هزینه موجود باشد)
- جریان نقدی خالص (Net Cash Flow)
- موجودی انبار (Stock Value)

### نمودارها:
1. **روند فروش ماهانه** (Line Chart)
   - Axis: JMonthName از dim.Date
   - Values: Net Sales
   
2. **فروش به تفکیک مشتری** (Bar Chart)
   - Axis: FullName از dim.Party
   - Values: Net Sales
   - Top N: 10

3. **ترکیب دریافت و پرداخت** (Donut Chart)
   - Legend: FlowType
   - Values: AbsAmount

4. **وضعیت چک‌ها** (Stacked Bar)
   - Axis: ChequeStateName
   - Values: AbsAmount
   - Legend: ChequeType

### Slicers (فیلترها):
- سال مالی (FiscalYear)
- تاریخ شمسی (JDateString)
- مشتری (Party FullName)

---

## 5.2 داشبورد فروش (Sales Dashboard)

### KPI Cards:
- فروش خالص (Net Sales)
- تعداد فاکتور (Invoice Count)
- میانگین فاکتور (Avg Invoice Value)
- تعداد مشتری فعال (Active Customers)
- درصد تخفیف (Discount %)

### نمودارها:
1. **روند فروش روزانه** (Area Chart)
   - Axis: FullDate
   - Values: Net Sales

2. **فروش به تفکیک کالا** (Treemap)
   - Group: Title از dim.Item
   - Values: Net Sales

3. **فروش به تفکیک مشتری** (Bar Chart)
   - Axis: FullName
   - Values: Net Sales
   - Sorted: Descending

4. **مقایسه فروش ماهانه** (Clustered Column)
   - Axis: JMonthName
   - Values: Net Sales (سال جاری), Sales PY (سال قبل)

5. **جدول جزئیات فاکتور** (Table)
   - InvoiceNumber, InvoiceDate, Customer, Net Sales

### Slicers:
- تاریخ (Date Range)
- کالا (Item)
- مشتری (Party)
- انبار (Stock)

---

## 5.3 داشبورد انبار (Inventory Dashboard)

### KPI Cards:
- موجودی کل (Stock Quantity)
- ارزش موجودی (Stock Value)
- تعداد رسید (Receipt Count)
- تعداد حواله (Delivery Count)

### نمودارها:
1. **موجودی به تفکیک کالا** (Bar Chart)
   - Axis: Title از dim.Item
   - Values: Stock Quantity

2. **موجودی به تفکیک انبار** (Pie Chart)
   - Legend: Title از dim.Stock
   - Values: Stock Value

3. **روند ورود/خروج** (Line Chart)
   - Axis: FullDate
   - Values: Receipt Quantity, Delivery Quantity

4. **کاردکس کالا** (Table)
   - Date, MovementType, Quantity, Amount
   - فیلتر: یک کالای خاص

### Slicers:
- کالا (Item)
- انبار (Stock)
- تاریخ (Date Range)
- نوع حرکت (MovementType)

---

## 5.4 داشبورد خزانه‌داری (Treasury Dashboard)

### KPI Cards:
- جریان نقدی خالص (Net Cash Flow)
- دریافت‌ها (Total Receipts)
- پرداخت‌ها (Total Payments)
- چک در جریان (Pending Cheques)

### نمودارها:
1. **جریان نقدی ماهانه** (Waterfall Chart)
   - Category: JMonthName
   - Values: Net Cash Flow

2. **ترکیب دریافت‌ها** (Donut Chart)
   - Legend: ItemTypeName
   - Values: AbsAmount (فیلتر: Receipt)

3. **وضعیت چک‌های دریافتی** (Funnel Chart)
   - Group: ChequeStateName
   - Values: AbsAmount

4. **چک‌های سررسید نزدیک** (Table)
   - ChequeNumber, DueDate, Amount, PartyName
   - فیلتر: سررسید 30 روز آینده

5. **روند دریافت و پرداخت** (Dual-axis Line Chart)
   - Axis: FullDate
   - Values: Total Receipts, Total Payments

### Slicers:
- تاریخ (Date Range)
- نوع تراکنش (FlowType)
- روش (ItemTypeName)
- طرف حساب (Party)

---

## 5.5 داشبورد حسابداری (GL Dashboard)

### KPI Cards:
- جمع بدهکار (Total Debit)
- جمع بستانکار (Total Credit)
- تعداد سند (Voucher Count)
- تعداد آرتیکل (Transaction Count)

### نمودارها:
1. **مانده حساب‌های سطح 1** (Bar Chart)
   - Axis: L1_Title
   - Values: Balance

2. **روند ثبت اسناد** (Line Chart)
   - Axis: FullDate
   - Values: Voucher Count

3. **تراکنش به تفکیک نوع سند** (Pie Chart)
   - Legend: VoucherTypeName
   - Values: Transaction Count

4. **تراز آزمایشی** (Matrix)
   - Rows: Account Hierarchy (L1 → L2 → L3)
   - Values: Debit Balance, Credit Balance

### Slicers:
- سال مالی (FiscalYear)
- تاریخ (Date Range)
- حساب (Account)
- وضعیت سند (VoucherStateName)

---

# 6. نکات بهینه‌سازی

## 6.1 Performance

1. **Import Mode استفاده کنید** (نه DirectQuery)
2. **فقط ستون‌های لازم را وارد کنید**
3. **Relationship ها را Single Direction نگه دارید**
4. **از Integer Keys استفاده کنید** (نه String)

## 6.2 تنظیمات پیشنهادی

```
Power BI Options → Data Load:
  ☑ Auto date/time OFF
  ☑ Background data OFF
```

## 6.3 Refresh Schedule

- **روزانه**: یک بار در شب
- **یا**: Incremental Refresh برای جداول بزرگ

---

# پایان مستندات
================================================================================
