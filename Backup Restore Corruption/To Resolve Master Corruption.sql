--Master is the most crucial database in an instance, if it is corrupt entire instance gets affected.
--If master database is corrupt, it is either completely corrupt or partially corrupt. If partially corrupt (only some pages are corrupt) instance will start with -m;-t3608 and if it is completely corrupt instance wouldn't start.



--Method1:-
--1. Master database doesn't start with /m /t3608 and hence we need to rebuild the master database.
--2. Rebuild master
--SQL Server 2005:
start /wait setup.exe /qb INSTANCENAME=MSSQLSERVER REINSTALL=SQL_Engine REBUILDDATABASE=1 SAPWD=Admin143$$

--SQL Server 2008:
setup.exe /QUIETSIMPLE /ACTION=REBUILDDATABASE /INSTANCENAME="MSSQLSERVER" /SQLSYSADMINACCOUNTS="KDSSG\KDSSGDBATEAM" /SAPWD="Admin143$$"

--SQL Server 2008R2/2012/2014/2016/2017/2019:
setup.exe /QS /ACTION=REBUILDDATABASE /INSTANCENAME="MSSQLSERVER" /SQLSYSADMINACCOUNTS="KDP-PC\Krish" /SAPWD="Admin143$$$$$" /IAcceptSQLServerLicenseTerms

--1. Start instance with /m /t3608
--'/m' means 'single user mode' and '/t3608' is 'master only mode'
net stop "SQL Server (MSSQLSERVER)"
net start "SQL Server (MSSQLSERVER)" /m /t3608
--2. Restore master database WITH REPLACE option
restore database master from disk=N'F:\Master.bak' WITH REPLACE

--Rebuilding master also rebuilds Model, MSDB. So restore model and msdb backups too.



--Method2:-
--Restore master database using files in Binn\Templates directory. In this scenario no need to rebuild the instance and also Model and MSDB databases are left untouched.

--1. As instance is corrupt, so stop SQL Server instance.
net stop "SQL Server (MSSQLSERVER)"
--2. Copy the files in Binn\Templates in instance root directory to DATA directory.
--3. Now start the instance with /m and /t3608
--'/m' means 'single user mode' and '/t3608' is 'master only mode'
net start "SQL Server (MSSQLSERVER)" /m /t3608
--4. Now instance starts but master has incorrect path references to all the other databases. So a restore would not work. So first we will have to check and change all path references using below commands.

select * from sys.sysdatabases
select * from sys.sysaltfiles

--Changing incorrect path references using below commands.

alter database [mssqlsystemresource] modify file (name='Data',filename='C:\Program Files\Microsoft SQL Server\MSSQL13.INST2K16\MSSQL\Binn\mssqlsystemresource.mdf')
alter database [mssqlsystemresource] modify file (name='Log',filename='C:\Program Files\Microsoft SQL Server\MSSQL13.INST2K16\MSSQL\Binn\mssqlsystemresource.ldf')

alter database [model] modify file (name='modeldev',filename='C:\Program Files\Microsoft SQL Server\MSSQL13.INST2K16\MSSQL\DATA\model.mdf')
alter database [model] modify file (name='modellog',filename='C:\Program Files\Microsoft SQL Server\MSSQL13.INST2K16\MSSQL\DATA\modellog.ldf')

alter database [msdb] modify file (name='MSDBData',filename='C:\Program Files\Microsoft SQL Server\MSSQL13.INST2K16\MSSQL\DATA\MSDBData.mdf')
alter database [msdb] modify file (name='MSDBLog',filename='C:\Program Files\Microsoft SQL Server\MSSQL13.INST2K16\MSSQL\DATA\MSDBLog.ldf')

alter database [tempdb] modify file (name='tempdev',filename='C:\Program Files\Microsoft SQL Server\MSSQL13.INST2K16\MSSQL\DATA\tempdb.mdf')
alter database [tempdb] modify file (name='templog',filename='C:\Program Files\Microsoft SQL Server\MSSQL13.INST2K16\MSSQL\DATA\templog.ldf')

--Create login as its a new master and there will be no logins in the instance.

CREATE LOGIN [KDSSG\KDSSGDBATeam] FROM WINDOWS
sp_addsrvrolemember 'KDSSG\KDSSGDBATeam','sysadmin'

--1. After all references are changes, restart the instance once with /m /t3608 for all changes to take affect.
--'/m' means 'single user mode' and '/t3608' is 'master only mode'
net stop "SQL Server (MSSQLSERVER)"
net start "SQL Server (MSSQLSERVER)" /m /t3608
--2. Now restore the backup of master.
restore database [master] from disk=N'Master.bak' with replace.



--Method3:-
--Resolving Master database corruption through Restoring it as a user database in another instance.
--1. Restore master database as a user database in another instance.
Restore database [master_copy] from disk=N'C:\Media\Master_Full.bak'
WITH MOVE 'Master' to 'C:\Media\Master_Copy.mdf',
MOVE 'Master_log' to 'C:\Media\Master_Copy.ldf'
--2. After restoring master database a user database. Detach the database.
sp_detach_db 'Master_Copy'
--3. Rename the files C:\Media\Master_Copy.mdf and C:\Media\Master_Copy.ldf as master database files(master.mdf and master_log.ldf) and replace them with existing Master database in Data Directory.
--4. Stop the instance and start the instance normally.