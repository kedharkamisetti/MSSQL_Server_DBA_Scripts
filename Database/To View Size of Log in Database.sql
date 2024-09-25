SELECT [database_transaction_log_bytes_used]
FROM sys.dm_tran_database_transactions
WHERE [database_id] = DB_ID (N'databasename');
GO