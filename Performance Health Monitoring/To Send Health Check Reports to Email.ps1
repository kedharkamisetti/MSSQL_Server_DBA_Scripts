<#*Remove all files in mentioned floder
Remove-Item -Path "C:\HealthcheckReports\*" -Force

#Remove all html files in mentioned floder
Remove-Item -Path "C:\HealthcheckReports\*.html" -Force

#Remove all html files in mentioned floder which are 2 days old--You can adjust as per requirement.
$limit = (Get-Date).AddDays(-2)
Get-ChildItem -Path "C:\HealthcheckReports" -File -Filter *.html | Where-Object { $_.CreationTime -lt $limit } | Remove-Item -Force
#>
# Send all attachments in single email.

# Define the email parameters
$EmailFrom = "xxxxxxx@gmail.com"
$EmailTo = @("xxxxxxx@gmail.com")  # Add multiple recipients here
$Subject = "SQL Server Health Check Report"
$Body = "Please find attached the SQL Server Health Check Report."
$SMTPServer = "smtp.gmail.com"
$SMTPClient = New-Object Net.Mail.SmtpClient($SMTPServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("xxxxxxx@gmail.com", "xxxxxxx")

# Specify the directory containing the HTML reports
$reportDirectory = "C:\HealthcheckReports"

# Get all HTML files in the specified directory
$reportFiles = Get-ChildItem -Path $reportDirectory -Filter *.html

# Loop through each recipient and send an email
foreach ($recipient in $EmailTo) {
    # Construct the email message with attachments
    $mailMessage = New-Object system.net.mail.mailmessage
    $mailMessage.From = $EmailFrom
    $mailMessage.To.Add($recipient)
    $mailMessage.Subject = $Subject
    $mailMessage.Body = $Body

    foreach ($file in $reportFiles) {
        $attachment = New-Object System.Net.Mail.Attachment($file.FullName)
        $mailMessage.Attachments.Add($attachment)
    }

    # Send the email
    $SMTPClient.Send($mailMessage)

    # Clean up attachments and message object
    foreach ($attachment in $mailMessage.Attachments) {
        $attachment.Dispose()
    }
    $mailMessage.Dispose()

    Write-Host "Email sent successfully to $recipient with all attachments."
}

Write-Host "All emails sent successfully."
