DECLARE @datapath NVARCHAR(260) = 'D:\SQLdata';
DECLARE @logpath NVARCHAR(260) = 'G:\SQLLogs';

DECLARE @Statements NVARCHAR(MAX);

WITH DatabaseFilesCTE AS (
    SELECT 
        d.name AS DatabaseName, 
        f.name AS LogicalName,
        RIGHT(f.physical_name, CHARINDEX('\', REVERSE(f.physical_name)) - 1) AS FileName,
        f.type_desc AS TypeofFile,
        CASE 
            WHEN f.type_desc = 'ROWS' THEN @datapath
            WHEN f.type_desc = 'LOG' THEN @logpath
            ELSE '' -- Handle other file types if needed
        END AS NewPath
    FROM 
        sys.master_files f
    INNER JOIN 
        sys.databases d ON d.database_id = f.database_id
    WHERE 
        d.name NOT IN ('master', 'model', 'msdb', 'tempdb')
        AND f.type_desc IN ('ROWS', 'LOG')
)
SELECT 
    @Statements = COALESCE(@Statements + CHAR(13) + CHAR(10), '') +
        'ALTER DATABASE [' + DatabaseName + '] MODIFY FILE (NAME = [' + LogicalName + '], FILENAME = ''' + NewPath + '\' + FileName + ''')'
FROM 
    DatabaseFilesCTE;

PRINT @Statements;