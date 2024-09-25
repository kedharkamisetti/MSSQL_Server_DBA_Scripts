USE [msdb]
GO

CREATE TRIGGER [dbo].[JobStatusAlert]
   ON [dbo].[sysjobs]
   AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if job is enabled/disabled
    DECLARE @MailBody VARCHAR(300)
    
    -- Check if job status is changed (enabled/disabled)
    IF (SELECT TOP 1 CASE WHEN d.enabled = i.enabled THEN 0 ELSE 1 END
        FROM deleted d INNER JOIN inserted i
        ON d.job_id = i.job_id) = 1
    BEGIN
        -- Get session detail and create a message
        SELECT TOP 1 @MailBody = 'Job "'
            + i.name
            + '" is recently '
            + CASE WHEN i.enabled = 0 THEN ' DISABLED ' ELSE ' ENABLED ' END
            + ' by user '
            + login_name
            + ' with session id '
            + CAST(c.session_id AS VARCHAR(3))
            + ' and host name '
            + host_name + ' at '
            + CONVERT(VARCHAR(50), last_request_end_time, 109)
        FROM sys.dm_exec_connections c
        INNER JOIN sys.dm_exec_sessions s ON c.session_id = s.session_id
        CROSS APPLY sys.dm_exec_sql_text(most_recent_sql_handle)
        CROSS APPLY inserted i
        WHERE text LIKE '%exec msdb.dbo.sp_help_job%'
        AND text NOT LIKE '%SELECT c.session_id'
        ORDER BY last_read DESC;
        
        -- Send mail to DBA Team
        EXEC msdb.dbo.sp_send_dbmail
            @recipients='bajeyudu@SQLDBANOW.com', -- Change mail address accordingly
            @subject = 'Job Status Changed at SQLDBANOWDB01 Server',
            @profile_name = 'Sqlmail', -- Change profile name accordingly
            @body = @MailBody;
    END
END
GO