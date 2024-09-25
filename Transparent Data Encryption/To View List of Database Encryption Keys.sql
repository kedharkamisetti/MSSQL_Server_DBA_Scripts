select * from sys.dm_database_encryption_keys

--or

SELECT DB_NAME(database_id)
  ,encryption_state = CASE 
    WHEN encryption_state = 1
      THEN 'Unencrypted'
    WHEN encryption_state = 2
      THEN 'Encryption in progress'
    WHEN encryption_state = 3
      THEN 'Encrypted'
    WHEN encryption_state = 4
      THEN 'Key change in progress'
    WHEN encryption_state = 5
      THEN 'Decryption in progress'
    WHEN encryption_state = 6
      THEN 'Protection change in progress'
    WHEN encryption_state = 0
      THEN 'No database encryption key present, no encryption'
    END
  ,create_date
  ,encryptor_type
FROM sys.dm_database_encryption_keys