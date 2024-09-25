USE [master]
GO

/****** Object:  StoredProcedure [dbo].[BlockingMonitor]    Script Date: 22-05-2023 04:48:32 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE proc [dbo].[BlockingMonitor]
(
@waittime bigint=1000, -- Period of time (in second) for search blocking processes
@Recipients varchar(2000), -- Recipient(s) of this email (; separated in case of multiple recipients).
@IsDBMailEnabled bit=1,
@MailProfile varchar(100) -- Mail profile name which exists on the target database server
)
as
begin

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

/* Drop/Create our temp tables */
If Object_Id('tempdb..#dbmail_profile') is not null
Drop Table #dbmail_profile;

Create Table #dbmail_profile (
profileid int NULL,
profilename varchar(125) NULL,
accountid int NULL,
accountname varchar(125) NULL,
sequencenumber int NULL )

If Object_Id('tempdb..#Blocking') is not null
Drop Table #Blocking

Create table #Blocking (
WaitInSeconds bigint NULL,
BlockingSessionId int NULL,
DatabaseName nvarchar(128) NULL,
BlockingUser nvarchar(128) NOT NULL,
BlockingLocation nvarchar(128) NULL,
BlockingSQL nvarchar(max) NULL,
BlockedSessionId smallint NOT NULL,
BlockedUser nvarchar(128) NOT NULL,
BlockedLocation nvarchar(128) NULL,
BlockedSQL nvarchar(max) NULL,
[Blocked Individual Query] nvarchar(max) NULL,
wait_type nvarchar(60) NULL,
programname nvarchar(120) NULL)

Declare
-- HTML Variables
@Body nvarchar(max), 
@TableTail varchar(100),
@TableHead varchar(max),

-- EMail Variables
@TableHTML varchar(MAX), -- HTML
@MailSubject varchar(100),
@Subject varchar (100) -- Subject line

/* Set some initial variables */ 

--Set @waittime = 1 -- In seconds the amount of time we want a task to wait prior to being eligible to be returned. 
Set @waittime = @waittime * 1000 -- Convert to miliseconds

/* Check sys.configurations to see if DB Mail has been turned on */
Select
@IsDBMailEnabled = CONVERT(INT, ISNULL(value, value_in_use)) 
From 
sys.configurations
Where 
name LIKE 'Database Mail XPs';
/* If DB Mail is not active, fail out of the process, otherwise proceed */
--If @IsDBMailEnabled = 0
-- Begin
--RAISERROR('Warning: Database mail is disabled. Database mail is required to send out alert', 12, 1)
-- End
--Else
-- Begin

/* Gather all of our information where the wait time exceeds the parameter value we supplied */ 
Insert Into #Blocking 
(WaitInSeconds, BlockingSessionId, DatabaseName, BlockingUser, BlockingLocation, BlockingSQL, 
BlockedSessionId, BlockedUser, BlockedLocation, BlockedSQL, [Blocked Individual Query], wait_type,programname) 
Select
Waits.wait_duration_ms / 1000 as WaitInSeconds, 
Blocking.session_id as BlockingSessionId,
DB_NAME(Blocked.database_id) as DatabaseName,
Sess.login_name as BlockingUser,
Sess.host_name as BlockingLocation,
BlockingSQL.text as BlockingSQL,
Blocked.session_id as BlockedSessionId,
BlockedSess.login_name as BlockedUser,
BlockedSess.host_name as BlockedLocation,
BlockedSQL.text as BlockedSQL,
SUBSTRING (BlockedSQL.text, -- String
(BlockedReq.statement_start_offset/2) + 1, -- Starting point
((CASE -- Length
WHEN BlockedReq.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), BlockedSQL.text)) * 2
ELSE BlockedReq.statement_end_offset
END - BlockedReq.statement_start_offset)/2) + 1) as [Blocked Individual Query],
Waits.wait_type,Sess.program_name
From
sys.dm_exec_connections Blocking
Join sys.dm_exec_requests Blocked ON (Blocking.session_id = Blocked.blocking_session_id)
Join sys.dm_exec_sessions Sess ON (Blocking.session_id = sess.session_id)
Left Outer Join sys.dm_tran_session_transactions st ON (Blocking.session_id = st.session_id)
Left Outer Join sys.dm_exec_requests er ON (st.session_id = er.session_id)
Join sys.dm_os_waiting_tasks Waits ON (Blocked.session_id = Waits.session_id) 
Join sys.dm_exec_requests BlockedReq ON (Waits.session_id = BlockedReq.session_id)
Join sys.dm_exec_sessions BlockedSess ON (Waits.session_id = BlockedSess.session_id)
Cross Apply sys.dm_exec_sql_text(Blocking.most_recent_sql_handle) AS BlockingSQL
Cross Apply sys.dm_exec_sql_text(Blocked.sql_handle) AS BlockedSQL
Where
Waits.wait_duration_ms / 1000 > 30  --Mentioned the time in seconds
Order By 
WaitInSeconds Desc;

