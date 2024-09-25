USE [databasename]
GO
ALTER ROLE [db_datareader] DROP MEMBER [username]
GO
USE [databasename]
GO
ALTER ROLE [db_owner] ADD MEMBER [username]
GO