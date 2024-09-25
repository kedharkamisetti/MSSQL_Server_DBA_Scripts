select name, type, buckets_count
from sys.dm_os_memory_cache_hash_tables
where name IN ( 'SQL Plans' , 'Object Plans' , 'Bound Trees' ,'Extended Stored Procedures')

select name, type, pages_kb, entries_count
from sys.dm_os_memory_cache_counters
where name IN ( 'SQL Plans' , 'Object Plans' ,  'Bound Trees' ,'Extended Stored Procedures')