select * from sys.dm_os_memory_clerks

--to view only unique but not duplicates, use the following command
select distinct(type) from sys.dm_os_memory_clerks
order by type