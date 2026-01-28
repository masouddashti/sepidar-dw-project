/*
===============================================================================
SEPIDAR Data Warehouse Project
Phase 4: Load Fact Tables
===============================================================================
Script: 02_Load_Fact_Tables.sql
Purpose: ETL procedures to load fact tables from SEPIDAR
Author: BI Team
Version: 1.0
Date: January 2026
===============================================================================
*/

USE DW_DB;
GO

-- ============================================================================
-- Load fact.GLTransaction
-- ============================================================================
CREATE OR ALTER PROCEDURE etl.usp_Load_Fact_GLTransaction
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RowsInserted INT = 0;
    
    -- Clear and reload (full load for now)
    TRUNCATE TABLE fact.GLTransaction;
    
    INSERT INTO fact.GLTransaction (
        DateKey, AccountKey, DLKey, CurrencyKey, FiscalYearKey,
        VoucherId, VoucherNumber, VoucherDate, VoucherType, VoucherTypeName,
        VoucherState, VoucherStateName, DailyNumber,
        VoucherItemId, RowNumber,
        Debit, Credit, CurrencyRate, CurrencyDebit, CurrencyCredit,
        TrackingNumber, TrackingDate, IssuerEntityName, IssuerEntityId,
        Description
    )
    SELECT 
        -- Dimension Keys
        ISNULL(d.DateKey, -1) AS DateKey,
        ISNULL(a.AccountKey, -1) AS AccountKey,
        ISNULL(dl.DLKey, -1) AS DLKey,
        ISNULL(c.CurrencyKey, -1) AS CurrencyKey,
        ISNULL(fy.FiscalYearKey, -1) AS FiscalYearKey,
        
        -- Voucher Header
        v.VoucherId,
        v.Number AS VoucherNumber,
        CAST(v.Date AS DATE) AS VoucherDate,
        v.Type AS VoucherType,
        CASE v.Type
            WHEN 0 THEN N'عادی'
            WHEN 1 THEN N'افتتاحیه'
            WHEN 2 THEN N'اختتامیه'
            WHEN 3 THEN N'بستن حساب'
            WHEN 4 THEN N'تعدیل'
            ELSE N'سایر'
        END AS VoucherTypeName,
        v.State AS VoucherState,
        CASE v.State
            WHEN 0 THEN N'موقت'
            WHEN 1 THEN N'دائم'
            WHEN 2 THEN N'قطعی'
            ELSE N'نامشخص'
        END AS VoucherStateName,
        v.DailyNumber,
        
        -- Voucher Item
        vi.VoucherItemId,
        vi.RowNumber,
        
        -- Measures
        vi.Debit,
        vi.Credit,
        vi.CurrencyRate,
        vi.CurrencyDebit,
        vi.CurrencyCredit,
        
        -- Tracking
        vi.TrackingNumber,
        CAST(vi.TrackingDate AS DATE) AS TrackingDate,
        vi.IssuerEntityName,
        vi.IssuerEntityRef AS IssuerEntityId,
        
        -- Description
        vi.Description
        
    FROM src.Voucher v
    INNER JOIN src.VoucherItem vi ON v.VoucherId = vi.VoucherRef
    LEFT JOIN dim.Date d ON CAST(v.Date AS DATE) = d.FullDate
    LEFT JOIN dim.Account a ON vi.AccountSLRef = a.AccountId
    LEFT JOIN dim.DL dl ON vi.DLRef = dl.DLId
    LEFT JOIN dim.Currency c ON vi.CurrencyRef = c.CurrencyId
    LEFT JOIN dim.FiscalYear fy ON v.FiscalYearRef = fy.FiscalYearId;
    
    SET @RowsInserted = @@ROWCOUNT;
    PRINT 'fact.GLTransaction loaded: ' + CAST(@RowsInserted AS VARCHAR(20)) + ' rows';
END;
GO


