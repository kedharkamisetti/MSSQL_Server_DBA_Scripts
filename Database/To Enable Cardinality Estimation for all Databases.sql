USE [master]
GO

DECLARE @SqlStatement NVARCHAR(MAX)

SET @SqlStatement = (
    SELECT STRING_AGG(
        'USE [' + [Name] + '];' + CHAR(13) + CHAR(10) + 'ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = ON;' + CHAR(13) + CHAR(10) + 'GO',
        CHAR(13) + CHAR(10)
    ) WITHIN GROUP (ORDER BY [Name])
    FROM sys.databases
    WHERE database_id > 5
)

-- Uncomment the next line to verify the generated SQL before executing
PRINT @SqlStatement

-- EXEC sp_executesql @SqlStatement  -- Uncomment this line to execute the generated SQL
