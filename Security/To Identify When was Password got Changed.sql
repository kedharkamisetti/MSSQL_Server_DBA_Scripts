SELECT name AS LoginName, modify_date AS LastPasswordChangeDate
FROM sys.sql_logins
WHERE name = 'YourLoginName'