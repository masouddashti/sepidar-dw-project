/*
===============================================================================
SEPIDAR Data Warehouse Project
Phase 3: Load Dimension Tables
===============================================================================
Script: 03_Load_Dim_Tables.sql
Purpose: ETL procedures to load dimension tables from SEPIDAR
Author: BI Team
Version: 1.0
Date: January 2026
===============================================================================
*/

USE DW_DB;
GO

-- ============================================================================
-- Load dim.FiscalYear
-- ============================================================================
CREATE OR ALTER PROCEDURE etl.usp_Load_Dim_FiscalYear
AS
BEGIN
    SET NOCOUNT ON;
    
    MERGE dim.FiscalYear AS Target
    USING (
        SELECT 
            FiscalYearId,
            Title,
            Title_En,
            CAST(StartDate AS DATE) AS StartDate,
            CAST(EndDate AS DATE) AS EndDate,
            Status,
            CASE Status WHEN 0 THEN N'باز' WHEN 1 THEN N'بسته' ELSE N'نامشخص' END AS StatusName
        FROM src.FiscalYear
    ) AS Source
    ON Target.FiscalYearId = Source.FiscalYearId
    
    WHEN MATCHED THEN
        UPDATE SET 
            Title = Source.Title,
            Title_En = Source.Title_En,
            StartDate = Source.StartDate,
            EndDate = Source.EndDate,
            Status = Source.Status,
            StatusName = Source.StatusName
    
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (FiscalYearId, Title, Title_En, StartDate, EndDate, Status, StatusName)
        VALUES (Source.FiscalYearId, Source.Title, Source.Title_En, Source.StartDate, Source.EndDate, Source.Status, Source.StatusName);
    
    -- Set current fiscal year
    UPDATE dim.FiscalYear SET IsCurrent = 0;
    UPDATE dim.FiscalYear SET IsCurrent = 1 WHERE Status = 0;
    
    PRINT 'dim.FiscalYear loaded: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows';
END;
GO


-- ============================================================================
-- Load dim.Currency
-- ============================================================================
CREATE OR ALTER PROCEDURE etl.usp_Load_Dim_Currency
AS
BEGIN
    SET NOCOUNT ON;
    
    MERGE dim.Currency AS Target
    USING (
        SELECT 
            CurrencyID AS CurrencyId,
            Title,
            Title_En,
            ExchangeUnit,
            PrecisionCount,
            PrecisionName
        FROM src.Currency
    ) AS Source
    ON Target.CurrencyId = Source.CurrencyId
    
    WHEN MATCHED THEN
        UPDATE SET 
            Title = Source.Title,
            Title_En = Source.Title_En,
            ExchangeUnit = Source.ExchangeUnit,
            PrecisionCount = Source.PrecisionCount,
            PrecisionName = Source.PrecisionName
    
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (CurrencyId, Title, Title_En, ExchangeUnit, PrecisionCount, PrecisionName)
        VALUES (Source.CurrencyId, Source.Title, Source.Title_En, Source.ExchangeUnit, Source.PrecisionCount, Source.PrecisionName);
    
    -- Set base currency (usually ID = 1 or Rial)
    UPDATE dim.Currency SET IsBaseCurrency = 0;
    UPDATE dim.Currency SET IsBaseCurrency = 1 WHERE CurrencyId = 1;
    
    PRINT 'dim.Currency loaded: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows';
END;
GO


-- ============================================================================
-- Load dim.DL
-- ============================================================================
CREATE OR ALTER PROCEDURE etl.usp_Load_Dim_DL
AS
BEGIN
    SET NOCOUNT ON;
    
    MERGE dim.DL AS Target
    USING (
        SELECT 
            DLId,
            Code,
            Title,
            Title_En,
            Type AS DLType,
            CASE Type 
                WHEN 0 THEN N'عادی'
                WHEN 1 THEN N'طرف حساب'
                WHEN 2 THEN N'پرسنلی'
                ELSE N'سایر'
            END AS DLTypeName,
            IsActive
        FROM src.DL
    ) AS Source
    ON Target.DLId = Source.DLId
    
    WHEN MATCHED THEN
        UPDATE SET 
            Code = Source.Code,
            Title = Source.Title,
            Title_En = Source.Title_En,
            DLType = Source.DLType,
            DLTypeName = Source.DLTypeName,
            IsActive = Source.IsActive
    
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (DLId, Code, Title, Title_En, DLType, DLTypeName, IsActive)
        VALUES (Source.DLId, Source.Code, Source.Title, Source.Title_En, Source.DLType, Source.DLTypeName, Source.IsActive);
    
    PRINT 'dim.DL loaded: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows';
