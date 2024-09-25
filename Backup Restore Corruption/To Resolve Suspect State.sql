--Steps to Resolve Suspect State:
--1--check the status of the database using 'databasepropertyex'
		--select databasepropertyex('databasename', 'status')
--2--try resetting the status using 'sp_resetstatus'
		--sp_resetstatus databasename
--3--try putting in 'emergency mode' and 'single user mode'
		--ALTER DATABASE databasename SET EMERGENCY
--4--then check the integrity with 'dbcc checkdb'
--5--if corruption found, check backup is available or not and then take action.

--Method1:
--Without detaching the database we can rebuild the log file. 
--First rename/delete the old log file and create a new one using command below.
ALTER DATABASE databasename
REBUILD LOG ON (NAME = logfilename, FILENAME='path\filename.LDF')

Alter database SuspectTest set multi_user


--Method2
--(Method works only when you have single log file)
--Put database into OFFLINE state and delete existing log file and bring it back to ONLINE state.
--OFFLINE to ONLINE rebuild process would not work if there are multiple log files.


--Method3
DBCC CHECKDB('databasename',REPAIR_ALLOW_DATA_LOSS)
--Risk involved with this method is all log files will be removed and one single log file is created during rebuild process.


--Method4
--(Method works even if you have multiple log files)
CREATE DATABASE [databasename] ON (FILENAME = 'path\filename.mdf')
FOR ATTACH_REBUILD_LOG


--Method5
--(Method works only when we have single log file)
EXEC sp_detach_db @dbname = 'DBSRC2';

EXEC sp_attach_single_file_db @dbname = 'DBSRC2',
@physname = N'path\filename.mdf';

CREATE DATABASE PageTest
ON PRIMARY (FILENAME = 'newpath\filename.mdf')
FOR ATTACH
GO
--This method works only when there is single log file


--Method6
--Perform Detach/Attach through GUI.