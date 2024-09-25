CREATE TABLE #sp_who2 (SPID INT,Status VARCHAR(255),
      Login  VARCHAR(255),HostName  VARCHAR(255),
      BlkBy  VARCHAR(255),DBName  VARCHAR(255),
      Command VARCHAR(255),CPUTime INT,
      DiskIO INT,LastBatch VARCHAR(255),
      ProgramName VARCHAR(255),SPID2 INT,
      REQUESTID INT)
Insert into #sp_who2 EXEC sp_who2
--Filter the results
Select * FROM #sp_who2 ---- filter the results by using where condition.

Truncate table #sp_who2 --Note:Truncate the table everytime to load current result set.
select * from #sp_who2 where spid >55 and ProgramName = 'Microsoft SQL Server Management Studio - Query'

========================

SELECT CO.client_net_address,SE.host_name,SE.login_name,ST.text
FROM sys.dm_exec_sessions SE
INNER JOIN sys.dm_exec_connections CO ON SE.session_id = CO.session_id
CROSS APPLY sys.dm_exec_sql_text(CO.most_recent_sql_handle) ST
WHERE SE.program_name LIKE 'Microsoft SQL Server Management Studio%'
ORDER BY SE.program_name, CO.client_net_address;
