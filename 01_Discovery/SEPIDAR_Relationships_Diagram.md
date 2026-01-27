# 🔗 SEPIDAR - Entity Relationships & Star Schema

## 📊 Key Findings from Column Analysis

### Statistics
- **Total Tables Analyzed**: 29
- **Total Columns**: 669
- **Average Columns per Table**: 23

### Largest Tables (by columns)
| Table | Columns | Type |
|-------|---------|------|
| Invoice | 79 | Fact |
| InvoiceItem | 60 | Fact |
| InventoryReceiptItem | 42 | Fact |
| Party | 41 | Dimension |
| Item | 38 | Dimension |

---

## 🔑 Primary Keys Pattern

همه جداول از الگوی **`[TableName]Id`** پیروی می‌کنند:

| Table | Primary Key |
|-------|-------------|
| Account | AccountId |
| Party | PartyId |
| Item | ItemID |
| Voucher | VoucherId |
| Invoice | InvoiceId |
| Stock | StockID |

---

## 🔗 Foreign Keys Pattern

الگوی **`[TableName]Ref`** برای FK استفاده شده:

| Column Pattern | References |
|----------------|------------|
| `PartyRef` | Party.PartyId |
| `ItemRef` | Item.ItemID |
| `StockRef` | Stock.StockID |
| `VoucherRef` | Voucher.VoucherId |
| `CurrencyRef` | Currency.CurrencyID |
| `FiscalYearRef` | FiscalYear.FiscalYearId |
| `DLRef` | DL.DLId |
| `AccountSLRef` | Account.AccountId |

---

## ⭐ Star Schema Design

```
                                    ┌──────────────────┐
                                    │    dim.Date      │
                                    │  (از اکسل)       │
                                    └────────┬─────────┘
                                             │
        ┌────────────────┐          ┌────────┴─────────┐          ┌────────────────┐
        │  dim.Account   │          │                  │          │   dim.Party    │
        │    (343)       │──────────│ fact.GLTransaction│──────────│    (181)       │
        │  AccountId     │          │    (13,441)      │          │   PartyId      │
        │  Code, Title   │          │                  │          │  Name, Type    │
        └────────────────┘          │  Debit, Credit   │          └────────────────┘
                                    │  Amount          │
        ┌────────────────┐          │                  │          ┌────────────────┐
        │    dim.DL      │──────────│                  │──────────│ dim.FiscalYear │
        │    (190)       │          └──────────────────┘          │     (3)        │
        │  DLId, Code    │                                        │  StartDate     │
        └────────────────┘                                        └────────────────┘
                                             │
                                    ┌────────┴─────────┐
                                    │  dim.Currency    │
                                    │      (6)         │
                                    └──────────────────┘


                                    ┌──────────────────┐
                                    │    dim.Date      │
                                    └────────┬─────────┘
                                             │
        ┌────────────────┐          ┌────────┴─────────┐          ┌────────────────┐
        │   dim.Party    │          │                  │          │   dim.Item     │
        │  (Customer)    │──────────│   fact.Sales     │──────────│    (20)        │
        │   PartyId      │          │     (201)        │          │   ItemID       │
        │   IsCustomer=1 │          │                  │          │  Code, Title   │
        └────────────────┘          │  Qty, Fee        │          └────────────────┘
                                    │  Price, Tax      │
        ┌────────────────┐          │  Discount        │          ┌────────────────┐
        │   dim.Stock    │──────────│  NetPrice        │──────────│ dim.Currency   │
        │     (4)        │          └──────────────────┘          │     (6)        │
        └────────────────┘                                        └────────────────┘


                                    ┌──────────────────┐
                                    │    dim.Date      │
                                    └────────┬─────────┘
                                             │
        ┌────────────────┐          ┌────────┴─────────┐          ┌────────────────┐
        │   dim.Item     │          │                  │          │   dim.Stock    │
        │    (20)        │──────────│fact.InventoryRcpt│──────────│     (4)        │
        │   ItemID       │          │    (2,046)       │          │   StockID      │
        └────────────────┘          │                  │          └────────────────┘
                                    │  Qty, Price      │
        ┌────────────────┐          │  Tax, Duty       │          ┌────────────────┐
        │   dim.Party    │──────────│  NetPrice        │──────────│ dim.Currency   │
        │  (Deliverer)   │          └──────────────────┘          │     (6)        │
        └────────────────┘                                        └────────────────┘
```

---

## 📋 Dimension to Fact Mapping

