--Execute the below script on the secondary server
declare @databaseName varchar(300)
set @databaseName = 'databasename' -- Secondary Database Name
-- 0 = Restore log with NORECOVERY.
-- 1 = Restore log with STANDBY.
select secondary_database,
case restore_mode 
when 0 then 'No Recovery'
when 1 then 'Stand by' end AS 'restore_mode'
from msdb.dbo.log_shipping_secondary_databases 
where secondary_database = @databaseName

--Execute the below script on the secondary server
update msdb.dbo.log_shipping_secondary_databases
set restore_mode = 1, disconnect_users=1
where secondary_database = 'databasename'