--Step 1: Set up an Extended Event session to capture session activity.

-- Drop the event session if it already exists
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'TrackSleepingSessions')
BEGIN
    DROP EVENT SESSION [TrackSleepingSessions] ON SERVER;
END
GO

-- Create the event session to track SQL batch completion
--Make sure you have the "temp" named folder in "c drive" or adjust the path as you like.
CREATE EVENT SESSION [TrackSleepingSessions] ON SERVER
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.session_id, sqlserver.sql_text)
    WHERE (sqlserver.sql_text LIKE '%sleeping%'))
ADD TARGET package0.event_file(SET filename = N'C:\temp\TrackSleepingSessions.xel', max_file_size = (5), max_rollover_files = (2))
GO

-- Start the event session
ALTER EVENT SESSION [TrackSleepingSessions] ON SERVER STATE = START;
GO



--Step 2: Create a stored procedure to log sleeping sessions (if needed).

-- Create a table to log sleeping sessions
CREATE TABLE SleepingSessionsLog (
    session_id INT PRIMARY KEY,
    login_name NVARCHAR(128),
    sleep_start_time DATETIME
);

-- Procedure to log new sleeping sessions
CREATE PROCEDURE LogSleepingSessions
AS
BEGIN
    -- Insert new sleeping sessions into the log
    INSERT INTO SleepingSessionsLog (session_id, login_name, sleep_start_time)
    SELECT s.session_id, s.login_name, GETDATE()
    FROM sys.dm_exec_sessions s
    LEFT JOIN SleepingSessionsLog l ON s.session_id = l.session_id
    WHERE s.is_user_process = 1
      AND s.status = 'sleeping'
      AND l.session_id IS NULL; -- Only log sessions not already in the table
END;



--Step 3: Create a stored procedure to kill old sleeping sessions for specific logins.

-- Procedure to kill sessions for specific login names that have been sleeping for 10 minutes or more
CREATE PROCEDURE KillSpecificLoginSessions
    @logins NVARCHAR(MAX) -- Comma-separated list of login names
AS
BEGIN
    DECLARE @spid INT;
    DECLARE @sql NVARCHAR(4000);
    DECLARE @loginTable TABLE (login_name NVARCHAR(128));

    -- Split the comma-separated list into a table
    ;WITH LoginCTE AS (
        SELECT value AS login_name
        FROM STRING_SPLIT(@logins, ',')
    )
    INSERT INTO @loginTable (login_name)
    SELECT login_name
    FROM LoginCTE;

    -- Cursor to loop through each old sleeping session for specific logins
    DECLARE cur CURSOR FOR
    SELECT s.session_id
    FROM sys.dm_exec_sessions s
    JOIN @loginTable l ON s.login_name = l.login_name
    WHERE s.is_user_process = 1
      AND s.status = 'sleeping'
      AND DATEDIFF(MINUTE, s.login_time, GETDATE()) >= 10;

    OPEN cur;
    FETCH NEXT FROM cur INTO @spid;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Build the KILL command
        SET @sql = 'KILL ' + CAST(@spid AS NVARCHAR(10));
        -- Execute the KILL command
        EXEC sp_executesql @sql;

        -- Optionally, remove the killed session from the log
        DELETE FROM SleepingSessionsLog
        WHERE session_id = @spid;

        FETCH NEXT FROM cur INTO @spid;
    END

    CLOSE cur;
    DEALLOCATE cur;
END;



--Step 4: Set up SQL Server Agent Jobs to automate the process.

--Job 1: Log Sleeping Sessions
		--Name: Log Sleeping Sessions
		--Step name: LogSleepingSessionsStep
		--Command: EXEC LogSleepingSessions;
		--Schedule it to run every minute or as needed.

--Job 2: Kill Specific Login Sessions
		--Name: Kill Specific Login Sessions
		--Step name: KillSpecificLoginSessionsStep
		--Command: EXEC KillSpecificLoginSessions @logins = 'login1,login2,login3';
		--Schedule it to run every minute or as needed.