### dim.Account → Facts
| Fact Table | FK Column | Usage |
|------------|-----------|-------|
| fact.GLTransaction | AccountSLRef | Account for GL entry |
| fact.Payment | AccountSlRef | Settlement account |
| fact.Receipt | AccountSlRef | Settlement account |

### dim.Party → Facts
| Fact Table | FK Column | Usage |
|------------|-----------|-------|
| fact.Sales | CustomerPartyRef | Customer |
| fact.InventoryReceipt | DelivererDLRef → Party | Supplier/Deliverer |
| fact.Payment | DlRef → Party | Payee |
| fact.Receipt | DlRef → Party | Payer |
| fact.PaymentCheque | DlRef → Party | Payee |
| fact.ReceiptCheque | DlRef → Party | Cheque issuer |

### dim.Item → Facts
| Fact Table | FK Column | Usage |
|------------|-----------|-------|
| fact.Sales | ItemRef | Sold item |
| fact.InventoryReceipt | ItemRef | Received item |
| fact.InventoryDelivery | ItemRef | Delivered item |

### dim.Stock → Facts
| Fact Table | FK Column | Usage |
|------------|-----------|-------|
| fact.Sales | StockRef | Source warehouse |
| fact.InventoryReceipt | StockRef | Destination warehouse |
| fact.InventoryDelivery | StockRef | Source warehouse |
| fact.InventoryDelivery | DestinationStockRef | Destination warehouse |

### dim.Currency → Facts
| Fact Table | FK Column | Usage |
|------------|-----------|-------|
| fact.GLTransaction | CurrencyRef | Transaction currency |
| fact.Sales | CurrencyRef | Invoice currency |
| fact.InventoryReceipt | CurrencyRef | Receipt currency |
| fact.Payment | CurrencyRef | Payment currency |
| fact.Receipt | CurrencyRef | Receipt currency |
| fact.PaymentCheque | CurrencyRef | Cheque currency |
| fact.ReceiptCheque | CurrencyRef | Cheque currency |

### dim.FiscalYear → Facts
| Fact Table | FK Column | Usage |
|------------|-----------|-------|
| All Facts | FiscalYearRef | Fiscal period |

---

## 🔄 Important Relationships

### Party ↔ DL (تفصیلی)
```
Party.DLRef → DL.DLId
```
- هر طرف حساب یک تفصیلی در حسابداری دارد
- این رابطه برای گزارشات مالی حیاتی است

### Voucher ↔ Source Documents
```
Invoice.VoucherRef → Voucher.VoucherId
PaymentHeader.VoucherRef → Voucher.VoucherId
ReceiptHeader.VoucherRef → Voucher.VoucherId
InventoryReceipt.AccountingVoucherRef → Voucher.VoucherId
```
- همه اسناد تجاری یک سند حسابداری تولید می‌کنند
- `IssuerEntityName` در VoucherItem نوع سند مبدا را مشخص می‌کند

### Account Hierarchy
```
Account.ParentAccountRef → Account.AccountId (Self-reference)
```
- ساختار درختی: گروه → کل → معین
- نیاز به محاسبه Level و Path در ETL

---

## 📝 ETL Notes

### Common Audit Columns (در همه جداول)
- `Creator` - کاربر ایجادکننده
- `CreationDate` - تاریخ ایجاد
- `LastModifier` - آخرین ویرایشگر
- `LastModificationDate` - تاریخ آخرین ویرایش
- `Version` - نسخه رکورد

### Status/State Codes
| Value | Voucher | Invoice | Cheque |
|-------|---------|---------|--------|
| 0 | Draft | Draft | Issued |
| 1 | Confirmed | Confirmed | Cashed |
| 2 | Posted | - | Returned |
| 3 | - | - | Cancelled |
| 9 | Cancelled | Cancelled | - |

### Type Codes in Party
| Field | Value | Meaning |
|-------|-------|---------|
| Type | 0 | Legal (حقوقی) |
| Type | 1 | Real (حقیقی) |
| IsCustomer | 1 | Is a customer |
| IsVendor | 1 | Is a supplier |
| IsBroker | 1 | Is a broker |
| IsEmployee | 1 | Is an employee |

---

## ✅ Ready for Next Phase

با این تحلیل، آماده‌ایم برای:
1. ✅ ساخت Synonym‌ها
2. ✅ ساخت dim.Date از اکسل
3. ✅ ساخت سایر Dimensions
4. ✅ ساخت Fact Tables
5. ✅ ETL Procedures
