--Steps:
--1. Verify if Model is corrupt or not in Eventviewer and SQL Server Error Logs.
--2. Confirm if a valid database backup exists or not using restore verifyonly/headeronly.
--3. As instance isn't starting, rebuilding entire instance is correct answer but may not be a correct approach just for the sake of model database. Copy only the BINN\TEMPLATE model database files to DATA folder.

--This would start the instance. Once instance starts restore Model just as a user database.

--1. Restore the Model database from backup.
restore database model from disk=N'F:\Model.bak' WITH REPLACE