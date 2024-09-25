SELECT 'You have connected as "DAC"' [Who you are] 
FROM sys.dm_exec_sessions s join sys.endpoints  e
ON (s.endpoint_id = e.endpoint_id) 
WHERE e.name ='Dedicated Admin Connection'
AND s.session_id = @@spid
GO