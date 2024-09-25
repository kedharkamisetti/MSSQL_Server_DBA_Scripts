DECLARE @HTMLTablecount NVARCHAR(MAX);
DECLARE @HTMLtable NVARCHAR(MAX);
DECLARE @HTMLDeletedTables NVARCHAR(MAX);
DECLARE @HTMLNewColumns NVARCHAR(MAX);
DECLARE @HTMLDataTypeChange NVARCHAR(MAX);
DECLARE @HTMLDataTypeSizeChange NVARCHAR(MAX);
DECLARE @EmailBody NVARCHAR(MAX);

-- HTML for New Tables Created
SET @HTMLtable = 
N'<H5 style="color: #3dab15; font-family: Arial, Verdana">New Tables Created Report</H5>' +
N'<table border="3" style="font-family: Arial, Verdana; text-align:left; font-size:9pt; color: #000033; width: auto;">' +
N'<tr style="text-align: left;">
<th style="text-align:left;background-color: #FFA500; color:#FFF; font-weight: bold; width: auto;">New Tables Created</th> 
</tr>' +
CAST(( 
    SELECT 
        Currents.TableName AS 'td'
    FROM 
        (SELECT table_name AS TableName
         FROM information_schema.tables
         WHERE table_type = 'BASE TABLE') AS Currents
    LEFT JOIN 
        TableStructureSnapshot AS Snapshots
    ON 
        Currents.TableName = Snapshots.TableName
    WHERE 
        Snapshots.TableName IS NULL
    FOR XML PATH('tr'), TYPE
) AS NVARCHAR(MAX) ) + 
N'</table>';

-- HTML for New Tables Count
SET @HTMLTablecount = 
N'<H5 style="color: #3dab15; font-family: Arial, Verdana">Total Count of Tables</H5>'+
N'<table border="3" style="font-family: Arial, Verdana; text-align:left; font-size:9pt; width: auto; color: #000033">' +
N'<tr style="text-align: left;">
<th style="text-align:left;background-color: #FFA500; color:#FFF; font-weight: bold; width: 25%;">New Tables Count</th> 
</tr>' +
CAST(( 
    SELECT 
        COUNT(*) AS 'td'
    FROM 
        information_schema.tables
    FOR XML PATH('tr'), TYPE
) AS NVARCHAR(MAX) ) + 
N'</table>';

-- HTML for Missing Tables
SET @HTMLDeletedTables = 
N'<H5 style="color: #3dab15; font-family: Arial, Verdana">Missing Tables Report</H5>' +
N'<table border="3" style="font-family: Arial, Verdana; text-align:left; font-size:9pt; color: #000033">' +
N'<tr style="text-align: left;">
<th style="text-align:left;background-color: #FFA500; color:#FFF; font-weight: bold; width: 25%;">Missing Tables</th> 
</tr>' +
CAST(( 
    SELECT 
      DISTINCT 
        Snapshots.TableName, ''
    FROM 
        TableStructureSnapshot AS Snapshots
    LEFT JOIN 
        information_schema.tables AS Currents
    ON 
        Snapshots.TableName = Currents.table_name
    WHERE 
        Currents.table_name IS NULL
    FOR XML PATH('tr'), TYPE
) AS NVARCHAR(MAX) ) + 
N'</table>';

-- Create a temporary table for column comparison results
IF OBJECT_ID('tempdb..#ComparisonResults') IS NOT NULL
    DROP TABLE #ComparisonResults;

CREATE TABLE #ComparisonResults (
    TableName NVARCHAR(255),
    ColumnName NVARCHAR(255),
    DataType NVARCHAR(255),
    IsNullable NVARCHAR(3)
);

-- Insert comparison results into the temporary table
INSERT INTO #ComparisonResults (TableName, ColumnName, DataType, IsNullable)
SELECT 
    curr.TableName, 
    curr.ColumnName, 
    curr.DataType, 
    curr.IsNullable
FROM 
    (SELECT table_name AS TableName, column_name AS ColumnName, data_type AS DataType, is_nullable AS IsNullable
     FROM information_schema.columns) AS curr
FULL OUTER JOIN 
    TableStructureSnapshot AS snap
ON 
    curr.TableName = snap.TableName 
    AND curr.ColumnName = snap.ColumnName
WHERE 
    curr.TableName IS NULL 
    OR snap.TableName IS NULL 
    OR curr.ColumnName IS NULL 
    OR snap.ColumnName IS NULL 
    OR curr.DataType <> snap.DataType 
    OR curr.IsNullable <> snap.IsNullable;

-- Generate HTML for New Columns Detected
SET @HTMLNewColumns = 
N'<H5 style="color: #3dab15; font-family: Arial, Verdana">New Columns Detected</H5>' +
N'<table border="3" style="font-family: Arial, Verdana; text-align:left; font-size:9pt; color: #000033">' +
N'<tr style="text-align: left;">
<th style="text-align:left;background-color: #FFA500; color:#FFF; font-weight: bold; width: 25%;">TableName</th>
<th style="text-align:left;background-color: #FFA500; color:#FFF; font-weight: bold; width: 25%;">ColumnName</th>
<th style="text-align:left;background-color: #FFA500; color:#FFF; font-weight: bold; width: 25%;">DataType</th>
<th style="text-align:left;background-color: #FFA500; color:#FFF; font-weight: bold; width: 25%;">IsNullable</th>
</tr>' +
CAST(( 
    SELECT 
      TableName AS 'TD',
      ColumnName AS 'TD',
      DataType AS 'TD',
      IsNullable AS 'TD'
    FROM 
        #ComparisonResults
    WHERE 
        TableName IS NOT NULL
    FOR XML PATH('tr'), TYPE
) AS NVARCHAR(MAX) ) + 
N'</table>';

