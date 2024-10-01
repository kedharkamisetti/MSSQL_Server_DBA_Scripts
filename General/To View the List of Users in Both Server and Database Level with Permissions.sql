-- Script to get both database-level and server-level permissions along with roles
DECLARE @DatabaseName NVARCHAR(255)
DECLARE @SQL NVARCHAR(MAX) = ''

-- Cursor to loop through all databases
DECLARE db_cursor CURSOR FOR 
SELECT name 
FROM sys.databases 
WHERE state_desc = 'ONLINE' AND name NOT IN ('master', 'tempdb', 'model', 'msdb') -- Exclude system databases

OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @DatabaseName

-- Prepare dynamic SQL for database-level permissions
SET @SQL += '
SELECT ''Database'' AS Level, ''' + @DatabaseName + ''' AS DatabaseName, 
       dp.name AS UserName, dp.type_desc AS UserType, o.name AS ObjectName, 
       p.permission_name AS PermissionName, p.state_desc AS PermissionState, 
       STRING_AGG(dr.name, '','') AS Roles
FROM [' + @DatabaseName + '].sys.database_principals AS dp
LEFT JOIN [' + @DatabaseName + '].sys.database_permissions AS p 
ON dp.principal_id = p.grantee_principal_id
LEFT JOIN [' + @DatabaseName + '].sys.objects AS o 
ON p.major_id = o.object_id
LEFT JOIN [' + @DatabaseName + '].sys.database_role_members AS drm 
ON dp.principal_id = drm.member_principal_id
LEFT JOIN [' + @DatabaseName + '].sys.database_principals AS dr 
ON drm.role_principal_id = dr.principal_id
WHERE dp.type IN (''S'', ''U'', ''G'') 
GROUP BY dp.name, dp.type_desc, o.name, p.permission_name, p.state_desc
UNION ALL '

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL += '
    SELECT ''Database'' AS Level, ''' + @DatabaseName + ''' AS DatabaseName, 
           dp.name AS UserName, dp.type_desc AS UserType, o.name AS ObjectName, 
           p.permission_name AS PermissionName, p.state_desc AS PermissionState, 
           STRING_AGG(dr.name, '','') AS Roles
    FROM [' + @DatabaseName + '].sys.database_principals AS dp
    LEFT JOIN [' + @DatabaseName + '].sys.database_permissions AS p 
    ON dp.principal_id = p.grantee_principal_id
    LEFT JOIN [' + @DatabaseName + '].sys.objects AS o 
    ON p.major_id = o.object_id
    LEFT JOIN [' + @DatabaseName + '].sys.database_role_members AS drm 
    ON dp.principal_id = drm.member_principal_id
    LEFT JOIN [' + @DatabaseName + '].sys.database_principals AS dr 
    ON drm.role_principal_id = dr.principal_id
    WHERE dp.type IN (''S'', ''U'', ''G'') 
    GROUP BY dp.name, dp.type_desc, o.name, p.permission_name, p.state_desc
    UNION ALL '

    FETCH NEXT FROM db_cursor INTO @DatabaseName
END

CLOSE db_cursor
DEALLOCATE db_cursor

-- Remove the last UNION ALL and finalize the SQL for database-level permissions
SET @SQL = LEFT(@SQL, LEN(@SQL) - LEN(' UNION ALL '))

-- Add the server-level permissions query
SET @SQL += '
UNION ALL
SELECT ''Server'' AS Level, ''N/A'' AS DatabaseName, sp.name AS LoginName, 
       sp.type_desc AS LoginType, ''N/A'' AS ObjectName, p.permission_name AS PermissionName, 
       p.state_desc AS PermissionState, 
       STRING_AGG(sr.name, '','') AS Roles
FROM sys.server_principals AS sp
LEFT JOIN sys.server_permissions AS p ON sp.principal_id = p.grantee_principal_id
LEFT JOIN sys.server_role_members AS srm ON sp.principal_id = srm.member_principal_id
LEFT JOIN sys.server_principals AS sr ON srm.role_principal_id = sr.principal_id
WHERE sp.type IN (''S'', ''U'', ''G'')
GROUP BY sp.name, sp.type_desc, p.permission_name, p.state_desc'

-- Execute the combined SQL
EXEC sp_executesql @SQL