END;
GO


-- ============================================================================
-- Load dim.Account (با ساختار سلسله‌مراتبی)
-- ============================================================================
CREATE OR ALTER PROCEDURE etl.usp_Load_Dim_Account
AS
BEGIN
    SET NOCOUNT ON;
    
    -- First, load raw data with hierarchy calculation
    ;WITH AccountHierarchy AS (
        -- Level 1: Root accounts (no parent)
        SELECT 
            AccountId,
            ParentAccountRef AS ParentAccountId,
            Code,
            Title,
            Title_En,
            Type AS AccountType,
            BalanceType,
            HasDL,
            HasCurrency,
            HasTracking,
            CashFlowCategory,
            IsActive,
            CreationDate,
            LastModificationDate,
            1 AS AccountLevel,
            CAST(Code AS VARCHAR(500)) AS AccountPath,
            AccountId AS L1_AccountId,
            Code AS L1_Code,
            Title AS L1_Title,
            NULL AS L2_AccountId,
            NULL AS L2_Code,
            CAST(NULL AS NVARCHAR(200)) AS L2_Title,
            NULL AS L3_AccountId,
            NULL AS L3_Code,
            CAST(NULL AS NVARCHAR(200)) AS L3_Title
        FROM src.Account
        WHERE ParentAccountRef IS NULL OR ParentAccountRef NOT IN (SELECT AccountId FROM src.Account)
        
        UNION ALL
        
        -- Level 2+: Child accounts
        SELECT 
            a.AccountId,
            a.ParentAccountRef,
            a.Code,
            a.Title,
            a.Title_En,
            a.Type,
            a.BalanceType,
            a.HasDL,
            a.HasCurrency,
            a.HasTracking,
            a.CashFlowCategory,
            a.IsActive,
            a.CreationDate,
            a.LastModificationDate,
            h.AccountLevel + 1,
            CAST(h.AccountPath + ' > ' + a.Code AS VARCHAR(500)),
            -- Keep L1
            h.L1_AccountId,
            h.L1_Code,
            h.L1_Title,
            -- Set L2 if level 2
            CASE WHEN h.AccountLevel = 1 THEN a.AccountId ELSE h.L2_AccountId END,
            CASE WHEN h.AccountLevel = 1 THEN a.Code ELSE h.L2_Code END,
            CASE WHEN h.AccountLevel = 1 THEN CAST(a.Title AS NVARCHAR(200)) ELSE h.L2_Title END,
            -- Set L3 if level 3
            CASE WHEN h.AccountLevel = 2 THEN a.AccountId ELSE h.L3_AccountId END,
            CASE WHEN h.AccountLevel = 2 THEN a.Code ELSE h.L3_Code END,
            CASE WHEN h.AccountLevel = 2 THEN CAST(a.Title AS NVARCHAR(200)) ELSE h.L3_Title END
        FROM src.Account a
        INNER JOIN AccountHierarchy h ON a.ParentAccountRef = h.AccountId
        WHERE h.AccountLevel < 10  -- Prevent infinite loop
    )
    MERGE dim.Account AS Target
    USING (
        SELECT 
            ah.AccountId,
            ah.ParentAccountId,
            ah.AccountLevel,
            ah.AccountPath,
            ah.L1_AccountId, ah.L1_Code, ah.L1_Title,
            ah.L2_AccountId, ah.L2_Code, ah.L2_Title,
            ah.L3_AccountId, ah.L3_Code, ah.L3_Title,
            ah.Code,
            ah.Title,
            ah.Title_En,
            -- Full code and title
            CASE 
                WHEN ah.AccountLevel = 1 THEN ah.Code
                WHEN ah.AccountLevel = 2 THEN ah.L1_Code + '-' + ah.Code
                ELSE COALESCE(ah.L1_Code + '-', '') + COALESCE(ah.L2_Code + '-', '') + ah.Code
            END AS FullCode,
            CASE 
                WHEN ah.AccountLevel = 1 THEN ah.Title
                WHEN ah.AccountLevel = 2 THEN ah.L1_Title + N' > ' + ah.Title
                ELSE COALESCE(ah.L1_Title + N' > ', N'') + COALESCE(ah.L2_Title + N' > ', N'') + ah.Title
            END AS FullTitle,
            ah.AccountType,
            CASE ah.AccountType
                WHEN 1 THEN N'دارایی'
                WHEN 2 THEN N'بدهی'
                WHEN 3 THEN N'حقوق صاحبان سهام'
                WHEN 4 THEN N'درآمد'
                WHEN 5 THEN N'هزینه'
                ELSE N'سایر'
            END AS AccountTypeName,
            ah.BalanceType,
            CASE ah.BalanceType
                WHEN 0 THEN N'بدهکار'
                WHEN 1 THEN N'بستانکار'
                ELSE N'هر دو'
            END AS BalanceTypeName,
            ah.HasDL,
            ah.HasCurrency,
            ah.HasTracking,
            ah.CashFlowCategory,
            ah.IsActive,
            -- Is leaf (no children)
            CASE WHEN EXISTS (SELECT 1 FROM src.Account c WHERE c.ParentAccountRef = ah.AccountId) THEN 0 ELSE 1 END AS IsLeaf,
            ah.CreationDate AS CreatedDate,
            ah.LastModificationDate AS ModifiedDate
        FROM AccountHierarchy ah
    ) AS Source
    ON Target.AccountId = Source.AccountId
    
    WHEN MATCHED THEN
        UPDATE SET 
            ParentAccountId = Source.ParentAccountId,
            AccountLevel = Source.AccountLevel,
            AccountPath = Source.AccountPath,
            L1_AccountId = Source.L1_AccountId, L1_Code = Source.L1_Code, L1_Title = Source.L1_Title,
            L2_AccountId = Source.L2_AccountId, L2_Code = Source.L2_Code, L2_Title = Source.L2_Title,
            L3_AccountId = Source.L3_AccountId, L3_Code = Source.L3_Code, L3_Title = Source.L3_Title,
            Code = Source.Code,
            Title = Source.Title,
            Title_En = Source.Title_En,
            FullCode = Source.FullCode,
            FullTitle = Source.FullTitle,
            AccountType = Source.AccountType,
            AccountTypeName = Source.AccountTypeName,
            BalanceType = Source.BalanceType,
            BalanceTypeName = Source.BalanceTypeName,
            HasDL = Source.HasDL,
            HasCurrency = Source.HasCurrency,
            HasTracking = Source.HasTracking,
            CashFlowCategory = Source.CashFlowCategory,
            IsActive = Source.IsActive,
            IsLeaf = Source.IsLeaf,
            ModifiedDate = Source.ModifiedDate,
            DW_UpdateDate = GETDATE()
    
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (AccountId, ParentAccountId, AccountLevel, AccountPath,
                L1_AccountId, L1_Code, L1_Title, L2_AccountId, L2_Code, L2_Title, L3_AccountId, L3_Code, L3_Title,
                Code, Title, Title_En, FullCode, FullTitle, AccountType, AccountTypeName, 
                BalanceType, BalanceTypeName, HasDL, HasCurrency, HasTracking, CashFlowCategory, IsActive, IsLeaf, CreatedDate, ModifiedDate)
        VALUES (Source.AccountId, Source.ParentAccountId, Source.AccountLevel, Source.AccountPath,
                Source.L1_AccountId, Source.L1_Code, Source.L1_Title, Source.L2_AccountId, Source.L2_Code, Source.L2_Title, Source.L3_AccountId, Source.L3_Code, Source.L3_Title,
                Source.Code, Source.Title, Source.Title_En, Source.FullCode, Source.FullTitle, Source.AccountType, Source.AccountTypeName,
                Source.BalanceType, Source.BalanceTypeName, Source.HasDL, Source.HasCurrency, Source.HasTracking, Source.CashFlowCategory, Source.IsActive, Source.IsLeaf, Source.CreatedDate, Source.ModifiedDate);
    
    PRINT 'dim.Account loaded: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows';
