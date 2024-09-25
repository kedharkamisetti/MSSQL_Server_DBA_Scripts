--for full backup
restore database databasename from disk = 'path\filename.bak'
with norecovery,
move 'mdffilename' to 'newpath\filename.mdf',
move 'ldffilename' to 'newpath\filename.ldf'

--for differential backup
restore database databasename from disk = 'path\filename.bak' with norecovery

--for log backup
restore log databasename from disk = 'path\filename.trn' with recovery

--for changing the recovery status of a database
restore database databasename with recovery