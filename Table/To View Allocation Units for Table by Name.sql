select * from sys.system_internals_allocation_units
where container_id=(select hobt_id from sys.partitions
where object_id=object_id('tablename'))