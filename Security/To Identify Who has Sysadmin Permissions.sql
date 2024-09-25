USE master
GO
SELECT DISTINCT p.name AS [loginname] ,
p.type ,
p.type_desc ,
p.is_disabled,
s.sysadmin,
CONVERT(VARCHAR(10),p.create_date ,101) AS [created],
CONVERT(VARCHAR(10),p.modify_date , 101) AS [update]
FROM sys.server_principals p
JOIN sys.syslogins s ON p.sid = s.sid
JOIN sys.server_permissions sp ON p.principal_id = sp.grantee_principal_id
WHERE p.type_desc IN ('SQL_LOGIN', 'WINDOWS_LOGIN', 'WINDOWS_GROUP')
-- Logins that are not process logins
AND p.name NOT LIKE '##%'
-- Logins that are sysadmins or have GRANT CONTROL SERVER
AND (s.sysadmin = 1 OR sp.permission_name = 'CONTROL SERVER')
ORDER BY p.name
GO