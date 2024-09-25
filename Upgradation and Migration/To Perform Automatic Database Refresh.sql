--Steps to Setup Automatic Database Refresh between Two Servers:
	--modify the source and destination code accordingly.
	--use appropriate login and backup\copy\output paths in both source and destination.
	--create a database in destination with the same name as in source server.
	--then execute the job at source and in the destination.
	--finally deal with orphan users.





--use the following script to create a job in source server
USE [msdb]
GO

/****** Object:  Job [DB Refresh Back up of Adventurworks2019]    Script Date: 8/28/2024 4:47:00 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 8/28/2024 4:47:00 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DB Refresh Back up of Adventurworks2019', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'MAC1\kedhar', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Backup with Copyonly]    Script Date: 8/28/2024 4:47:00 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Backup with Copyonly', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=2, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'BACKUP DATABASE [AdventureWorks2019] TO  DISK = N''C:\sqlserver\backups\Adventureworks2019.bak'' WITH  COPY_ONLY, NOFORMAT, NOINIT,  
NAME = N''AdventureWorks2019-Full Database Backup'', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Move adventureworks2019.bak file to Destination Server.]    Script Date: 8/28/2024 4:47:00 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Move adventureworks2019.bak file to Destination Server.', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'Copy "C:\sqlserver\backups\*.bak" "C:\sqlserver\destination" /Y', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO





--use the following script to create a job in destination server
USE [msdb]
GO

/****** Object:  Job [DB Refresh of Adventureworks2019]    Script Date: 8/28/2024 4:50:03 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 8/28/2024 4:50:03 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DB Refresh of Adventureworks2019', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'MAC1\kedhar', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Back up of user permissions of destination Server database to Tempary table in tempdb]    Script Date: 8/28/2024 4:50:04 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Back up of user permissions of destination Server database to Tempary table in tempdb', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=2, 
		@on_fail_action=2, 
		@on_fail_step_id=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Create the global temporary table to hold the output
USE tempdb;
GO
IF OBJECT_ID(''tempdb..OutputTable'', ''U'') IS NOT NULL
    DROP TABLE tempdb..OutputTable;
GO
CREATE TABLE tempdb..OutputTable
(
    ID INT IDENTITY(1, 1),
    SQLStatement VARCHAR(2048)
);
GO

-- Check if the cursor already exists and deallocate it if it does
IF CURSOR_STATUS(''global'', ''tmp'') >= 0
BEGIN
    DEALLOCATE tmp;
END

Use Adventureworks2019

-- Declare variables
DECLARE @_specificLoginName VARCHAR(250);
SET @_specificLoginName = '''';

DECLARE 
    @sql VARCHAR(2048),
    @sort INT;

-- Declare the cursor
DECLARE tmp CURSOR FOR
/*********************************************/
/*********   DB CONTEXT STATEMENT    *********/
/*********************************************/
SELECT ''-- [-- DB CONTEXT --] --'' AS [-- SQL STATEMENTS --],
        1 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT  ''USE'' + SPACE(1) + QUOTENAME(DB_NAME()) AS [-- SQL STATEMENTS --],
        1 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT '''' AS [-- SQL STATEMENTS --],
        2 AS [-- RESULT ORDER HOLDER --]
UNION
/*********************************************/
/*********     DB USER CREATION      *********/
/*********************************************/
SELECT ''-- [-- DB USERS --] --'' AS [-- SQL STATEMENTS --],
        3 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT  ''IF NOT EXISTS (SELECT [name] FROM sys.database_principals WHERE [name] = '' + SPACE(1) + '''''''' + [name] + '''''''' + '') BEGIN CREATE USER '' + SPACE(1) + QUOTENAME([name]) + '' FOR LOGIN '' + QUOTENAME([name]) + '' WITH DEFAULT_SCHEMA = '' + QUOTENAME([default_schema_name]) + SPACE(1) + ''END; '' AS [-- SQL STATEMENTS --],
        4 AS [-- RESULT ORDER HOLDER --]
FROM    sys.database_principals AS rm
WHERE [type] IN (''U'', ''S'', ''G'') -- windows users, sql users, windows groups
UNION
/*********************************************/
/*********    DB ROLE PERMISSIONS    *********/
/*********************************************/
SELECT ''-- [-- DB ROLES --] --'' AS [-- SQL STATEMENTS --],
        5 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT  ''EXEC sp_addrolemember @rolename =''
    + SPACE(1) + QUOTENAME(USER_NAME(rm.role_principal_id), '''''''') + '', @membername ='' + SPACE(1) + QUOTENAME(USER_NAME(rm.member_principal_id), '''''''') AS [-- SQL STATEMENTS --],
        6 AS [-- RESULT ORDER HOLDER --]
FROM    sys.database_role_members AS rm
WHERE   USER_NAME(rm.member_principal_id) IN (  
                                                --get user names on the database
                                                SELECT [name]
                                                FROM sys.database_principals
                                                WHERE [principal_id] > 4 -- 0 to 4 are system users/schemas
                                                and [type] IN (''G'', ''S'', ''U'') -- S = SQL user, U = Windows user, G = Windows group
                                              )
UNION
SELECT '''' AS [-- SQL STATEMENTS --],
        7 AS [-- RESULT ORDER HOLDER --]
