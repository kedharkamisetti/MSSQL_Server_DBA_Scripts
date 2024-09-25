DECLARE @NonSaJobs TABLE (
    JobName NVARCHAR(128),
    JobOwner NVARCHAR(128)
);

INSERT INTO @NonSaJobs (JobName, JobOwner)
SELECT name AS JobName, suser_sname(owner_sid) AS JobOwner
FROM msdb.dbo.sysjobs
WHERE suser_sname(owner_sid) <> 'sa';

Declare @subject Varchar(200)
Set @subject = 'SQL Server Job Owner Alert Of' +  @@SERVERNAME

IF EXISTS (SELECT 1 FROM @NonSaJobs)
BEGIN
    DECLARE @JobList NVARCHAR(MAX) = '';

    SELECT @JobList = @JobList + 
                      '<tr><td>' + JobName + '</td><td>' + JobOwner + '</td></tr>'
    FROM @NonSaJobs;

    DECLARE @body NVARCHAR(MAX);
    SET @body = '<html>' +
                '<head>' +
                '<style>' +
                'table {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse; font-size: 12px; width: auto;}' +
                'th {border-width: 1px; padding: 2px; border-style: solid; border-color: black; background-color: Pink; font-size: 12px; white-space: nowrap;}' +
                'td {border-width: 1px; padding: 2px; border-style: solid; border-color: black; font-size: 12px; white-space: nowrap;}' +
                'h1 {font-size: 16px;}' +
                '</style>' +
                '</head>' +
                '<body>' +
                '<p>The following Jobs are Not Owned by sa:</p>' +
                '<table>' +
                '<tr><th>Job Name</th><th>Job Owner</th></tr>' +
                @JobList +
                '</table>' +
                '</body>' +
                '</html>';

    -- Send alert email
    EXEC msdb.dbo.sp_send_dbmail
        @profile_name = 'outlook', -- Change to your Database Mail profile name
        @recipients = 'musi@gmail.com', -- Change to your alert email address
        @subject = @subject,
        @body = @body,
        @body_format = 'HTML'; -- Specify that the body is HTML
END;