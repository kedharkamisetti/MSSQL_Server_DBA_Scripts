--to connect another sql server
EXEC master.dbo.sp_addlinkedserver @server = N'servername', @srvproduct=N'SQL Server'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = N'servername', @rmtuser = N'loginname', @rmtpassword = N'loginpassword'