DECLARE @SQL NVARCHAR(MAX)
SET @SQL = ''
DECLARE @SessionID INT
DECLARE spid_cursor CURSOR FOR
SELECT spid
FROM master..sysprocesses
WHERE DB_NAME(dbid) NOT IN ('master', 'tempdb', 'model', 'msdb', 'distribution') -- Exclude specified database names
OPEN spid_cursor
FETCH NEXT FROM spid_cursor INTO @SessionID
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = @SQL + 'KILL ' + CAST(@SessionID AS NVARCHAR(10)) + ';' + CHAR(13)
    FETCH NEXT FROM spid_cursor INTO @SessionID
END
CLOSE spid_cursor
DEALLOCATE spid_cursor
PRINT @SQL -- View the generated script
-- If you are satisfied with the script, uncomment the following line to execute it:
--EXEC sp_executesql @SQL