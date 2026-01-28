/*
===============================================================================
SEPIDAR Data Warehouse Project
Phase 3: Populate dim.Date
===============================================================================
Script: 02_Populate_Dim_Date.sql
Purpose: Generate date dimension with Jalali (Shamsi) calendar
Author: BI Team
Version: 1.0
Date: January 2026

Note: This script generates dates from 1398/01/01 to 1410/12/29 (Jalali)
      which covers approximately 2019-03-21 to 2032-03-19 (Gregorian)
===============================================================================
*/

USE DW_DB;
GO

-- ============================================================================
-- Clear existing data
-- ============================================================================
TRUNCATE TABLE dim.Date;
GO

-- ============================================================================
-- Jalali Date Conversion Functions
-- ============================================================================

-- Function to convert Gregorian to Jalali
CREATE OR ALTER FUNCTION dbo.fn_GregorianToJalali(@GDate DATE)
RETURNS TABLE
AS
RETURN
(
    WITH JalaliCalc AS (
        SELECT 
            @GDate AS GDate,
            DATEPART(YEAR, @GDate) AS gy,
            DATEPART(MONTH, @GDate) AS gm,
            DATEPART(DAY, @GDate) AS gd
    ),
    DayCalc AS (
        SELECT 
            GDate, gy, gm, gd,
            DATEDIFF(DAY, '1600-03-21', @GDate) AS days_from_base,
            -- Approximate Jalali calculation
            CASE 
                WHEN MONTH(@GDate) < 3 OR (MONTH(@GDate) = 3 AND DAY(@GDate) < 21) 
                THEN YEAR(@GDate) - 622
                ELSE YEAR(@GDate) - 621
            END AS jy_approx
        FROM JalaliCalc
    ),
    JalaliResult AS (
        SELECT 
            GDate,
            jy_approx AS JYear,
            -- Calculate Jalali month and day based on day of year
            CASE 
                WHEN DATEDIFF(DAY, 
                    CASE 
                        WHEN MONTH(@GDate) < 3 OR (MONTH(@GDate) = 3 AND DAY(@GDate) < 21)
                        THEN DATEFROMPARTS(YEAR(@GDate)-1, 3, 21)
                        ELSE DATEFROMPARTS(YEAR(@GDate), 3, 21)
                    END, @GDate) + 1 <= 31 THEN 1
                WHEN DATEDIFF(DAY, 
                    CASE 
                        WHEN MONTH(@GDate) < 3 OR (MONTH(@GDate) = 3 AND DAY(@GDate) < 21)
                        THEN DATEFROMPARTS(YEAR(@GDate)-1, 3, 21)
                        ELSE DATEFROMPARTS(YEAR(@GDate), 3, 21)
                    END, @GDate) + 1 <= 62 THEN 2
                WHEN DATEDIFF(DAY, 
                    CASE 
                        WHEN MONTH(@GDate) < 3 OR (MONTH(@GDate) = 3 AND DAY(@GDate) < 21)
                        THEN DATEFROMPARTS(YEAR(@GDate)-1, 3, 21)
                        ELSE DATEFROMPARTS(YEAR(@GDate), 3, 21)
                    END, @GDate) + 1 <= 93 THEN 3
                WHEN DATEDIFF(DAY, 
                    CASE 
                        WHEN MONTH(@GDate) < 3 OR (MONTH(@GDate) = 3 AND DAY(@GDate) < 21)
                        THEN DATEFROMPARTS(YEAR(@GDate)-1, 3, 21)
                        ELSE DATEFROMPARTS(YEAR(@GDate), 3, 21)
                    END, @GDate) + 1 <= 124 THEN 4
                WHEN DATEDIFF(DAY, 
                    CASE 
                        WHEN MONTH(@GDate) < 3 OR (MONTH(@GDate) = 3 AND DAY(@GDate) < 21)
                        THEN DATEFROMPARTS(YEAR(@GDate)-1, 3, 21)
                        ELSE DATEFROMPARTS(YEAR(@GDate), 3, 21)
                    END, @GDate) + 1 <= 155 THEN 5
                WHEN DATEDIFF(DAY, 
                    CASE 
                        WHEN MONTH(@GDate) < 3 OR (MONTH(@GDate) = 3 AND DAY(@GDate) < 21)
                        THEN DATEFROMPARTS(YEAR(@GDate)-1, 3, 21)
                        ELSE DATEFROMPARTS(YEAR(@GDate), 3, 21)
                    END, @GDate) + 1 <= 186 THEN 6
                WHEN DATEDIFF(DAY, 
                    CASE 
                        WHEN MONTH(@GDate) < 3 OR (MONTH(@GDate) = 3 AND DAY(@GDate) < 21)
                        THEN DATEFROMPARTS(YEAR(@GDate)-1, 3, 21)
                        ELSE DATEFROMPARTS(YEAR(@GDate), 3, 21)
                    END, @GDate) + 1 <= 216 THEN 7
                WHEN DATEDIFF(DAY, 
                    CASE 
                        WHEN MONTH(@GDate) < 3 OR (MONTH(@GDate) = 3 AND DAY(@GDate) < 21)
                        THEN DATEFROMPARTS(YEAR(@GDate)-1, 3, 21)
                        ELSE DATEFROMPARTS(YEAR(@GDate), 3, 21)
                    END, @GDate) + 1 <= 246 THEN 8
                WHEN DATEDIFF(DAY, 
                    CASE 
                        WHEN MONTH(@GDate) < 3 OR (MONTH(@GDate) = 3 AND DAY(@GDate) < 21)
                        THEN DATEFROMPARTS(YEAR(@GDate)-1, 3, 21)
                        ELSE DATEFROMPARTS(YEAR(@GDate), 3, 21)
                    END, @GDate) + 1 <= 276 THEN 9
                WHEN DATEDIFF(DAY, 
                    CASE 
                        WHEN MONTH(@GDate) < 3 OR (MONTH(@GDate) = 3 AND DAY(@GDate) < 21)
                        THEN DATEFROMPARTS(YEAR(@GDate)-1, 3, 21)
                        ELSE DATEFROMPARTS(YEAR(@GDate), 3, 21)
                    END, @GDate) + 1 <= 306 THEN 10
                WHEN DATEDIFF(DAY, 
                    CASE 
                        WHEN MONTH(@GDate) < 3 OR (MONTH(@GDate) = 3 AND DAY(@GDate) < 21)
                        THEN DATEFROMPARTS(YEAR(@GDate)-1, 3, 21)
                        ELSE DATEFROMPARTS(YEAR(@GDate), 3, 21)
                    END, @GDate) + 1 <= 336 THEN 11
                ELSE 12
            END AS JMonth
        FROM DayCalc
    )
    SELECT 
        GDate,
        JYear,
        JMonth,
        -- Calculate day of month
        CASE 
            WHEN JMonth = 1 THEN DATEDIFF(DAY, 
                CASE 
                    WHEN MONTH(@GDate) < 3 OR (MONTH(@GDate) = 3 AND DAY(@GDate) < 21)
                    THEN DATEFROMPARTS(YEAR(@GDate)-1, 3, 21)
                    ELSE DATEFROMPARTS(YEAR(@GDate), 3, 21)
                END, @GDate) + 1
            WHEN JMonth <= 6 THEN DATEDIFF(DAY, 
                CASE 
                    WHEN MONTH(@GDate) < 3 OR (MONTH(@GDate) = 3 AND DAY(@GDate) < 21)
                    THEN DATEFROMPARTS(YEAR(@GDate)-1, 3, 21)
                    ELSE DATEFROMPARTS(YEAR(@GDate), 3, 21)
                END, @GDate) + 1 - ((JMonth - 1) * 31)
            WHEN JMonth <= 11 THEN DATEDIFF(DAY, 
                CASE 
                    WHEN MONTH(@GDate) < 3 OR (MONTH(@GDate) = 3 AND DAY(@GDate) < 21)
                    THEN DATEFROMPARTS(YEAR(@GDate)-1, 3, 21)
                    ELSE DATEFROMPARTS(YEAR(@GDate), 3, 21)
                END, @GDate) + 1 - (186 + ((JMonth - 7) * 30))
            ELSE DATEDIFF(DAY, 
                CASE 
                    WHEN MONTH(@GDate) < 3 OR (MONTH(@GDate) = 3 AND DAY(@GDate) < 21)
                    THEN DATEFROMPARTS(YEAR(@GDate)-1, 3, 21)
                    ELSE DATEFROMPARTS(YEAR(@GDate), 3, 21)
                END, @GDate) + 1 - 336
        END AS JDay
    FROM JalaliResult
);
GO


