create database test
GO

USE [master]
GO
ALTER DATABASE [test] SET RECOVERY SIMPLE WITH NO_WAIT
GO
ALTER DATABASE [test] MODIFY FILE ( NAME = N'test', FILEGROWTH = 0)
GO



BACKUP DATABASE [test] TO DISK = N'C:\test.bak' 
WITH NOFORMAT, NOINIT,  NAME = N'test-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO


use test
GO
create table test(id int,name varchar(100),location varchar(100))

insert into test values(1,'harsha','india')
GO 50000

SELECT COUNT(*) FROM test


-- Query to get detailed information about database files
SELECT 
    db.name AS [Database Name],
    mf.name AS [File Name],
    mf.physical_name AS [Physical File Name],
    mf.type_desc AS [File Type],
    mf.state_desc AS [File State],
    CAST(mf.size AS BIGINT) * 8 / 1024 AS [Size (MB)],
    CASE 
        WHEN mf.is_percent_growth = 1 THEN CAST(mf.growth AS NVARCHAR(20)) + ' %'
        ELSE CAST(mf.growth * 8 / 1024 AS NVARCHAR(20)) + ' MB'
    END AS [Autogrowth],
    mf.max_size AS [Max Size]
FROM 
    sys.master_files mf
JOIN 
    sys.databases db ON mf.database_id = db.database_id
	 WHERE db.name = 'TEST' 
ORDER BY 
    db.name, mf.type_desc;
	

 DECLARE
       @dbname VARCHAR(100) = NULL,
       @SpaceUsed FLOAT = NULL
DECLARE @LOGSPACE TABLE(
       dbName VARCHAR(100),
       LogSizeMB FLOAT,
       [LogSpaceUsed%] FLOAT,
       [Status] INT
       )
INSERT @LOGSPACE EXEC ('DBCC SQLPERF(''logspace'')')
SELECT dbName, LogSizeMB, [LogSpaceUsed%], [Status] FROM @LOGSPACE where [dbName] = 'TEST'

select * from sys.sysmessages where msglangid = 1033 and severity = 17