UNION
/*********************************************/
/*********  OBJECT LEVEL PERMISSIONS *********/
/*********************************************/
SELECT ''-- [-- OBJECT LEVEL PERMISSIONS --] --'' AS [-- SQL STATEMENTS --],
        8 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT  CASE 
            WHEN perm.state <> ''W'' THEN perm.state_desc 
            ELSE ''GRANT''
        END
        + SPACE(1) + perm.permission_name + SPACE(1) + ''ON '' + QUOTENAME(SCHEMA_NAME(obj.schema_id)) + ''.'' + QUOTENAME(obj.name) --select, execute, etc on specific objects
        + CASE
                WHEN cl.column_id IS NULL THEN SPACE(0)
                ELSE ''('' + QUOTENAME(cl.name) + '')''
          END
        + SPACE(1) + ''TO'' + SPACE(1) + QUOTENAME(USER_NAME(usr.principal_id)) COLLATE database_default
        + CASE 
                WHEN perm.state <> ''W'' THEN SPACE(0)
                ELSE SPACE(1) + ''WITH GRANT OPTION''
          END
            AS [-- SQL STATEMENTS --],
        9 AS [-- RESULT ORDER HOLDER --]
FROM    
    sys.database_permissions AS perm
        INNER JOIN
    sys.objects AS obj
            ON perm.major_id = obj.[object_id]
        INNER JOIN
    sys.database_principals AS usr
            ON perm.grantee_principal_id = usr.principal_id
        LEFT JOIN
    sys.columns AS cl
            ON cl.column_id = perm.minor_id AND cl.[object_id] = perm.major_id
UNION
SELECT '''' AS [-- SQL STATEMENTS --],
    10 AS [-- RESULT ORDER HOLDER --]
UNION
/*********************************************/
/*********    DB LEVEL PERMISSIONS   *********/
/*********************************************/
SELECT ''-- [--DB LEVEL PERMISSIONS --] --'' AS [-- SQL STATEMENTS --],
        11 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT  CASE 
            WHEN perm.state <> ''W'' THEN perm.state_desc --W=Grant With Grant Option
            ELSE ''GRANT''
        END
    + SPACE(1) + perm.permission_name --CONNECT, etc
    + SPACE(1) + ''TO'' + SPACE(1) + ''['' + USER_NAME(usr.principal_id) + '']'' COLLATE database_default --TO <user name>
    + CASE 
            WHEN perm.state <> ''W'' THEN SPACE(0) 
            ELSE SPACE(1) + ''WITH GRANT OPTION'' 
      END
        AS [-- SQL STATEMENTS --],
        12 AS [-- RESULT ORDER HOLDER --]
FROM    sys.database_permissions AS perm
    INNER JOIN
    sys.database_principals AS usr
    ON perm.grantee_principal_id = usr.principal_id
WHERE   [perm].[major_id] = 0
    AND [usr].[principal_id] > 4 -- 0 to 4 are system users/schemas
    AND [usr].[type] IN (''G'', ''S'', ''U'') -- S = SQL user, U = Windows user, G = Windows group
UNION
SELECT '''' AS [-- SQL STATEMENTS --],
        13 AS [-- RESULT ORDER HOLDER --]