END;
GO


-- ============================================================================
-- Load dim.Party
-- ============================================================================
CREATE OR ALTER PROCEDURE etl.usp_Load_Dim_Party
AS
BEGIN
    SET NOCOUNT ON;
    
    MERGE dim.Party AS Target
    USING (
        SELECT 
            p.PartyId,
            p.DLRef AS DLId,
            p.Type AS PartyType,
            CASE p.Type WHEN 0 THEN N'حقوقی' WHEN 1 THEN N'حقیقی' ELSE N'سایر' END AS PartyTypeName,
            p.SubType,
            p.IsCustomer,
            p.IsVendor,
            p.IsBroker,
            p.IsEmployee,
            p.Name,
            p.LastName,
            p.Name_En,
            p.LastName_En,
            p.EconomicCode,
            p.IdentificationCode AS NationalCode,
            p.RegistrationCode,
            p.Website,
            p.Email,
            p.CustomerGroupingRef AS CustomerGroupId,
            p.DiscountRate,
            p.MaximumCredit,
            p.HasCredit,
            p.SalespersonPartyRef AS SalespersonId,
            p.VendorGroupingRef AS VendorGroupId,
            p.CommissionRate,
            p.IsInBlacklist,
            p.CreationDate AS CreatedDate,
            p.LastModificationDate AS ModifiedDate
        FROM src.Party p
    ) AS Source
    ON Target.PartyId = Source.PartyId
    
    WHEN MATCHED THEN
        UPDATE SET 
            DLId = Source.DLId,
            PartyType = Source.PartyType,
            PartyTypeName = Source.PartyTypeName,
            SubType = Source.SubType,
            IsCustomer = Source.IsCustomer,
            IsVendor = Source.IsVendor,
            IsBroker = Source.IsBroker,
            IsEmployee = Source.IsEmployee,
            Name = Source.Name,
            LastName = Source.LastName,
            Name_En = Source.Name_En,
            LastName_En = Source.LastName_En,
            EconomicCode = Source.EconomicCode,
            NationalCode = Source.NationalCode,
            RegistrationCode = Source.RegistrationCode,
            Website = Source.Website,
            Email = Source.Email,
            CustomerGroupId = Source.CustomerGroupId,
            DiscountRate = Source.DiscountRate,
            MaximumCredit = Source.MaximumCredit,
            HasCredit = Source.HasCredit,
            SalespersonId = Source.SalespersonId,
            VendorGroupId = Source.VendorGroupId,
            CommissionRate = Source.CommissionRate,
            IsInBlacklist = Source.IsInBlacklist,
            ModifiedDate = Source.ModifiedDate,
            DW_UpdateDate = GETDATE()
    
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (PartyId, DLId, PartyType, PartyTypeName, SubType, IsCustomer, IsVendor, IsBroker, IsEmployee,
                Name, LastName, Name_En, LastName_En, EconomicCode, NationalCode, RegistrationCode,
                Website, Email, CustomerGroupId, DiscountRate, MaximumCredit, HasCredit, SalespersonId,
                VendorGroupId, CommissionRate, IsInBlacklist, CreatedDate, ModifiedDate)
        VALUES (Source.PartyId, Source.DLId, Source.PartyType, Source.PartyTypeName, Source.SubType, Source.IsCustomer, Source.IsVendor, Source.IsBroker, Source.IsEmployee,
                Source.Name, Source.LastName, Source.Name_En, Source.LastName_En, Source.EconomicCode, Source.NationalCode, Source.RegistrationCode,
                Source.Website, Source.Email, Source.CustomerGroupId, Source.DiscountRate, Source.MaximumCredit, Source.HasCredit, Source.SalespersonId,
                Source.VendorGroupId, Source.CommissionRate, Source.IsInBlacklist, Source.CreatedDate, Source.ModifiedDate);
    
    PRINT 'dim.Party loaded: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows';
