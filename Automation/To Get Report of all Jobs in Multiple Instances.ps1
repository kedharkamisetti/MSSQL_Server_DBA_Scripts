############################################
# Daily Job Monitor Report Status 
# Single HTML Will Get created for all Servers 
#############################################

$starttime = Get-Date
# Format the date and time to remove invalid characters
$formattedDate = $starttime.ToString("-yyyy-MM-dd_HH-mm-ss")
$servernames = Get-Content -Path "C:\HealthcheckReports\serverlist.txt"

# Define the path for the combined report
$path = "C:\HealthcheckReports"

# Initialize an empty string to store combined HTML content
$combinedHtmlContent = ""

foreach ($servername in $servernames) {
    Write-Host "Starting Server $servername"

    $dataSource = $servername
    $database = "master"
    $name = $dataSource -replace "\\","_"
    $OutputFile_new = Join-Path -Path $path -ChildPath ($name + $formattedDate + '.html')

    $style = @"
<style>
BODY { background-color: #e0e0e0; height: 100%; width: 100%; transform: scale(0.8); transform-origin: top left; }
TABLE { border-width: 1px; border: 2px solid black; }
TH { border-width: 2px; padding: 5px; border: 2px solid black;background-color: pink; font-family: 'Arial Narrow', Arial, sans-serif; }
TD { border-width: 2px; padding: 5px; border: 2px solid black; BGCOLOR = LIGHTGREEN }
tr:nth-child(even) { background-color: #f2f2f2 }
.ENABLED { color: green; font-weight: bold; }
.DISABLED { color: red; font-weight: bold; }
.SUCCEEDED { color: green; font-weight: bold; }
.FAILED { color: red; font-weight: bold; }
.NEVER { color: Orange; font-weight: bold; }
</style>
"@

    $connectionDetails = "Provider=sqloledb; Data Source=$dataSource; Initial Catalog=$database; Integrated Security=SSPI;"

    $Jobreport = @"
    SELECT @@SERVERNAME as SERVERNAME,
           [SJOB].[NAME] AS [JOBNAME],
           CASE 
               WHEN [SJOBH].[RUN_DATE] IS NULL OR [SJOBH].[RUN_TIME] IS NULL THEN NULL
               ELSE CAST(
                   CAST([SJOBH].[RUN_DATE] AS CHAR(8))
                   + ' ' 
                   + STUFF(
                       STUFF(RIGHT('000000' + CAST([SJOBH].[RUN_TIME] AS VARCHAR(6)),  6)
                       , 3, 0, ':')
                   , 6, 0, ':') AS DATETIME)
           END AS [LASTRUNDATETIME],
           CASE [SJOBH].[RUN_STATUS]
               WHEN 0 THEN 'FAILED'
               WHEN 1 THEN 'SUCCEEDED'
               WHEN 2 THEN 'RETRY'
               WHEN 3 THEN 'CANCELLED'
               WHEN 4 THEN 'RUNNING'
           END AS [LASTRUNSTATUS],
           STUFF(
               STUFF(RIGHT('000000' + CAST([SJOBH].[RUN_DURATION] AS VARCHAR(6)),  6)
               , 3, 0, ':')
           , 6, 0, ':') AS [LASTRUNDURATION],
           CASE WHEN ENABLED = 1 THEN 'ENABLED' ELSE 'DISABLED' END AS [JOBSTATUS],
           CASE [SJOBSCH].[NEXTRUNDATE]
               WHEN 0 THEN NULL
               ELSE CAST(
                   CAST([SJOBSCH].[NEXTRUNDATE] AS CHAR(8))
                   + ' ' 
                   + STUFF(
                       STUFF(RIGHT('000000' + CAST([SJOBSCH].[NEXTRUNTIME] AS VARCHAR(6)),  6)
                       , 3, 0, ':')
                   , 6, 0, ':') AS DATETIME)
           END AS [NEXTRUNDATETIME]
    INTO #AGENT_JOBSTAUS
    FROM [MSDB].[DBO].[SYSJOBS] AS [SJOB]
    LEFT JOIN (
               SELECT
                   [JOB_ID],
                   MIN([NEXT_RUN_DATE]) AS [NEXTRUNDATE],
                   MIN([NEXT_RUN_TIME]) AS [NEXTRUNTIME]
               FROM [MSDB].[DBO].[SYSJOBSCHEDULES]
               GROUP BY [JOB_ID]
           ) AS [SJOBSCH] ON [SJOB].[JOB_ID] = [SJOBSCH].[JOB_ID]
    LEFT JOIN (
               SELECT [JOB_ID],
                      [RUN_DATE],
                      [RUN_TIME],
                      [RUN_STATUS],
                      [RUN_DURATION],
                      [MESSAGE],
                      ROW_NUMBER() OVER (
                                           PARTITION BY [JOB_ID] 
                                           ORDER BY [RUN_DATE] DESC, [RUN_TIME] DESC
                      ) AS ROWNUMBER
               FROM [MSDB].[DBO].[SYSJOBHISTORY]
               WHERE [STEP_ID] = 0
           ) AS [SJOBH] ON [SJOB].[JOB_ID] = [SJOBH].[JOB_ID] AND [SJOBH].[ROWNUMBER] = 1
    ORDER BY [JOBNAME];

    SELECT SERVERNAME,
           JOBNAME,
           COALESCE(CONVERT(VARCHAR(20), LASTRUNDATETIME, 120), 'NEVER') AS LASTRUNDATETIME,
           COALESCE(CONVERT(VARCHAR(20), LASTRUNSTATUS, 120), 'NEVER') AS LASTRUNSTATUS,
           COALESCE(CONVERT(VARCHAR(20), LASTRUNDURATION, 120), 'NEVER') AS LASTRUNDURATION,
           COALESCE(CONVERT(VARCHAR(20), JOBSTATUS, 120), 'NEVER') AS JOBSTATUS,
           COALESCE(CONVERT(VARCHAR(20), NEXTRUNDATETIME, 120), 'NEVER') AS NEXTRUNDATETIME
    FROM #AGENT_JOBSTAUS;

    DROP TABLE #AGENT_JOBSTAUS;
"@

    $connection = New-Object System.Data.OleDb.OleDbConnection $connectionDetails
    $command = New-Object System.Data.OleDb.OleDbCommand $Jobreport, $connection
    $connection.Open()

    $dataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter $command
    $dataSet = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet) | Out-Null
    $connection.Close()

    # Generate HTML rows with conditional coloring for LASTRUNSTATUS
    $rows = foreach ($row in $dataSet.Tables[0].Rows) {
        $lastRunStatus = $row.LASTRUNSTATUS
        $statusClass = switch ($lastRunStatus) {
            'NEVER' { 'class="NEVER"' }
            'FAILED' { 'class="FAILED"' }
            'SUCCEEDED' { 'class="SUCCEEDED"' }
            default { '' }
        }

        $JOBSTATUS = $row.JOBSTATUS
        $JOBSTATUSClass = switch ($JOBSTATUS) {
            'ENABLED' { 'class="ENABLED"' }
            'DISABLED' { 'class="DISABLED"' }
            default { '' }
        }

        $LASTRUNDURATION = $row.LASTRUNDURATION
        $lastSTATUSClass = switch ($LASTRUNDURATION) {
            'NEVER' { 'class="NEVER"' }
            default { '' }
        }

        $LASTRUNDATETIME = $row.LASTRUNDATETIME
        $lastLASTRUNDATETIMEClass = switch ($LASTRUNDATETIME) {
            'NEVER' { 'class="NEVER"' }
            default { '' }
        }

        "<tr>
            <td>$($row.SERVERNAME)</td>
            <td>$($row.JOBNAME)</td>
            <td $lastLASTRUNDATETIMEClass>$LASTRUNDATETIME</td>
            <td $statusClass>$lastRunStatus</td>
            <td $lastSTATUSClass>$LASTRUNDURATION</td>
            <td $JOBSTATUSClass>$JOBSTATUS</td>
            <td>$($row.NEXTRUNDATETIME)</td>
        </tr>"
    }

    # Append the rows to the combined HTML content
    $combinedHtmlContent += @"
    <h2 align='Left'>Job Monitor Report for Server: $($dataSource)</h2>
    <table>
    <tr><th>SERVERNAME</th><th>JOBNAME</th><th>LASTRUNDATETIME</th><th>LASTRUNSTATUS</th><th>LASTRUNDURATION</th><th>JOBSTATUS</th><th>NEXTRUNDATETIME</th></tr>
    $($rows -join "`n")
    </table>
"@
}

# Wrap all server reports in a single HTML structure
$htmlContent = @"
<html>
<head>
$style
</head>
<body>
<h1 align='Center'>Combined Job Monitor Report</h1>
$combinedHtmlContent
</body>
</html>
"@

# Save the combined HTML content to a file
$outputFileCombined = Join-Path -Path $path -ChildPath ("Combined_Report" + $formattedDate + '.html')
$htmlContent | Out-File -FilePath $outputFileCombined -Encoding utf8

Write-Host "Combined report saved to $outputFileCombined"