DECLARE @NonSaDBs  TABLE (
    DBName NVARCHAR(128),
    DBOwner NVARCHAR(128)
);

INSERT INTO @NonSaDBs (DBName, DBOwner)
select Name,suser_sname(owner_sid) AS DbOwner from sys.databases 
WHERE suser_sname(owner_sid) <> 'sa'

Declare @subject Varchar(200)
Set @subject = 'SQL Server DB Owner Alert Of' +  @@SERVERNAME

IF EXISTS (SELECT 1 FROM @NonSaDBs)
BEGIN
    DECLARE @DBList NVARCHAR(MAX) = '';

    SELECT @DBList = @DBList + 
                      '<tr><td>' + DBName + '</td><td>' + DBOwner + '</td></tr>'
    FROM @NonSaDBs;

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
                '<p>The following Databases are Not Owned by sa:</p>' +
                '<table>' +
                '<tr><th>DB Name</th><th>Job Owner</th></tr>' +
                @DBList +
                '</table>' +
                '</body>' +
                '</html>';

    -- Send alert email
    EXEC msdb.dbo.sp_send_dbmail
        @profile_name = 'DBATEAM', -- Change to your Database Mail profile name
        @recipients = 'xxxxx@gmail.com', -- Change to your alert email address
        @subject = @subject,
        @body = @body,
        @body_format = 'HTML'; -- Specify that the body is HTML
END;