END;
GO


-- ============================================================================
-- Load dim.ItemCategory
-- ============================================================================
CREATE OR ALTER PROCEDURE etl.usp_Load_Dim_ItemCategory
AS
BEGIN
    SET NOCOUNT ON;
    
    MERGE dim.ItemCategory AS Target
    USING (
        SELECT 
            ItemCategoryID AS CategoryId,
            Code,
            Title
        FROM src.ItemCategory
    ) AS Source
    ON Target.CategoryId = Source.CategoryId
    
    WHEN MATCHED THEN
        UPDATE SET 
            Code = Source.Code,
            Title = Source.Title
    
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (CategoryId, Code, Title)
        VALUES (Source.CategoryId, Source.Code, Source.Title);
    
    PRINT 'dim.ItemCategory loaded: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows';
END;
GO


-- ============================================================================
-- Load dim.Item
-- ============================================================================
CREATE OR ALTER PROCEDURE etl.usp_Load_Dim_Item
AS
BEGIN
    SET NOCOUNT ON;
    
    MERGE dim.Item AS Target
    USING (
        SELECT 
            i.ItemID AS ItemId,
            i.Code,
            i.Title,
            i.Title_En,
            i.Barcode,
            i.IranCode,
            i.Type AS ItemType,
            CASE i.Type 
                WHEN 0 THEN N'کالا'
                WHEN 1 THEN N'خدمات'
                ELSE N'سایر'
            END AS ItemTypeName,
            i.ItemCategoryRef AS CategoryId,
            c.Code AS CategoryCode,
            c.Title AS CategoryName,
            i.UnitRef AS UnitId,
            u1.Title AS UnitName,
            i.SecondaryUnitRef AS SecondaryUnitId,
            u2.Title AS SecondaryUnitName,
            i.SaleUnitRef AS SaleUnitId,
            u3.Title AS SaleUnitName,
            i.UnitsRatio,
            i.DefaultStockRef AS DefaultStockId,
            s.Title AS DefaultStockName,
            i.TaxExempt,
            i.TaxRate,
            i.DutyRate,
            i.CanHaveTracing,
            i.SerialTracking,
            i.Weight,
            i.Volume,
            i.IsActive,
            i.Sellable,
            i.CreationDate AS CreatedDate,
            i.LastModificationDate AS ModifiedDate
        FROM src.Item i
        LEFT JOIN src.ItemCategory c ON i.ItemCategoryRef = c.ItemCategoryID
        LEFT JOIN src.Unit u1 ON i.UnitRef = u1.UnitID
        LEFT JOIN src.Unit u2 ON i.SecondaryUnitRef = u2.UnitID
        LEFT JOIN src.Unit u3 ON i.SaleUnitRef = u3.UnitID
        LEFT JOIN src.Stock s ON i.DefaultStockRef = s.StockID
    ) AS Source
    ON Target.ItemId = Source.ItemId
    
    WHEN MATCHED THEN
        UPDATE SET 
            Code = Source.Code,
            Title = Source.Title,
            Title_En = Source.Title_En,
            Barcode = Source.Barcode,
            IranCode = Source.IranCode,
            ItemType = Source.ItemType,
            ItemTypeName = Source.ItemTypeName,
            CategoryId = Source.CategoryId,
            CategoryCode = Source.CategoryCode,
            CategoryName = Source.CategoryName,
            UnitId = Source.UnitId,
            UnitName = Source.UnitName,
            SecondaryUnitId = Source.SecondaryUnitId,
            SecondaryUnitName = Source.SecondaryUnitName,
            SaleUnitId = Source.SaleUnitId,
            SaleUnitName = Source.SaleUnitName,
            UnitsRatio = Source.UnitsRatio,
            DefaultStockId = Source.DefaultStockId,
            DefaultStockName = Source.DefaultStockName,
            TaxExempt = Source.TaxExempt,
            TaxRate = Source.TaxRate,
            DutyRate = Source.DutyRate,
            CanHaveTracing = Source.CanHaveTracing,
            SerialTracking = Source.SerialTracking,
            Weight = Source.Weight,
            Volume = Source.Volume,
            IsActive = Source.IsActive,
            Sellable = Source.Sellable,
            ModifiedDate = Source.ModifiedDate
    
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (ItemId, Code, Title, Title_En, Barcode, IranCode, ItemType, ItemTypeName,
                CategoryId, CategoryCode, CategoryName, UnitId, UnitName, SecondaryUnitId, SecondaryUnitName,
                SaleUnitId, SaleUnitName, UnitsRatio, DefaultStockId, DefaultStockName, TaxExempt, TaxRate,
                DutyRate, CanHaveTracing, SerialTracking, Weight, Volume, IsActive, Sellable, CreatedDate, ModifiedDate)
        VALUES (Source.ItemId, Source.Code, Source.Title, Source.Title_En, Source.Barcode, Source.IranCode, Source.ItemType, Source.ItemTypeName,
                Source.CategoryId, Source.CategoryCode, Source.CategoryName, Source.UnitId, Source.UnitName, Source.SecondaryUnitId, Source.SecondaryUnitName,
                Source.SaleUnitId, Source.SaleUnitName, Source.UnitsRatio, Source.DefaultStockId, Source.DefaultStockName, Source.TaxExempt, Source.TaxRate,
                Source.DutyRate, Source.CanHaveTracing, Source.SerialTracking, Source.Weight, Source.Volume, Source.IsActive, Source.Sellable, Source.CreatedDate, Source.ModifiedDate);
    
    PRINT 'dim.Item loaded: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows';