-- ============================================================================
-- Load fact.Sales
-- ============================================================================
CREATE OR ALTER PROCEDURE etl.usp_Load_Fact_Sales
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RowsInserted INT = 0;
    
    TRUNCATE TABLE fact.Sales;
    
    INSERT INTO fact.Sales (
        DateKey, CustomerKey, ItemKey, StockKey, CurrencyKey, FiscalYearKey, SalespersonKey,
        InvoiceId, InvoiceNumber, InvoiceDate, InvoiceState, InvoiceStateName, SaleType,
        InvoiceItemId, RowNumber,
        Quantity, SecondaryQuantity,
        UnitPrice, GrossAmount, DiscountAmount, AdditionAmount, TaxAmount, DutyAmount, NetAmount,
        GrossAmountBase, DiscountAmountBase, NetAmountBase,
        CurrencyRate, Description
    )
    SELECT 
        -- Dimension Keys
        ISNULL(d.DateKey, -1) AS DateKey,
        ISNULL(p.PartyKey, -1) AS CustomerKey,
        ISNULL(it.ItemKey, -1) AS ItemKey,
        ISNULL(st.StockKey, -1) AS StockKey,
        ISNULL(c.CurrencyKey, -1) AS CurrencyKey,
        ISNULL(fy.FiscalYearKey, -1) AS FiscalYearKey,
        sp.PartyKey AS SalespersonKey,
        
        -- Invoice Header
        i.InvoiceId,
        i.Number AS InvoiceNumber,
        CAST(i.Date AS DATE) AS InvoiceDate,
        i.State AS InvoiceState,
        CASE i.State
            WHEN 0 THEN N'پیش‌نویس'
            WHEN 1 THEN N'تأیید شده'
            WHEN 2 THEN N'ابطال'
            ELSE N'نامشخص'
        END AS InvoiceStateName,
        i.SaleTypeRef AS SaleType,
        
        -- Invoice Item
        ii.InvoiceItemID AS InvoiceItemId,
        ii.RowID AS RowNumber,
        
        -- Quantities
        ii.Quantity,
        ii.SecondaryQuantity,
        
        -- Prices
        ii.Fee AS UnitPrice,
        ii.Price AS GrossAmount,
        ii.Discount AS DiscountAmount,
        ii.Addition AS AdditionAmount,
        ii.Tax AS TaxAmount,
        ii.Duty AS DutyAmount,
        ii.NetPrice AS NetAmount,
        
        -- Base Currency
        ii.PriceInBaseCurrency AS GrossAmountBase,
        ii.DiscountInBaseCurrency AS DiscountAmountBase,
        ii.NetPriceInBaseCurrency AS NetAmountBase,
        
        -- Currency
        ii.Rate AS CurrencyRate,
        
        -- Description
        ii.Description
        
    FROM src.Invoice i
    INNER JOIN src.InvoiceItem ii ON i.InvoiceId = ii.InvoiceRef
    LEFT JOIN dim.Date d ON CAST(i.Date AS DATE) = d.FullDate
    LEFT JOIN dim.Party p ON i.CustomerPartyRef = p.PartyId
    LEFT JOIN dim.Item it ON ii.ItemRef = it.ItemId
    LEFT JOIN dim.Stock st ON ii.StockRef = st.StockId
    LEFT JOIN dim.Currency c ON i.CurrencyRef = c.CurrencyId
    LEFT JOIN dim.FiscalYear fy ON i.FiscalYearRef = fy.FiscalYearId
    LEFT JOIN dim.Party sp ON p.SalespersonId = sp.PartyId;
    
    SET @RowsInserted = @@ROWCOUNT;
    PRINT 'fact.Sales loaded: ' + CAST(@RowsInserted AS VARCHAR(20)) + ' rows';
END;
GO


