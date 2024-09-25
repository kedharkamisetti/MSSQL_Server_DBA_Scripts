::for default instance

::run cmd
::to stop the default instance
Net stop Mssqlsever
::to start the default instance in single user mode
Net start MSQLSERVER /m"SQLCMD"
::to run quries
SQLCMD
::to create a login
Create login loginname with password = 'urpassword'
go
::to add the login into a role
Sp_addsrvrolemember loginname , "SYSADMIN"
Go


::for named instance
::everything will be the same, except the name
::mention "mssql$" infront of name of the instance and rest of the process is same
::ex: net stop mssql$instancename