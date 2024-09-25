--------------------------------------------------
-- Configure min and max memory
--------------------------------------------------
EXEC sys.sp_configure N'show advanced options', N'1'  
RECONFIGURE WITH OVERRIDE
GO
DECLARE @ServerMemory int = (SELECT (total_physical_memory_kb/1024) AS total_physical_memory_mb FROM sys.dm_os_sys_memory)
DECLARE @setMemory int = (SELECT @ServerMemory*(.80))
DECLARE @setminMemory int = 2048
EXEC sys.sp_configure N'max server memory (MB)', @setMemory
EXEC sys.sp_configure N'min server memory (MB)', @setminMemory
GO
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'show advanced options', N'0'  
RECONFIGURE WITH OVERRIDE
GO
PRINT 'Max Memory Changed Successfully';
PRINT 'Min Memory Changed Successfully';


--------------------------------------------------
-- Set AUTO_CLOSE to OFF for all databases
--------------------------------------------------
USE master;
GO
DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql += N'ALTER DATABASE [' + name + N'] SET AUTO_CLOSE OFF;' + CHAR(13)
FROM sys.databases WHERE is_auto_close_on = 1
EXEC(@sql);


--------------------------------------------------
-- Enable backup compression at server level
--------------------------------------------------
IF EXISTS(SELECT * FROM sys.configurations WHERE name = 'backup compression default' AND value = 0)   
BEGIN
    EXEC sp_configure 'backup compression default', 1;  
    RECONFIGURE;  
END


--------------------------------------------------
-- CreateCycleErrorlogJob
--------------------------------------------------
EXEC sp_cycle_errorlog
EXEC msdb.dbo.sp_cycle_agent_errorlog


--------------------------------------------------
-- SetSave30ErrorLogs
--------------------------------------------------
USE [master]
GO
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'NumErrorLogs', REG_DWORD, 30
GO


--------------------------------------------------
-- Enable Remote DAC
--------------------------------------------------
USE master
GO
sp_configure 'remote admin connections', 1
GO
RECONFIGURE WITH OVERRIDE
GO


--------------------------------------------------
-- CreateDbExecutorInModel
--------------------------------------------------
USE [model]
GO
CREATE ROLE db_executor
GRANT EXECUTE TO db_executor


--------------------------------------------------
-- CreateSQLOperator
--------------------------------------------------
USE [msdb]
GO
EXEC msdb.dbo.sp_add_operator @name=N'Maintenance_SQLOperator', 
    @enabled=1, 
    @weekday_pager_start_time=90000, 
    @weekday_pager_end_time=180000, 
    @saturday_pager_start_time=90000, 
    @saturday_pager_end_time=180000, 
    @sunday_pager_start_time=90000, 
    @sunday_pager_end_time=180000, 
    @pager_days=0, 
    @email_address=N'{{email}}', 
    @category_name=N'[Uncategorized]'
GO


--------------------------------------------------
-- IncreaseSQLAgentHistory
--------------------------------------------------
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=500000
GO


--------------------------------------------------
-- SetCostThresholdForParallelism
--------------------------------------------------
USE [master]
GO
EXEC sp_configure 'show advanced option', '1';  
RECONFIGURE WITH OVERRIDE
EXEC sp_configure N'cost threshold for parallelism', N'50'
GO
RECONFIGURE WITH OVERRIDE
GO


--------------------------------------------------
-- CreateSQLProductionMail
--------------------------------------------------
EXECUTE sp_configure 'show advanced', 1;
RECONFIGURE;
EXECUTE sp_configure 'Database Mail XPs',1;
RECONFIGURE;
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1, @alert_replace_runtime_tokens=1
GO
EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'UseDatabaseMail', N'REG_DWORD', 1
GO
USE [msdb]
GO
EXECUTE msdb.dbo.sysmail_add_profile_sp
    @profile_name = 'Automated database mail',
    @description = 'Profile used for administrative mail.' ;       
