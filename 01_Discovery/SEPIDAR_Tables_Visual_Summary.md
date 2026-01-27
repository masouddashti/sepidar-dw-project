# 📊 SEPIDAR - Dimension & Fact Tables Classification

## 📁 DIMENSION TABLES (جداول بُعد)

### ⭐⭐⭐ Critical Dimensions

| جدول | ماژول | تعداد | توضیح |
|-------|-------|-------|--------|
| **DimDate** | BAS | 25,194 | تاریخ (اکسل خارجی) |
| **Account** | FIN | 343 | حساب‌های معین |
| **Party** | BAS | 181 | طرف حساب (مشتری/تامین‌کننده) |
| **Item** | INV | 20 | کالا |
| **Stock** | INV | 4 | انبار |

### ⭐⭐ Important Dimensions

| جدول | ماژول | تعداد | توضیح |
|-------|-------|-------|--------|
| AccountTopic | FIN | 268 | سرفصل حساب |
| AccountType | FIN | 10 | نوع حساب |
| DL | FIN | 190 | تفصیلی |
| FiscalYear | FIN | 3 | سال مالی |
| ItemCategory | INV | 42 | گروه کالا |
| Unit | INV | 4 | واحد اندازه‌گیری |
| Bank | CSH | 33 | بانک |
| BankAccount | CSH | 3 | حساب بانکی |
| Currency | BAS | 6 | ارز |
| Personnel | HR | 51 | پرسنل |

### ⭐ Supporting Dimensions

| جدول | ماژول | تعداد | توضیح |
|-------|-------|-------|--------|
| Topic | FIN | 29 | سرفصل |
| CostCenter | FIN | 4 | مرکز هزینه |
| PartyAddress | BAS | 56 | آدرس طرف حساب |
| PartyPhone | BAS | 5 | تلفن |
| ItemStock | INV | 19 | موجودی کالا |
| ItemStockSummary | INV | 50 | خلاصه موجودی |
| BankBranch | CSH | 3 | شعبه بانک |
| Cash | CSH | 2 | صندوق |
| PettyCash | CSH | 7 | تنخواه |
| Branch | BAS | 2 | شعبه |
| Emplacement | BAS | 6 | محل استقرار |
| Location | BAS | 7,636 | مکان |
| DeliveryLocation | BAS | 2 | محل تحویل |
| Job | HR | 8 | شغل |
| Element | HR | 237 | عناصر حقوقی |
| ElementItem | HR | 154 | اقلام عناصر |
| SaleType | SAL | 3 | نوع فروش |
| Commission | SAL | 2 | کمیسیون |
| CommissionBroker | SAL | 2 | واسطه |
| TaxGroup | TAX | 3 | گروه مالیاتی |
| TaxTable | TAX | 63 | جدول مالیات |
| TaxTableItem | TAX | 217 | اقلام مالیات |
| AssetClass | AST | 6 | طبقه دارایی |
| AssetGroup | AST | 9 | گروه دارایی |
| DepreciationRule | AST | 169 | قانون استهلاک |
| Contract | CNT | 51 | قرارداد |
| ContractElement | CNT | 213 | عناصر قرارداد |
| Lookup | SYS | 1,487 | لوکاپ‌ها |
| Coefficient | BAS | 7 | ضرایب |

**مجموع Dimensions: ~38 جدول**

---

## 📊 FACT TABLES (جداول فکت)

### ⭐⭐⭐ Critical Facts

| جدول | ماژول | تعداد | Grain | توضیح |
|-------|-------|-------|-------|--------|
| **Voucher** | FIN | 5,238 | هر سند | سند حسابداری (Header) |
| **VoucherItem** | FIN | 13,441 | هر ردیف سند | اقلام سند (Detail) ⭐ |
| **Invoice** | SAL | 150 | هر فاکتور | فاکتور فروش (Header) |
| **InvoiceItem** | SAL | 201 | هر ردیف | اقلام فاکتور (Detail) |
| **InventoryReceipt** | INV | 1,882 | هر رسید | رسید انبار (Header) |
| **InventoryReceiptItem** | INV | 2,046 | هر ردیف | اقلام رسید (Detail) |
| **InventoryDelivery** | INV | 162 | هر حواله | حواله انبار (Header) |
| **InventoryDeliveryItem** | INV | 240 | هر ردیف | اقلام حواله (Detail) |
| **PaymentHeader** | CSH | 2,194 | هر پرداخت | پرداخت |
| **ReceiptHeader** | CSH | 345 | هر دریافت | دریافت |
| **PaymentCheque** | CHQ | 213 | هر چک | چک پرداختی |
| **ReceiptCheque** | CHQ | 210 | هر چک | چک دریافتی |
| **Calculation** | HR | 18,512 | هر محاسبه | محاسبات حقوق |

