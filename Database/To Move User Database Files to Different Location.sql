--identify the database files location
select file_id, name, physical_name
from databasename.sys.database_files

--set database offline
alter database databasename set offline
with rollback immediate

--now move the mdf and ldf files of the target database to the new location
--make sure your sql server have access to the new location

--now update the system catalog
alter database databasename
modify file (name = 'logicaldatabasename', filename = 'path')
alter database databasename
modify file (name = 'logicaldatabaselogname', filename = 'path')

--set database online
alter database databasename set online