--for specific database
USE msdb;
GO

SELECT
    b.database_name, 
    bm.physical_device_name, 
    b.backup_start_date, 
    b.backup_finish_date
FROM 
    dbo.backupset b
JOIN 
    dbo.backupmediafamily bm
    ON b.media_set_id = bm.media_set_id
WHERE 
    b.database_name = 'YourDatabaseName'
ORDER BY 
    b.backup_finish_date DESC;



--for all databases
SELECT
    bs.database_name,
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.server_name, 
    bs.user_name,
    bs.type,
    bm.physical_device_name
FROM msdb.dbo.backupset AS bs
INNER JOIN msdb.dbo.backupmediafamily AS bm on bs.media_set_id = bm.media_set_id

--or

SELECT 
    database_name, 
    backup_size/1024/1024 AS 'Backup Size in MB', 
    backup_start_date, 
    backup_finish_date, 
    CASE type 
        WHEN 'D' THEN 'Full'
        WHEN 'I' THEN 'Differential'
        WHEN 'L' THEN 'Transaction Log'
    END AS 'Backup Type'
FROM 
    msdb.dbo.backupset
WHERE 
    backup_start_date > DATEADD(mm, -1, GETDATE())
ORDER BY 
    backup_start_date DESC;