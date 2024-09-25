# run this in powershell ise
# make sure to provide the file with all of the instances names in it

Function TestSQLInstance
{
Param([String] $InputFile)
Function Test-SQLConn ($Server)
{
$connectionString = "Data Source=$Server;Integrated Security=true;Initial Catalog=master;Connect Timeout=3;"
$sqlConn = new-object ("Data.SqlClient.SqlConnection") $connectionString
trap
{
Write-output "$instance Cannot connect.";
continue
}
$sqlConn.Open()

if ($sqlConn.State -eq 'Open')
{
$sqlConn.Close();
"$instance  Opened successfully."
}
}

ForEach ($instance in Get-Content $InputFile)
{
Test-SQLConn -server $instance
}
}

TestSQLInstance -InputFile "C:\Serverlist.txt" |Out-File C:\Ouptut.txt