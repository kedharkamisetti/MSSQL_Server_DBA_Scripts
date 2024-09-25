select login_name ,DB_NAME(database_id) As Database_Name , count(*) as Total_connections from sys.dm_exec_sessions where session_id > 55
group by login_name,DB_NAME(database_id)