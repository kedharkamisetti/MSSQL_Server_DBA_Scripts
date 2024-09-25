--full backup
backup database databasename to disk = 'path\filename.bak'

--differential backup
backup database databasename to disk = 'path\filename.bak' with differential

--transaction log backup
backup log databasename to disk = 'path\filename.trn'

--tail log backup
--to perform tail log backup and keep the database in restoring state
backup log databasename to disk = 'path\filename.trun' with norecovery
--or
--use this only when the database is damaged
backup log databasename to disk = 'path\filename.trn' with no_truncate
--or
--use this when the database is damaged and unable to take tail log backup
backup log databasename to disk = 'path\filename.trun' with continue_after_error

--file backup
backup database databasename flie = 'filename' to disk = 'path\filename.fil'

--filegroup backup
backup database databasename filegroup = 'filegroupname' to disk = 'path\filename.flg'

--partial backup (for read_write_filegroups)
backup database databasename read_write_filegroups to disk = 'path\filename.bak'

--split backup (upto 64)
backup database databasename to
disk = 'path1\filename1.bak',
disk = 'path2\filename2.bak',
disk = 'path3\filename3.bak'

--copy only backup
backup database databasename to disk = 'path\filename.bak' with copy_only

--mirror backup (upto 4)
backup database databasename
to disk = 'path1\filename.bak'
mirror
to disk = 'path2\filename.bak'
with format

--to compress a backup
backup database databasename to disk = 'path\filename.bak' with compression

--to take a backup with modified buffercount, buffersize and status
--buffer count range = 1 to int_max
--by default sql server uses buffer count of 7 (7 during taking backup and 6 during restoring the backup) and int_max means the maximum value of an int on the platform being used.
--buffer size (maxtransfersize) range = 64 KB to 4 MB and we should write in bytes, so 65536 bytes(64 KB) and 4194304 (4 MB)
--stats will tell how much the backup is completed 1 to 100, like every 5% or 10% and so on... based on the value that we want.
backup database databasename to disk = 'path\filename.bak'
with buffercount = 14, maxtransfersize = 4194304, stats = 5