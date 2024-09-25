USE MASTER
GO
BEGIN
DECLARE @SQLVerNo INT;
SET @SQLVerNo = cast(substring(CAST(Serverproperty('ProductVersion') AS VARCHAR(50)) ,0,charindex('.',CAST(Serverproperty('ProductVersion') AS VARCHAR(50)) ,0)) as int);

IF @SQLVerNo >= 9 
    IF EXISTS (SELECT TOP 1 *
               FROM Tempdb.sys.objects (nolock)
               WHERE name LIKE '#TUser%')
        DROP TABLE #TUser
ELSE
IF @SQLVerNo = 8
BEGIN
    IF EXISTS (SELECT TOP 1 *
               FROM Tempdb.dbo.sysobjects (nolock)
               WHERE name LIKE '#TUser%')
        DROP TABLE #TUser
END

CREATE TABLE #TUser (
    ServerName    varchar(256),
    DBName        SYSNAME,
    [Name]        SYSNAME,
    GroupName     SYSNAME NULL,
    LoginName     SYSNAME NULL,
    default_database_name  SYSNAME NULL,
    default_schema_name    VARCHAR(256) NULL,
    Principal_id  INT,
    [sid]         VARBINARY(85))

IF @SQLVerNo = 8
BEGIN
INSERT INTO #TUser
EXEC sp_MSForEachdb
'
 SELECT 
   @@SERVERNAME,
   ''?'' as DBName,
   u.name As UserName,
   CASE WHEN (r.uid IS NULL) THEN ''public'' ELSE r.name END AS GroupName,
   l.name AS LoginName,
   NULL AS Default_db_Name,
   NULL as default_Schema_name,
   u.uid,
   u.sid
 FROM [?].dbo.sysUsers u
   LEFT JOIN ([?].dbo.sysMembers m 
   JOIN [?].dbo.sysUsers r
   ON m.groupuid = r.uid)
   ON m.memberuid = u.uid
   LEFT JOIN dbo.sysLogins l
   ON u.sid = l.sid
 WHERE u.islogin = 1 OR u.isntname = 1 OR u.isntgroup = 1
   /*and u.name like ''tester''*/ ORDER BY u.name
'
END

ELSE 
IF @SQLVerNo >= 9
BEGIN
INSERT INTO #TUser
EXEC sp_MSForEachdb
'
 SELECT 
   @@SERVERNAME,
   ''?'',
   u.name,
   CASE WHEN (r.principal_id IS NULL) THEN ''public'' ELSE r.name END GroupName,
   l.name LoginName,
   l.default_database_name,
   u.default_schema_name,
   u.principal_id,
   u.sid
 FROM [?].sys.database_principals u
   LEFT JOIN ([?].sys.database_role_members m
   JOIN [?].sys.database_principals r 
   ON m.role_principal_id = r.principal_id)
   ON m.member_principal_id = u.principal_id
   LEFT JOIN [?].sys.server_principals l
   ON u.sid = l.sid
 WHERE u.TYPE <> ''R''
   /*and u.name like ''tester''*/ order by u.name
 '
END

SELECT *
FROM #TUser
ORDER BY DBName,
 [name],
 GroupName

DROP TABLE #TUser
END


/** end of script **/