END;
GO


-- ============================================================================
-- Load dim.Stock
-- ============================================================================
CREATE OR ALTER PROCEDURE etl.usp_Load_Dim_Stock
AS
BEGIN
    SET NOCOUNT ON;
    
    MERGE dim.Stock AS Target
    USING (
        SELECT 
            StockID AS StockId,
            Code,
            Title,
            Title_En,
            StockClerk,
            Phone,
            Address,
            IsActive
        FROM src.Stock
    ) AS Source
    ON Target.StockId = Source.StockId
    
    WHEN MATCHED THEN
        UPDATE SET 
            Code = Source.Code,
            Title = Source.Title,
            Title_En = Source.Title_En,
            StockClerk = Source.StockClerk,
            Phone = Source.Phone,
            Address = Source.Address,
            IsActive = Source.IsActive
    
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (StockId, Code, Title, Title_En, StockClerk, Phone, Address, IsActive)
        VALUES (Source.StockId, Source.Code, Source.Title, Source.Title_En, Source.StockClerk, Source.Phone, Source.Address, Source.IsActive);
    
    PRINT 'dim.Stock loaded: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows';
END;
GO


-- ============================================================================
-- Load dim.Bank
-- ============================================================================
CREATE OR ALTER PROCEDURE etl.usp_Load_Dim_Bank
AS
BEGIN
    SET NOCOUNT ON;
    
    MERGE dim.Bank AS Target
    USING (
        SELECT 
            BankId,
            Title,
            Title_En,
            TaxFileCode
        FROM src.Bank
    ) AS Source
    ON Target.BankId = Source.BankId
    
    WHEN MATCHED THEN
        UPDATE SET 
            Title = Source.Title,
            Title_En = Source.Title_En,
            TaxFileCode = Source.TaxFileCode
    
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (BankId, Title, Title_En, TaxFileCode)
        VALUES (Source.BankId, Source.Title, Source.Title_En, Source.TaxFileCode);
    
    PRINT 'dim.Bank loaded: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows';