UNION 
SELECT ''-- [--DB LEVEL SCHEMA PERMISSIONS --] --'' AS [-- SQL STATEMENTS --],
        14 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT  CASE
            WHEN perm.state <> ''W'' THEN perm.state_desc --W=Grant With Grant Option
            ELSE ''GRANT''
            END
                + SPACE(1) + perm.permission_name --CONNECT, etc
                + SPACE(1) + ''ON'' + SPACE(1) + class_desc + ''::'' COLLATE database_default --TO <user name>
                + QUOTENAME(SCHEMA_NAME(major_id))
                + SPACE(1) + ''TO'' + SPACE(1) + QUOTENAME(USER_NAME(grantee_principal_id)) COLLATE database_default
                + CASE
                    WHEN perm.state <> ''W'' THEN SPACE(0)
                    ELSE SPACE(1) + ''WITH GRANT OPTION''
                    END
            AS [-- SQL STATEMENTS --],
        15 AS [-- RESULT ORDER HOLDER --]
FROM sys.database_permissions AS perm
    INNER JOIN sys.schemas s
        ON perm.major_id = s.schema_id
    INNER JOIN sys.database_principals dbprin
        ON perm.grantee_principal_id = dbprin.principal_id
WHERE class = 3 --class 3 = schema
ORDER BY [-- RESULT ORDER HOLDER --];

-- Open the cursor
OPEN tmp;
FETCH NEXT FROM tmp INTO @sql, @sort;

-- Loop through the cursor and store SQL statements in the temporary table
WHILE @@FETCH_STATUS = 0
BEGIN
    INSERT INTO tempdb..OutputTable (SQLStatement)
    VALUES (@sql);
    
    FETCH NEXT FROM tmp INTO @sql, @sort;
END;

-- Close and deallocate the cursor
CLOSE tmp;
DEALLOCATE tmp;

-- Retrieve the stored SQL statements from the temporary table
SELECT SQLStatement
FROM tempdb..OutputTable
ORDER BY ID;

-- Drop the global temporary table
--DROP TABLE tempdb..OutputTable;
', 
		@database_name=N'AdventureWorks2019', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Backup database user permissions of destination Server database to local floder for back up purpose]    Script Date: 8/28/2024 4:50:04 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Backup database user permissions of destination Server database to local floder for back up purpose', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Use AdventureWorks2019
go

SET NOCOUNT ON

SELECT  ''USE'' + SPACE(1) + QUOTENAME(DB_NAME()) AS ''--Database Context''

--Generates datbase role memberships:
SELECT  ''EXEC sp_addrolemember @rolename =''
               + SPACE(1) + QUOTENAME(USER_NAME(rm.role_principal_id), '''''''') + '', @membername ='' + SPACE(1) + QUOTENAME(USER_NAME(rm.member_principal_id), '''''''') AS ''--Role Memberships''
FROM    sys.database_role_members AS rm
WHERE USER_NAME(rm.member_principal_id) IN
                              ( Select name from sys.database_principals Where principal_id >=5 And type_desc in (''SQL_USER'',''WINDOWS_USER'',''WINDOWS_GROUP''))
ORDER BY rm.role_principal_id ASC;


--Generates Database Level GRANTS:
SELECT  CASE WHEN perm.state <> ''W'' THEN perm.state_desc ELSE ''GRANT'' END
               + SPACE(1) + perm.permission_name + SPACE(1)
               + SPACE(1) + ''TO'' + SPACE(1) + QUOTENAME(usr.name) COLLATE database_default
               + CASE WHEN perm.state <> ''W'' THEN SPACE(0) ELSE SPACE(1) + ''WITH GRANT OPTION'' END AS ''--Database Level Permissions''
FROM    sys.database_permissions AS perm
               INNER JOIN
               sys.database_principals AS usr
               ON perm.grantee_principal_id = usr.principal_id
