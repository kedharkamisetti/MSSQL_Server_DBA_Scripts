CREATE MASTER KEY ENCRYPTION BY PASSWORD='Password@123';  
 
CREATE DATABASE SCOPED CREDENTIAL JobRun WITH IDENTITY = 'sqladmin',
    SECRET = 'P@ssWord';  

EXEC [jobs].sp_add_target_group N'ServerGroup';
GO

EXEC [jobs].sp_add_target_group_member
@target_group_name = N'ServerGroup',
@target_type = N'SqlServer',
@refresh_credential_name = N'jobrun', --credential required to refresh the databases in a server
@server_name = N'testdemo05.database.windows.net';
GO

EXEC [jobs].sp_add_target_group_member
@target_group_name = N'ServerGroup',
@membership_type = N'Exclude',
@target_type = N'SqlDatabase',
@server_name = N'testdemo05.database.windows.net',
@database_name = N'testing123';

SELECT * FROM [jobs].target_groups WHERE target_group_name = N'ServerGroup';
SELECT * FROM [jobs].target_group_members WHERE target_group_name = N'ServerGroup';

--Connect to the job database specified when creating the job agent

--Add job for create table
EXEC jobs.sp_add_job @job_name = 'CreateTableTest', @description = 'Create Table Test';

-- Add job step for create table
EXEC jobs.sp_add_jobstep @job_name = 'CreateTableTest',
@command = N'IF NOT EXISTS (SELECT * FROM sys.tables WHERE object_id = object_id(''Test''))
CREATE TABLE [dbo].[Test]([TestId] [int] NOT NULL);',
@credential_name = 'jobrun',
@target_group_name = 'servergroup';

EXEC jobs.sp_start_job 'CreateTableTest';
SELECT * FROM jobs.target_groups
SELECT target_group_name, 
        membership_type,
        refresh_credential_name,
        server_name,
        database_name
FROM jobs.target_group_members

--View top-level execution status for the job named 'CreateTableTest'
SELECT * FROM jobs.job_executions
WHERE job_name = 'CreateTableTest' and step_id IS NULL
ORDER BY start_time DESC;

--View all top-level execution status for all jobs
SELECT * FROM jobs.job_executions WHERE step_id IS NULL
ORDER BY start_time DESC;

--View all execution statuses for job named 'CreateTableTest'
SELECT * FROM jobs.job_executions
WHERE job_name = 'CreateTableTest'
ORDER BY start_time DESC;

-- View all active executions to determine job execution id
SELECT * FROM jobs.job_executions
WHERE is_active = 1 AND job_name = 'CreateTableTest'
ORDER BY start_time DESC;
GO

-- Cancel job execution with the specified job execution id
EXEC jobs.sp_stop_job '01234567-89ab-0123-456789abcdef';

--Connect to the job database specified when creating the job agent

-- Delete history of a specific job's executions older than the specified date
EXEC jobs.sp_purge_jobhistory @job_name='CreateTableTest', @oldest_date='2016-07-01 00:00:00';

--Note: job history is automatically deleted if it is >45 days old

--Connect to the job database specified when creating the job agent

EXEC jobs.sp_update_job
@job_name = 'ResultsJob',
@enabled=1,
@schedule_interval_type = 'Minutes',
@schedule_interval_count = 15;

 ----Below are the different interval types we can specify for a job.
 -- Once
 -- Minutes
 -- Hours
 -- Days
 -- Weeks
 -- Months
