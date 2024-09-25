--Verify the reason of failure in the error logs and troubleshoot accordingly. If database is really corrupt then look out for a available valid backup. If backup is available restore MSDB as a normal user database and it would be restored.
RESTORE DATABASE [msdb] FROM
DISK='C:\OurBackups\MSDB.bak'
WITH REPLACE

--if backup is not available then go to binn\template folder and copy the msdb files and paste them in the data folder.
--in this case we have lost jobs, plans, automation related stuff and so on.