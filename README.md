# SEPIDAR Data Warehouse Project

## 📋 ترتیب اجرای اسکریپت‌ها (مهم!)

### مرحله 1: Setup (اجباری - اول اجرا شود)
```sql
-- 1. ایجاد دیتابیس و Schema‌ها
00_Setup/01_Create_Database_Structure.sql

-- 2. ایجاد جداول متادیتا
00_Setup/02_Create_Metadata_Tables.sql

-- 3. ایجاد پروسیجرهای Synonym
00_Setup/03_Create_Synonym_Procedures.sql
```

### مرحله 2: Synonyms
```sql
-- 1. ایجاد Synonym‌ها (اسم دیتابیس رو تغییر بده!)
02_Synonyms/01_Create_Synonyms_All.sql

-- 2. پروسیجرهای کمکی
02_Synonyms/02_Synonym_Utilities.sql

-- 3. ثبت در TableMapping
02_Synonyms/03_Populate_TableMapping.sql
```

## پروژه انبار داده سپیدار

---

## 📁 ساختار پوشه‌ها

```
sepidar-dw-project/
│
├── 00_Setup/                          # راه‌اندازی اولیه
│   ├── 01_Create_Database_Structure.sql   # ایجاد دیتابیس و Schema‌ها
│   ├── 02_Create_Metadata_Tables.sql      # جداول متادیتا و تنظیمات
│   └── 03_Create_Synonym_Procedures.sql   # پروسیجرهای مدیریت Synonym
│
├── 01_Discovery/                      # شناسایی و تحلیل داده‌ها
│   ├── Source_Tables_List.sql            # لیست جداول سپیدار
│   ├── Table_Analysis.sql                # تحلیل ساختار جداول
│   └── Data_Profiling.sql                # پروفایلینگ داده‌ها
│
├── 02_Mapping/                        # نگاشت جداول
│   ├── Table_Classification.sql          # دسته‌بندی جداول به ماژول‌ها
│   ├── Create_Synonyms.sql               # ایجاد Synonym‌ها
│   └── Module_[XXX]_Mapping.sql          # نگاشت هر ماژول
│
├── 03_Dimensions/                     # جداول Dimension
│   ├── dim.Date.sql                      # بُعد تاریخ
│   ├── dim.Customer.sql                  # بُعد مشتری
│   ├── dim.Product.sql                   # بُعد کالا
│   └── ...
│
├── 04_Facts/                          # جداول Fact
│   ├── fact.Sales.sql                    # فکت فروش
│   ├── fact.Inventory.sql                # فکت انبار
│   └── ...
│
├── 05_ETL/                            # پروسیجرهای ETL
│   ├── etl.Load_Dim_[Name].sql           # لود Dimension‌ها
│   ├── etl.Load_Fact_[Name].sql          # لود Fact‌ها
│   └── etl.Master_Load.sql               # پروسیجر اصلی ETL
│
├── 06_Marts/                          # Data Mart Views
│   ├── mart.Financial_Summary.sql
│   ├── mart.Sales_Analysis.sql
│   └── ...
│
├── 07_Reports/                        # ویوهای گزارشی (Power BI)
│   ├── rpt.Executive_KPIs.sql
│   ├── rpt.Financial_Dashboard.sql
│   └── ...
│
├── 99_Documentation/                  # مستندات
│   ├── Data_Dictionary.md                # دیکشنری داده‌ها
│   ├── Module_Descriptions.md            # شرح ماژول‌ها
│   └── ERD/                              # نمودارهای ER
│
└── README.md                          # این فایل
```

---

## 🔧 نحوه استفاده

### مرحله 1: راه‌اندازی اولیه
```sql
-- به ترتیب اجرا کنید:
:r 00_Setup/01_Create_Database_Structure.sql
:r 00_Setup/02_Create_Metadata_Tables.sql
:r 00_Setup/03_Create_Synonym_Procedures.sql
```

### مرحله 2: تنظیم Source Database
```sql
-- نام دیتابیس سپیدار را تنظیم کنید:
UPDATE meta.SourceConfig 
SET ConfigValue = 'YourSepidarDB'  -- نام واقعی دیتابیس
WHERE ConfigKey = 'SourceDatabaseName';
```

### مرحله 3: ایجاد Synonym‌ها
```sql
-- بعد از پر کردن meta.TableMapping
EXEC etl.usp_CreateAllSynonyms;
```

---

## 📊 Schema‌ها

| Schema | کاربرد | توضیحات |
|--------|--------|---------|
| `src` | Source Synonyms | اشاره به جداول دیتابیس مبدا |
| `stg` | Staging | جداول موقت برای پردازش ETL |
| `dim` | Dimensions | جداول بُعد (Master Data) |
| `fact` | Facts | جداول فکت (تراکنش‌ها) |
| `mart` | Data Marts | ویوهای تجمیعی |
| `etl` | ETL Procedures | پروسیجرهای ETL |
| `meta` | Metadata | تنظیمات و متادیتا |
| `rpt` | Reports | ویوهای گزارشی Power BI |

---

## 📦 ماژول‌ها

| کد | نام انگلیسی | نام فارسی |
|----|-------------|-----------|
| SYS | System | سیستم |
| BAS | Base Data | اطلاعات پایه |
| FIN | Financial | مالی |
| SAL | Sales | فروش |
| INV | Inventory | انبار |
| PRC | Procurement | خرید |
| CSH | Cash & Treasury | خزانه |
| CHQ | Cheque | چک |

---

## 🔄 فازهای پروژه

- [x] **فاز 0**: راه‌اندازی ساختار
- [ ] **فاز 1**: شناسایی جداول سپیدار
- [ ] **فاز 2**: دسته‌بندی و Synonym
- [ ] **فاز 3**: ساخت Dimensions
- [ ] **فاز 4**: ساخت Facts
- [ ] **فاز 5**: ETL Procedures
- [ ] **فاز 6**: Data Marts
- [ ] **فاز 7**: Power BI Reports

---

## 📝 نکات مهم

1. **قبل از اجرا** روی سرور Production، حتماً روی محیط Test تست کنید
2. **Synonym‌ها** امکان تغییر سریع دیتابیس مبدا را فراهم می‌کنند
3. **ETL Log** را مرتب بررسی کنید برای شناسایی خطاها
4. **Incremental Load** را برای جداول بزرگ فعال کنید

---

*آخرین بروزرسانی: January 2026*