-- ============================================================================
-- Load fact.Inventory
-- ============================================================================
CREATE OR ALTER PROCEDURE etl.usp_Load_Fact_Inventory
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RowsReceipt INT = 0;
    DECLARE @RowsDelivery INT = 0;
    
    TRUNCATE TABLE fact.Inventory;
    
    -- Part 1: Load Receipts (رسید - مثبت)
    INSERT INTO fact.Inventory (
        DateKey, ItemKey, StockKey, DestStockKey, PartyKey, CurrencyKey, FiscalYearKey,
        MovementType, MovementSign,
        DocumentId, DocumentNumber, DocumentDate, DocumentType, IsReturn, IsTransfer,
        DocumentItemId, RowNumber,
        Quantity, SecondaryQuantity,
        UnitPrice, Amount, TaxAmount, DutyAmount, TransportAmount, NetAmount,
        CurrencyRate, Description
    )
    SELECT 
        -- Dimension Keys
        ISNULL(d.DateKey, -1) AS DateKey,
        ISNULL(it.ItemKey, -1) AS ItemKey,
        ISNULL(st.StockKey, -1) AS StockKey,
        NULL AS DestStockKey,
        ISNULL(p.PartyKey, -1) AS PartyKey,
        ISNULL(c.CurrencyKey, -1) AS CurrencyKey,
        ISNULL(fy.FiscalYearKey, -1) AS FiscalYearKey,
        
        -- Movement Type
        'Receipt' AS MovementType,
        CASE WHEN ir.IsReturn = 1 THEN -1 ELSE 1 END AS MovementSign,  -- برگشت از فروش = منفی
        
        -- Document Header
        ir.InventoryReceiptID AS DocumentId,
        ir.Number AS DocumentNumber,
        CAST(ir.Date AS DATE) AS DocumentDate,
        ir.Type AS DocumentType,
        ir.IsReturn,
        0 AS IsTransfer,
        
        -- Document Item
        iri.InventoryReceiptItemID AS DocumentItemId,
        iri.RowNumber,
        
        -- Quantities (با علامت)
        CASE WHEN ir.IsReturn = 1 THEN -iri.Quantity ELSE iri.Quantity END AS Quantity,
        CASE WHEN ir.IsReturn = 1 THEN -iri.SecondaryQuantity ELSE iri.SecondaryQuantity END AS SecondaryQuantity,
        
        -- Prices
        iri.Fee AS UnitPrice,
        CASE WHEN ir.IsReturn = 1 THEN -iri.Price ELSE iri.Price END AS Amount,
        iri.Tax AS TaxAmount,
        iri.Duty AS DutyAmount,
        iri.TransportPrice AS TransportAmount,
        CASE WHEN ir.IsReturn = 1 THEN -iri.NetPrice ELSE iri.NetPrice END AS NetAmount,
        
        -- Currency
        iri.CurrencyRate,
        
        -- Description
        iri.Description
        
    FROM src.InventoryReceipt ir
    INNER JOIN src.InventoryReceiptItem iri ON ir.InventoryReceiptID = iri.InventoryReceiptRef
    LEFT JOIN dim.Date d ON CAST(ir.Date AS DATE) = d.FullDate
    LEFT JOIN dim.Item it ON iri.ItemRef = it.ItemId
    LEFT JOIN dim.Stock st ON ir.StockRef = st.StockId
    LEFT JOIN dim.Party p ON ir.DelivererDLRef = p.DLId
    LEFT JOIN dim.Currency c ON iri.CurrencyRef = c.CurrencyId
    LEFT JOIN dim.FiscalYear fy ON ir.FiscalYearRef = fy.FiscalYearId;
    
    SET @RowsReceipt = @@ROWCOUNT;
    
    -- Part 2: Load Deliveries (حواله - منفی)
    INSERT INTO fact.Inventory (
        DateKey, ItemKey, StockKey, DestStockKey, PartyKey, CurrencyKey, FiscalYearKey,
        MovementType, MovementSign,
        DocumentId, DocumentNumber, DocumentDate, DocumentType, IsReturn, IsTransfer,
        DocumentItemId, RowNumber,
        Quantity, SecondaryQuantity,
        UnitPrice, Amount, TaxAmount, DutyAmount, TransportAmount, NetAmount,
        CurrencyRate, Description
    )
    SELECT 
        -- Dimension Keys
        ISNULL(d.DateKey, -1) AS DateKey,
        ISNULL(it.ItemKey, -1) AS ItemKey,
        ISNULL(st.StockKey, -1) AS StockKey,
        dst.StockKey AS DestStockKey,
        ISNULL(p.PartyKey, -1) AS PartyKey,
        -1 AS CurrencyKey,  -- No currency in delivery
        ISNULL(fy.FiscalYearKey, -1) AS FiscalYearKey,
        
        -- Movement Type
        'Delivery' AS MovementType,
        CASE WHEN id.IsReturn = 1 THEN 1 ELSE -1 END AS MovementSign,  -- برگشت از خرید = مثبت
        
        -- Document Header
        id.InventoryDeliveryID AS DocumentId,
        id.Number AS DocumentNumber,
        CAST(id.Date AS DATE) AS DocumentDate,
        id.Type AS DocumentType,
        id.IsReturn,
        CASE WHEN id.DestinationStockRef IS NOT NULL THEN 1 ELSE 0 END AS IsTransfer,
        
        -- Document Item
        idi.InventoryDeliveryItemID AS DocumentItemId,
        idi.RowNumber,
        
        -- Quantities (با علامت - حواله منفی، برگشت از خرید مثبت)
        CASE WHEN id.IsReturn = 1 THEN idi.Quantity ELSE -idi.Quantity END AS Quantity,
        CASE WHEN id.IsReturn = 1 THEN idi.SecondaryQuantity ELSE -idi.SecondaryQuantity END AS SecondaryQuantity,
        
        -- Prices
        idi.Fee AS UnitPrice,
        CASE WHEN id.IsReturn = 1 THEN idi.Price ELSE -idi.Price END AS Amount,
        NULL AS TaxAmount,
        NULL AS DutyAmount,
        NULL AS TransportAmount,
        CASE WHEN id.IsReturn = 1 THEN idi.Price ELSE -idi.Price END AS NetAmount,
        
        -- Currency
        NULL AS CurrencyRate,
        
        -- Description
        idi.Description
        
    FROM src.InventoryDelivery id
    INNER JOIN src.InventoryDeliveryItem idi ON id.InventoryDeliveryID = idi.InventoryDeliveryRef
    LEFT JOIN dim.Date d ON CAST(id.Date AS DATE) = d.FullDate
    LEFT JOIN dim.Item it ON idi.ItemRef = it.ItemId
    LEFT JOIN dim.Stock st ON id.StockRef = st.StockId
    LEFT JOIN dim.Stock dst ON id.DestinationStockRef = dst.StockId
    LEFT JOIN dim.Party p ON id.ReceiverDLRef = p.DLId
    LEFT JOIN dim.FiscalYear fy ON id.FiscalYearRef = fy.FiscalYearId;
    
    SET @RowsDelivery = @@ROWCOUNT;
    
    PRINT 'fact.Inventory loaded: ' + CAST(@RowsReceipt AS VARCHAR(20)) + ' receipts, ' + 
          CAST(@RowsDelivery AS VARCHAR(20)) + ' deliveries = ' +
          CAST(@RowsReceipt + @RowsDelivery AS VARCHAR(20)) + ' total rows';
