-- 1. Enable Database Mail feature if not already enabled
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
EXEC sp_configure 'Database Mail XPs', 1;
GO
RECONFIGURE;
GO


-- 2. Create a Database Mail account
EXEC msdb.dbo.sysmail_add_account_sp
    @account_name = 'YourMailAccountName',  -- Name for the mail account
    @description = 'Account for sending emails from SQL Server',
    @email_address = 'youremail@domain.com',  -- Your email address
    @display_name = 'SQL Server Database Mail',
    @mailserver_name = 'smtp.yourmailserver.com',  -- SMTP server
    @port = 587,  -- Port (587 for TLS, 25 for regular SMTP, 465 for SSL)
    @username = 'yourSMTPusername',  -- Your SMTP login
    @password = 'yourSMTPpassword',  -- Your SMTP password
    @enable_ssl = 1;  -- Enable SSL (1 for Yes, 0 for No)
GO


-- 3. Create a Database Mail profile
EXEC msdb.dbo.sysmail_add_profile_sp
    @profile_name = 'YourMailProfile',
    @description = 'Profile for sending emails from SQL Server';
GO


-- 4. Add the account to the profile
EXEC msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = 'YourMailProfile',
    @account_name = 'YourMailAccountName',
    @sequence_number = 1;
GO


-- 5. Test the Database Mail setup by sending a test email
EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'YourMailProfile',
    @recipients = 'recipient@domain.com',  -- Recipient's email
    @subject = 'Test Email',
    @body = 'This is a test email sent from SQL Server Database Mail.';
GO
