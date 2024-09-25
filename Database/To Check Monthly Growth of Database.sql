
--********************************************************************************************************
--Source: https://www.mssqltips.com/sqlservertip/6158/how-to-check-monthly-growth-of-database-in-sql-server/
-- Script name:
-- AllDbsBkpSizeEvolutionReport
--
-- Pupose:
-- This script presents the data growth for a all databases of an instance of SQL Server and their delta
-- compared to the previous month. The script will work only if there is enough historical data in the
-- msdb database, because it makes all the calculations based on the database backup information history.
-- This script is based on the script developped by Alejandro Cobar witch gives works for one specific
-- database.
--
-- Source:
-- https://www.mssqltips.com/sqlservertip/6158/how-to-check-monthly-growth-of-database-in-sql-server/
--
-- History:
-- Alejandro Cobar 2019-09-05 Author
-- Ali Ben Tahar 2020-11-02 Update to work for all databases in the server
--
--
-- NOTE:
-- Copy this template script in a new window and change its parameters before to run it
-- Press Ctrl + Shift + M to change the script parameters.
--********************************************************************************************************

-- Create a temporary table to hold the report for all databases in the server
create TABLE
#DbBkpGrowth (DBName sysname, Year int, month int, BkpSizeGB int, DeltaNormal int, CmpBkpSizeGB int, DeltaCmp int);

--SECTION 1 BEGIN
exec sp_MSforeachdb
'WITH BackupsSize AS(
SELECT TOP 1000
[database_name]
, rn = ROW_NUMBER() OVER (ORDER BY DATEPART(year,[backup_start_date]) ASC, DATEPART(month,[backup_start_date]) ASC)
, [Year] = DATEPART(year,[backup_start_date])
, [Month] = DATEPART(month,[backup_start_date])
, [Backup Size GB] = CONVERT(DECIMAL(10,2),ROUND(AVG([backup_size]/1024/1024/1024),4))
, [Compressed Backup Size GB] = CONVERT(DECIMAL(10,2),ROUND(AVG([compressed_backup_size]/1024/1024/1024),4))
FROM
msdb.dbo.backupset
WHERE
[database_name] = N''?''
AND [type] = ''D''
AND backup_start_date BETWEEN DATEADD(mm, - 3, GETDATE()) AND GETDATE()
GROUP BY
[database_name]
, DATEPART(yyyy,[backup_start_date])
, DATEPART(mm, [backup_start_date])
ORDER BY [Year],[Month])
--SECTION 1 END

--SECTION 2 BEGIN
INSERT INTO
#DbBkpGrowth
SELECT
[database_name],
b.Year,
b.Month,
b.[Backup Size GB],
0 AS deltaNormal,
b.[Compressed Backup Size GB],
0 AS deltaCompressed
FROM BackupsSize b
WHERE b.rn = 1
UNION
SELECT
[database_name],
b.Year,
b.Month,
b.[Backup Size GB],
b.[Backup Size GB] - d.[Backup Size GB] AS deltaNormal,
b.[Compressed Backup Size GB],
b.[Compressed Backup Size GB] - d.[Compressed Backup Size GB] AS deltaCompressed
FROM BackupsSize b
CROSS APPLY (
SELECT bs.[Backup Size GB],bs.[Compressed Backup Size GB]
FROM BackupsSize bs
WHERE bs.rn = b.rn - 1
) AS d'
--SECTION 2 END

SELECT
*
FROM
#DbBkpGrowth
ORDER BY
DeltaNormal desc;

DROP TABLE #DbBkpGrowth;