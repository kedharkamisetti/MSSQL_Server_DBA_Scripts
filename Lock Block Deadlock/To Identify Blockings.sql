select * from sys.dm_exec_requests
where session_id>50 and blocking_session_id<>0