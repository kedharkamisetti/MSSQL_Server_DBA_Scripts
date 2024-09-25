--use the following rules only with small tables
--fragmentation = 0-10% (No Action)
--fragmentation = 10-30% (Reorganize)
--fragmentation = >30% (Rebuild)
--if the table size is huge, then even 4% fragmentation is also needs to be fixed.


--to rebuild the index, use the following command:
	--to keep the table online while rebuilding, use "online = on"
	--to add fillfactor or intermediate level pages, use "pad_index = on"
	--to use tempdb space for sorting while rebuilding, use "sort_in_tempdb = on"
	--to pause rebuild index process, use "resumable = on"
	--to allocate more worker threads to rebuilding, use "maxdop = no.ofworkerthreads"
ALTER INDEX [indexname]
ON [tablename] REBUILD
WITH (ONLINE = ON, 
			FILLFACTOR = 70, 
			pad_index = on, 
			sort_in_tempdb = on, 
			resumable = on, 
			maxdop = 12);
GO

-- Reorganize the index
ALTER INDEX [indexname]
ON [tablename] REORGANIZE;
GO