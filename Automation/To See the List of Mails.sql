--sent mails:
select * from msdb.dbo.sysmail_sentitems

--unsent mails:
select * from msdb.dbo.sysmail_unsentitems

--failed mails:
select * from msdb.dbo.sysmail_faileditems

--error messages returned by database mail:
select * from msdb.dbo.sysmail_event_log