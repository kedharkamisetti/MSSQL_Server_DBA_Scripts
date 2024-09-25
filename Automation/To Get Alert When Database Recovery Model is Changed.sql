--This code will trigger an alert to your email when recovery model got change.
USE [master]
GO

CREATE OR ALTER TRIGGER [RecoveryModechanged]
ON ALL SERVER 
FOR ALTER_DATABASE AS
BEGIN
    DECLARE @text nvarchar(max)
    DECLARE @login varchar(128)
    DECLARE @recovery smallint
    DECLARE @body nvarchar(max)
    DECLARE @subject nvarchar(255)

    SET @text = EVENTDATA().value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'nvarchar(max)') 
    SET @login = EVENTDATA().value('(/EVENT_INSTANCE/LoginName)[1]', 'varchar(128)') 
    SET @recovery = PATINDEX('%RECOVERY%', @text) 

    SET @subject = 'Alter database on ' + @@SERVERNAME + ' - Recovery model changed!'

    SET @body = '<html><body><table style="border-collapse: collapse; border: 1px solid black;">' +
                '<tr><td style="border: 1px solid black;"><b>Instance Name</b></td>' +
                '<td style="border: 1px solid black;"><b>Login Name</b></td>' +
                '<td style="border: 1px solid black;"><b>Event</b></td></tr>' +
                '<tr><td style="border: 1px solid black;">' + @@SERVERNAME + '</td>' +
                '<td style="border: 1px solid black;">' + @login + '</td>' +
                '<td style="border: 1px solid black;">' + @text + '</td></tr>' +
                '</table></body></html>'

    IF @recovery > 0
    BEGIN 
        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'outlook',
            @recipients = 'musicandra@gmail.com',
            @body = @body,
            @body_format = 'HTML',
            @subject = @subject,
            @importance = 'High';
    END
END
GO

ENABLE TRIGGER [RecoveryModechanged] ON ALL SERVER
GO
=======================================================

-- This will create a table and maintain the history
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'RecoveryModelChangeLog')
DROP TABLE RecoveryModelChangeLog;
Go
CREATE TABLE RecoveryModelChangeLog (
    ChangeDate DATETIME,
    LoginName NVARCHAR(128),
    HostName NVARCHAR(128),
    DatabaseName NVARCHAR(128),
    NewRecoveryModel NVARCHAR(50)
);
GO

-- Create or alter the stored procedure to retrieve the current recovery model for a database
CREATE OR ALTER PROCEDURE dbo.GetDatabaseRecoveryModel
    @DatabaseName NVARCHAR(128),
    @RecoveryModel NVARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @RecoveryModel = recovery_model_desc
    FROM sys.databases
    WHERE name = @DatabaseName;
END;
GO

-- Create or alter the trigger
CREATE OR ALTER TRIGGER Trg_RecoveryModelChange
ON ALL SERVER
FOR ALTER_DATABASE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EventData XML;
    SET @EventData = EVENTDATA();

    DECLARE @LoginName NVARCHAR(128);
    DECLARE @HostName NVARCHAR(128);
    DECLARE @DatabaseName NVARCHAR(128);
    DECLARE @NewRecoveryModel NVARCHAR(50);

    SELECT 
        @LoginName = ORIGINAL_LOGIN(),
        @HostName = HOST_NAME(),
        @DatabaseName = @EventData.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'NVARCHAR(128)');

    DECLARE @CurrentRecoveryModel NVARCHAR(50);
    EXEC dbo.GetDatabaseRecoveryModel @DatabaseName, @CurrentRecoveryModel OUTPUT;

    -- Wait for a few milliseconds to ensure the recovery model change has taken effect
    WAITFOR DELAY '00:00:00.100';

    EXEC dbo.GetDatabaseRecoveryModel @DatabaseName, @NewRecoveryModel OUTPUT;

    -- Insert the change information into the log table
    INSERT INTO RecoveryModelChangeLog (
        ChangeDate,
        LoginName,
        HostName,
        DatabaseName,
        NewRecoveryModel
    )
    VALUES (
        GETDATE(),
        @LoginName,
        @HostName,
        @DatabaseName,
        @NewRecoveryModel
    );
END;
================================================
--- The Below T SQL Code pull the information of recovery model change from the default traces and errorlog

DECLARE @tracefile VARCHAR(500)
DECLARE @ProcessInfoSPID VARCHAR(20)

CREATE TABLE [dbo].[#SQLerrorlog](
[LogDate] DATETIME NULL,
[ProcessInfo] VARCHAR(10) NULL,
[Text] VARCHAR(MAX) NULL
)

/*
Valid parameters for sp_readerrorlog
1 – Error log: 0 = current, 1 = Archive #1, 2 = Archive #2, etc…
2 – Log file type: 1 or NULL = error log, 2 = SQL Agent log
3 – Search string 1
4 – Search string 2

Change parameters to meet your need
*/
-- Read error log looking for the words RECOVERY
--and either FULL, SIMPLE or BULK_LOGGED indicating a change from prior state

INSERT INTO #SQLerrorlog EXEC sp_readerrorlog 0, 1, 'RECOVERY', 'FULL'
INSERT INTO #SQLerrorlog EXEC sp_readerrorlog 0, 1, 'RECOVERY', 'SIMPLE'
INSERT INTO #SQLerrorlog EXEC sp_readerrorlog 0, 1, 'RECOVERY', 'BULK_LOGGED'

UPDATE #SQLerrorlog
SET ProcessInfo = SUBSTRING(ProcessInfo,5,20) FROM #SQLerrorlog
WHERE ProcessInfo LIKE 'spid%'

-- Get path of default trace file
SELECT @tracefile = CAST(value AS VARCHAR(500))
FROM sys.fn_trace_getinfo(DEFAULT)
WHERE traceid = 1
AND property = 2

-- Get objects altered from the default trace
SELECT IDENTITY(int, 1, 1) AS RowNumber, *
INTO #temp_trc
FROM sys.fn_trace_gettable(@tracefile, default) g -- default = read all trace files
WHERE g.EventClass = 164
SELECT t.DatabaseID, t.DatabaseName, t.NTUserName, t.NTDomainName,
t.HostName, t.ApplicationName, t.LoginName, t.SPID, t.StartTime, l.Text
FROM #temp_trc t
JOIN #SQLerrorlog l ON t.SPID = l.ProcessInfo
WHERE t.StartTime > GETDATE()-1 -- filter by time within the last 24 hours
ORDER BY t.StartTime DESC

DROP TABLE #temp_trc
DROP TABLE #SQLerrorlog
GO
=============================
--It will search the word with the recovery in the error log
Sp_readerrorlog 0, 1, 'recovery'