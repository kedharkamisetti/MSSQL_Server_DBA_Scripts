--for a specific database
select databasepropertyex ('databasename', 'status')

--for all databases
select name, state_desc from sys.databases
--or
sp_helpdb