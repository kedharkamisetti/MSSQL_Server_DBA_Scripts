SELECT name AS [Database Name],
recovery_model_desc AS [Recovery Model] FROM sys.databases

-------- list only select database Recovery Model -------

SELECT 'Tlogdemo' AS [Database Name],
DATABASEPROPERTYEX('tlogdemo', 'RECOVERY')
AS [Recovery Model] 

SELECT D.recovery_model_desc FROM sys.databases D WHERE name = 'tlogdemo'

SELECT DATABASEPROPERTYEX('Tlogdemo', 'Recovery')

--------- List Database Recovery Models and also paths,stastus,size ---------
SELECT 
  A.recovery_model_desc AS [Recovery Model], 
  A.name AS [Database Name], 
  C.physical_name AS [Filename], 
  CAST(C.size * 8 / 1024.00 AS DECIMAL(10,2)) AS [Size in MB], 
  C.state_desc AS [Database State]
FROM sys.databases A
INNER JOIN sys.master_files C ON A.database_id = C.database_id
ORDER BY [Recovery Model], [Database Name], [Filename]