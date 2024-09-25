<#===================================================================================================================

================================================================================================#>
$ServerList = "C:\Test\serverlist.txt"
$ReportFileName = "C:\Test\ServerDriveSpace.htm"
#$EmailTo = "sqldbanow@gmail.com"
#$EmailFrom = "ajeyudub@gmail.com"
$date = ( get-date ).ToString('MM/dd/yyyy')
$EmailSubject = "Test Server Disk Space Report for " + $date
#$SMTPServer = "smtp.sqldbanow.com"


$EmailFrom = “peddareddy1989@outlook.com”
$EmailTo = “musicandra@gmail.com”
$Subject = "Test Server Disk Space Report for " + $date
#$Body = “Disk Space Alerts”
$SMTPServer = “smtp.outlook.com”
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential(“peddareddi@outlook.com”, “Giveurpassword”);
$mailMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body)
$attachmentPath = "C:\Test\ServerDriveSpace.htm"
$attachment = New-Object System.Net.Mail.Attachment($attachmentPath)
$mailMessage.Attachments.Add($attachment)

$SMTPClient.Send($mailMessage)


# Thresholds: % of available disk space to trigger colors in report. Warning is yellow, Critical is red
$warning = 15
$critical = 10

# Clear the display, show information if running locally.
Clear
Write-Host "Gathering server information..." -foreground "Yellow"
Write-Host


# Create output file and nullify display output
New-Item -ItemType file $ReportFileName -Force > $null


# Write the HTML Header to the file
$date = ( get-date ).ToString('MM/dd/yyyy')
Add-Content $ReportFileName "<html>"
Add-Content $ReportFileName "<head>"
Add-Content $ReportFileName "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>"
Add-Content $ReportFileName '<title>Server Drive Space Report</title>'
Add-Content $ReportFileName '<STYLE TYPE="text/css">'
Add-Content $ReportFileName "td {"
Add-Content $ReportFileName "font-family: Cambria;"
Add-Content $ReportFileName "font-size: 11px;"
Add-Content $ReportFileName "border-top: 1px solid #999999;"
Add-Content $ReportFileName "border-right: 1px solid #999999;"
Add-Content $ReportFileName "border-bottom: 1px solid #999999;"
Add-Content $ReportFileName "border-left: 1px solid #999999;"
Add-Content $ReportFileName "padding-top: 0px;"
Add-Content $ReportFileName "padding-right: 0px;"
Add-Content $ReportFileName "padding-bottom: 0px;"
Add-Content $ReportFileName "padding-left: 0px;"
Add-Content $ReportFileName "}"
Add-Content $ReportFileName "body {"
Add-Content $ReportFileName "margin-left: 5px;"
Add-Content $ReportFileName "margin-top: 5px;"
Add-Content $ReportFileName "margin-right: 0px;"
Add-Content $ReportFileName "margin-bottom: 10px;"
Add-Content $ReportFileName "table {"
Add-Content $ReportFileName "border: thin solid #000000;"
Add-Content $ReportFileName "}"
Add-Content $ReportFileName "</style>"
Add-Content $ReportFileName "</head>"
Add-Content $ReportFileName "<body>"
Add-Content $ReportFileName "<table width='75%' align=`"center`">"
Add-Content $ReportFileName "<tr bgcolor='#CCCCCC'>"
Add-Content $ReportFileName "<td colspan='7' height='25' align='center'>"
Add-Content $ReportFileName "<font face='Cambria' color='#003399' size='4'><strong>$EmailSubject</strong></font>"
Add-Content $ReportFileName "</td>"
Add-Content $ReportFileName "</tr>"
Add-Content $ReportFileName "</table>"


# Add color descriptions here
Add-content $ReportFileName "<table width='50%' align=`"center`">"  
Add-Content $ReportFileName "<tr>"  
Add-Content $ReportFileName "<td width='10%' bgcolor='#4CBB17' align='center'><B>Good > $warning%</B></td>"  
Add-Content $ReportFileName "<td width='10%' bgcolor='#FBB917' align='center'><B>Warning = $warning%</B></td>"  
Add-Content $ReportFileName "<td width='10%' bgcolor='#FF0000' align='center'><B>Critical = $critical%</B></td>"  
Add-Content $ReportFileName "</tr>"  
Add-Content $ReportFileName "</table>"


# Function to write the Table Header to the file
Function writeTableHeader
{
	param($fileName)
	Add-Content $fileName "<tr bgcolor=#CCCCCC>"
	Add-Content $fileName "<td width='10%' align='center'>Drive</td>"
	Add-Content $fileName "<td width='10%' align='center'>Drive Label</td>"
	Add-Content $fileName "<td width='15%' align='center'>Total Capacity (GB)</td>"
	Add-Content $fileName "<td width='15%' align='center'>Used Capacity (GB)</td>"
	Add-Content $fileName "<td width='15%' align='center'>Free Space (GB)</td>"
	Add-Content $fileName "<td width='10%' align='center'>Free Space %</td>"
	Add-Content $fileName "</tr>"
}


