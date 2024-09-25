--first add these counters in performance monitor
--Processor: Processor Time
--Processor: Privileged Time
--Processor: User Time
--System: Processor Queue Length   (<2 is good)



--the following queries will help you to deal with executed queries which has longer time to execute:
--Top three queries by total worker time (DESC)
SELECT TOP 3
        [qs].[last_worker_time],
        [qs].[max_worker_time],
        [qs].[total_worker_time],
        [qs].[execution_count],
        stmt_start = [qs].[statement_start_offset],
        stmt_end = [qs].[statement_end_offset],
        [qt].[dbid],
        [qt].[objectid],
        SUBSTRING([qt].[text], [qs].[statement_start_offset] / 2,
                  (CASE WHEN [qs].[statement_end_offset] = -1
                        THEN LEN(CONVERT(NVARCHAR(MAX), [qt].[text])) * 2
                        ELSE [qs].[statement_end_offset]
                   END - [qs].[statement_start_offset]) / 2) AS statement
FROM    [sys].[dm_exec_query_stats] qs
CROSS APPLY [sys].[dm_exec_sql_text]([qs].[sql_handle]) AS qt
ORDER BY [qs].[total_worker_time] DESC;

-- But observe properly there is something important missing in this result?
SELECT  [qs].[last_worker_time],
        [qs].[max_worker_time],
        [qs].[total_worker_time],
        [qs].[execution_count],
        stmt_start = [qs].[statement_start_offset],
        stmt_end = [qs].[statement_end_offset],
        [qt].[dbid],
        [qt].[objectid],
        SUBSTRING([qt].[text], [qs].[statement_start_offset] / 2,
                  (CASE WHEN [qs].[statement_end_offset] = -1
                        THEN LEN(CONVERT(NVARCHAR(MAX), [qt].[text])) * 2
                        ELSE [qs].[statement_end_offset]
                   END - [qs].[statement_start_offset]) / 2) AS statement
FROM    [sys].[dm_exec_query_stats] qs
CROSS APPLY [sys].[dm_exec_sql_text]([qs].[sql_handle]) AS qt
ORDER BY [qs].[total_worker_time] DESC;
--If you observe the output there would be many smaller queries with shorter
--execution times which are may be consuming more CPU. So aggregate and validate.

-- Now lets try it based on aggregated time and look for several executes
SELECT TOP 5
        [qs].[query_hash],
        SUM([qs].[total_worker_time]) total_worker_time,
        SUM([qs].[execution_count]) total_execution_count
FROM    [sys].[dm_exec_query_stats] qs
CROSS APPLY [sys].[dm_exec_sql_text]([qs].[sql_handle]) AS qt
GROUP BY [qs].[query_hash]
HAVING  SUM([qs].[execution_count]) > 100
ORDER BY SUM([qs].[total_worker_time]) DESC;
--Observe this query where we are grouping queries with similar Query Hash, which 
--would tell us how many queries are similar natured and are doing repeated execution.
--They all will have same Query Hash. (What is Query Hash?)

-- Plug in query hash for an example
SELECT  SUBSTRING([qt].[text], [qs].[statement_start_offset] / 2,
                  (CASE WHEN [qs].[statement_end_offset] = -1
                        THEN LEN(CONVERT(NVARCHAR(MAX), [qt].[text])) * 2
                        ELSE [qs].[statement_end_offset]
                   END - [qs].[statement_start_offset]) / 2) AS statement,
        [qs].[total_worker_time],
        [qs].[execution_count],
        [qs].[query_hash],
        [qs].[query_plan_hash]
FROM    [sys].[dm_exec_query_stats] qs
CROSS APPLY [sys].[dm_exec_sql_text]([qs].[sql_handle]) AS qt
WHERE   [qs].[query_hash] = 0x284FF4A81CCF28ED;



--the following queries will help you to deal with high I/O:
-- What LIOs, PIOs, CPU time do we see?
SELECT  t.text,
        s.total_logical_reads,
        s.total_physical_reads,
        s.total_worker_time,
        p.query_plan
FROM    sys.dm_exec_query_stats s
CROSS APPLY sys.dm_exec_query_plan(s.plan_handle) p
CROSS APPLY sys.dm_exec_sql_text(s.plan_handle) t
WHERE   t.text LIKE '%WHERE charge_dt%';
GO