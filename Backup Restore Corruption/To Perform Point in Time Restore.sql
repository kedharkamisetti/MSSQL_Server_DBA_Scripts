--to identify the drop transaction
select [Current LSN], [Operation], [Transaction ID], [Parent Transaction ID],
	[Begin Time], [Transaction Name], [Transaction SID]
from fn_dblog(null, null)
where [Operation] = 'LOP_BEGIN_XACT' and [Transaction Name]='DROPOBJ'


--If log file was truncated, then we can use fn_dump_dblog to retrieve LSN information from Log Backup.
SELECT [Current LSN], [Operation], [Transaction ID], [Parent Transaction ID],
	[Begin Time], [Transaction Name], [Transaction SID]
FROM fn_dump_dblog
(
DEFAULT, DEFAULT, DEFAULT, DEFAULT, 
'C:\Backups\PIT_Tlog3.trn', 
DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, 
DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, 
DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, 
DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, 
DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, 
DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, 
DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT
)
where OPERATION='LOP_BEGIN_XACT' and [Transaction Name]='DROPOBJ'
GO


--To find person who dropped the table use:
select suser_sname(transactionsid)


--For Point in Time recovery mention STOPAT parameter with appropriate timeline (or) STOPBEFOREMARK with LSN Number.
USE [master]
RESTORE DATABASE [newdatabasename] FROM  DISK = N'path\filename.bak' 
WITH   
MOVE N'mdffilename' TO N'newpath\filename.mdf',  
MOVE N'ldffilename' TO N'newpath\filename.ldf',  
NORECOVERY,  STATS = 5

RESTORE DATABASE [newdatabasename] FROM  DISK = N'path\filename.bak' WITH NORECOVERY

RESTORE LOG [newdatabasename] FROM  DISK = N'path\filename.trn' WITH  NORECOVERY

--Restores to specific Time provided.
RESTORE LOG [newdatabasename] FROM  DISK = N'path\filename.trn' WITH  RECOVERY, 
STOPAT = N'Jul 10, 2017 07:06:06:136 AM'

--Restores to specific LSN Number.
RESTORE LOG [newdatabasename] FROM  DISK = N'path\filename.trn' 
WITH STOPBEFOREMARK = 'lsn:0x00000020:00000161:0001'
GO
--Prefix 'lsn:0x' along with the LSN number for hexadecimal format.
