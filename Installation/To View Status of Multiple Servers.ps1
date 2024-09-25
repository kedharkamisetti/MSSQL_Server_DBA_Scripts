$servers = Get-Content "C:\Test\serverlist.txt"

Get-WmiObject win32_service -computer $servers |
Where-Object {$_.name -match '^*SQL*' -and ($_.Name -ne 'SQLBrowser') -and ($_.Name -ne 'SQLWriter') -and ($_.Name -notlike '*SQLTELEMETRY*')  } | select SystemName, Name, StartName ,State