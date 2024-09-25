dbcc sqlperf (logspace)

--or

DECLARE
       @dbname VARCHAR(100) = NULL,
       @SpaceUsed FLOAT = NULL
DECLARE @LOGSPACE TABLE(
       dbName VARCHAR(100),
       LogSizeMB FLOAT,
       [LogSpaceUsed%] FLOAT,
       [Status] INT
       )
INSERT @LOGSPACE EXEC ('DBCC SQLPERF(''logspace'')')
SELECT dbName, LogSizeMB, [LogSpaceUsed%], [Status] FROM @LOGSPACE where [LogSpaceUsed%] > 30
SELECT dbName, LogSizeMB, [LogSpaceUsed%], [Status] FROM @LOGSPACE where [LogSizeMB] > 10