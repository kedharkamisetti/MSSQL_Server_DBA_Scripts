/****** Object:  StoredProcedure [dbo].[Automate_DB_Snapshot] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [DBO].[AUTOMATE_DB_SNAPSHOT]
@DBNAME SYSNAME,
@CREATESS BIT = 0,
@DRIVELETTEROVERRIDE CHAR(1) = NULL,
@SSNAME SYSNAME = NULL OUTPUT

AS
/*
Here's a breakdown of what the stored procedure does:
1.	It accepts several input parameters:
	•	@DBName: The name of the database for which a snapshot needs to be created.
	•	@CreateSS: A bit parameter (0 or 1) indicating whether to actually create the snapshot or just generate the script for it. (Default is 0, which generates the script only.)
	•	@DriveLetterOverride: An optional parameter that allows overriding the drive letter where the snapshot folder will be created.
	•	@SSName: An output parameter that will contain the name of the created snapshot.

2.	The stored procedure checks if the specified database exists. If it doesn't, an error message is raised.

3.	It creates a temporary table (#FileNameList) to store the logical and physical file names of the database files.

4.	It generates a SQL script to create the snapshot database using the CREATE DATABASE statement. The script includes file mappings from the original database to the snapshot database.

5.	For each file in the original database, it retrieves the file's ID, drive letter, physical name, and logical name from the #FileNameList table.

6.	It constructs the snapshot folder path based on the drive letter and file path of the original database files. It replaces the "\Data" portion of the path with "\SnapShot".

7.	It executes the xp_create_subdir system stored procedure to create the snapshot folder if it doesn't already exist.

8.	It builds the file mappings for the snapshot database using the file information obtained earlier.

9.	If @CreateSS is set to 1, it executes the dynamically generated SQL script to create the snapshot database.

10.	If the snapshot creation is successful, it prints a success message. Otherwise, it prints a failure message.

11.	If an error occurs during the execution of the stored procedure, an error message is printed.

In summary, this stored procedure automates the process of creating a database snapshot in SQL Server.*/


SET NOCOUNT ON

DECLARE @SSFOLDERPATH SYSNAME,
@SSFOLDER SYSNAME,
@MESSAGE VARCHAR(250),
@SNAPSHOTDATE VARCHAR(10) = CONVERT(VARCHAR(10),GETDATE(),112),
@SQL NVARCHAR(MAX),
@SQL2 NVARCHAR(MAX),
@LOOP INT = 1,
@DRIVELETTER CHAR(1),
@FOLDERTREE SYSNAME,
@PHYSICAL_NAME SYSNAME ,
@ID INT,
@NAME SYSNAME

SET @DBNAME = LTRIM(RTRIM(@DBNAME))
SET @SSNAME = LEFT(@DBNAME,116) +'_SS_'+ @SNAPSHOTDATE

IF NOT EXISTS
(
SELECT TOP 1 1
FROM SYS.DATABASES WITH (NOLOCK)
WHERE NAME = @DBNAME
)
BEGIN
SET @MESSAGE = 'DATABASE ' + QUOTENAME(@DBNAME) + ' DOES NOT EXIST.'
RAISERROR (@MESSAGE,16,1)
RETURN
END

IF OBJECT_ID ('TEMPDB.DBO.#FILENAMELIST') IS NOT NULL
DROP TABLE #FILENAMELIST
CREATE TABLE #FILENAMELIST
(
ID INT IDENTITY(1,1),
NAME SYSNAME,
PHYSICAL_NAME SYSNAME
)

SET @SQL = 'SELECT NAME, PHYSICAL_NAME FROM '+QUOTENAME(@DBNAME)+'.SYS.DATABASE_FILES WITH (NOLOCK) WHERE TYPE = 0'

INSERT #FILENAMELIST
(
NAME,
PHYSICAL_NAME
)
EXECUTE SP_EXECUTESQL
@COMMAND = @SQL

SET @SQL = 'CREATE DATABASE  ' + QUOTENAME(@SSNAME) +' ON ' + CHAR(13) + CHAR(10)

WHILE @LOOP < (SELECT MAX(ID) FROM #FILENAMELIST) + 1
BEGIN
SELECT @ID = ID,
@DRIVELETTER = COALESCE(@DRIVELETTEROVERRIDE, LEFT(PHYSICAL_NAME, 1)),
@PHYSICAL_NAME = PHYSICAL_NAME,
@NAME = NAME
FROM #FILENAMELIST
WHERE ID = @LOOP

IF @@ROWCOUNT = 0
BREAK

SET @FOLDERTREE = SUBSTRING(@PHYSICAL_NAME, 3, LEN(@PHYSICAL_NAME) - ( CHARINDEX('\',REVERSE(@PHYSICAL_NAME))+ 1))
SET @FOLDERTREE = REPLACE(@FOLDERTREE,'\DATA\','\SNAPSHOT\')
SET @SSFOLDERPATH = @DRIVELETTER + ':' + @FOLDERTREE
SET @SSFOLDER = LEFT(@SSFOLDERPATH, LEN(@SSFOLDERPATH)-1)

SET @SQL2 = 'EXECUTE MASTER.DBO.XP_CREATE_SUBDIR "' + @SSFOLDER + '"'
EXECUTE SP_EXECUTESQL
@COMMAND = @SQL2

SELECT @SQL = @SQL +
CASE @ID
WHEN 1
THEN ''
ELSE ','
END +
'(NAME= ' + QUOTENAME(@NAME) + ', FILENAME = ''' + @SSFOLDERPATH + REPLACE(@NAME, '-','') + @SNAPSHOTDATE + '.SS'')' + CHAR(13) + CHAR(10)

SET @LOOP = @LOOP + 1
END

SET @SQL = @SQL + 'AS SNAPSHOT OF ' + QUOTENAME(@DBNAME) + ';'
PRINT @SQL

IF @CREATESS = 1
BEGIN
EXECUTE SP_EXECUTESQL
@COMMAND = @SQL

IF @@ERROR = 0
PRINT 'SNAPSHOT '  + @SSNAME + ' CREATED SUCCESSFULLY.'
ELSE
PRINT 'SNAPSHOT '  + @SSNAME + ' CREATION FAILED.'
END

IF @@ERROR <> 0
PRINT 'ERROR'
GO
