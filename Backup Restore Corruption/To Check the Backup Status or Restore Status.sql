SELECT session_id as SPID, command, a.text AS Query, start_time, percent_complete, dateadd(second,estimated_completion_time/1000, getdate()) as estimated_completion_time 
FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a 
WHERE r.command in ('BACKUP DATABASE','RESTORE DATABASE')

--or

SELECT r.session_id AS [Session_Id]
,r.command AS [command]
,CONVERT(NUMERIC(6, 2), r.percent_complete) AS [% Complete]
,GETDATE() AS [Current Time]
,CONVERT(VARCHAR(20), DATEADD(ms, r.estimated_completion_time, GetDate()), 20) AS [Estimated Completion Time]
,CONVERT(NUMERIC(32, 2), r.total_elapsed_time / 1000.0 / 60.0) AS [Elapsed Min]
,CONVERT(NUMERIC(32, 2), r.estimated_completion_time / 1000.0 / 60.0) AS [Estimated Min]
,CONVERT(NUMERIC(32, 2), r.estimated_completion_time / 1000.0 / 60.0 / 60.0) AS [Estimated Hours]
,CONVERT(VARCHAR(1000), (
SELECT SUBSTRING(TEXT, r.statement_start_offset / 2, CASE
WHEN r.statement_end_offset = - 1
THEN 1000
ELSE (r.statement_end_offset - r.statement_start_offset) / 2
END) 'Statement text'
FROM sys.dm_exec_sql_text(sql_handle)
))
FROM sys.dm_exec_requests r
WHERE command like 'RESTORE%'
or command like 'BACKUP%'
or command like 'DbccFilesCompact'
or command like 'DbccSpaceReclaim'