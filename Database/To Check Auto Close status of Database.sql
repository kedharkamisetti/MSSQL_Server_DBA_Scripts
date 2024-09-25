--for single database
select databaseproperty ('databasename', 'isautoclose')

--for all the databases in an instance
select name, is_auto_close_on from sys.databases
where is_auto_close_on = 1