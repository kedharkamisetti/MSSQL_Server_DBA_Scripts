--run this query in all the machines to view the permissions
SELECT 'Identify Mirroring Endpoint Permissions';
SELECT EP.name, SP.STATE,
CONVERT(nvarchar(38), suser_name(SP.grantor_principal_id))
AS GRANTOR,
SP.TYPE AS PERMISSION,
CONVERT(nvarchar(46),suser_name(SP.grantee_principal_id))
AS GRANTEE
FROM sys.server_permissions SP , sys.endpoints EP
WHERE SP.major_id = EP.endpoint_id
ORDER BY Permission,grantor, grantee;
GO