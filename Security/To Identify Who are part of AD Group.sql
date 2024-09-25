--Finding out members of Active Directory Group that is already in SQL Server
EXEC master.dbo.xp_logininfo 'Forest\SQLADMINS',@option ='Members'


--Finding out Active directory group that below user belong to.
EXEC master.dbo.xp_logininfo 'FOREST\user02'