EXECUTE msdb.dbo.sysmail_add_account_sp
    @account_name = 'SQL Server production mail',
    @description = 'Mail account for administrative mail.',
    @email_address = '{{email}}',
    @display_name = 'Automated Mailer',
    @mailserver_name = '{{mailserver}}' ;
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = 'Automated database mail',
    @account_name = 'SQL Server production mail',
    @sequence_number = 1;
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
    @profile_name = 'Automated database mail',
    @principal_name = 'public',
    @is_default = 1;
GO
EXECUTE msdb.dbo.sp_send_dbmail
    @subject = 'Test Database Mail Message',
    @recipients = '{{email}}',
    @query = 'SELECT @@SERVERNAME';
GO
USE [msdb]
GO
EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'DatabaseMailProfile', N'REG_SZ', N'Company automated database mail'
GO


--------------------------------------------------
-- SetIdleCPU
--------------------------------------------------
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @cpu_poller_enabled=1
GO


--------------------------------------------------
-- CreateBlockedProcessReport
--------------------------------------------------
USE [master]
GO
sp_configure 'show advanced options', 1 ;
GO
RECONFIGURE ;
GO
sp_configure 'blocked process threshold', 5 ;
GO
RECONFIGURE ;
GO
USE [msdb]
GO
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Misc]' AND category_class=1)
BEGIN
    EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Misc]'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Blocked_Process_Report_Response', 
    @enabled=1, 
    @notify_level_eventlog=0, 
    @notify_level_email=0, 
    @notify_level_netsend=0, 
    @notify_level_page=0, 
    @delete_level=0, 
    @description=N'No description available.', 
    @category_name=N'[Misc]', 
    @owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Send Error Text', 
    @step_id=1, 
    @cmdexec_success_code=0, 
    @on_success_action=1, 
    @on_success_step_id=0, 
    @on_fail_action=2, 
    @on_fail_step_id=0, 
    @retry_attempts=0, 
    @retry_interval=0, 
    @os_run_priority=0, @subsystem=N'TSQL', 
    @command=N'EXEC msdb.dbo.sp_send_dbmail
    @profile_name = ''Automated database mail'',
    @recipients = ''{{email}}'',
    @body = N''$(ESCAPE_SQUOTE(WMI(TextData)))'' ,
    @subject =  ''Blocked Process Report from $(ESCAPE_SQUOTE(WMI(ServerName)))'';
', 
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
USE [msdb]
GO
DECLARE @Response_Job_ID uniqueidentifier
DECLARE @WMI_NAMESPACE_PATH varchar(500)
SET @Response_Job_ID = (SELECT job_id from msdb.dbo.sysjobs WHERE name = 'Blocked_Process_Report_Response')
SET @WMI_NAMESPACE_PATH = N'\\.\root\Microsoft\SqlServer\ServerEvents\MSSQLSERVER'
IF(CAST(SERVERPROPERTY('InstanceName') as nvarchar(100)) <> 'MSSQLSERVER')
BEGIN
    SET @WMI_NAMESPACE_PATH = REPLACE(@WMI_NAMESPACE_PATH, 'MSSQLSERVER', CAST(SERVERPROPERTY('InstanceName') as nvarchar(100)))
END
EXEC msdb.dbo.sp_add_alert @name=N'Blocked_Process_Report', 
    @enabled=1, 
    @delay_between_responses=600, 
    @include_event_description_in=1, 
    @wmi_namespace=@WMI_NAMESPACE_PATH,
    @wmi_query=N'SELECT * FROM BLOCKED_PROCESS_REPORT', 
    @job_id=@Response_Job_ID
GO


