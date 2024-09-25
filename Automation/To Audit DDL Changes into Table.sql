Create Database objectAuditLogs


USE [objectAuditLogs]
GO

/****** Object:  Table [dbo].[objectAuditLog]    Script Date: 31-03-2023 05:45:48 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[objectAuditLog](
	[EventDateTime] [datetime2](7) NULL,
	[EventType] [nvarchar](100) NULL,
	[ObjectName] [nvarchar](500) NULL,
	[LoginName] [nvarchar](100) NULL,
	[DatabaseName] [nvarchar](100) NULL,
	[TSQLCommand] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO




--Trigger:

USE [master]
GO

/****** Object:  DdlTrigger [ObjectDDLTrigger]    Script Date: 31-03-2023 05:44:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


Create TRIGGER [ObjectDDLTrigger]
ON ALL SERVER
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE, CREATE_PROCEDURE, ALTER_PROCEDURE, DROP_PROCEDURE, CREATE_VIEW, ALTER_VIEW, DROP_VIEW, CREATE_FUNCTION, ALTER_FUNCTION, DROP_FUNCTION, CREATE_TRIGGER, ALTER_TRIGGER, DROP_TRIGGER, CREATE_DATABASE, DROP_DATABASE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @event_type NVARCHAR(100);
    DECLARE @object_name NVARCHAR(500);
    DECLARE @login_name NVARCHAR(100);
    DECLARE @database_name NVARCHAR(100);
    DECLARE @TSQLCommand NVARCHAR(MAX);

    SELECT @event_type = EVENTDATA().value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)'),
           @object_name = EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(500)'),
           @login_name = EVENTDATA().value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(100)'),
           @database_name = EVENTDATA().value('(/EVENT_INSTANCE/DatabaseName)[1]', 'NVARCHAR(100)'),
           @TSQLCommand = EVENTDATA().value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'NVARCHAR(MAX)');

    IF @event_type IN ('CREATE_TABLE', 'ALTER_TABLE', 'DROP_TABLE', 'CREATE_PROCEDURE', 'ALTER_PROCEDURE', 'DROP_PROCEDURE', 'CREATE_VIEW', 'ALTER_VIEW', 'DROP_VIEW', 'CREATE_FUNCTION', 'ALTER_FUNCTION', 'DROP_FUNCTION', 'CREATE_TRIGGER', 'ALTER_TRIGGER', 'DROP_TRIGGER')
    BEGIN
        INSERT INTO ObjectAuditLogs.dbo.ObjectAuditLog (EventDateTime, EventType, ObjectName, LoginName, DatabaseName, TSQLCommand)
        VALUES (GETDATE(), @event_type, @object_name, @login_name, @database_name, @TSQLCommand);
    END

   IF EVENTDATA().value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(128)') = 'DROP_DATABASE'
        SET @event_type = 'Database Drop';
    ELSE
        SET @event_type = 'Database Create';
    
  INSERT INTO ObjectAuditLogs.dbo.ObjectAuditLog (EventDateTime, EventType, ObjectName, LoginName, DatabaseName, TSQLCommand)
        VALUES (GETDATE(), @event_type, @database_name, @login_name, @database_name, @TSQLCommand);
END;

ENABLE TRIGGER [ObjectDDLTrigger] ON ALL SERVER
GO


---------------------------------------------------

 DELETE FROM [dbo].[objectAuditLog]
WHERE DATEDIFF(day,EventDateTime, GETDATE()) >= 30