-- HTML for Datatype Changes
SET @HTMLDataTypeChange = 
N'<H5 style="color: #3dab15; font-family: Arial, Verdana">Datatype Changes Detected</H5>' +
N'<table border="3" style="font-family: Arial, Verdana; text-align:left; font-size:9pt; color: #000033">' +
N'<tr style="text-align: left;">
<th style="text-align:left;background-color: #FFA500; color:#FFF; font-weight: bold; width: 25%;">TableName</th>
<th style="text-align:left;background-color: #FFA500; color:#FFF; font-weight: bold; width: 25%;">ColumnName</th>
<th style="text-align:left;background-color: #FFA500; color:#FFF; font-weight: bold; width: 25%;">OldDataType</th>
<th style="text-align:left;background-color: #FFA500; color:#FFF; font-weight: bold; width: 25%;">NewDataType</th>
</tr>' +
CAST(( 
    SELECT 
      tss.TableName AS 'TD',
      tss.ColumnName AS 'TD',
      tss.OldDataType AS 'TD',
      tss.NewDataType AS 'TD'
    FROM 
        (SELECT 
            tss.TableName,
            tss.ColumnName,
            tss.DataType AS OldDataType,
            ic.DATA_TYPE AS NewDataType
        FROM 
            TableStructureSnapshot tss
        JOIN 
            information_schema.columns ic
        ON 
            tss.TableName = ic.TABLE_NAME
            AND tss.ColumnName = ic.COLUMN_NAME
        JOIN
            information_schema.tables it
        ON
            it.TABLE_NAME = tss.TableName
        WHERE 
            tss.DataType <> ic.DATA_TYPE
            AND it.TABLE_TYPE = 'BASE TABLE'
        ) AS tss
    FOR XML PATH('tr'), TYPE
) AS NVARCHAR(MAX) ) + 
N'</table>';

-- HTML for Datatype Size Changes
SET @HTMLDataTypeSizeChange = 
N'<H5 style="color: #3dab15; font-family: Arial, Verdana">Datatype Size Changes Detected</H5>' +
N'<table border="3" style="font-family: Arial, Verdana; text-align:left; font-size:9pt; color: #000033">' +
N'<tr style="text-align: left;">
<th style="text-align:left;background-color: #FFA500; color:#FFF; font-weight: bold; width: 25%;">TableName</th>
<th style="text-align:left;background-color: #FFA500; color:#FFF; font-weight: bold; width: 25%;">ColumnName</th>
<th style="text-align:left;background-color: #FFA500; color:#FFF; font-weight: bold; width: 25%;">OldMaxLength</th>
<th style="text-align:left;background-color: #FFA500; color:#FFF; font-weight: bold; width: 25%;">NewMaxLength</th>
</tr>' +
CAST(( 
    SELECT 
      tss.TableName AS 'TD',
      tss.ColumnName AS 'TD',
      tss.OldMaxLength AS 'TD',
      tss.NewMaxLength AS 'TD'
    FROM 
        (SELECT 
            tss.TableName,
            tss.ColumnName,
            tss.CHARACTER_MAXIMUM_LENGTH AS OldMaxLength,
            ic.CHARACTER_MAXIMUM_LENGTH AS NewMaxLength
        FROM 
            TableStructureSnapshot tss
        JOIN 
            information_schema.columns ic
        ON 
            tss.TableName = ic.TABLE_NAME
            AND tss.ColumnName = ic.COLUMN_NAME
        JOIN
            information_schema.tables it
        ON
            it.TABLE_NAME = tss.TableName
        WHERE 
            tss.CHARACTER_MAXIMUM_LENGTH <> ic.CHARACTER_MAXIMUM_LENGTH
            AND it.TABLE_TYPE = 'BASE TABLE'
        ) AS tss
    FOR XML PATH('tr'), TYPE
) AS NVARCHAR(MAX) ) + 
N'</table>';

-- Combine all sections into a single email body
SET @EmailBody = @HTMLTablecount + N'<br/><br/>' + @HTMLtable + N'<br/><br/>' + @HTMLDeletedTables + N'<br/><br/>' + @HTMLNewColumns + N'<br/><br/>' + @HTMLDataTypeChange + N'<br/><br/>' + @HTMLDataTypeSizeChange;

-- Send email with the combined HTML body
EXEC msdb.dbo.sp_send_dbmail 
    @profile_name = 'your_db_mail_profile',
    @recipients = 'your_email@example.com',
    @body = @EmailBody,
    @body_format = 'HTML',
    @subject = 'Database Health Report';

-- Optionally, drop the temporary table when done
IF OBJECT_ID('tempdb..#ComparisonResults') IS NOT NULL
    DROP TABLE #ComparisonResults;
