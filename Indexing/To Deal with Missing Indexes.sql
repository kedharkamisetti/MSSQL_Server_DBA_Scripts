--Missing Indexes Script
--this will suggest if indexes are required
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT TOP 100 st.text AS [Parent Query] , 
DB_NAME(st.dbid)AS [DatabaseName] , 
cp.usecounts AS [Usage Count] , 
qp.query_plan FROM sys.dm_exec_cached_plans cp 
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st 
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp 
WHERE CAST(qp.query_plan AS NVARCHAR(MAX)) 
LIKE '%<MissingIndexes>%'ORDER BY cp.usecounts DESC