-- ============================================================================
-- Generate Dates
-- ============================================================================
PRINT 'Generating date dimension...';

-- Generate dates from 2019-01-01 to 2032-12-31
;WITH DateSeries AS (
    SELECT CAST('2019-01-01' AS DATE) AS FullDate
    UNION ALL
    SELECT DATEADD(DAY, 1, FullDate)
    FROM DateSeries
    WHERE FullDate < '2032-12-31'
)
INSERT INTO dim.Date (
    DateKey,
    FullDate,
    GYear, GMonth, GDay, GQuarter,
    GMonthName, GMonthNameFa, GDayOfWeek, GDayName, GDayNameFa, GWeekOfYear,
    JYear, JMonth, JDay, JQuarter,
    JMonthName, JDayOfWeek, JDayName, JWeekOfYear, JDateString, JYearMonth,
    IsWeekend, IsHoliday
)
SELECT 
    -- DateKey (YYYYMMDD)
    YEAR(d.FullDate) * 10000 + MONTH(d.FullDate) * 100 + DAY(d.FullDate) AS DateKey,
    d.FullDate,
    
    -- Gregorian
    YEAR(d.FullDate) AS GYear,
    MONTH(d.FullDate) AS GMonth,
    DAY(d.FullDate) AS GDay,
    DATEPART(QUARTER, d.FullDate) AS GQuarter,
    DATENAME(MONTH, d.FullDate) AS GMonthName,
    CASE MONTH(d.FullDate)
        WHEN 1 THEN N'ژانویه' WHEN 2 THEN N'فوریه' WHEN 3 THEN N'مارس'
        WHEN 4 THEN N'آوریل' WHEN 5 THEN N'مه' WHEN 6 THEN N'ژوئن'
        WHEN 7 THEN N'ژوئیه' WHEN 8 THEN N'اوت' WHEN 9 THEN N'سپتامبر'
        WHEN 10 THEN N'اکتبر' WHEN 11 THEN N'نوامبر' WHEN 12 THEN N'دسامبر'
    END AS GMonthNameFa,
    DATEPART(WEEKDAY, d.FullDate) AS GDayOfWeek,
    DATENAME(WEEKDAY, d.FullDate) AS GDayName,
    CASE DATEPART(WEEKDAY, d.FullDate)
        WHEN 1 THEN N'یکشنبه' WHEN 2 THEN N'دوشنبه' WHEN 3 THEN N'سه‌شنبه'
        WHEN 4 THEN N'چهارشنبه' WHEN 5 THEN N'پنجشنبه' WHEN 6 THEN N'جمعه' WHEN 7 THEN N'شنبه'
    END AS GDayNameFa,
    DATEPART(WEEK, d.FullDate) AS GWeekOfYear,
    
    -- Jalali (using function)
    j.JYear,
    j.JMonth,
    j.JDay,
    CASE WHEN j.JMonth <= 3 THEN 1 WHEN j.JMonth <= 6 THEN 2 WHEN j.JMonth <= 9 THEN 3 ELSE 4 END AS JQuarter,
    CASE j.JMonth
        WHEN 1 THEN N'فروردین' WHEN 2 THEN N'اردیبهشت' WHEN 3 THEN N'خرداد'
        WHEN 4 THEN N'تیر' WHEN 5 THEN N'مرداد' WHEN 6 THEN N'شهریور'
        WHEN 7 THEN N'مهر' WHEN 8 THEN N'آبان' WHEN 9 THEN N'آذر'
        WHEN 10 THEN N'دی' WHEN 11 THEN N'بهمن' WHEN 12 THEN N'اسفند'
    END AS JMonthName,
    -- Jalali week day (Saturday = 1, Friday = 7)
    CASE DATEPART(WEEKDAY, d.FullDate)
        WHEN 7 THEN 1  -- Saturday
        WHEN 1 THEN 2  -- Sunday
        WHEN 2 THEN 3  -- Monday
        WHEN 3 THEN 4  -- Tuesday
        WHEN 4 THEN 5  -- Wednesday
        WHEN 5 THEN 6  -- Thursday
        WHEN 6 THEN 7  -- Friday
    END AS JDayOfWeek,
    CASE DATEPART(WEEKDAY, d.FullDate)
        WHEN 7 THEN N'شنبه' WHEN 1 THEN N'یکشنبه' WHEN 2 THEN N'دوشنبه'
        WHEN 3 THEN N'سه‌شنبه' WHEN 4 THEN N'چهارشنبه' WHEN 5 THEN N'پنجشنبه' WHEN 6 THEN N'جمعه'
    END AS JDayName,
    (j.JDay + (j.JMonth - 1) * 30) / 7 + 1 AS JWeekOfYear,
    -- Format: 1403/01/15
    RIGHT('0000' + CAST(j.JYear AS VARCHAR(4)), 4) + '/' + 
    RIGHT('00' + CAST(j.JMonth AS VARCHAR(2)), 2) + '/' + 
    RIGHT('00' + CAST(j.JDay AS VARCHAR(2)), 2) AS JDateString,
    -- YearMonth: 140301
    j.JYear * 100 + j.JMonth AS JYearMonth,
    
    -- Weekend (Friday in Iran)
    CASE WHEN DATEPART(WEEKDAY, d.FullDate) = 6 THEN 1 ELSE 0 END AS IsWeekend,
    0 AS IsHoliday