END;
GO


-- ============================================================================
-- Master Load Procedure
-- ============================================================================
CREATE OR ALTER PROCEDURE etl.usp_Load_All_Dimensions
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME = GETDATE();
    
    PRINT '===============================================================================';
    PRINT 'Loading all dimension tables...';
    PRINT 'Started at: ' + CONVERT(VARCHAR(30), @StartTime, 121);
    PRINT '===============================================================================';
    
    EXEC etl.usp_Load_Dim_FiscalYear;
    EXEC etl.usp_Load_Dim_Currency;
    EXEC etl.usp_Load_Dim_DL;
    EXEC etl.usp_Load_Dim_Account;
    EXEC etl.usp_Load_Dim_Party;
    EXEC etl.usp_Load_Dim_ItemCategory;
    EXEC etl.usp_Load_Dim_Item;
    EXEC etl.usp_Load_Dim_Stock;
    EXEC etl.usp_Load_Dim_Bank;
    
    PRINT '';
    PRINT '===============================================================================';
    PRINT 'All dimensions loaded successfully!';
    PRINT 'Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS VARCHAR(10)) + ' seconds';
    PRINT '===============================================================================';
END;
GO


PRINT '';
PRINT 'ETL procedures created successfully!';
PRINT 'Run: EXEC etl.usp_Load_All_Dimensions';
GO