WHERE usr.name IN
                              ( Select name from sys.database_principals Where principal_id >=5 And type_desc in (''SQL_USER'',''WINDOWS_USER'',''WINDOWS_GROUP''))
and perm.class_desc <> ''OBJECT_OR_COLUMN''

ORDER BY perm.permission_name ASC, perm.state_desc ASC;


--Generates Object or column level grants:
SELECT  CASE WHEN perm.state <> ''W'' THEN perm.state_desc ELSE ''GRANT'' END
               + SPACE(1) + perm.permission_name + SPACE(1) + ''ON '' + QUOTENAME(USER_NAME(obj.schema_id)) + ''.'' + QUOTENAME(obj.name)
               + CASE WHEN cl.column_id IS NULL THEN SPACE(0) ELSE ''('' + QUOTENAME(cl.name) + '')'' END
               + SPACE(1) + ''TO'' + SPACE(1) + QUOTENAME(usr.name) COLLATE database_default
               + CASE WHEN perm.state <> ''W'' THEN SPACE(0) ELSE SPACE(1) + ''WITH GRANT OPTION'' END AS ''--Object Level Permissions''
FROM    sys.database_permissions AS perm
               INNER JOIN
               sys.objects AS obj
               ON perm.major_id = obj.[object_id]
               INNER JOIN
               sys.database_principals AS usr
               ON perm.grantee_principal_id = usr.principal_id
               LEFT JOIN
               sys.columns AS cl
               ON cl.column_id = perm.minor_id AND cl.[object_id] = perm.major_id
WHERE usr.name IN
                              ( Select name from sys.database_principals Where principal_id >=5 And type_desc in (''SQL_USER'',''WINDOWS_USER'',''WINDOWS_GROUP''))

ORDER BY perm.permission_name ASC, perm.state_desc ASC;', 
		@database_name=N'AdventureWorks2019', 
		@output_file_name=N'C:\sqlserver\destination\output\$(ESCAPE_SQUOTE(JOBNAME))$(ESCAPE_SQUOTE(STEPID))$(ESCAPE_SQUOTE(DATE))_$(ESCAPE_SQUOTE(TIME)).txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Back up of Adventureworks2019 from destination server for back up purpose]    Script Date: 8/28/2024 4:50:04 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Back up of Adventureworks2019 from destination server for back up purpose', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'BACKUP DATABASE [AdventureWorks2019] TO  DISK = N''C:\sqlserver\destination\backups\Adventureworks2019.bak'' WITH  COPY_ONLY, NOFORMAT, INIT, Compression,
