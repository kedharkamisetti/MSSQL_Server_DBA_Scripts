select Object_name(object_id) as TableName,* 
from sys.partitions 
where object_id=object_id('tablename')