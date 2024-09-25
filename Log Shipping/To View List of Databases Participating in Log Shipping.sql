--the following commands will give the list of databases and info about jobs as well

--in primary:
--to get the info about last backup file
select * from msdb.dbo.log_shipping_primary_databases

--in standby/secondary:
--to get the info about last copy file
select * from msdb.dbo.log_shipping_secondary
--to get the info about last restore file
select * from msdb.dbo.log_shipping_secondary_databases