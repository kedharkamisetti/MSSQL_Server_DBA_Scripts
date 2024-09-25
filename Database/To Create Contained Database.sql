--enable contained database feature in instance settings
EXEC sys.sp_configure 'contained database authentication', '1'
GO
RECONFIGURE WITH OVERRIDE
GO

--change the containment type in database settings
ALTER DATABASE [databasename] SET CONTAINMENT = PARTIAL WITH NO_WAIT
GO

--create a database user to use contained database
USE [databasename]
CREATE USER [username] WITH PASSWORD=N'complexpassword'


--to check the database containment type
select containment, name from sys.databases where name = 'databasename'

--to check which users are listed as contained users
select name, type_desc, authentication_type_desc
from sys.database_principals where authentication_type = 2