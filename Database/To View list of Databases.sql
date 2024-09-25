select * from sys.databases

--or

select * from sys.sysaltfiles

--or

sp_helpdb

--or

select sys.databases.name as Database_name,
sys.master_files.name as Logical_name,
Physical_name, type_desc
from sys.master_files
inner join
sys.databases
on sys.master_files.database_id = sys.databases.database_id