--set database in single user mode
alter database databasename
set single_user with rollback immediate

--set database offline
alter database databasename set offline

--rename the physical file names of the target database

--update the system catalog where the older file name is present
alter database databasename
modify file (name = 'logicaldatabasefilename', filename = 'path')
alter database databasename
modify file (name = 'logicaldatabaselogfilename', filename = 'path')

--bring database online
alter database databasename set online

--set database in multi user mode
alter database databasename
set multi_user