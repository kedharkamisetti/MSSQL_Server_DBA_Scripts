--for a specific database
select name, physical_name from databasename.sys.database_files

--for the list of all databases
select file_id, name, physical_name from sys.master_files