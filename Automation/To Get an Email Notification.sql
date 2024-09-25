--add this stored procedure as a new step in a job and setup
exec msdb.dbo.sp_send_dbmail
@profile_name = 'profilename'
@recipients = 'youremail'
@subject = 'notification for job success or failure'
@body = 'job succeded or failed'