FROM DateSeries d
CROSS APPLY dbo.fn_GregorianToJalali(d.FullDate) j
OPTION (MAXRECURSION 0);

PRINT 'Date dimension populated.';
GO


-- ============================================================================
-- Add Unknown Date
-- ============================================================================
INSERT INTO dim.Date (
    DateKey, FullDate,
    GYear, GMonth, GDay, GQuarter,
    GMonthName, GMonthNameFa, GDayOfWeek, GDayName, GDayNameFa, GWeekOfYear,
    JYear, JMonth, JDay, JQuarter,
    JMonthName, JDayOfWeek, JDayName, JWeekOfYear, JDateString, JYearMonth,
    IsWeekend, IsHoliday
)
VALUES (
    -1, '1900-01-01',
    1900, 1, 1, 1,
    'Unknown', N'نامشخص', 1, 'Unknown', N'نامشخص', 1,
    1278, 10, 11, 4,
    N'دی', 1, N'نامشخص', 1, '1278/10/11', 127810,
    0, 0
);
GO


-- ============================================================================
-- Summary
-- ============================================================================
SELECT 
    MIN(FullDate) AS MinDate,
    MAX(FullDate) AS MaxDate,
    COUNT(*) AS TotalDays,
    MIN(JYear) AS MinJYear,
    MAX(JYear) AS MaxJYear
FROM dim.Date
WHERE DateKey > 0;

SELECT TOP 10 
    DateKey, FullDate, JDateString, JMonthName, JDayName, IsWeekend
FROM dim.Date
WHERE DateKey > 0
ORDER BY FullDate;

PRINT 'dim.Date completed!';
GO
