USE master;
GO
DECLARE @newfilepath NVARCHAR(260) = 'E:\data\new\'; -- Update this with your new file path

DECLARE @stmt NVARCHAR(MAX) = '';
SELECT @stmt += 'ALTER DATABASE tempdb MODIFY FILE (NAME = ' + name + ', FILENAME = ''' + @newfilepath + REPLACE(physical_name, 'C:\Program Files\Microsoft SQL Server\MSSQL15.SQLHYD2019\MSSQL\DATA\', '') + ''') '  + CHAR(13)
FROM tempdb.sys.database_files;
PRINT @stmt