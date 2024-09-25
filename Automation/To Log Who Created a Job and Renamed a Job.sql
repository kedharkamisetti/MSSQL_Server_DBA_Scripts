USE [msdb]
GO

/****** Object:  Table [dbo].[JobChanges]    Script Date: 01-04-2023 03:46:42 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[JobChanges](
	[JobChangeID] [int] IDENTITY(1,1) NOT NULL,
	[JobName] [varchar](100) NOT NULL,
	[OldJobName] [varchar](100) NULL,
	[ChangeType] [varchar](20) NOT NULL,
	[ChangeTime] [datetime] NOT NULL,
	[LoginName] [varchar](100) NOT NULL,
	[JobOwner] [varchar](100) NOT NULL,
)

-------------------------------------------------------
CREATE TRIGGER track_job_changes
ON msdb.dbo.sysjobs
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @loginName VARCHAR(100) = SUSER_SNAME();
    DECLARE @sqlText NVARCHAR(MAX) = NULL;

    IF EXISTS (SELECT * FROM inserted)
    BEGIN
        -- Job created or updated
    
        INSERT INTO dbo.JobChanges (JobName, OldJobName, ChangeType, ChangeTime, LoginName, JobOwner )
        SELECT name, NULL, CASE WHEN EXISTS (SELECT * FROM deleted) THEN 'Updated' ELSE 'Created' END, GETDATE(), @loginName, SUSER_SNAME(owner_sid)
        FROM inserted
        WHERE NOT EXISTS (SELECT * FROM deleted);
    END
    ELSE IF EXISTS (SELECT * FROM deleted)
    BEGIN
        -- Job deleted
        INSERT INTO dbo.JobChanges (JobName, ChangeType, ChangeTime, LoginName, JobOwner)
        SELECT name, 'Deleted', GETDATE(), @loginName, SUSER_SNAME(owner_sid)
        FROM deleted;
    END

    -- Check if any job has been renamed
    IF EXISTS (SELECT * FROM deleted d INNER JOIN inserted i ON d.job_id = i.job_id WHERE d.name <> i.name)
    BEGIN
        -- Job renamed
        INSERT INTO dbo.JobChanges (JobName, OldJobName, ChangeType, ChangeTime, LoginName, JobOwner)
        SELECT i.name, d.name, 'Renamed', GETDATE(), @loginName, SUSER_SNAME(i.owner_sid)
        FROM deleted d INNER JOIN inserted i ON d.job_id = i.job_id WHERE d.name <> i.name;
    END
END