END;
GO


-- ============================================================================
-- Load fact.CashFlow
-- ============================================================================
CREATE OR ALTER PROCEDURE etl.usp_Load_Fact_CashFlow
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RowsReceipt INT = 0;
    DECLARE @RowsPayment INT = 0;
    
    TRUNCATE TABLE fact.CashFlow;
    
    -- Part 1: Load Receipts (دریافت - مثبت)
    INSERT INTO fact.CashFlow (
        DateKey, PartyKey, AccountKey, DLKey, CurrencyKey, FiscalYearKey, CashKey,
        FlowType, FlowSign,
        DocumentId, DocumentNumber, DocumentDate, DocumentType, DocumentState, DocumentStateName,
        ItemType, ItemTypeName,
        Amount, DiscountAmount, TotalAmount,
        AmountBase, TotalAmountBase,
        CurrencyRate, VoucherId, Description
    )
    SELECT 
        -- Dimension Keys
        ISNULL(d.DateKey, -1) AS DateKey,
        ISNULL(p.PartyKey, -1) AS PartyKey,
        a.AccountKey AS AccountKey,
        ISNULL(dl.DLKey, -1) AS DLKey,
        ISNULL(c.CurrencyKey, -1) AS CurrencyKey,
        ISNULL(fy.FiscalYearKey, -1) AS FiscalYearKey,
        NULL AS CashKey,  -- TODO: Add dim.Cash
        
        -- Flow Type
        'Receipt' AS FlowType,
        1 AS FlowSign,
        
        -- Document
        rh.ReceiptHeaderId AS DocumentId,
        rh.Number AS DocumentNumber,
        CAST(rh.Date AS DATE) AS DocumentDate,
        rh.Type AS DocumentType,
        rh.State AS DocumentState,
        CASE rh.State
            WHEN 0 THEN N'پیش‌نویس'
            WHEN 1 THEN N'تأیید'
            WHEN 2 THEN N'ثبت شده'
            ELSE N'نامشخص'
        END AS DocumentStateName,
        
        -- Item Type
        rh.ItemType,
        CASE rh.ItemType
            WHEN 0 THEN N'نقد'
            WHEN 1 THEN N'چک'
            WHEN 2 THEN N'کارت'
            WHEN 3 THEN N'انتقال'
            ELSE N'سایر'
        END AS ItemTypeName,
        
        -- Measures (مثبت)
        rh.Amount,
        rh.Discount AS DiscountAmount,
        rh.TotalAmount,
        rh.AmountInBaseCurrency AS AmountBase,
        rh.TotalAmountInBaseCurrency AS TotalAmountBase,
        
        -- Currency
        rh.Rate AS CurrencyRate,
        
        -- Voucher
        rh.VoucherRef AS VoucherId,
        
        -- Description
        rh.Description
        
    FROM src.ReceiptHeader rh
    LEFT JOIN dim.Date d ON CAST(rh.Date AS DATE) = d.FullDate
    LEFT JOIN dim.Party p ON rh.DlRef = p.DLId
    LEFT JOIN dim.Account a ON rh.AccountSlRef = a.AccountId
    LEFT JOIN dim.DL dl ON rh.DlRef = dl.DLId
    LEFT JOIN dim.Currency c ON rh.CurrencyRef = c.CurrencyId
    LEFT JOIN dim.FiscalYear fy ON rh.FiscalYearRef = fy.FiscalYearId;
    
    SET @RowsReceipt = @@ROWCOUNT;
    
    -- Part 2: Load Payments (پرداخت - منفی)
    INSERT INTO fact.CashFlow (
        DateKey, PartyKey, AccountKey, DLKey, CurrencyKey, FiscalYearKey, CashKey,
        FlowType, FlowSign,
        DocumentId, DocumentNumber, DocumentDate, DocumentType, DocumentState, DocumentStateName,
        ItemType, ItemTypeName,
        Amount, DiscountAmount, TotalAmount,
        AmountBase, TotalAmountBase,
        CurrencyRate, VoucherId, Description
    )
    SELECT 
        -- Dimension Keys
        ISNULL(d.DateKey, -1) AS DateKey,
        ISNULL(p.PartyKey, -1) AS PartyKey,
        a.AccountKey AS AccountKey,
        ISNULL(dl.DLKey, -1) AS DLKey,
        ISNULL(c.CurrencyKey, -1) AS CurrencyKey,
        ISNULL(fy.FiscalYearKey, -1) AS FiscalYearKey,
        NULL AS CashKey,
        
        -- Flow Type
        'Payment' AS FlowType,
        -1 AS FlowSign,
        
        -- Document
        ph.PaymentHeaderId AS DocumentId,
        ph.Number AS DocumentNumber,
        CAST(ph.Date AS DATE) AS DocumentDate,
        ph.Type AS DocumentType,
        ph.State AS DocumentState,
        CASE ph.State
            WHEN 0 THEN N'پیش‌نویس'
            WHEN 1 THEN N'تأیید'
            WHEN 2 THEN N'ثبت شده'
            ELSE N'نامشخص'
        END AS DocumentStateName,
        
        -- Item Type
        ph.ItemType,
        CASE ph.ItemType
            WHEN 0 THEN N'نقد'
            WHEN 1 THEN N'چک'
            WHEN 2 THEN N'کارت'
            WHEN 3 THEN N'انتقال'
            ELSE N'سایر'
        END AS ItemTypeName,
        
        -- Measures (منفی)
        -ph.Amount AS Amount,
        ph.Discount AS DiscountAmount,
        -ph.TotalAmount AS TotalAmount,
        -ph.AmountInBaseCurrency AS AmountBase,
        -ph.TotalAmountInBaseCurrency AS TotalAmountBase,
        
        -- Currency
        ph.Rate AS CurrencyRate,
        
        -- Voucher
        ph.VoucherRef AS VoucherId,
        
        -- Description
        ph.Description
        
    FROM src.PaymentHeader ph
    LEFT JOIN dim.Date d ON CAST(ph.Date AS DATE) = d.FullDate
    LEFT JOIN dim.Party p ON ph.DlRef = p.DLId
    LEFT JOIN dim.Account a ON ph.AccountSlRef = a.AccountId
    LEFT JOIN dim.DL dl ON ph.DlRef = dl.DLId
    LEFT JOIN dim.Currency c ON ph.CurrencyRef = c.CurrencyId
    LEFT JOIN dim.FiscalYear fy ON ph.FiscalYearRef = fy.FiscalYearId;
    
    SET @RowsPayment = @@ROWCOUNT;
    
    PRINT 'fact.CashFlow loaded: ' + CAST(@RowsReceipt AS VARCHAR(20)) + ' receipts, ' + 
          CAST(@RowsPayment AS VARCHAR(20)) + ' payments = ' +
          CAST(@RowsReceipt + @RowsPayment AS VARCHAR(20)) + ' total rows';