# Function to write the HTML Footer to the file
Function writeHtmlFooter
{
	param($fileName)
	Add-Content $fileName "</body>"
	Add-Content $fileName "</html>"
}


# Function to write Disk info to the file
Function writeDiskInfo
{
	param(
			$fileName
			,$devId
			,$volName
			,$frSpace
			,$totSpace
		)
	$totSpace 	= [math]::Round(($totSpace/1073741824),2)
	$frSpace 	= [Math]::Round(($frSpace/1073741824),2)
	$usedSpace 	= $totSpace - $frspace
	$usedSpace 	= [Math]::Round($usedSpace,2)
	$freePercent 	= ($frspace/$totSpace)*100
	$freePercent 	= [Math]::Round($freePercent,0)
	Add-Content $fileName "<tr>"
	Add-Content $fileName "<td align='center'>$devid</td>"
	Add-Content $fileName "<td align='center'>$volName</td>"
	Add-Content $fileName "<td align='right'>$totSpace</td>"
	Add-Content $fileName "<td align='right'>$usedSpace</td>"
	Add-Content $fileName "<td align='right'>$frSpace</td>"

	if ($freePercent -gt $warning)
	{
	# bgcolor='#4CBB17' = Green for Good
		Add-Content $fileName "<td bgcolor='#4CBB17' align='center'>$freePercent</td>"
		Add-Content $fileName "</tr>"
	}
	elseif ($freePercent -le $critical)
	{
	# bgcolor='#FF0000' = Red for Critical
		Add-Content $fileName "<td bgcolor='#FF0000' align=center>$freePercent</td>"
		Add-Content $fileName "</tr>"
	}
	else
	{
	# bgcolor='#FBB917' = Yellow for Warning
		Add-Content $fileName "<td bgcolor='#FBB917' align=center>$freePercent</td>"
		Add-Content $fileName "</tr>"
	}
}


foreach ($server in Get-Content $serverlist)
{
	try {
		$ServerName = [System.Net.Dns]::gethostentry($server).hostname
		}
	catch [System.DivideByZeroException] {
		Write-Host "DivideByZeroException: "
		$_.Exception
		Write-Host
		if ($_.Exception.InnerException) {
			Write-Host "Inner Exception: "
			$_.Exception.InnerException.Message # display the exception's InnerException if it has one
			}
		"Continuing..."
		continue
		}
	catch [System.UnauthorizedAccessException] {
		Write-Host "System.UnauthorizedAccessException"
		$_.Exception
		Write-Host
		if ($_.Exception.InnerException) {
			Write-Host "Inner Exception: "
			$_.Exception.InnerException.Message # display the exception's InnerException if it has one
			}
		"Continuing..."
		continue
		}
	catch [System.Management.Automation.RuntimeException] {
		Write-Host "RuntimeException"
		$_.Exception
		Write-Host
		if ($_.Exception.InnerException) {
			Write-Host "Inner Exception: "
			$_.Exception.InnerException.Message # display the exception's InnerException if it has one
			}
		"Continuing..."
		continue
		}	
	catch [System.Exception] {
		Write-Host "Exception connecting to $Server" 
		$_.Exception
		Write-Host
		if ($_.Exception.InnerException) {
			Write-Host "Inner Exception: "
			$_.Exception.InnerException.Message # display the exception's InnerException if it has one
			}
		"Continuing..."
		continue
		}	

	if ($ServerName -eq $null) {
			$ServerName = $Server
			}

# Begin Server Disk tables
	Add-Content $ReportFileName "</table>"
	Add-Content $ReportFileName "<br>"
	Add-Content $ReportFileName "<table width='75%' align=`"Center`">"
	Add-Content $ReportFileName "<tr bgcolor='#CCCCCC'>"
	Add-Content $ReportFileName "<td width='75%' align='center' colSpan=6><font face='Cambria' color='#003399' size='2'><strong> $Server </strong></font></td>"
	Add-Content $ReportFileName "</tr>"

	writeTableHeader $ReportFileName

	$dp = Get-WmiObject win32_logicaldisk -ComputerName $server |  Where-Object {$_.drivetype -eq 3}

	foreach ($item in $dp)
	{
		Write-Host  $ServerName $item.DeviceID  $item.VolumeName $item.FreeSpace $item.Size
		writeDiskInfo $ReportFileName $item.DeviceID $item.VolumeName $item.FreeSpace $item.Size
	}
	$ServerName = $NULL
#	Add-Content $ReportFileName "<br>"
}

writeHtmlFooter $ReportFileName

# Send Email 
$bodyreport = Get-Content "$ReportFileName" -Raw
Send-MailMessage	-To		$EmailTo `
		 	-Subject 	$EmailSubject `
			-From 		$EmailFrom `
			-SmtpServer 	$SMTPServer `
			-bodyashtml	-body $bodyreport