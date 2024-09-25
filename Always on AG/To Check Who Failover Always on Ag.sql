DECLARE @FileName NVARCHAR(4000)
SELECT @FileName = target_data.value('(EventFileTarget/File/@name)[1]','nvarchar(4000)')
FROM (
    SELECT CAST(target_data AS XML) target_data
    FROM sys.dm_xe_sessions s
    JOIN sys.dm_xe_session_targets t
    ON s.address = t.event_session_address
    WHERE s.name = N'AlwaysOn_health'
) ft

SELECT 
    XEData.value('(event/@timestamp)[1]','datetime2(3)') AS event_timestamp,
    XEData.value('(event/data[@name="availability_group_name"]/value)[1]', 'nvarchar(max)') AS availability_group_name,
    XEData.value('(event/data[@name="client_app_name"]/value)[1]', 'nvarchar(max)') AS client_app_name,
    XEData.value('(event/data[@name="client_hostname"]/value)[1]', 'nvarchar(max)') AS client_hostname,    
    XEData.value('(event/data[@name="client_hostname"]/value)[1]', 'nvarchar(255)') AS client_hostname,
    XEData.value('(event/data[@name="nt_username"]/value)[1]', 'nvarchar(255)') AS nt_username,
    XEData.value('(event/data[@name="statement"]/value)[1]', 'nvarchar(max)') AS statement
FROM (
    SELECT CAST(event_data AS XML) XEData, *
    FROM sys.fn_xe_file_target_read_file(@FileName, NULL, NULL, NULL)
    WHERE object_name = 'alwayson_ddl_executed'
) event_data