END;
GO


-- ============================================================================
-- Load fact.Cheque
-- ============================================================================
CREATE OR ALTER PROCEDURE etl.usp_Load_Fact_Cheque
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RowsReceipt INT = 0;
    DECLARE @RowsPayment INT = 0;
    
    TRUNCATE TABLE fact.Cheque;
    
    -- Part 1: Load Receipt Cheques (چک دریافتی - مثبت)
    INSERT INTO fact.Cheque (
        IssueDateKey, DueDateKey, PartyKey, DLKey, BankKey, BankAccountKey, CurrencyKey, FiscalYearKey,
        ChequeType, ChequeSign,
        ChequeId, ChequeNumber, SecondNumber, SayadCode, AccountNo,
        IssueDate, DueDate,
        ChequeState, ChequeStateName, InitialState, IsGuarantee,
        HeaderId, HeaderNumber, HeaderDate,
        Amount, AmountBase, CurrencyRate,
        ChequeOwner, BranchCode, BranchName,
        Description
    )
    SELECT 
        -- Dimension Keys
        ISNULL(di.DateKey, -1) AS IssueDateKey,
        dd.DateKey AS DueDateKey,
        ISNULL(p.PartyKey, -1) AS PartyKey,
        ISNULL(dl.DLKey, -1) AS DLKey,
        b.BankKey AS BankKey,
        NULL AS BankAccountKey,
        ISNULL(c.CurrencyKey, -1) AS CurrencyKey,
        ISNULL(fy.FiscalYearKey, -1) AS FiscalYearKey,
        
        -- Cheque Type
        'Receipt' AS ChequeType,
        1 AS ChequeSign,
        
        -- Cheque Info
        rc.ReceiptChequeId AS ChequeId,
        rc.Number AS ChequeNumber,
        rc.SecondNumber,
        rc.SayadCode,
        rc.AccountNo,
        
        -- Dates
        CAST(rc.HeaderDate AS DATE) AS IssueDate,
        CAST(rc.Date AS DATE) AS DueDate,
        
        -- Status
        rc.State AS ChequeState,
        CASE rc.State
            WHEN 0 THEN N'در جریان'
            WHEN 1 THEN N'وصول شده'
            WHEN 2 THEN N'برگشتی'
            WHEN 3 THEN N'خرج شده'
            WHEN 4 THEN N'واگذار به بانک'
            ELSE N'سایر'
        END AS ChequeStateName,
        rc.InitState AS InitialState,
        rc.IsGuarantee,
        
        -- Header
        rc.ReceiptHeaderRef AS HeaderId,
        rc.HeaderNumber,
        CAST(rc.HeaderDate AS DATE) AS HeaderDate,
        
        -- Measures (مثبت)
        rc.Amount,
        rc.AmountInBaseCurrency AS AmountBase,
        rc.Rate AS CurrencyRate,
        
        -- Additional
        rc.ChequeOwner,
        rc.BranchCode,
        rc.BranchTitle AS BranchName,
        
        -- Description
        rc.Description
        
    FROM src.ReceiptCheque rc
    LEFT JOIN src.ReceiptHeader rh ON rc.ReceiptHeaderRef = rh.ReceiptHeaderId
    LEFT JOIN dim.Date di ON CAST(rc.HeaderDate AS DATE) = di.FullDate
    LEFT JOIN dim.Date dd ON CAST(rc.Date AS DATE) = dd.FullDate
    LEFT JOIN dim.Party p ON rc.DlRef = p.DLId
    LEFT JOIN dim.DL dl ON rc.DlRef = dl.DLId
    LEFT JOIN dim.Bank b ON rc.BankRef = b.BankId
    LEFT JOIN dim.Currency c ON rc.CurrencyRef = c.CurrencyId
    LEFT JOIN dim.FiscalYear fy ON rh.FiscalYearRef = fy.FiscalYearId;
    
    SET @RowsReceipt = @@ROWCOUNT;
    
    -- Part 2: Load Payment Cheques (چک پرداختی - منفی)
    INSERT INTO fact.Cheque (
        IssueDateKey, DueDateKey, PartyKey, DLKey, BankKey, BankAccountKey, CurrencyKey, FiscalYearKey,
        ChequeType, ChequeSign,
        ChequeId, ChequeNumber, SecondNumber, SayadCode, AccountNo,
        IssueDate, DueDate,
        ChequeState, ChequeStateName, InitialState, IsGuarantee,
        HeaderId, HeaderNumber, HeaderDate,
        Amount, AmountBase, CurrencyRate,
        ChequeOwner, BranchCode, BranchName,
        Description
    )
    SELECT 
        -- Dimension Keys
        ISNULL(di.DateKey, -1) AS IssueDateKey,
        dd.DateKey AS DueDateKey,
        ISNULL(p.PartyKey, -1) AS PartyKey,
        ISNULL(dl.DLKey, -1) AS DLKey,
        ba.BankKey AS BankKey,
        ba.BankAccountKey AS BankAccountKey,
        ISNULL(c.CurrencyKey, -1) AS CurrencyKey,
        ISNULL(fy.FiscalYearKey, -1) AS FiscalYearKey,
        
        -- Cheque Type
        'Payment' AS ChequeType,
        -1 AS ChequeSign,
        
        -- Cheque Info
        pc.PaymentChequeId AS ChequeId,
        pc.Number AS ChequeNumber,
        pc.SecondNumber,
        pc.SayadCode,
        NULL AS AccountNo,
        
        -- Dates
        CAST(pc.HeaderDate AS DATE) AS IssueDate,
        CAST(pc.Date AS DATE) AS DueDate,
        
        -- Status
        pc.State AS ChequeState,
        CASE pc.State
            WHEN 0 THEN N'صادر شده'
            WHEN 1 THEN N'نقد شده'
            WHEN 2 THEN N'برگشتی'
            WHEN 3 THEN N'ابطال'
            ELSE N'سایر'
        END AS ChequeStateName,
        NULL AS InitialState,
        pc.IsGuarantee,
        
        -- Header
        pc.PaymentHeaderRef AS HeaderId,
        pc.HeaderNumber,
        CAST(pc.HeaderDate AS DATE) AS HeaderDate,
        
        -- Measures (منفی)
        -pc.Amount AS Amount,
        -pc.AmountInBaseCurrency AS AmountBase,
        pc.Rate AS CurrencyRate,
        
        -- Additional
        NULL AS ChequeOwner,
        NULL AS BranchCode,
        NULL AS BranchName,
        
        -- Description
        pc.Description
        
    FROM src.PaymentCheque pc
    LEFT JOIN src.PaymentHeader ph ON pc.PaymentHeaderRef = ph.PaymentHeaderId
    LEFT JOIN dim.Date di ON CAST(pc.HeaderDate AS DATE) = di.FullDate
    LEFT JOIN dim.Date dd ON CAST(pc.Date AS DATE) = dd.FullDate
    LEFT JOIN dim.Party p ON pc.DlRef = p.DLId
    LEFT JOIN dim.DL dl ON pc.DlRef = dl.DLId
    LEFT JOIN dim.BankAccount ba ON pc.BankAccountRef = ba.BankAccountId
    LEFT JOIN dim.Currency c ON pc.CurrencyRef = c.CurrencyId
    LEFT JOIN dim.FiscalYear fy ON ph.FiscalYearRef = fy.FiscalYearId;
    
    SET @RowsPayment = @@ROWCOUNT;
    
    PRINT 'fact.Cheque loaded: ' + CAST(@RowsReceipt AS VARCHAR(20)) + ' receipt cheques, ' + 
          CAST(@RowsPayment AS VARCHAR(20)) + ' payment cheques = ' +
          CAST(@RowsReceipt + @RowsPayment AS VARCHAR(20)) + ' total rows';
END;
GO


-- ============================================================================
-- Master Load Procedure for All Facts
-- ============================================================================
CREATE OR ALTER PROCEDURE etl.usp_Load_All_Facts
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME = GETDATE();
    
    PRINT '===============================================================================';
    PRINT 'Loading all fact tables...';
    PRINT 'Started at: ' + CONVERT(VARCHAR(30), @StartTime, 121);
    PRINT '===============================================================================';
    
    EXEC etl.usp_Load_Fact_GLTransaction;
    EXEC etl.usp_Load_Fact_Sales;
    EXEC etl.usp_Load_Fact_Inventory;
    EXEC etl.usp_Load_Fact_CashFlow;
    EXEC etl.usp_Load_Fact_Cheque;
    
    PRINT '';
    PRINT '===============================================================================';
    PRINT 'All fact tables loaded successfully!';
    PRINT 'Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS VARCHAR(10)) + ' seconds';
    PRINT '===============================================================================';
END;
GO


PRINT '';
PRINT 'Fact ETL procedures created successfully!';
PRINT 'Run: EXEC etl.usp_Load_All_Facts';
GO