--------------------------------------------------
--CreateMonitor_AUTO_GROW_Events:
--------------------------------------------------
USE [msdb]
GO
/****** Object:  Job [Monitor_AUTO_GROW_Events_Response]    Script Date: 11/11/2010 11:33:37 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Misc]]]    Script Date: 11/11/2010 11:33:37 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Misc]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Misc]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Monitor_AUTO_GROW_Events_Response', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Misc]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Notify]    Script Date: 11/11/2010 11:33:38 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Notify', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC msdb.dbo.sp_send_dbmail
    @profile_name = ''Automated database mail'',
    @recipients = ''{{email}}'',
    @body = N''The file $(ESCAPE_SQUOTE(WMI(FileName))) in database $(ESCAPE_SQUOTE(WMI(DatabaseName))) auto grew.'' ,
    @subject =  N''Auto grow event occured on $(ESCAPE_SQUOTE(WMI(ComputerName)))\$(ESCAPE_SQUOTE(WMI(SQLInstance)))'';
', 
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
USE [msdb]
GO
/****** Object:  Alert [Monitor_AUTO_GROW_Events]    Script Date: 11/11/2010 11:34:26 ******/
DECLARE @Response_Job_ID uniqueidentifier
DECLARE @WMI_NAMESPACE_PATH varchar(500)
SET @Response_Job_ID = (SELECT job_id from msdb.dbo.sysjobs WHERE name = 'Monitor_AUTO_GROW_Events_Response')
SET @WMI_NAMESPACE_PATH = N'\\.\root\Microsoft\SqlServer\ServerEvents\MSSQLSERVER'
IF(CAST(SERVERPROPERTY('InstanceName') as nvarchar(100)) <> 'MSSQLSERVER')
BEGIN
	SET @WMI_NAMESPACE_PATH = REPLACE(@WMI_NAMESPACE_PATH, 'MSSQLSERVER', CAST(SERVERPROPERTY('InstanceName') as nvarchar(100)))
END
EXEC msdb.dbo.sp_add_alert @name=N'Monitor_AUTO_GROW_Events', 
		@message_id=0, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=0, 
		@category_name=N'[Uncategorized]', 
		@wmi_namespace=@WMI_NAMESPACE_PATH, 
		@wmi_query=N'SELECT * FROM DATA_FILE_AUTO_GROW', 
		@job_id=@Response_Job_ID
GO


