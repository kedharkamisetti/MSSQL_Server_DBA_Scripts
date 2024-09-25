--TEMPDB Data File Full:-
--1) Try to add more space if possible from any other drive

--2) Add file from another drive if possible.

--3) Perform a shrink operation if possible

--4) If tempdb is full, rather than taking any action identify the cause of the increase in size

select * from sys.sysprocesses where dbid=2
--(OR)
select * from sys.dm_exec_requests where database_id=2

DBCC INPUTBUFFER(SPID)
kill spid. Approval MANDATORY.

--5) Restart the instance.

-------------Temporary Remedy to move TEMPDB files to a new drive where there is more space available.
--6) Moving Tempdb files from one drive to another where there is ample space. This also requires restart of instance as the new files added will be in affect only after restarting the instance.
alter database Tempdb modify file(name='Tempdev',filename='Physical Path')
alter database Tempdb modify file(name='Templog',filename='Physical Path')




--TEMPDB Log File Full:
--1) Verify the size of log file currently
dbcc sqlperf(logspace)

--2) Perform Shrink operation on the log file of tempdb for any free space.

--3) Verify if Log File is awaiting any operation through

select name,log_reuse_wait_desc from sys.databases

--Verify the LOG_REUSE_WAIT_DESC and check the description of the WAIT. Multiple states are possible and respective action should be taken based on the state.

--4) Add another log file from different drive

--5) Find the transaction which is occupying maximum amount in Tempdb and kill that transaction upon approval

select * from sys.sysprocesses where dbid=2

--7) Strictly in SQL Server 2005 and lower versions
backup log Tempdb to disk=N'd:\Tempdb.trn' WITH TRUNCATE_ONLY

--8) Restart the instance