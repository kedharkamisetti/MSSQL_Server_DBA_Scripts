--first add these counters in performance monitor
--Avg Disk Reads/sec     (<=8 is good, >20 is bad)
--Avg Disk Writes/sec    (<=1 is good, >4 is bad)
--Avg Disk Transfer
--Avg Disk Queue Length

--use the following command to analyse IO related metrics
select * from sys.dm_io_virtual_file_stats