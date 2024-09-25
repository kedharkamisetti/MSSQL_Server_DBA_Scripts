--encryption_state = 3 encrypted; =2 in progress

USE master
GO
SELECT db_name(database_id) [TDE Encrypted DB Name], c.name as CertName, encryptor_thumbprint , dek.*     FROM sys.dm_database_encryption_keys dek     INNER JOIN sys.certificates c on dek.encryptor_thumbprint = c.thumbprint