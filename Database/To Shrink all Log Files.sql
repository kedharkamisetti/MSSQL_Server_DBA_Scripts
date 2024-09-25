USE master;
GO

DECLARE @Log_name VARCHAR(1000);
DECLARE @Db_name VARCHAR(1000);
DECLARE @Recovery_model_desc VARCHAR(1000);
DECLARE @SQL NVARCHAR(2000);
DECLARE @ParmDefinition NVARCHAR(1000);
DECLARE @SizeAfter INT;

DECLARE db_cursor CURSOR FOR
SELECT 
    F.NAME AS [LOG_NAME],
    DB.NAME AS [DB_NAME],
    DB.RECOVERY_MODEL_DESC AS [RECOVERY_MODEL_DESC]
FROM 
    MASTER.SYS.MASTER_FILES F
    INNER JOIN MASTER.SYS.DATABASES DB ON DB.DATABASE_ID = F.DATABASE_ID
WHERE 
    F.FILE_ID = 2
    AND DB.NAME <> 'master'
    AND DB.NAME <> 'model'
    AND DB.NAME <> 'msdb'
    AND DB.NAME <> 'tempdb'
    AND DB.NAME <> 'distribution'
    AND DB.STATE_DESC = 'ONLINE';

OPEN db_cursor;

FETCH NEXT FROM db_cursor INTO @Log_name, @Db_name, @Recovery_model_desc;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = N'
        SELECT F.SIZE
        FROM MASTER.SYS.MASTER_FILES F
        INNER JOIN MASTER.SYS.DATABASES DB ON DB.DATABASE_ID = F.DATABASE_ID
        WHERE F.NAME = ''' + @Log_name + ''' AND DB.NAME = ''' + @Db_name + '''
    ';

    SET @SQL = @SQL + N'
        USE [' + @Db_name + '];
        CHECKPOINT;
        DBCC SHRINKFILE (' + @Log_name + ', 10);
    ';

    SET @sql = @sql + N'
        SELECT F.SIZE
        FROM MASTER.SYS.MASTER_FILES F
        INNER JOIN MASTER.SYS.DATABASES DB ON DB.DATABASE_ID = F.DATABASE_ID
        WHERE F.NAME = ''' + @Log_name + ''' AND DB.NAME = ''' + @Db_name + '''
    ';

    SET @ParmDefinition = N'@Size INT OUTPUT';

    EXECUTE sp_executesql @SQL, @ParmDefinition, @Size = @SizeAfter OUTPUT;

    FETCH NEXT FROM db_cursor INTO @Log_name, @Db_name, @Recovery_model_desc;
END;

CLOSE db_cursor;
DEALLOCATE db_cursor;