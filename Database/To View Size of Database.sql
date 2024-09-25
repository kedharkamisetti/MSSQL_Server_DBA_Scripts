sp_spaceused


--for all databases
-- To retrieve list of all the databases on your SQL Server instance, showing the logical name, physical location, size in GBs, and whether the file is a data file (MDF) or log file --
SELECT 
    DB_NAME(database_id) AS [Database Name],
    CAST(SUM(size) * 8. / 1024 / 1024 AS DECIMAL(8,2)) AS [Total Size in GB],
    CAST(SUM(CASE WHEN type_desc = 'LOG' THEN size END) * 8. / 1024 / 1024 AS DECIMAL(8,2)) AS [Log Size in GB],
    CAST(SUM(CASE WHEN type_desc = 'ROWS' THEN size END) * 8. / 1024 / 1024 AS DECIMAL(8,2)) AS [Data Size in GB],
    CAST(SUM(CASE WHEN type_desc = 'ROWS' THEN (size - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)) END) * 8. / 1024 / 1024 AS DECIMAL(8,2)) AS [Available Space in GB]
FROM 
    sys.master_files
GROUP BY 
    database_id
ORDER BY 
    [Database Name];

-- To retrieve list of all databases on the SQL Server instance, showing the total size, log file size, data file size, and available space for each database in GB --
SELECT 
    DB_NAME(database_id) AS [Database Name],
    Name AS [Logical Name],
    Physical_Name AS [File Location],
    (size * 8.0 / 1024 / 1024) AS [Size in GBs],
    type_desc AS [File Type]
FROM 
    sys.master_files
ORDER BY 
    [Database Name], [File Type]; 