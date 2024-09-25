--1) Verify the space utilization of the log file
DBCC SQLPERF(logspace)

--2) Verify the recovery model of the database.
select recovery_model_desc from sys.databases where name='databasename'

--3) Verify if Log File is awaiting any operation through.
select name,log_reuse_wait_desc from sys.databases

--Verify the LOG_REUSE_WAIT_DESC and check the description of the WAIT. Multiple states are possible and respective action should be taken based on the state.

--Reuse of transaction log space is currently waiting on one of the following:
--0 = Nothing
--1 = Checkpoint 
--2 = Log Backup 
--3 = Active backup or restore
--4 = Active Transaction
--5 = Database Mirroring
--6 = Replication 
--7 = Database snapshot creation 
--8 = Log Scan
--9 = An Always On Availability Groups secondary replica is applying transaction log records of this database to a corresponding secondary database
--9 = Other (Transient)
--10 = For internal use only 
--11 = For internal use only 
--12 = For internal use only 
--13 = Oldest page 
--14 = Other 
--16 = XTP_CHECKPOINT (When a database uses a recovery model and has a memory-optimized data filegroup, you should expect to see the log_reuse_wait column indicate checkpoint or xtp_checkpoint)

--If Log Backup is the reason
--4) If in FULL/Bulk Logged recovery model, take log backup of the database.
--Once backup is complete, if required to release space then only perform shrink operation.

--Sometimes shrink doesn't completely clear the space in the log file. Then attempt taking log backup and performing shrink operation 2-3 times.

--If Active Transaction is the reason
--5) Identify what all transactions are running on the database.

select * from sys.sysprocesses where dbid=<int>
select * from sys.dm_exec_requests where database_id=<int> and session_id>50
(or) 
DBCC OPENTRAN

DBCC INPUTBUFFER(spid)

--Find out what the transactions are doing and whether COMMIT has been issued or not. On approval Kill the Sessions. Ask app team to commit.

--Inform application team to issue COMMIT for the uncommitted transactions.

--If AG/Replication/Mirroring are the reasons
--6) Whether AG/Replication/DB Mirroring are enabled or not. 
--Troubleshoot AG/Replication/DB Mirroring.

--In other cases (Special Cases)
--7) If space is a constraint in L: drive, add another log file from different drive which has ample space.
--Check if any log file truncation and shrink can be performed, it is always good to cleanup space in log file than adding new files.

--8) Change Recovery Model to Simple, then perform Shrink Operation. 
--If Log Shipping/Mirroring are enabled then disable them first and perform this operation.
--Condition: After changing recovery model from Full to Simple and again to Full. Take a FULL Backup.

--9) If SQL Server 2005, as last remedy we can try TRUNCATE_ONLY, this option has been removed from SQL Server 2008 onwards.

--SQL Server 2005:
backup log [DatabaseName] to disk='C:\Backups\DBName.trn' WITH TRUNCATE_ONLY

--In SQL Server 2008 if we have to perform TRUNCATE operation on Log file, it is not possible directly but there is an undocumented command (DO NOT TRY THIS UNLESS IT IS CRITICAL SITUATION)

BACKUP LOG [DatabaseName] TO DISK = 'nul:'

--Answer like this (Interviews - Special Case1):-
--If log file is full and there is no space to take log backup, then what will you do.
--1) Will try to take backup to another drive.
--2) Will try to take backup to network path.
--3) Perform cleanup and delete some older backups so that space can be created to take new backup.
--4) Will ask Windows team to add more space on the drive. If windows team allocates the space we can add one more log file in L: drive (or) take a log backup after providing space.
--5) Shrink the log files of other databases if there is a possibility.
--6) Change recovery model of the database to Simple, if allowed in your environment.
--7) Truncating the log file content using NUL Device.

--Answer like this (Interviews - Special Case2):-
--If simple recovery model, perform shrink operation.
--10)
--If shrink is unsuccesful then find the transactions that are holding the log file. Never attempt to take a log backup in Simple Recovery Model. Adding a file is possible, if space is available.

--Answer like this (Interviews - Special Case3):-
--Sometimes it is also possible that when log file is full and database is in Full Recovery model and when you check the reason it shows Replication. But replication was never configured on that database. Even if you try to take log backup, it will run but we cannot Shrink the log file? 

--------------------------------------------------------------------------------------------------------
--The Transaction log growth may occur because of the following reasons
--1. Uncommitted transactions
--2. Extremely large transactions
--3. Operations: DBCC DBREINDEX and CREATE INDEX
--4. While restoring from transaction log backups
--5. Client applications do not process all results
--6. Queries time out before a transaction log completes the expansion and you receive false "Log full" error message
--7. Un-replicated transactions
--------------------------------------------------------------------------------------------------------