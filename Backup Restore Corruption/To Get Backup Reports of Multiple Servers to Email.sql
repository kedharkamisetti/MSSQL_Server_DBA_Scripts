$ServerList = "C:\test\Serverlist.txt"
$OutputFile = "C:\test\Output.htm"

#If Smtp is having You can use the below code which is surronded by commenting.
## ## ## ## ## ## ## ## ## ## ## ## ## 
## $ServerList = "C:\DBA\Servers.csv"## 
## $OutputFile = "C:\DBA\Output.htm"## 
## $emlist="sqldbanow@gmail.com"    ## 
## $MailServer="smtp.sqldbanow.com" ## 
## ## ## ## ## ## ## ## ## ## ## ## ## 



$HTML = '<style type="text/css">
#Header {
    font-family:"Trebuchet MS", Arial, Helvetica, sans-serif;
    width:100%;
    border-collapse:collapse;
}
#Header td, #Header th {
    font-size:14px;
    border:1px solid #98bf21;
    padding:3px 7px 2px 7px;
}
#Header th {
    font-size:14px;
    text-align:left;
    padding-top:5px;
    padding-bottom:4px;
    background-color:#ADD8E6;
    color:#fff;
}
#Header tr.alt td {
    color:#000;
    background-color:#ADD8E6;
}
</style>'

$HTML += "<HTML><BODY><Table border=1 cellpadding=0 cellspacing=0 width=100% id=Header>
  <TR>
   <TH><B>Database Name</B></TH>
   <TH><B>Recovery Model</B></TH>
   <TH><B>Last Full Backup Date</B></TH>
   <TH><B>Last Differential Backup Date</B></TH>
   <TH><B>Last Log Backup Date</B></TH>
   </TR>"

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null
Import-CSV $ServerList | ForEach-Object {
    $ServerName = $_.ServerName
    $InstanceName = $_.InstanceName
    $AppName = $_.ApplicationName
    $HTML += "<TR bgColor='#ccff66'><TD colspan=5 align=center><strong>$ServerName - $InstanceName - $AppName</strong></TD></TR>"
    $SQLServer = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $ServerName 
    Foreach ($Database in $SQLServer.Databases) {
        $DaysSince = ((Get-Date) - $Database.LastBackupDate).Days
        $DaysSinceDiff = ((Get-Date) - $Database.LastDifferentialBackupDate).Days
        $DaysSinceLog = ((Get-Date) - $Database.LastLogBackupDate).Days

        if (($Database.Name) -ne 'tempdb' -and ($Database.Name) -ne 'model') {
            if ($Database.RecoveryModel -like "simple") {
                if ($DaysSince -gt 1) {
                    $HTML += "<TR>
                        <TD>$($Database.Name)</TD>
                        <TD>$($Database.RecoveryModel)</TD>
                        <TD bgcolor='FF0000'>$($Database.LastBackupDate)</TD>
                        <TD>$($Database.LastDifferentialBackupDate)</TD>
                        <TD>NA</TD>
                        </TR>"
                }
            }
            if ($Database.RecoveryModel -like "full") {
                if ($DaysSince -gt 1) {
                    $HTML += "<TR>
                        <TD>$($Database.Name)</TD>
                        <TD>$($Database.RecoveryModel)</TD>
                        <TD bgcolor='FF0000'>$($Database.LastBackupDate)</TD>
                        <TD>$($Database.LastDifferentialBackupDate)</TD>
                        <TD>$($Database.LastLogBackupDate)</TD>
                        </TR>"
                }
            }
            if ($DaysSince -lt 1) {
                $HTML += "<TR>
                    <TD>$($Database.Name)</TD>
                    <TD>$($Database.RecoveryModel)</TD>
                    <TD bgcolor='00FF00'>$($Database.LastBackupDate)</TD>
                    <TD>$($Database.LastDifferentialBackupDate)</TD>
                    <TD>$($Database.LastLogBackupDate)</TD>
                    </TR>"
            }
        }
    }
}

$HTML += "</Table></BODY></HTML>"
$HTML | Out-File $OutputFile


#If Smtp is working then u can uncomment the below code and fill required detail and remove the code and tested it properly and use.

#################################################################################################
#Function sendEmail  
#{ 
#param($from,$to,$subject,$smtphost,$htmlFileName)  

#$body = Get-Content $htmlFileName 
#$body = New-Object System.Net.Mail.MailMessage $from, "$to", $subject, $body 
#$body.isBodyhtml = $true
#$smtpServer = $MailServer
#$smtp = new-object Net.Mail.SmtpClient($smtpServer)
#$smtp.Send($body)

#}  

#$date = ( get-date ).ToString('MM/dd/yyyy')
#$emlist
#sendEmail sqldbanow@gmail.com $emlist "SQLDBANOW Test Server Backup Report for - $Date" $MailServer $OutputFile
#################################################################################################




$EmailFrom = "peddaredd@outlook.com"
$EmailTo = "musicandra@gmail.com"
$Subject = "Prod Servers Database Back up Reports  $(Get-Date -Format 'MM/dd/yyyy')"
$Body = "SQL Server Database Backup Reports"

$SMTPServer = "smtp.outlook.com"
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("Peddaredd@outlook.com", "Giveurpassword")

$mailMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject,$Body)
$attachmentPath = "C:\Test\Output.htm"
$attachment = New-Object System.Net.Mail.Attachment($attachmentPath)
$mailMessage.Attachments.Add($attachment)
$SMTPClient.Send($mailMessage)