/* If loaded any records in the previous step, proceed to generate the HTML and send an e-mail */ 
If Exists (Select 1 From #Blocking)
Begin

/*HTMLs generation - Head & Tail sections */
SET @TableTail = '</tbody></table>';
SET @TableHead = '<table>' +
'<tr>' +
'<td> <font style="font-family:Verdana; font-size:12pt; font-weight:bold; width:auto; float:left;"> '+@@servername+' </font> </td>' +
'<td> <font style="font-family:Verdana; font-size:12pt; width:auto; float:left; padding-left:5px; ">If Blocking is there for more than 15 minutes and If It is select command  Drop an email to client and if no response then please kill the spid to release the blocking. Do not wait for confirmation on this. Apart from this If Any Follow SOP”” </font> </td>' +
'</tr>' +
'</table>' +
'<br>' +
'<table style="border: 1px solid #000000; border-collapse:collapse; width=100%; table-layout:fixed; font-family:Verdana; font-size:12px;" cellpadding=0 cellspacing=0 border=0>' +
'<thead>' +
'<tr style=" font-family:Verdana; font-size:12px; background-color:#0066FF; color:white; height:30px;">' +
'<th style="width : 120; border: 1px solid #000000;" align=center>Wait Time HH:MM:SS</th>' +
'<th style="width : 50; border: 1px solid #000000;" align=center>Blocking Session Id</th>' +
'<th style="width : 120; border: 1px solid #000000;" align=center>Database Name</th>' +
'<th style="width : 100; border: 1px solid #000000;" align=center>Blocking User</th>' +
'<th style="width : 100; border: 1px solid #000000;" align=center>Blocking Location</th>' +
'<th style="min-width : 300; border: 1px solid #000000;" align=center>Blocking SQL</th>' + 
'<th style="width : 50; border: 1px solid #000000;" align=center>Blocked Session Id</th>' +
'<th style="width : 100; border: 1px solid #000000;" align=center>Blocked User</th>' +
'<th style="width : 100; border: 1px solid #000000;" align=center>Blocked Location</th>' +
'<th style="min-width : 300; border: 1px solid #000000;" align=center>Blocked SQL</th>' +
'<th style="min-width : 300; border: 1px solid #000000;" align=center>Blocked Individual Query</th>' +
'<th style="width : 200; border: 1px solid #000000;" align=center>Wait Type</th>' +
'<th style="width : 200; border: 1px solid #000000;" align=center>Program Name</th>' +
'</tr>' +
'</thead>' +
'<tbody style = "font-family:Verdana; font-size:12px">';

/* HTML generation - Body section */
Set @Body = 
(Select 
Case When ABS(ROW_NUMBER() Over(Order By WaitInSeconds Desc)) % 2 = 1 Then 'odd' Else 'even' END AS [td],
CONVERT(VARCHAR,DATEADD(ss,WaitInSeconds,0),108) AS [td],
BlockingSessionId AS [td],
DatabaseName AS [td],
BlockingUser AS [td],
BlockingLocation AS [td],
BlockingSQL AS [td],
BlockedSessionId AS [td],
BlockedUser AS [td],
BlockedLocation AS [td],
BlockedSQL AS [td],
[Blocked Individual Query] AS [td],
wait_type AS [td],
programname AS [td]
From 
#Blocking 
Order By
WaitInSeconds Desc
For xml raw('tr'), Elements);

/* In this section we are going to replace set the height property for the row, and for the even rows, change the background color so it stands out
Going to add a border the individual cells
In case there are longer entries in the blocked, blocking and blocked individual SQL columns we are going to insert a line break after each comma, otherwise, in Outlook, 
the HTML table will become malformed and become (almost) unreadable
Finally, we will assemble the head, body and tail into a single variable
*/ 
Set @Body = Replace(@Body, '<tr><td>odd</td>', '<tr style="height:20px;">');
Set @Body = Replace(@Body, '<tr><td>even</td>', '<tr style="background-color:#D8EBFF; height:20px;">') ;

Set @Body = Replace(@Body, '<td>', '<td style="border: 1px solid #000000;">');

Set @Body = Replace(@Body, ',', ', <br>');

Set @Body = @TableHead + @Body + @TableTail +'</BR><B>Thanks</BR>Your Company Name</B>'
/* In this section we will be assembling and sending the e-mail */

-- Set the subject
Select @MailSubject = CONVERT(VARCHAR(50),@@servername) + ' Blocked Processes Alert!';
/* Load the #dbmail_profile table */

Insert Into #dbmail_profile
Exec msdb.dbo.sysmail_help_profileaccount_sp;
/* Extact our mail profile */
if ((@MailProfile is null) or (@MailProfile=''))
begin
Select 
@MailProfile = @MailProfile
From 
#dbmail_profile
Where sequencenumber = 1;
end
print @Body
/* Send the e-mail */
EXEC msdb.dbo.sp_send_dbmail
@profile_name = @MailProfile,
@recipients = @Recipients,
@subject = @MailSubject,
@body = @Body,
@body_format = 'HTML';
END
END
SET NOCOUNT OFF
GO