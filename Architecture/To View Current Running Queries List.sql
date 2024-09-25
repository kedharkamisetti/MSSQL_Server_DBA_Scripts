select * from sys.dm_exec_requests where session_id>50 and status = 'running'

--for active sessions
SELECT sqltext.TEXT,
req.session_id,
req.status,
req.command,
req.cpu_time,req.database_id,
req.total_elapsed_time
FROM sys.dm_exec_requests req
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext where sqltext.text like '%Your Target Key Word%'

--for sleeping user sessions
SELECT CURRENT_TIMESTAMP as currenttime, datediff(minute,last_batch,GETDATE()) as 'idletime_in_minute' ,sp.status,sp.spid,sp.login_time,sp.program_name,sp.hostprocess,sp.loginame,text FROM sys.sysprocesses sp CROSS APPLY sys.dm_exec_sql_text(sp.sql_handle) AS QT where sp.status = 'sleeping' and datediff(minute,last_batch,GETDATE()) >15 and spid>50