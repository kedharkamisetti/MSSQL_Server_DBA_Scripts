USE [databasename]
DBCC SHRINKFILE (N'databasename_Log' , 0, TRUNCATEONLY)