Use DB_Name;  --Change your database here
go
SELECT 
 s.name + '.' + t.Name AS [Table Name],
 part.rows AS [Total Rows In Table - Modified],
 CAST((SUM( DISTINCT au.Total_pages) * 8 ) / 1024.000 / 1024.000 AS NUMERIC(18, 3)) 
 AS [Table's Total Space In GB]
FROM
 SYS.Tables t INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
 INNER JOIN SYS.Indexes idx ON t.Object_id = idx.Object_i
 INNER JOIN SYS.Partitions part ON idx.Object_id = part.Object_id 
                    AND idx.Index_id = part.Index_id
 INNER JOIN SYS.Allocation_units au ON part.Partition_id = au.Container_id
 INNER JOIN SYS.Filegroups fGrp ON idx.Data_space_id = fGrp.Data_space_i
 INNER JOIN SYS.Database_files Df ON Df.Data_space_id = fGrp.Data_space_id
WHERE t.Is_ms_shipped = 0 AND idx.Object_id > 255 
GROUP BY t.Name, s.name, part.rows
ORDER BY [Table's Total Space In GB] DESC