--to get the info about indexes on a table and so on
Use databasename
GO
select * from sys.indexes where OBJECT_NAME(object_id)='tablename'

--to display the allocation and deallocation status of a data pages in a table or index
DBCC IND('databasename','tablename',0)

--we have to turn on this trace flag to view the content inside a page
DBCC TRACEON(3604,-1)

--to view the content inside a page
DBCC PAGE(14,1,296,3)
--dbcc page ({dbid}, {filenum}, {pagenum}, {printopt=[0|1|2|3]})
--0 = print just the page header
--1 = page header plus per-row hex dumps and a dump of the page slot array (unless its a page that doesn t have one, like allocation bitmaps)
--2 = page header plus whole page hex dump
--3 = page header plus detailed per-row interpretation

--Run DBCC CHECKDB, to identify if just a single page is corrupt or if multiple pages are corrupt.

--Take Backup with NORECOVERY, this will put database in --RESTORING State.
BACKUP LOG databasename
TO DISK=N'path\filename.trn'
WITH NORECOVERY

--Start the restore sequence.
--for full backup
restore database databasename
PAGE='1:312',PAGE='1:313'
from disk=N'path\filename.bak'
WITH NORECOVERY

--for differential backup
restore database databasename
from disk=N'path\filename.bak'
WITH NORECOVERY

--for log backup
restore log databasename
from disk=N'path\filename.trn'
WITH NORECOVERY

--to recover the recent log backup which took in the beginning
restore log databasename
from disk=N'path\filename.trn'
WITH RECOVERY