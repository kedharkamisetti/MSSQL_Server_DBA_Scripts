--to set the database online
alter database databasename set online

--to set the database offline
alter database databasename set offline
with rollback immediate
--this last line will stop any uncommitted transactions.