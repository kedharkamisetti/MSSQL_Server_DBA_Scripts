select * from sys.dm_db_index_operational_stats(DB_ID (N'databasename'),OBJECT_ID('tablename'),NULL,NULL)


-- With DETAILED option
SELECT * FROM sys.dm_db_index_physical_stats (
	DB_ID (N'databasename'),
	OBJECT_ID('tablename'),
	NULL,
	NULL,
	N'DETAILED');
GO


-- And now with a bit more useful info
SELECT
	OBJECT_NAME ([ips].[object_id]) AS [Object Name],
	[si].[name] AS [Index Name],
	ROUND ([ips].[avg_fragmentation_in_percent], 2) AS [Fragmentation],
	[ips].[page_count] AS [Pages],
	ROUND ([ips].[avg_page_space_used_in_percent], 2) AS [Page Density]
FROM sys.dm_db_index_physical_stats 
(DB_ID (N'databasename'), NULL, NULL, NULL, N'DETAILED') [ips]
CROSS APPLY [sys].[indexes] [si]
WHERE
	[si].[object_id] = [ips].[object_id]
	AND [si].[index_id] = [ips].[index_id]
	AND [ips].[index_level] = 0
GO