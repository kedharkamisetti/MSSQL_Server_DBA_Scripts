--first add these counters in performance monitor
--Memory -> Available Mbytes
--SQL Server -> Memory Manager -> Target Server Memory (KB)
--SQL Server -> Memory Manager -> Total Server Memory (KB)
--SQL Server: Memory Manager: Memory Grants Pending
--SQL Server: Buffer Manager -> Free List Stalls/sec
--SQL Server: Buffer Manager -> Page Life Expectancy
--SQL Server: Buffer Manager -> Buffer Cache Hit Ratio  (>95% is good)
--SQL Server: BufferManager -> Lazy Writes/sec
--SQL Server: BufferManager -> Page Reads/sec

--to view how much memory is sql server is consuming:
select sum(pages_kb) from sys.dm_os_memory_clerks

--to find out who is consuming more memory in SQL Server use below query:
select * from sys.dm_os_memory_clerks order by pages_kb desc