
<#This code is retrieving disk information for a list of servers specified in a text file and outputting the information to the console and a text file.
 It uses the `Get-WmiObject` cmdlet to retrieve information about logical disks on each server, and then formats and outputs the information using
`Format-Table` and `Out-File`. The `try` and `catch` blocks are used to handle any errors that may occur during the process.#>

$computers = Get-Content "C:\Test\serverlist.txt"

foreach ($computer in $computers) {
    try {
        $disks = Get-WmiObject -ComputerName $computer -Class Win32_LogicalDisk |
                 Select-Object DeviceID, MediaType, VolumeName, `
                               @{n="Size (GB)";e={[math]::Round($_.Size/1GB, 2)}}, `
                               @{n="Free Space (GB)";e={[math]::Round($_.FreeSpace/1GB, 2)}}

        Write-Host ("Disk information for {0}:" -f $computer)
        $disks | Format-Table

        $header = "Disk information for {0}:" -f $computer
        $header | Out-File -FilePath "C:\Test\output.txt" -Append
        $disks | Format-Table | Out-String | Out-File -FilePath "C:\Test\output.txt" -Append

    } catch {
        Write-Host ("Failed to retrieve disk information for {0}: {1}" -f $computer, $_)
    }
}