### ⭐⭐ Important Facts

| جدول | ماژول | تعداد | توضیح |
|-------|-------|-------|--------|
| Quotation | SAL | 42 | پیش فاکتور |
| QuotationItem | SAL | 74 | اقلام پیش فاکتور |
| InvoiceCommissionBroker | SAL | 105 | کمیسیون فاکتور |
| PaymentDraft | CSH | 2,140 | پیش‌نویس پرداخت |
| ReceiptDraft | CSH | 261 | پیش‌نویس دریافت |
| PaymentChequeBanking | CHQ | 97 | عملیات بانکی چک |
| PaymentChequeHistory | CHQ | 367 | تاریخچه چک |
| ReceiptChequeBanking | CHQ | 175 | عملیات بانکی چک |
| ReceiptChequeHistory | CHQ | 511 | تاریخچه چک |
| InventoryPricingVoucher | INV | 805 | سند قیمت‌گذاری |
| PartyAccountSettlement | FIN | 31 | تسویه حساب |
| PartyAccountSettlementItem | FIN | 224 | اقلام تسویه |
| PartyOpeningBalance | FIN | 596 | مانده افتتاحیه |
| DebitCreditNote | FIN | 194 | اعلامیه بدهکار/بستانکار |
| DebitCreditNoteItem | FIN | 291 | اقلام اعلامیه |
| MonthlyDataPersonnel | HR | 187 | داده ماهانه پرسنل |
| MonthlyDataPersonnelElement | HR | 1,683 | عناصر ماهانه |
| PricingItemPrice | SAL | 427 | قیمت کالا |

### ⭐ Supporting Facts

| جدول | ماژول | تعداد | توضیح |
|-------|-------|-------|--------|
| ReturnedInvoice | SAL | 3 | برگشت از فروش |
| ReturnedInvoiceItem | SAL | 5 | اقلام برگشت |
| InventoryPurchaseInvoice | PRC | 4 | فاکتور خرید |
| InventoryPurchaseInvoiceItem | PRC | 6 | اقلام خرید |
| ReceiptPettyCash | CSH | 143 | دریافت تنخواه |
| PettyCashBill | CSH | 80 | صورتحساب تنخواه |
| PettyCashBillItem | CSH | 1,104 | اقلام تنخواه |
| RefundCheque | CHQ | 29 | چک برگشتی |
| RefundChequeItem | CHQ | 51 | اقلام چک برگشتی |
| PaymentChequeBankingItem | CHQ | 107 | اقلام عملیات |
| ReceiptChequeBankingItem | CHQ | 264 | اقلام عملیات |
| PaymentChequeOther | CHQ | 33 | سایر چک |
| InventoryPricingVoucherItem | INV | 88 | اقلام قیمت‌گذاری |
| TaxPayerBill | TAX | 107 | صورتحساب مودیان |
| TaxPayerBillItem | TAX | 115 | اقلام مودیان |
| CommissionCalculation | SAL | 4 | محاسبه کمیسیون |
| CommissionCalculationInvoice | SAL | 144 | فاکتور کمیسیون |

**مجموع Facts: ~45 جدول**

---

## 📈 Star Schema Overview

```
                    ┌─────────────┐
                    │  dim.Date   │
                    └──────┬──────┘
                           │
┌─────────────┐    ┌───────┴───────┐    ┌─────────────┐
│ dim.Account │────│               │────│  dim.Party  │
└─────────────┘    │ fact.Voucher  │    └─────────────┘
                   │    Item       │
┌─────────────┐    │               │    ┌─────────────┐
│   dim.DL    │────│   (13,441)    │────│dim.CostCenter│
└─────────────┘    └───────────────┘    └─────────────┘


                    ┌─────────────┐
                    │  dim.Date   │
                    └──────┬──────┘
                           │
┌─────────────┐    ┌───────┴───────┐    ┌─────────────┐
│  dim.Party  │────│               │────│  dim.Item   │
│ (Customer)  │    │  fact.Sales   │    └─────────────┘
└─────────────┘    │    (201)      │    
                   │               │    ┌─────────────┐
                   └───────────────┘────│  dim.Stock  │
                                        └─────────────┘
```

---

## 📋 Summary

| Category | Count | Total Rows |
|----------|-------|------------|
| **Dimension Tables** | 38 | ~36,000 |
| **Fact Tables** | 45 | ~55,000 |
| **Total for Synonym** | **83** | **~91,000** |

---

## ✅ Next Steps

1. ایجاد اسکریپت Synonym برای 83 جدول
2. شروع با ماژول BAS (اطلاعات پایه)
3. سپس FIN → SAL → INV → CSH → CHQ → HR

آیا این دسته‌بندی تأیید می‌شه؟ 🚀
