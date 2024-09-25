DECLARE @xml NVARCHAR(max)
DECLARE @body NVARCHAR(max)
-- specify long running query duration threshold
DECLARE @longrunningthreshold int
SET @longrunningthreshold = 1
-- step 1: collect long running query details.
;WITH cte AS (
    SELECT [Session_id] = spid,
           [Session_start_time] = (SELECT start_time FROM sys.dm_exec_requests WHERE spid = session_id),
           [Session_status] = LTRIM(RTRIM([status])),
           [Session_Duration] = DATEDIFF(mi, (SELECT start_time FROM sys.dm_exec_requests WHERE spid = session_id), GETDATE()),
           [Session_query] = SUBSTRING(st.text, (qs.stmt_start / 2) + 1, ((CASE qs.stmt_end WHEN -1 THEN DATALENGTH(st.text) ELSE qs.stmt_end END - qs.stmt_start) / 2) + 1)
    FROM sys.sysprocesses qs
    CROSS APPLY sys.dm_exec_sql_text(sql_handle) st
)
-- step 2: generate html table 
SELECT @xml = CAST((
    SELECT session_id AS 'td',
           '',
           session_duration AS 'td',
           '',
           session_status AS 'td',
           '',
           [session_query] AS 'td'
    FROM cte
    WHERE session_duration >= @longrunningthreshold 
    FOR XML PATH('tr'), ELEMENTS
) AS NVARCHAR(max))

-- step 3: do rest of html formatting
SET @body =
'<html>
<body>
    <h2 style="color: #333;">Long Running Queries (Limit &gt; 1 Minute)</h2>
    <table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse;">
        <tr>
            <th style="background-color: #ccc;">Session ID</th>
            <th style="background-color: #ccc;">Session Duration (Minutes)</th>
            <th style="background-color: #ccc;">Session Status</th>
            <th style="background-color: #ccc;">Session Query</th>
        </tr>'
SET @body = @body + @xml + '
    </table>
</body>
</html>'

-- step 4: send email if a long running query is found.
IF (@xml IS NOT NULL)
BEGIN
    EXEC msdb.dbo.sp_send_dbmail
        @profile_name = 'outlook',
        @body = @body,
        @body_format = 'HTML',
        @recipients = 'musicandra@gmail.com;',
        @subject = 'ALERT: Long Running Queries from LENOVO\SQLMARCH';
END