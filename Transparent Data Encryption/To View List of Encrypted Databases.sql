select * from sys.dm_database_encryption_keys
where encryption_state = 3;
go

--note: by default if we encrypt any database, tempdb will also get encrypted.