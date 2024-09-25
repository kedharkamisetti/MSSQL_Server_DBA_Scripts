$servers = Get-Content "C:\Test\serverlist.txt"
$results = @()

foreach ($sqlinstance in $servers) {
    Write-Host "Server: $sqlinstance"

    $query = @"
SELECT @@servername, Name,state_desc from sys.databases  
"@

    try {
        $result = Invoke-Sqlcmd -ServerInstance $sqlinstance -Query $query
        $results += $result
    } catch {
        Write-Host "Failed to execute the SQL query on the server."
        Write-Host "Error: $_"
    }

    Write-Host "--------------------------"
}

$results |  Format-Table -AutoSize ##Out-GridView 