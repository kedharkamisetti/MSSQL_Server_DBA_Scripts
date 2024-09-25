-- Step 1: Buffer Pool Utilization by Database
-- Adjust the size calculation if the page size is different from 8 KB (8192 bytes).
SELECT 
    DBName = CASE WHEN database_id = 32767 THEN 'RESOURCEDB' 
                  ELSE DB_NAME(database_id) 
             END,
    Size_MB = COUNT(1) * 8 / 1024.0  -- Assuming each page is 8 KB (8192 bytes), adjust if necessary.
FROM sys.dm_os_buffer_descriptors
GROUP BY database_id
ORDER BY Size_MB DESC;

-- Step 2: Buffer Pool Utilization by Object in a Database
USE AdventureWorks2019;  -- Replace with your target database if necessary.
GO
SELECT 
    DBName = DB_NAME(obd.database_id),
    ObjName = o.name,
    Size_MB = COUNT(1) * 8 / 1024.0  -- Assuming each page is 8 KB (8192 bytes), adjust if necessary.
FROM sys.dm_os_buffer_descriptors obd
INNER JOIN sys.allocation_units au
    ON obd.allocation_unit_id = au.allocation_unit_id
INNER JOIN sys.partitions p
    ON au.container_id = p.hobt_id
INNER JOIN sys.objects o
    ON p.object_id = o.object_id
WHERE obd.database_id = DB_ID()
  AND o.type NOT IN ('S', 'IT')  -- Exclude system tables and internal tables.
GROUP BY obd.database_id, o.name
ORDER BY Size_MB DESC;

-- Step 3: Clean and Dirty Pages Count in a Database
USE AdventureWorks2019;  -- Replace with your target database if necessary.
GO
SELECT 
    Page_Status = CASE WHEN is_modified = 1 THEN 'Dirty' 
                       ELSE 'Clean' 
                  END,
    DBName = DB_NAME(database_id),
    Pages = COUNT(1)
FROM sys.dm_os_buffer_descriptors
WHERE database_id = DB_ID()
GROUP BY database_id, is_modified
ORDER BY Page_Status;

-- Step 4: Clear Dirty Pages from Memory
-- Ensure this operation is appropriate for your environment before running it.
CHECKPOINT;
GO

-- Step 5: Clean All Data Pages from Memory
-- Ensure this operation is appropriate for your environment before running it.
DBCC DROPCLEANBUFFERS;
GO
