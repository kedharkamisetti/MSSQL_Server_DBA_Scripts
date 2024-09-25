# Set your email credentials
$smtpServer = "smtp.gmail.com"
$smtpPort = 587
$emailFrom = "kedhar713@gmail.com" # email id - from
$emailPassword = "jaehprsjlgmxsrsg" # app password
$emailTo = "kedhar713@gmail.com" # email id - to

# List of SQL Server Instances
$sqlInstances = @("MACP\INST1")  # Add your instances here

# Function to send email alerts
function Send-EmailAlert {
    param (
        [string]$subject,
        [string]$body
    )
    $smtp = New-Object Net.Mail.SmtpClient($smtpServer, $smtpPort)
    $smtp.EnableSsl = $true
    $smtp.Credentials = New-Object Net.NetworkCredential($emailFrom, $emailPassword)
    $smtp.Send($emailFrom, $emailTo, $subject, $body)
}

# Function to get database status
function Get-DatabaseStatus {
    param (
        [int]$status
    )
    switch ($status) {
        0 { return "ONLINE" }
        1 { return "RESTORING" }
        2 { return "RECOVERING" }
        3 { return "RECOVERY_PENDING" }
        4 { return "SUSPECT" }
        5 { return "EMERGENCY" }
        6 { return "OFFLINE" }
        7 { return "COPYING" }
        10 { return "OFFLINE_SECONDARY" }
        default { return "UNKNOWN" }
    }
}

# Check each SQL Server Instance
foreach ($instance in $sqlInstances) {
    $alertMessages = @()  # Initialize an array to hold alert messages

    # Check SQL Server Instance Status
    try {
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $sqlConnection.ConnectionString = "Server=$instance;Integrated Security=True;"
        $sqlConnection.Open()
        Write-Host "SQL Server instance '$instance' is up and running."
    } catch {
        $alertMessages += "The SQL Server instance '$instance' is down or unreachable. Error: $($_.Exception.Message)"
        Write-Host "SQL Server instance '$instance' is down. Sending email alert."

        # Send email alert if instance is down
        try {
            $emailBody = "Alert: SQL Server instance '$instance' is down. Error: $($_.Exception.Message)"
            Send-EmailAlert -subject "SQL Server Instance Down: $instance" -body $emailBody
            Write-Host "Email alert sent."
        } catch {
            Write-Host "Failed to send email alert. Error: $_"
        }
        continue  # Skip further checks if instance is down
    }

    # Proceed with checks if the instance is up
    try {
        # Suspect Database State
        $suspectDBs = Invoke-Sqlcmd -Query "SELECT name, state, database_id FROM sys.databases WHERE state <> 0" -ConnectionString "Server=$instance;Integrated Security=True;"
        if ($suspectDBs) {
            $suspectDetails = $suspectDBs | ForEach-Object {
                $status = Get-DatabaseStatus $_.state
                "Database: $($_.name), Status: $status"
            }
            $alertMessages += "### Suspect Databases:n$($suspectDetails -join "n")n"
            Send-EmailAlert -subject "Suspect Databases Alert for $instance" -body "Suspect Databases:n$($suspectDetails -join "n")"
        }

        # Long Running User Queries
        $longRunningQueries = Invoke-Sqlcmd -Query "
            SELECT session_id, status, start_time, command,
                (SELECT login_name FROM sys.dm_exec_sessions WHERE session_id = r.session_id) AS login_name
            FROM sys.dm_exec_requests AS r
            WHERE DATEDIFF(MINUTE, start_time, GETDATE()) > 60 
            AND session_id >= 50" -ConnectionString "Server=$instance;Integrated Security=True;"

        if ($longRunningQueries) {
            $longQueryDetails = $longRunningQueries | ForEach-Object {
                "Session ID: $($_.session_id), Status: $($_.status), Start Time: $($_.start_time), Command: $($_.command), User: $($_.login_name)"
            }
            Send-EmailAlert -subject "Long Running Queries Alert for $instance" -body "Long Running User Queries (over 1 hour):n$($longQueryDetails -join "n")"
        }

        # Fragmented Index Check
        $fragmentedIndexes = Invoke-Sqlcmd -Query "
            DECLARE @DatabaseName NVARCHAR(255)
            DECLARE @SQL NVARCHAR(MAX)

            CREATE TABLE #FragmentationResults (
                DatabaseName NVARCHAR(255),
                SchemaName NVARCHAR(255),
                TableName NVARCHAR(255),
                IndexName NVARCHAR(255),
                IndexType NVARCHAR(50),
                AvgFragmentationInPercent FLOAT
            )

            DECLARE db_cursor CURSOR FOR
            SELECT name 
            FROM sys.databases 
            WHERE state_desc = 'ONLINE' AND database_id > 4

            OPEN db_cursor  
            FETCH NEXT FROM db_cursor INTO @DatabaseName  

            WHILE @@FETCH_STATUS = 0  
            BEGIN  
                SET @SQL = '
                USE [' + @DatabaseName + '];

                INSERT INTO #FragmentationResults (DatabaseName, SchemaName, TableName, IndexName, IndexType, AvgFragmentationInPercent)
                SELECT 
                    ''' + @DatabaseName + ''', 
                    s.name AS SchemaName,
                    OBJECT_NAME(i.object_id) AS TableName,
                    i.name AS IndexName,
                    CASE WHEN i.type = 1 THEN ''Clustered'' ELSE ''Non-clustered'' END AS IndexType,
                    ps.avg_fragmentation_in_percent
                FROM 
                    sys.indexes AS i
                JOIN 
                    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, ''LIMITED'') AS ps
                    ON i.object_id = ps.object_id AND i.index_id = ps.index_id
                JOIN 
                    sys.schemas AS s
                    ON OBJECT_SCHEMA_NAME(i.object_id, DB_ID()) = s.name
                WHERE 
                    ps.avg_fragmentation_in_percent > 30
                    AND OBJECTPROPERTY(i.object_id, ''IsUserTable'') = 1;'

                EXEC sp_executesql @SQL
                FETCH NEXT FROM db_cursor INTO @DatabaseName  
            END  

            CLOSE db_cursor  
            DEALLOCATE db_cursor  

            SELECT * FROM #FragmentationResults;

            DROP TABLE #FragmentationResults;" -ConnectionString "Server=$instance;Integrated Security=True;"

        if ($fragmentedIndexes) {
            $indexDetails = $fragmentedIndexes | ForEach-Object {
                "Database: $($_.DatabaseName)nSchema: $($_.SchemaName)nTable: $($_.TableName)nIndex: $($_.IndexName)nIndex Type: $($_.IndexType)nFragmentation: $([math]::Round($_.AvgFragmentationInPercent, 2))%n"
            }
            Send-EmailAlert -subject "Fragmented Indexes Alert for $instance" -body "Fragmented Indexes (over 30% fragmentation):n$($indexDetails -join "n")"
        }

        # Integrity Check
        $integrityCheckLogs = Invoke-Sqlcmd -Query "EXEC xp_readerrorlog 0, 1, N'DBCC CHECKDB'" -ConnectionString "Server=$instance;Integrated Security=True;"
        $allDatabases = Invoke-Sqlcmd -Query "SELECT name FROM sys.databases WHERE state_desc = 'ONLINE'" -ConnectionString "Server=$instance;Integrated Security=True;"
        $databasesWithoutChecks = @()
        $currentDateTime = Get-Date

        foreach ($db in $allDatabases) {
            $dbName = $db.name
            $checkEntry = $integrityCheckLogs | Where-Object { 
                $_.text -like "*($dbName)* found*" -and 
                [datetime]::Parse($_.logdate) -gt $currentDateTime.AddDays(-7) 
            }

            if ($checkEntry.Count -eq 0) {
                $databasesWithoutChecks += $dbName
            }
        }

        if ($databasesWithoutChecks.Count -gt 0) {
            $databaseNames = $databasesWithoutChecks -join ', '
            $alertMessage = "Integrity check not done in the last 7 days for: $databaseNames"
            Send-EmailAlert -subject "Integrity Check Alert for $instance" -body "Integrity check not done in the last 7 days for: $databaseNames"
        }

        # Log Backup Check
$logBackupNeverTaken = Invoke-Sqlcmd -Query "
    SELECT name 
    FROM sys.databases 
    WHERE NOT EXISTS (
        SELECT 1 
        FROM msdb.dbo.backupset 
        WHERE database_name = sys.databases.name AND type = 'L'
    )" -ConnectionString "Server=$instance;Integrated Security=True;"

if ($logBackupNeverTaken) {
    $logBackupMessage = "### Log Backup Alerts:`nThese databases have never had a log backup taken: $($logBackupNeverTaken.name -join ', ')`n"
    Send-EmailAlert -subject "Log Backup Alerts for $instance" -body $logBackupMessage
}

$logBackupOlderThanOneDay = Invoke-Sqlcmd -Query "
    SELECT name 
    FROM sys.databases 
    WHERE DATEDIFF(DAY, 
        (SELECT MAX(backup_finish_date) 
        FROM msdb.dbo.backupset 
        WHERE database_name = sys.databases.name AND type = 'L'), 
        GETDATE()) > 1" -ConnectionString "Server=$instance;Integrated Security=True;"

if ($logBackupOlderThanOneDay) {
    $logBackupOlderMessage = "Log backup is older than 1 day for: $($logBackupOlderThanOneDay.name -join ', ')`n"
    Send-EmailAlert -subject "Log Backup Older Than 1 Day for $instance" -body $logBackupOlderMessage
}

# Full Backup Check
$fullBackupNeverTaken = Invoke-Sqlcmd -Query "
    SELECT name 
    FROM sys.databases 
    WHERE NOT EXISTS (
        SELECT 1 
        FROM msdb.dbo.backupset 
        WHERE database_name = sys.databases.name AND type = 'D'
    )" -ConnectionString "Server=$instance;Integrated Security=True;"

if ($fullBackupNeverTaken) {
    $fullBackupMessage = "### Full Backup Alerts:`nThese databases have never had a full backup taken: $($fullBackupNeverTaken.name -join ', ')`n"
    Send-EmailAlert -subject "Full Backup Alerts for $instance" -body $fullBackupMessage
}

$fullBackupOlderThanSevenDays = Invoke-Sqlcmd -Query "
    SELECT name 
    FROM sys.databases 
    WHERE DATEDIFF(DAY, 
        (SELECT MAX(backup_finish_date) 
        FROM msdb.dbo.backupset 
        WHERE database_name = sys.databases.name AND type = 'D'), 
        GETDATE()) > 7" -ConnectionString "Server=$instance;Integrated Security=True;"

if ($fullBackupOlderThanSevenDays) {
    $fullBackupOlderMessage = "Full backup is older than 7 days for: $($fullBackupOlderThanSevenDays.name -join ', ')`n"
    Send-EmailAlert -subject "Full Backup Older Than 7 Days for $instance" -body $fullBackupOlderMessage
}

# PAGE VERIFY Option
$pageVerify = Invoke-Sqlcmd -Query "SELECT name FROM sys.databases WHERE page_verify_option_desc = 'NONE'" -ConnectionString "Server=$instance;Integrated Security=True;"
if ($pageVerify) {
    $pageVerifyMessage = "### PAGE VERIFY Alerts:`nPAGE VERIFY is set to NONE for: $($pageVerify.name)`n"
    Send-EmailAlert -subject "PAGE VERIFY Alerts for $instance" -body $pageVerifyMessage
}

# SQL Server Error Log
$currentTime = Get-Date
$timeThreshold = $currentTime.AddMinutes(-30)
$errorLog = Invoke-Sqlcmd -Query "EXEC xp_readerrorlog 0, 1, NULL" -ConnectionString "Server=$instance;Integrated Security=True;"

if ($errorLog) {
    $recentErrors = $errorLog | Where-Object {
        [datetime]$_.logdate -ge $timeThreshold -and 
        $_.text -match 'Error:|failed|exception|critical|severity|cannot|was not found'
    } | Select-Object -Property logdate, text
    
    if ($recentErrors) {
        $errorDetails = $recentErrors | ForEach-Object {
            "Date: $($_.logdate), Error: $($_.text)"
        }
        $errorLogMessage = "### Recent SQL Server Error Log:`n$($errorDetails -join "`n")`n"
        Send-EmailAlert -subject "Recent SQL Server Error Log for $instance" -body $errorLogMessage
    }
}

# Disk Usage Check
$diskInfo = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }

foreach ($disk in $diskInfo) {
    $usedSpace = $disk.Size - $disk.FreeSpace
    $usedPercentage = [math]::Round(($usedSpace / $disk.Size) * 100, 2)

    if ($usedPercentage -ge 80) {
        $diskUsageMessage = "### Disk Usage Alert:`nDrive $($disk.DeviceID) is at $usedPercentage% capacity. Free Space: $([math]::Round($disk.FreeSpace / 1GB, 2)) GB`n"
        Send-EmailAlert -subject "Disk Usage Alert for $instance" -body $diskUsageMessage
    }
}

# Check SQL Server Agent status
$agentServiceName = "SQLAgent$($instance.Split('\')[-1])"  # Extract instance name for Agent service
$agentService = Get-Service -Name $agentServiceName -ErrorAction SilentlyContinue

if ($agentService) {
    if ($agentService.Status -ne 'Running') {
        $subject = "SQL Server Agent Down for instance $instance"
        $body = "The SQL Server Agent for instance '$($instance.Split('\')[-1])' is down. Current Status: $($agentService.Status)"
        Send-EmailAlert -subject $subject -body $body
    }
} else {
    $subject = "SQL Server Agent Service Not Found for instance $instance"
    $body = "The SQL Server Agent service '$agentServiceName' not found for instance '$($instance.Split('\')[-1])'."
    Send-EmailAlert -subject $subject -body $body
}


} catch {
        Write-Host "An error occurred while checking the instance '$instance'. Error: $_"
    } finally {
        if ($sqlConnection) {
            $sqlConnection.Close()
        }
    }
}