NAME = N''AdventureWorks2019-Full Database Backup'', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Kill all the sessions on Adventureworks2019 Database]    Script Date: 8/28/2024 4:50:04 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Kill all the sessions on Adventureworks2019 Database', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--Kill all the sessions
USE master
Go
DECLARE @SQL NVARCHAR(3000)
set @SQL=''''
Select @SQL=LTRIM(RTRIM(@SQL))+ ''kill '' +convert(Varchar(10),spid)+'';''+CHAR(13)
from master..sysprocesses where dbid=db_id(''AdventureWorks2019'') -- Enter database nam in db_id
print @SQL
exec sp_executesql @SQL', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Take Single User Mode and Restore The adventureworks Database]    Script Date: 8/28/2024 4:50:04 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Take Single User Mode and Restore The adventureworks Database', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [master]
GO
ALTER DATABASE [AdventureWorks2019] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
USE [master]
RESTORE DATABASE [AdventureWorks2019] FROM  DISK = N''C:\sqlserver\destination\Adventureworks2019.bak'' 
WITH  FILE = 1,  MOVE N''AdventureWorks2019'' TO N''C:\sqlserver\destination\AdventureWorks2019.mdf'',  MOVE N''AdventureWorks2019_log''
TO N''C:\sqlserver\destination\AdventureWorks2019_log.ldf'',  NOUNLOAD,  REPLACE,  STATS = 5

GO

ALTER DATABASE [AdventureWorks2019] SET MULTI_USER
GO
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore Adventureworks2019 Database permissions]    Script Date: 8/28/2024 4:50:04 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore Adventureworks2019 Database permissions', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Declare variables
DECLARE @sqlStatement VARCHAR(2048);

-- Declare the cursor to retrieve SQL statements from ##OutputTable
DECLARE curStatements CURSOR FOR
    SELECT SQLStatement FROM tempdb..OutputTable ORDER BY ID;

-- Open the cursor
OPEN curStatements;

-- Fetch the first SQL statement
FETCH NEXT FROM curStatements INTO @sqlStatement;

-- Loop through the cursor and execute SQL statements
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Execute the SQL statement
    EXEC (@sqlStatement);

    -- Fetch the next SQL statement
    FETCH NEXT FROM curStatements INTO @sqlStatement;
END;

-- Close and deallocate the cursor
CLOSE curStatements;
DEALLOCATE curStatements;

DROP TABLE tempdb..OutputTable;
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Fix Orphan users]    Script Date: 8/28/2024 4:50:04 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Fix Orphan users', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Use Adventureworks2019
Go
--exec sp_change_users_login ''report''

EXEC sp_change_users_login ''report''--See all orphaned users in the database.
DECLARE @OrphanedUsers TABLE
(
  IndexKey Int IDENTITY(1,1) PRIMARY KEY,
  UserName SysName,--nVarChar(128)
  UserSID  VarBinary(85)
)
INSERT INTO @OrphanedUsers
    EXEC sp_change_users_login ''report''

DECLARE @CRLF as nVarChar
    SET @CRLF = CHAR(10) + ''&'' + CHAR(13)--NOTE: Carriage-Return/Line-Feed will only appear in PRINT statements, not SELECT statements.
DECLARE @Sql as nVarChar(MAX)
    SET @Sql = N''''
DECLARE @IndexKey as Int
    SET @IndexKey = 1
DECLARE @MaxIndexKey as Int
    SET @MaxIndexKey = (SELECT COUNT(*) FROM @OrphanedUsers)
DECLARE @Count as Int
    SET @Count = 0
DECLARE @UsersFixed as nVarChar(MAX)
    SET @UsersFixed = N''''
DECLARE @UserName as SysName--This is an orphaned Database user.

WHILE (@IndexKey <= @MaxIndexKey)
  BEGIN
    SET @UserName = (SELECT UserName FROM @OrphanedUsers WHERE IndexKey = @IndexKey)
    IF 1 = (SELECT COUNT(*) FROM sys.server_principals WHERE Name = @UserName)--Look for a match in the Server Logins.
      BEGIN
        SET @Sql = @Sql + ''EXEC sp_change_users_login ''''update_one'''', ['' + @UserName + ''], ['' + @UserName + '']'' + @CRLF
        SET @UsersFixed = @UsersFixed + @UserName + '', ''
        SET @Count = @Count + 1
      END
    SET @IndexKey = @IndexKey + 1
  END

PRINT @Sql
EXEC sp_executesql @Sql
PRINT   ''Total fixed: '' + CAST(@Count as VarChar) + ''.  Users Fixed: '' + @UsersFixed
SELECT (''Total fixed: '' + CAST(@Count as VarChar) + ''.  Users Fixed: '' + @UsersFixed)[Fixed]
--EXEC sp_change_users_login ''report''--See all orphaned users still in the database.


', 
		@database_name=N'AdventureWorks2019', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Delete the Orphan User]    Script Date: 8/28/2024 4:50:04 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete the Orphan User', 
		@step_id=8, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Generate DROP USER statements for orphaned users excluding specific users
DECLARE @DropUserCommands NVARCHAR(MAX) = '''';

SELECT @DropUserCommands += ''DROP USER '' + QUOTENAME(dp.name) + '';'' + CHAR(13)
FROM sys.database_principals dp
LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid
WHERE dp.type = ''S'' 
  AND sp.sid IS NULL
  AND dp.name NOT IN (''guest'', ''INFORMATION_SCHEMA'', ''sys'');

-- Print the generated DROP USER commands

--PRINT @DropUserCommands;
EXEC sp_executesql @DropUserCommands;', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO
