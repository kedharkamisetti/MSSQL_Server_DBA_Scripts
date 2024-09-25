-- Step 1: Check if the full backup job is running
DECLARE @fullBackupJobName NVARCHAR(128) = 'DatabaseBackup - USER_DATABASES - FULL'
DECLARE @fullBackupJobActivity INT

SELECT @fullBackupJobActivity = COUNT(*)
FROM msdb.dbo.sysjobactivity AS activity
INNER JOIN msdb.dbo.sysjobs AS jobs ON activity.job_id = jobs.job_id
WHERE jobs.name = @fullBackupJobName
    AND activity.start_execution_date IS NOT NULL
    AND activity.stop_execution_date IS NULL

IF @fullBackupJobActivity > 0
BEGIN
    -- The full backup job is still running, so exit the differential backup job
    PRINT 'Full backup job is still running. Exiting differential backup job.'
    RETURN
END

-- Step 2: Perform the differential backup job
--DECLARE @diffBackupJobName NVARCHAR(128) = 'DatabaseBackup - USER_DATABASES - DIFF'

-- Add your code to perform the differential backup here
EXECUTE [dbo].[DatabaseBackup]
@Databases = 'USER_DATABASES',
@Directory = N'C:\log',
@BackupType = 'DIFF',
@Verify = 'Y',
@CleanupTime = NULL,
@CheckSum = 'Y',
@LogToTable = 'Y'