--------------------------------------------------
--AddTempDBFiles:
--------------------------------------------------
USE Master
GO
SET NOCOUNT ON
GO
PRINT '-- Instance name: '+ @@servername + ' ;
/* Version: ' + @@version + ' */' 
-- Variables 
DECLARE @BITS Bigint                      -- Affinty Mask
,@NUMPROCS Smallint                       -- Number of cores addressed by instance
,@tempdb_files_count Int                  -- Number of exisiting datafiles
,@tempdbdev_location Nvarchar(4000)       -- Location of TEMPDB primary datafile
,@X Int                                   -- Counter
,@SQL Nvarchar(max)
,@new_tempdbdev_size_MB Int               -- Size of the new files,in Megabytes
,@new_tempdbdev_Growth_MB Int             -- New files growth rate,in Megabytes
,@new_files_Location Nvarchar(4000)       -- New files path 
-- Initialize variables 
Select  @X = 1, @BITS = 1
SELECT
@new_tempdbdev_size_MB = 4096              -- Four Gbytes , it's easy to increase that after file creation but harder to shrink.
,@new_tempdbdev_Growth_MB = 512            -- 512 Mbytes  , can be easily shrunk
,@new_files_Location = NULL                -- NULL means create in same location as primary file.
IF OBJECT_ID('tempdb..#SVer') IS NOT NULL
BEGIN
DROP TABLE #SVer
END
CREATE TABLE #SVer(ID INT,  Name  sysname, Internal_Value INT, Value NVARCHAR(512))
INSERT #SVer EXEC master.dbo.xp_msver processorCount
-- Get total number of Cores detected by the Operating system
SELECT @NUMPROCS=  Internal_Value FROM #SVer
Print '-- TOTAL numbers of CPU cores on server :' + cast(@NUMPROCS as varchar(5))
SET @NUMPROCS  = 0
-- Get number of Cores addressed by instance. 
WHILE @X <= (SELECT Internal_Value FROM #SVer ) AND @x <=32
BEGIN
    SELECT @NUMPROCS =
    CASE WHEN  CAST (VALUE AS INT) & @BITS > 0 THEN @NUMPROCS + 1 ELSE @NUMPROCS END
    FROM sys.configurations
    WHERE NAME = 'AFFINITY MASK'
    SET  @BITS = (@BITS * 2)
    SET @X = @X + 1
END
IF (SELECT Internal_Value FROM #SVer) > 32
    Begin
    WHILE @X <= (SELECT Internal_Value FROM #SVer )
    BEGIN
        SELECT @NUMPROCS =
        CASE WHEN  CAST (VALUE AS INT) & @BITS > 0 THEN @NUMPROCS + 1 ELSE @NUMPROCS END
        FROM sys.configurations
        WHERE NAME = 'AFFINITY64 MASK'
        SET  @BITS = (@BITS * 2)
        SET @X = @X + 1
    END
END
If @NUMPROCS = 0 SELECT @NUMPROCS=  Internal_Value FROM #SVer
Print '-- Number of CPU cores Configured for usage by instance :' + cast(@NUMPROCS as varchar(5))
-------------------------------------------------------------------------------------
-- Here you define how many files should exist per core ; Feel free to change
-------------------------------------------------------------------------------------
-- IF cores < 8 then no change , if between 8 & 32 inclusive then 1/2 of cores number
IF @NUMPROCS >8 and @NUMPROCS <=32
SELECT @NUMPROCS = @NUMPROCS /2
-- IF cores > 32 then files should be 1/4 of cores number
If @NUMPROCS >32
SELECT @NUMPROCS = @NUMPROCS /4
-- Get number of exisiting TEMPDB datafiles and the location of the primary datafile. 
SELECT @tempdb_files_count=COUNT(*) ,@tempdbdev_location=(SELECT REVERSE(SUBSTRING(REVERSE(physical_name), CHARINDEX('\',REVERSE(physical_name)) , LEN(physical_name) )) FROM tempdb.sys.database_files  WHERE name = 'tempdev')
FROM tempdb.sys.database_files
WHERE type_desc= 'Rows' AND state_desc= 'Online' 
Print '-- Current Number of Tempdb datafiles :' + cast(@tempdb_files_count as varchar(5)) 
-- Determine if we already have enough datafiles
If @tempdb_files_count >= @NUMPROCS
Begin
Print '--****Number of Recommedned datafiles is already there****'
Return
End
Set @new_files_Location= Isnull(@new_files_Location,@tempdbdev_location)
-- Determine if the new location exists or not
Declare @file_results table(file_exists int,file_is_a_directory int,parent_directory_exists int)
insert into @file_results(file_exists, file_is_a_directory, parent_directory_exists)
exec master.dbo.xp_fileexist @new_files_Location
if (select file_is_a_directory from @file_results ) = 0
Begin
print '-- New files Directory Does NOT exist , please specify a correct folder!'
Return
end
-- Determine if we have enough free space on the destination drive
Declare @FreeSpace Table (Drive char(1),MB_Free Bigint)
insert into @FreeSpace exec master..xp_fixeddrives
if (select MB_Free from @FreeSpace where drive = LEFT(@new_files_Location,1) ) < @NUMPROCS * @new_tempdbdev_size_MB
Begin
print '-- WARNING: Not enough free space on ' + Upper(LEFT(@new_files_Location,1)) + ':\ to accomodate the new files. Around '+ cast(@NUMPROCS * @new_tempdbdev_size_MB as varchar(10))+ ' Mbytes are needed; Please add more space or choose a new location!'
end
-- Determine if any of the exisiting datafiles have different size than proposed ones.
If exists
(
    SELECT (CONVERT (bigint, size) * 8)/1024 FROM tempdb.sys.database_files
    WHERE type_desc= 'Rows'
    and  (CONVERT (bigint, size) * 8)/1024  <> @new_tempdbdev_size_MB
)
PRINT
'
/*
WARNING: Some Existing datafile(s) do NOT have the same size as new ones.
It''s recommended if ALL datafiles have same size for optimal proportional-fill performance.Use ALTER DATABASE and DBCC SHRINKFILE to resize files
Optimizing tempdb Performance : http://msdn.microsoft.com/en-us/library/ms175527.aspx
'
Print '****Proposed New Tempdb Datafiles, PLEASE REVIEW CODE BEFORE RUNNIG  *****/
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
'
-- Generate the statements
WHILE @tempdb_files_count < @NUMPROCS
BEGIN
    SELECT @SQL = 'ALTER DATABASE [tempdb] ADD FILE (NAME = N''tempdev_new_0'+CAST (@tempdb_files_count +1 AS VARCHAR (5))+''',FILENAME = N'''+ @new_files_Location + 'tempdev_new_0'+CAST (@tempdb_files_count +1 AS VARCHAR(5)) +'.ndf'',SIZE = '+CAST(@new_tempdbdev_size_MB AS VARCHAR(15)) +'MB,FILEGROWTH = '+CAST(@new_tempdbdev_Growth_MB AS VARCHAR(15)) +'MB )
GO'
    PRINT @SQL
    SET @tempdb_files_count = @tempdb_files_count + 1
END


--------------------------------------------------
--CreateDeadlockAlert.sql
--------------------------------------------------
USE [msdb]
GO
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Misc]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Misc]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Capture_Deadlock_Response', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Misc]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Send Error Text]    Script Date: 09/03/2010 09:34:00 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Send Deadlock graph', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC msdb.dbo.sp_send_dbmail
    @profile_name = ''Automated database mail'',
    @recipients = ''{{email}}'',
    @body = N''$(ESCAPE_SQUOTE(WMI(TextData)))'' ,
    @subject =  ''Deadlock graph from $(ESCAPE_SQUOTE(WMI(ServerName)))'';
', 
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
USE [msdb]
GO
DECLARE @Response_Job_ID uniqueidentifier
DECLARE @WMI_NAMESPACE_PATH varchar(500)
SET @Response_Job_ID = (SELECT job_id from msdb.dbo.sysjobs WHERE name = 'Capture_Deadlock_Response')
SET @WMI_NAMESPACE_PATH = N'\\.\root\Microsoft\SqlServer\ServerEvents\MSSQLSERVER'
IF(CAST(SERVERPROPERTY('InstanceName') as nvarchar(100)) <> 'MSSQLSERVER')
BEGIN
	SET @WMI_NAMESPACE_PATH = REPLACE(@WMI_NAMESPACE_PATH, 'MSSQLSERVER', CAST(SERVERPROPERTY('InstanceName') as nvarchar(100)))
END
EXEC msdb.dbo.sp_add_alert @name=N'Capture_Deadlock', 
		@enabled=1, 
		@delay_between_responses=600, 
		@include_event_description_in=1, 
		@wmi_namespace=@WMI_NAMESPACE_PATH,
		@wmi_query=N'SELECT * FROM DEADLOCK_GRAPH', 
		@job_id=@Response_Job_ID
GO


--------------------------------------------------
--Install Ola hallengren Scripts
--------------------------------------------------


--------------------------------------------------
--EnableContainedDatabases: 
--------------------------------------------------
USE master;
GO
-- Enable contained databases
EXEC sp_configure 'contained database authentication', 1;
RECONFIGURE;
GO


--------------------------------------------------
--CreateError825Alert:
--------------------------------------------------
USE [msdb]
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error_825_Alert', 
		@message_id=825, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error_825_Alert', @operator_name=N'Maintenance_SQLOperator', @notification_method = 1
GO


--------------------------------------------------
--Locked pages in memory: 
--------------------------------------------------
USE master;
GO
-- Enable locked pages in memory
-- This requires that the SQL Server service account be granted the 'Lock Pages in Memory' user right.
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer', N'LockPagesInMemory', REG_DWORD, 1;
GO


--------------------------------------------------
--Set CPU in High Performance Mode
--------------------------------------------------