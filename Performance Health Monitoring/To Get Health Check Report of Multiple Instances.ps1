    ###       MS SQL SERVER HEALTH CHECK 
    ### Make sure to select the appropriate database and path for the file to be saved.

    #param(
    #[string]$servernames
    #)
    #Add-PSSnapin SqlServerCmdletSnapin110
    #Add-PSSnapin SqlServerProviderSnapin110
    #cls
    #write-host $servernames
    $starttime = Get-Date
    # Format the date and time to remove invalid characters
    $formattedDate = $starttime.ToString("-yyyy-MM-dd_HH-mm-ss")
    #$servernames=Read-Host -Prompt "Please Enter the Server Name"
    #$servernames = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a computer name", "Computer", "$env:computername")
    $servernames = get-content -path "C:\HealthcheckReports\serverlist.txt"
    foreach($servername in $servernames)
    {
    #write-host Server $servernames
    write-host Starting Server $servername
    #exit;

    $dataSource  =  $servername
    ##setup data source

    $database = "master"                                 ##Database name
    #$TableHeader = "SQL Server Health Check Report"      ##The title of the HTML page
    $path = "c:\HealthcheckReports\"
    #$path = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    $name = $dataSource -replace "\\","_"
    $OutputFile_new = $path+'\' + $name + $formattedDate +'.html'             ##The file location 
        
    $a = "<style = 'Width:100%'>"
    $a = $a + "BODY{background-color: #e0e0e0; height: 100%; width: 100%;}"
    $a = $a + "TABLE{border-width: 1px;border: 2px solid black;}"
    $a = $a + "TH{border-width: 2px;padding: 5px;border: 2px solid black; }"
    $a = $a + "TD{border-width: 2px;padding: 5px;border: 2px solid black;}"
    $a = $a + "tr:nth-child(even){background-color: #f2f2f2}"
    $a = $a + "</style>"


    ## Modification import image into the report
    #$image = "$Path\images.png"
    #$ImageBits = [Convert]::ToBase64String((Get-Content $image -Encoding Byte))
    #$ImageHTML = "<img src=data:image/png;base64,$($ImageBits) alt='My Image'/>"
    ## Modification

    $colorTagTable = @{
                        Stopped = ' bgcolor="#f44336">Stopped<';
                        Running = ' bgcolor="#76ff03">Running<';
                        OFFLINE = ' bgcolor="#f44336">OFFLINE<';
                        "Critical" = ' bgcolor="#f44336">Criticl<';
                        "Warning" = ' bgcolor="YELLOW">Warning<';
                        "Good" = ' bgcolor="#76ff03">Good<';
                        "Bad" = ' bgcolor="#f44336">Bad<';
                          "ENabled" = ' bgcolor="#76ff03">Enabled<';
                        "Disabled" = ' bgcolor="#f44336">Disabled<';
                        ONLINE  = ' bgcolor="#76ff03">ONLINE<'
                        "ALL DATABASES ARE" = ' bgcolor="#76ff03">ALL DATABASES ARE<'
                        "ALL Databases has been" = ' 
                        bgcolor="76ff03">ALL Databases has been<';
                        "backup" = ' bgcolor="#76ff03">backup<';
                        "in Last 24 Hours" = ' bgcolor="#76ff03">in Last 24 Hours<';
                        "No Job Failed in Last 24 Hours" = ' 
                        bgcolor="#76ff03">No Job Failed in Last 24 Hours<';
                        "Error Log" = ' bgcolor="#76ff03">Error Log<';
                        "check did not find out anything major" = ' 
                        bgcolor="#76ff03">check did not find out anything major<';
                        "but will still advise to please verify manually" = ' 
                        bgcolor="#76ff03">but will still advise to please verify manually<';
                        "Server Might Have Memory Issue"  = 'bgcolor="#f44336">Server Might Have Memory Issue<';
                        "Server has no Memory Issue" =' bgcolor="#76ff03">Server has no Memory Issue<';
                        "in Last 24 Hours1" = ' bgcolor="#76ff03">in Last 24 Hours<';

                        ## Added comment to color the Disk space utilization
                        ## RED - #f44336
                        ## GREEN = 76ff03

                    

                       } 

    ##Create a string variable with all our connection details 
    $connectionDetails = "Provider=sqloledb; " + "Data Source=$dataSource; 
    " + "Initial Catalog=$database; " + "Integrated Security=SSPI;"


    ##**************************************
    ##Calculating SQL Server Information
    ##**************************************
    #$sql_server_info = "select @@servername as [SQLNetworkName], 
    #CAST( SERVERPROPERTY('MachineName') AS NVARCHAR(128)) AS [MachineName],
    #CAST( SERVERPROPERTY('ServerName')AS NVARCHAR(128)) AS [SQLServerName],
    #serverproperty('edition') as [Edition],
    #serverproperty('productlevel') as [Servicepack],
    #CAST( SERVERPROPERTY('InstanceName') AS NVARCHAR(128)) AS [InstanceName],
    #SERVERPROPERTY('Productversion') AS [ProductVersion],@@version as [Serverversion]"

    $sql_server_info = " 
    DECLARE @PortNum NVARCHAR(50)
    SET @PortNum = (SELECT MAX(CONVERT(VARCHAR(15),value_data)) FROM sys.dm_server_registry WHERE registry_key LIKE '%MSSQLServer\SuperSocketNetLib\Tcp\%' AND value_name LIKE N'%TcpPort%' AND CONVERT(float,value_data) > 0)
    
    select
    'ServerName' = serverproperty('computernamephysicalnetbios')
    ,'SQLNetworkName'= @@servername
    ,'MachineType' = case sdosi.virtual_machine_type when '1' then 'Virtual Machine' when '0' then 'Physical Machine' end 
    ,'InstanceName'=SERVERPROPERTY('InstanceName')
    ,'IsCluster'=serverproperty('IsClustered')
    ,'PortNumber'=@PortNum
    --,'Edition' = serverproperty('edition')
    --,'Build' = serverproperty('productlevel')
    --,'VersionNumber'    = serverproperty('productversion')
    --,'ServicePack'=serverproperty('productlevel')
    ,'ServerVersion'=@@version

    from
    sys.dm_os_sys_info sdosi;"

    ##Connect to the data source using the connection details and T-SQL command we provided above, 
    ##and open the connection
    $connection = New-Object System.Data.OleDb.OleDbConnection $connectionDetails
    $command1 = New-Object System.Data.OleDb.OleDbCommand $sql_server_info,$connection
    $connection.Open()

    ##Get the results of our command into a DataSet object, and close the connection
    $dataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter $command1
    $dataSet1 = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet1)
    $connection.Close()


    ##Return all of the rows and pipe it into the ConvertTo-HTML cmdlet, 
    ##and then pipe that into our output file
    $frag1 = $dataSet1.Tables | Select-Object -Expand Rows |select -Property ServerName,SQLNetworkName,
    MachineType,InstanceName,IsCluster,PortNumber,
    ServerVersion | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2 align="center">SQL Server Info</h2>'|Out-String


    #$Frag00 = ConvertTo-Html -Body $style -PreContent "$imageHTML" |Out-String


    write-host $frag1
    #write-host $frag00

    ##**************************************
    ##2. Lead Blocking session Starts
    ##**************************************
    $sql_server_info1 = "

    select loginame,spid,blocked,lastwaittype, dbid login_time,status,hostname,program_name,cmd
    from  master..sysprocesses a
    where  exists ( select b.*
    from master..sysprocesses b
    where b.blocked > 0 and
    b.blocked = a.spid ) and not
    exists ( select b.*
    from master..sysprocesses b
    where b.blocked > 0 and
    b.spid = a.spid ) 
    order by spid

    "

    ##Connect to the data source using the connection details and T-SQL command we provided above, 
    ##and open the connection
    $connection = New-Object System.Data.OleDb.OleDbConnection $connectionDetails
    $command16 = New-Object System.Data.OleDb.OleDbCommand $sql_server_info1,$connection
    $connection.Open()

    ##Get the results of our command into a DataSet object, and close the connection
    $dataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter $command16
    $dataSet16 = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet16)
    $connection.Close()

    $count= $dataSet16.length
    If ($count –gt 1) {
 
    $frag16 = $dataSet16.Tables | Select-Object -Expand Rows |select -Property LoginName,SPID,Blocked,LastWait_Type,DBID, LoginTime,Status,HostName,ProgrameName,Command| ConvertTo-HTML -AS Table -Fragment -PreContent '<h2> Lead Blocking session</h2>'|Out-String
     } else { 

    $frag16 =  ConvertTo-HTML -AS Table -Fragment -PreContent '<h2 style="background-color:#76ff03; height: 27px;width: 300px"> No Lead Blocking session</h2>'|Out-String
 
    }

    ##**************************************
    ##2. Lead Blocking session End
    ##**************************************



    ##**************************************
    ##Database Backup in Last 24 Hours
    ##**************************************
    $SQLServerDatabaseBackup = "
    SELECT  name AS DBName ,
            recovery_model_desc AS RecoveryModel ,
            state_desc AS DBStatus ,
            d AS 'LastFullBackup' ,
            i AS 'LastDiffBackup' ,
            l AS 'LastLogBackup'
    FROM    ( SELECT    db.name ,
                        db.state_desc ,
                        db.recovery_model_desc ,
                        type ,
                        backup_finish_date
              FROM      master.sys.databases db
                        LEFT OUTER JOIN msdb.dbo.backupset a ON a.database_name = db.name
            ) AS Sourcetable 
        PIVOT 
            ( MAX(backup_finish_date) FOR type IN ( D, I, L ) ) AS MostRecentBackup
    "
    $connection = New-Object System.Data.OleDb.OleDbConnection $connectionDetails
    $command5 = New-Object System.Data.OleDb.OleDbCommand $SQLServerDatabaseBackup,$connection
    $connection.Open()

    ##Get the results of our command into a DataSet object, and close the connection
    $dataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter $command5
    $dataSet5 = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet5)
    $connection.Close()

    $frag5 = $dataSet5.Tables | Select-Object -Expand Rows |select -property DBName,RecoveryModel,
    DBStatus,LastFullBackup,LastDiffBackup,LastLogBackup | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2>Last Avaliable DB Backup</h2>'|Out-String

    $colorTagTable.Keys | foreach { $frag5 = $frag5 -replace ">$_<",($colorTagTable.$_) }

    write-host $frag5


    ##**************************************
    ##SQL Server ErrorLog
    ##**************************************
    $SQLServerErrorlog = "
    declare @errorlogcount int
    IF EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE ID = OBJECT_ID(N'tempdb..#errorlog'))
    BEGIN
    DROP TABLE #errorlog
    END
    create table #errorlog(date_time datetime,processinfo varchar(123),Comments varchar(max))
    insert into #errorlog exec sp_readerrorlog

    select @errorlogcount = count(*) from #errorlog 
    where date_time > (CONVERT(datetime,getdate()) - 0.2)
    and Comments like '%fail%' 
    and Comments like '%error%'
    and processinfo not in ('Server','Logon')

    if(@errorlogcount >= 1)
    begin
    select date_time as Date,processinfo as ProcessInfo, Comments from #errorlog 
    where date_time > (CONVERT(datetime,getdate()) - 0.2)
    and Comments like '%fail%' 
    and Comments like '%error%'
    and processinfo not in ('Server','Logon')
    end
    else
    begin
    select 'Error Log' as Date, 'check did not find out anything major' 
    as ProcessInfo, 'but will still advise to please verify manually' as Comments
    end
    "

    $connection = New-Object System.Data.OleDb.OleDbConnection $connectionDetails
    $command6 = New-Object System.Data.OleDb.OleDbCommand $SQLServerErrorlog,$connection
    $connection.Open()

    ##Get the results of our command into a DataSet object, and close the connection
    $dataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter $command6
    $dataSet6 = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet6)
    $connection.Close()

    $frag6 = $dataSet6.Tables | Select-Object -Expand Rows|select -Property Date,processinfo,Comments | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2>SQLServer ErroLog Information</h2>'|Out-String

    $colorTagTable.Keys | foreach { $frag6 = $frag6 -replace ">$_<",($colorTagTable.$_) }

    write-host $frag6

    ##**************************************
    ##CPU information
    ##**************************************
    $SQLServerCPUInformation = "DECLARE @xp_msver TABLE (
    [idx] [int] NULL
    ,[c_name] [varchar](100) NULL
    ,[int_val] [float] NULL
    ,[c_val] [varchar](128) NULL
    )
 
INSERT INTO @xp_msver
EXEC ('[master]..[xp_msver]');;
 
WITH [ProcessorInfo]
AS (
    SELECT ([cpu_count] / [hyperthread_ratio]) AS [number_of_physical_cpus]
        ,CASE
            WHEN hyperthread_ratio = cpu_count
                THEN cpu_count
            ELSE (([cpu_count] - [hyperthread_ratio]) / ([cpu_count] / [hyperthread_ratio]))
            END AS [number_of_cores_per_cpu]
        ,CASE
            WHEN hyperthread_ratio = cpu_count
                THEN cpu_count
            ELSE ([cpu_count] / [hyperthread_ratio]) * (([cpu_count] - [hyperthread_ratio]) / ([cpu_count] / [hyperthread_ratio]))
            END AS [total_number_of_cores]
        ,[cpu_count] AS [number_of_virtual_cpus]
        ,(
            SELECT [c_val]
            FROM @xp_msver
            WHERE [c_name] = 'Platform'
            ) AS [cpu_category]
    FROM [sys].[dm_os_sys_info]
    )
SELECT [number_of_physical_cpus]
    ,[number_of_cores_per_cpu]
    ,[total_number_of_cores]
    ,[number_of_virtual_cpus]
    ,LTRIM(RIGHT([cpu_category], CHARINDEX('x', [cpu_category]) - 1)) AS [cpu_category]
FROM [ProcessorInfo]
    "

    $connection = New-Object System.Data.OleDb.OleDbConnection $connectionDetails
    $command7 = New-Object System.Data.OleDb.OleDbCommand $SQLServerCPUInformation,$connection
    $connection.Open()

    ##Get the results of our command into a DataSet object, and close the connection
    $dataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter $command7
    $dataSet7 = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet7)
    $connection.Close()

    $frag7 = $dataSet7.Tables | Select-Object -Expand Rows|select -Property number_of_physical_cpus,number_of_cores_per_cpu,
    total_number_of_cores,number_of_virtual_cpus,cpu_category | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2>CPU Information</h2>'|Out-String
    write-host $frag7

    ##**************************************
    ##SQL Server Memory Infomration
    ##**************************************

    ## 1. Memory Allocated to SQL Server

    $SQLServerMemoryAllocated = "DECLARE @Total as Float
    DECLARE @Target as Float
    DECLARE @Ratio as Float
    DECLARE @Min as Float
    DECLARE @Max as Float
    DECLARE @Page_File as Float
    DECLARE @Memory_Grant as Float

    SET @Total=(SELECT ROUND(((CAST([cntr_value] AS float )/1024)/1024),2)FROM sys.dm_os_performance_counters WHERE [object_name] LIKE '%Memory Manager%' AND [counter_name] = 'Total Server Memory (KB)')
    SET @Target=(SELECT ROUND(((CAST([cntr_value] AS float )/1024)/1024),2) FROM sys.dm_os_performance_counters WHERE [object_name] LIKE '%Memory Manager%' AND [counter_name] ='Target Server Memory (KB)')
    SET @Page_File=(SELECT [cntr_value] FROM sys.dm_os_performance_counters WHERE [object_name] LIKE '%%Buffer Manager%' AND [counter_name] like'%Page life%')
    SET @Memory_Grant=(SELECT [cntr_value]  FROM sys.dm_os_performance_counters WHERE [object_name] LIKE '%Memory Manager%' AND [counter_name] like '%Memory Grants Pending%')
    SET @Ratio=(SELECT ROUND(100.0 * ( SELECT CAST([cntr_value] AS FLOAT) FROM sys.dm_os_performance_counters WHERE [object_name] LIKE '%Memory Manager%' AND [counter_name] = 'Total Server Memory (KB)' ) / ( SELECT CAST([cntr_value] AS FLOAT) FROM sys.dm_os_performance_counters WHERE [object_name] LIKE '%Memory Manager%' AND [counter_name] = 'Target Server Memory (KB)') , 2))
    SET @Min =(SELECT CAST(value AS float )/1024 FROM sys.configurations WHERE name ='min server memory (MB)')
    SET @Max =(SELECT CAST(value AS float )/1024 FROM sys.configurations WHERE name ='max server memory (MB)')
    SET @Max =(SELECT CAST(value AS float )/1024 FROM sys.configurations WHERE name ='max server memory (MB)')

    SELECT @Page_File as [Pagelifeexpectancy],@Memory_Grant As [MemoryGrantsPending], @Min AS [MinServerMemory_GB], @Max AS [MaxServerMemory_GB], 
    @Total AS [TotalServerMemory_GB],@Target AS [TargetServerMemory_GB],ROUND(@Total/@Target,4)*100 AS [Ratio_Total_Target]

    "

    $connection = New-Object System.Data.OleDb.OleDbConnection $connectionDetails
    $command8 = New-Object System.Data.OleDb.OleDbCommand $SQLServerMemoryAllocated,$connection
    $connection.Open()

    ##Get the results of our command into a DataSet object, and close the connection
    $dataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter $command8
    $dataSet8 = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet8)
    $connection.Close()

    $frag8 = $dataSet8.Tables | Select-Object -Expand Rows|select -Property Pagelifeexpectancy,MemoryGrantsPending,MinServerMemory_GB,MaxServerMemory_GB,
    TotalServerMemory_GB,TargetServerMemory_GB,Ratio_Total_Target | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2 >Memory Allocated to SQL Server</h2>'|Out-String
    write-host $frag8


    #2. Top 10 Memory Consuing Objects

    #3.     
    $sqlservermemorypressuredetection = "declare @totalmemoryused bigint
declare @bufferpool_allocated bigint
declare @query2008r2_total nvarchar(max)
declare @query2012_total nvarchar(max)
declare @version nvarchar(128)

Set @query2008r2_total  = 'select SUM(pages_kb + virtual_memory_committed_kb + awe_allocated_kb) / 1024
from sys.dm_os_memory_clerks' 

set @query2012_total = 'select SUM(pages_kb + virtual_memory_committed_kb + awe_allocated_kb) / 1024
from sys.dm_os_memory_clerks'

select @version = cast(SERVERPROPERTY('Productversion') as nvarchar(128))

if (@version like '15%') -- SQL Server 2022 uses a major version of 15
begin
    select @totalmemoryused = SUM(pages_kb + virtual_memory_committed_kb + awe_allocated_kb) / 1024
    from sys.dm_os_memory_clerks
end
else
begin
    select @totalmemoryused = SUM(pages_kb + virtual_memory_committed_kb + awe_allocated_kb) / 1024
    from sys.dm_os_memory_clerks
end

select @bufferpool_allocated = cntr_value / 1024
from sys.dm_os_performance_counters
where counter_name = 'Target Server Memory (KB)'

if (@bufferpool_allocated > @totalmemoryused)
begin
    select 'Server has no Memory Issue' as Comments
end
else
begin
    select 'Server Might Have Memory Issue' as Comments
end
    "
    $connection = New-Object System.Data.OleDb.OleDbConnection $connectionDetails
    $command10 = New-Object System.Data.OleDb.OleDbCommand $sqlservermemorypressuredetection,$connection
    $connection.Open()

    ##Get the results of our command into a DataSet object, and close the connection
    $dataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter $command10
    $dataSet10 = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet10)
    $connection.Close()

    $frag10 = $dataSet10.Tables | Select-Object -Expand Rows |select -Property Comments | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2>Server Have Memory Pressure or Not</h2>'|Out-String

    $colorTagTable.Keys | foreach { $frag10 = $frag10 -replace ">$_<",($colorTagTable.$_) }

    write-host $frag10

    ##**************************************
    ##CPU Pressure
    ##**************************************

    ##**************************************
    ## CLUSTER CONFIGURATION
    ##**************************************
    $Cluster_Info = "
    declare @version int
    select @version = cast (SERVERPROPERTY ('IsClustered') as int)
    
        If (@version >=1)
       begin
     With ClusterActiveNode as
        (
            SELECT SERVERPROPERTY('ComputerNamePhysicalNetBIOS') as NodeName, Cast('Active' as varchar(10)) as Active
        ),
    ClusterNodes as
        (
            SELECT NodeName FROM sys.dm_os_cluster_nodes
        )
    Select b.nodename, isnull(active,'Passive') as NodeStatus from ClusterNodes as b left join ClusterActiveNode as a
    on a.NodeName = b.nodename
end

  else 
    begin
    Select 'NO WFCS' as nodename,
    'NO SQL Cluster Configured on this instance ' as NodeStatus
    end 
       "
       
    ##Connect to the data source using the connection details and T-SQL command we provided above, 
    ##and open the connection
    $connection = New-Object System.Data.OleDb.OleDbConnection $connectionDetails
    $command2 = New-Object System.Data.OleDb.OleDbCommand $Cluster_Info,$connection
    $connection.Open()

    ##Get the results of our command into a DataSet object, and close the connection
    $dataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter $command2
    $dataSet2 = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet2)
    $connection.Close()

    
   # $count= $dataSet2.length  

    #If ($count) {
 
    $frag2 = $dataSet2.Tables | Select-Object -Expand Rows |select -Property nodename,NodeStatus | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2> Cluster Configuration details</h2>'|Out-String
    #$frag2 = $dataSet2.Tables | Select-Object -Expand Rows | select -Property NodeName | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2>Cluster Nodes </h2>'|Out-String
        
    # } else { 

    #$frag2 =  ConvertTo-HTML -AS Table -Fragment -PreContent '<h2 style="background-color:#76ff03; height: 27px;width: 300px"> No Cluster COnfigured </h2>'|Out-String
 
    #}

    ##**************************************
    ##CLUSTER CONFIGURATION
    ##**************************************

    ##**************************************
    ##Check the HA
    ##**************************************

    $WaitTimePercentage = "
    declare @AG_Enable int ;
    declare @AG_Config int ;
    DECLARE @myvar int;
    DECLARE @enable int;
    Declare @mirroring_enable int
    set @mirroring_enable = (select top 1 mirroring_state from sys.database_mirroring where mirroring_state != 0)

    --- *****Check is it configure with AG******

    if(SERVERPROPERTY('IsHadrEnabled')= 1) begin
    set @enable ='1';
    select @Enable as HA, c.name, b.replica_server_name,a.role_desc, a.connected_state_desc, a.synchronization_health_desc,b.endpoint_url from sys.dm_hadr_availability_replica_states as a
    inner join sys.availability_replicas  as b on a.replica_id = b.replica_id
    inner join sys.availability_groups_cluster as c on b.group_id=c.group_id
    end

    --- ***** Check is it configure with Mirroring *****
    else if (@mirroring_enable !=0)
    begin 
    set @enable ='2';
     SELECT   @enable  as HA, db_name(sd.[database_id])              AS [DatabaseName]
              ,sd.mirroring_state                  AS [MirrorState]
              ,sd.mirroring_state_desc             AS [MirrorState] 
              ,sd.mirroring_partner_name           AS [PartnerName]
              ,sd.mirroring_role_desc              AS [MirrorRole]  
              ,sd.mirroring_safety_level_desc      AS [SafetyLevel]
              ,sd.mirroring_witness_name           AS [Witness]
              ,sd.mirroring_connection_timeout AS [Timeout(sec)]
		       FROM sys.database_mirroring AS sd
        WHERE mirroring_guid IS NOT null
        ORDER BY [DatabaseName];
	
    end
    --- ***** Stand alone instance *****
    else begin
    set @enable ='3'
    Select @enable  as HA;
    end
 
    "


    $connection = New-Object System.Data.OleDb.OleDbConnection $connectionDetails
    $command17 = New-Object System.Data.OleDb.OleDbCommand $WaitTimePercentage,$connection
    $connection.Open()

    ##Get the results of our command into a DataSet object, and close the connection
    $dataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter $command17
    $dataSet17 = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet17)
    $connection.Close()

    foreach ($Row in $dataSet17.Tables[0].Rows) { 
		    $HA =$($Row.HA)
    }
    if ($HA -eq 3){
    ## Stand Alone Server
    $frag17 = ConvertTo-HTML -AS Table -Fragment -PreContent '<h2 style="background-color:#76ff03; height: 27px;width: 500px"> Stand Alone instance . No HA were configure </h2>'|Out-String

    } elseif ($HA -eq 2){
    ## Databases were configure with Mirroring
    ##Write-Host "Mirror Server" 
    $frag17 = $dataSet17.Tables | Select-Object -Expand Rows |select -Property HA,DatabaseName,MirrorState,MirrorState1,PartnerName, MirrorRole,SafetyLevel,Witness,Timeoutsec  | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2>Databases were configure with Mirroring</h2>'|Out-String

    } elseif( $HA -eq 1) {
    ## Database were configure with Always ON
    ##Write-Host "AG Server" 

    $frag17 = $dataSet17.Tables | Select-Object -Expand Rows |select -Property HA,name,replica_server_name,role_desc,connected_state_desc, synchronization_health_desc,endpoint_url | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2>Databases were configure with HA</h2>'|Out-String
    }

    write-host $frag17


    ##**************************************
    ## Disk Space utilization
    ##**************************************
    $Disk_space = "
    SELECT DISTINCT 
		    volume_mount_point [DiskMountPoint], 
		    --file_system_type [File System Type], 
		    logical_volume_name as [LogicalDriveName], 
		    CONVERT(DECIMAL(18,2),total_bytes/1073741824.0) AS [TotalSizeGB], ---1GB = 1073741824 bytes
		    CONVERT(DECIMAL(18,2),available_bytes/1073741824.0) AS [AvailableSizeGB],  
		    CAST(CAST(available_bytes AS FLOAT)/ CAST(total_bytes AS FLOAT) AS DECIMAL(18,2)) * 100 AS [Perct_SpaceFree],
			     (case when CAST((CAST(available_bytes AS FLOAT)/ CAST(total_bytes AS FLOAT) * 100) as int) <= '15' then 'Critical'
                 when CAST((CAST(available_bytes AS FLOAT)/ CAST(total_bytes AS FLOAT)  * 100) as int) between '15' and '50' then 'Warning'
			     when CAST((CAST(available_bytes AS FLOAT)/ CAST(total_bytes AS FLOAT) * 100) as int) >= '50' then 'Good'
			     --else 'good'
                end)as Status		
				    FROM sys.master_files 
    CROSS APPLY sys.dm_os_volume_stats(database_id, file_id)
    "

    $connection = New-Object System.Data.OleDb.OleDbConnection $connectionDetails
    $command19 = New-Object System.Data.OleDb.OleDbCommand $Disk_space,$connection
    $connection.Open()

    ##Get the results of our command into a DataSet object, and close the connection
    $dataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter $command19
    $dataSet19 = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet19)
    $connection.Close()


    $frag19 = $dataSet19.Tables | Select-Object -Expand Rows | select -Property DiskMountPoint,LogicalDriveName,TotalSizeGB,AvailableSizeGB,Perct_SpaceFree,Status | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2>Disk Space Utilization </h2>'|Out-String

    $colorTagTable.Keys | foreach { $frag19 = $frag19 -replace ">$_<",($colorTagTable.$_) }

    write-host $frag19
   

    ############### CPU Utilization Status ######################
    $cpu_Var = "
    SET NOCOUNT ON
    DECLARE @ts_now bigint 
    DECLARE @enable Varchar (10);
    DECLARE @AvgCPUUtilization DECIMAL(10,2) 

    SELECT @ts_now = cpu_ticks/(cpu_ticks/ms_ticks) FROM sys.dm_os_sys_info

    -- load the CPU utilization in the past 10 minutes into the temp table, you can load them into a permanent table
    SELECT TOP(10) SQLProcessUtilization AS [SQLServerProcessCPUUtilization]
    ,SystemIdle AS [SystemIdleProcess]
    ,100 - SystemIdle - SQLProcessUtilization AS [OtherProcessCPU Utilization]
    ,DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [EventTime] 
    INTO #CPUUtilization
    FROM ( 
          SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 
                record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
                AS [SystemIdle], 
                record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 
                'int') 
                AS [SQLProcessUtilization], [timestamp] 
          FROM ( 
                SELECT [timestamp], CONVERT(xml, record) AS [record] 
                FROM sys.dm_os_ring_buffers 
                WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
                AND record LIKE '%<SystemHealth>%') AS x 
          ) AS y 
    ORDER BY record_id DESC


    -- check if the average CPU utilization was over 80% in the past 10 minutes
    SELECT @AvgCPUUtilization = AVG([SQLServerProcessCPUUtilization] + [OtherProcessCPU Utilization])
    FROM #CPUUtilization
    WHERE EventTime > DATEADD(MM, -10, GETDATE())

    IF @AvgCPUUtilization >= 80
    BEGIN
	    SELECT TOP(10)
		    CONVERT(VARCHAR(25),@AvgCPUUtilization) +'%' AS [AvgCPUUtilization]
		    , GETDATE() [Date and Time]
		    , r.cpu_time
		    , r.total_elapsed_time
		    , s.session_id
		    , s.login_name
		    , s.host_name
		    , DB_NAME(r.database_id) AS DatabaseName
	    --	, SUBSTRING (t.text,(r.statement_start_offset/2) + 1,
		    --((CASE WHEN r.statement_end_offset = -1
			    --THEN LEN(CONVERT(NVARCHAR(MAX), t.text)) * 2
			    --ELSE r.statement_end_offset
		    --END - r.statement_start_offset)/2) + 1) AS [IndividualQuery]
		    --, SUBSTRING(text, 1, 200) AS [ParentQuery]
		    , r.status
		    , r.start_time
		    , r.wait_type
		    , s.program_name
	    INTO #PossibleCPUUtilizationQueries		
	    FROM sys.dm_exec_sessions s
	    INNER JOIN sys.dm_exec_connections c ON s.session_id = c.session_id
	    INNER JOIN sys.dm_exec_requests r ON c.connection_id = r.connection_id
	    CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
	    WHERE s.session_id > 50
		    AND r.session_id != @@spid
	    order by r.cpu_time desc
	    set @enable ='Bad';
	    -- query the temp table, you can also send an email report to yourself or your development team
	    SELECT  @enable  as CPU_Info,*
	    FROM #PossibleCPUUtilizationQueries		
    END
    ELSE BEGIN
    set @enable ='Good';
    Select @enable  as CPU_Info
    END
    -- drop the temp tables
    IF OBJECT_ID('TEMPDB..#CPUUtilization') IS NOT NULL
    drop table #CPUUtilization

    IF OBJECT_ID('TEMPDB..#PossibleCPUUtilizationQueries') IS NOT NULL
    drop table #PossibleCPUUtilizationQueries
    "
    $connection = New-Object System.Data.OleDb.OleDbConnection $connectionDetails
    $command20 = New-Object System.Data.OleDb.OleDbCommand $cpu_Var,$connection
    $connection.Open()

    ##Get the results of our command into a DataSet object, and close the connection
    $dataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter $command20
    $dataSet20 = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet20)
    $connection.Close()

    foreach ($Row in $dataSet20.Tables[0].Rows) { 
		    $CPUH =$($Row.CPU_Info)
    }
    if ($CPUH -eq 'Good'){
    ## Stand Alone Server

    $frag20 = ConvertTo-HTML -AS Table -Fragment -PreContent '<h2 style="background-color:#76ff03; height: 27px;width: 200px">CPU Looks Good</h2>'|Out-String

    } elseif ($CPUH -eq 'Bad'){
    ## Databases were configure with Mirroring
    ##Write-Host "Mirror Server" 

    #$frag20 = ConvertTo-HTML -AS Table -Fragment -PreContent '<h2> CPU Utilization is Bad </h2>'|Out-String
    $frag20 = $dataSet20.Tables | Select-Object -Expand Rows |select -Property CPU_Info,AvgCPkUUtilization,Date_and_Time,cpu_time,
    total_elapsed_time,session_id,login_name,host_name,DatabaseName,status,start_time,wait_type,
    Program_name  | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2 style="color:red;">CPU Under Presure</h2>'|Out-String

    }

    $colorTagTable.Keys | foreach { $frag20 = $frag20 -replace ">$_<",($colorTagTable.$_) }

    write-host $frag20
    Write-Host $CPUH

    ############### CPU Utilization Status ######################


    ##**************************************
    ## Database Properties
    ##**************************************
    $Db_prop = "
   SELECT
sd.[Name] AS [DatabaseName]
--,sd.database_id [Database Id]
,suser_sname(sd.owner_sid) as 'Owner'
--,sd.state_desc [DatabaseState]
,mf.name as [FileLogicalName]
,case
when type_desc = 'LOG' then 'Log File'
when type_desc = 'ROWS' then 'Data File'
Else type_desc
end as [FileType]
,mf.physical_name [PhysicalLocation]
,sd.create_date [DatabaseCreation]
,sd.collation_name [Collationname]
,sd.user_access_desc [UserAccessType]
,sd.recovery_model_desc [DatabaseRecoveryModel]
,sd.is_encrypted as 'Encrypted'
,sd.compatibility_level as 'Compatibility'
,size_on_disk_bytes/ 1024 / 1024 as [FileSizeMB]
FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS fs
inner join sys.databases sd on fs.database_id=sd.database_id
JOIN sys.master_files AS mf ON mf.database_id = fs.database_id
AND mf.file_id = fs.file_id
ORDER BY sd.database_id

    "

    $connection = New-Object System.Data.OleDb.OleDbConnection $connectionDetails
    $command30 = New-Object System.Data.OleDb.OleDbCommand $Db_prop,$connection
    $connection.Open()

    ##Get the results of our command into a DataSet object, and close the connection
    $dataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter $command30
    $dataSet30 = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet30)
    $connection.Close()


    $frag30 = $dataSet30.Tables | Select-Object -Expand Rows | select -Property DatabaseName,Owner,FileLogicalName,FileType,PhysicalLocation,DatabaseCreation,CollationName,UserAccessType,DatabaseRecoveryModel,Encrypted,Compatibility,FileSizeMB  | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2>Database Properties </h2>'|Out-String

    #DatabaseName,Owner,Encrypted,Compatibility,FileLogicalName,FileType,PhysicalLocation,DatabaseCreation,CollationName,UserAccessType,DatabaseRecoveryModel,DatabaseState,FileSizeMB
    
    #DBName,Owner,Status,Encrypted,is_trustworthy_on,Compatibility,RecoveryModel,COLLATION_NAME

    $colorTagTable.Keys | foreach { $frag30 = $frag30 -replace ">$_<",($colorTagTable.$_) }

    write-host $frag30

    ##**************************************
    ## Database Properties
    ##**************************************
    
    ##**************************************
    ## Database Job Properties
    ##**************************************

    $Db_job = "
    select 
           S.name AS JobName,
	       l.name AS JobOwner,
           SS.name AS ScheduleName, 
           CASE WHEN S.enabled=1 THEN 'Enabled' 
               ELSE 'Disabled' 
          END [IsEnabled],                   
           CASE(SS.freq_type)
                WHEN 1  THEN 'Once'
                WHEN 4  THEN 'Daily'
                WHEN 8  THEN (case when (SS.freq_recurrence_factor > 1) then  'Every ' + convert(varchar(3),SS.freq_recurrence_factor) + ' Weeks'  else 'Weekly'  end)
                WHEN 16 THEN (case when (SS.freq_recurrence_factor > 1) then  'Every ' + convert(varchar(3),SS.freq_recurrence_factor) + ' Months' else 'Monthly' end)
                WHEN 32 THEN 'Every ' + convert(varchar(3),SS.freq_recurrence_factor) + ' Months' -- RELATIVE
                WHEN 64 THEN 'SQL Startup'
                WHEN 128 THEN 'SQL Idle'
                ELSE '??'
            END AS Frequency,  
           CASE
                WHEN (freq_type = 1)                       then 'One time only'
                WHEN (freq_type = 4 and freq_interval = 1) then 'Every Day'
                WHEN (freq_type = 4 and freq_interval > 1) then 'Every ' + convert(varchar(10),freq_interval) + ' Days'
                WHEN (freq_type = 8) then (select 'Weekly Schedule' = MIN(D1+ D2+D3+D4+D5+D6+D7 )
                                            from (select SS.schedule_id,
                                                            freq_interval, 
                                                            'D1' = CASE WHEN (freq_interval & 1  <> 0) then 'Sun ' ELSE '' END,
                                                            'D2' = CASE WHEN (freq_interval & 2  <> 0) then 'Mon '  ELSE '' END,
                                                            'D3' = CASE WHEN (freq_interval & 4  <> 0) then 'Tue '  ELSE '' END,
                                                            'D4' = CASE WHEN (freq_interval & 8  <> 0) then 'Wed '  ELSE '' END,
                                                        'D5' = CASE WHEN (freq_interval & 16 <> 0) then 'Thu '  ELSE '' END,
                                                            'D6' = CASE WHEN (freq_interval & 32 <> 0) then 'Fri '  ELSE '' END,
                                                            'D7' = CASE WHEN (freq_interval & 64 <> 0) then 'Sat '  ELSE '' END
                                                        from msdb..sysschedules ss
                                                    where freq_type = 8
                                                ) as F
                                            where schedule_id = SJ.schedule_id
                                        )
                WHEN (freq_type = 16) then 'Day ' + convert(varchar(2),freq_interval) 
                WHEN (freq_type = 32) then (select  freq_rel + WDAY 
                                            from (select SS.schedule_id,
                                                            'freq_rel' = CASE(freq_relative_interval)
                                                                        WHEN 1 then 'First'
                                                                        WHEN 2 then 'Second'
                                                                        WHEN 4 then 'Third'
                                                                        WHEN 8 then 'Fourth'
                                                                        WHEN 16 then 'Last'
                                                                        ELSE '??'
                                                                        END,
                                                        'WDAY'     = CASE (freq_interval)
                                                                        WHEN 1 then ' Sun'
                                                                        WHEN 2 then ' Mon'
                                                                        WHEN 3 then ' Tue'
                                                                        WHEN 4 then ' Wed'
                                                                        WHEN 5 then ' Thu'
                                                                        WHEN 6 then ' Fri'
                                                                        WHEN 7 then ' Sat'
                                                                        WHEN 8 then ' Day'
                                                                        WHEN 9 then ' Weekday'
                                                                        WHEN 10 then ' Weekend'
                                                                        ELSE '??'
                                                                        END
                                                    from msdb..sysschedules SS
                                                    where SS.freq_type = 32
                                                    ) as WS 
                                            where WS.schedule_id = SS.schedule_id
                                            ) 
            END AS Interval,
            CASE (freq_subday_type)
                WHEN 1 then   left(stuff((stuff((replicate('0', 6 - len(active_start_time)))+ convert(varchar(6),active_start_time),3,0,':')),6,0,':'),8)
                WHEN 2 then 'Every ' + convert(varchar(10),freq_subday_interval) + ' seconds'
                WHEN 4 then 'Every ' + convert(varchar(10),freq_subday_interval) + ' minutes'
                WHEN 8 then 'Every ' + convert(varchar(10),freq_subday_interval) + ' hours'
                ELSE '??'
            END AS [Time],
            CASE SJ.next_run_date
                WHEN 0 THEN cast('n/a' as char(10))
                ELSE convert(char(10), convert(datetime, convert(char(8),SJ.next_run_date)),120)  + ' ' + left(stuff((stuff((replicate('0', 6 - len(next_run_time)))+ convert(varchar(6),next_run_time),3,0,':')),6,0,':'),8)
            END AS NextRunTime,
            LastRunOutcome = CASE (select top 1 jbh.run_status from msdb..sysjobhistory jbh where jbh.step_id = 0 and jbh.job_id = s.job_id order by run_date desc) 
            when 0 then 'Failed' 
            when 1 then 'Succeeded' 
            when 2 then 'Retry' 
            when 3 then 'Canceled' 
            when 4 then 'In Progress' 
            else '' 
            end
    from msdb.dbo.sysjobs S
    left join msdb.dbo.sysjobschedules SJ on S.job_id = SJ.job_id  
    left join msdb.dbo.sysschedules SS on SS.schedule_id = SJ.schedule_id
    LEFT JOIN master.sys.syslogins l ON s.owner_sid = l.sid
    order by S.name
    "

    $connection = New-Object System.Data.OleDb.OleDbConnection $connectionDetails
    $command31 = New-Object System.Data.OleDb.OleDbCommand $Db_job,$connection
    $connection.Open()

    ##Get the results of our command into a DataSet object, and close the connection
    $dataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter $command31
    $dataSet31 = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet31)
    $connection.Close()


    $frag31 = $dataSet31.Tables | Select-Object -Expand Rows | select -Property JobName,IsEnabled,JobOwner,ScheduleName,Frequency,Interval,Time.NextRunTime,LastRunOutcome | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2>Database Job Properties </h2>'|Out-String

    $colorTagTable.Keys | foreach { $frag31 = $frag31 -replace ">$_<",($colorTagTable.$_) }

    write-host $frag31

    ##**************************************
    ## Database Job Properties
    ##**************************************


    ##**************************************
    ## Database SP_CONFIG
    ##**************************************

    $sp_config = "exec SP_Configure"

    $connection = New-Object System.Data.OleDb.OleDbConnection $connectionDetails
    $command32 = New-Object System.Data.OleDb.OleDbCommand $sp_config,$connection
    $connection.Open()

    ##Get the results of our command into a DataSet object, and close the connection
    $dataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter $command32
    $dataSet32 = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet32)
    $connection.Close()


    $frag32 = $dataSet32.Tables | Select-Object -Expand Rows | select -Property name,minimum,maximum,config_value,run_value | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2>SP_CONFIG Properties </h2>'|Out-String

    $colorTagTable.Keys | foreach { $frag32 = $frag32 -replace ">$_<",($colorTagTable.$_) }

    write-host $frag32
    
    ##**************************************
    ## Database SP_CONFIG
    ##**************************************


    ##**************************************
    ## SQL Services Status
    ##**************************************

    $Db_Services = "
    SELECT DSS.servicename as ServiceName,
    DSS.startup_type_desc as StartUpType,
    DSS.status_desc as Status,
    DSS.last_startup_time as LastStartup,
    DSS.service_account as Account
    FROM sys.dm_server_services AS DSS;
    "


    $connection = New-Object System.Data.OleDb.OleDbConnection $connectionDetails
    $command33 = New-Object System.Data.OleDb.OleDbCommand $Db_Services,$connection
    $connection.Open()

    ##Get the results of our command into a DataSet object, and close the connection
    $dataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter $command33
    $dataSet33 = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet33)
    $connection.Close()


    $frag33 = $dataSet33.Tables | Select-Object -Expand Rows | select -Property ServiceName,StartUpType,Status,LastStartup,Account | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2>MSSQL Service Status </h2>'|Out-String

    $colorTagTable.Keys | foreach { $frag33 = $frag33 -replace ">$_<",($colorTagTable.$_) }

    write-host $frag33

    ##**************************************
    ## SQL Services Status
    ##**************************************

    ##**************************************
    ## Linked Server Details
    ##**************************************
    $linked_server = "
        SELECT a.server_id,a.name,a.product,a.provider,a.data_source,a.location,a.provider_string
        FROM sys.Servers a
        LEFT OUTER JOIN sys.linked_logins b ON b.server_id = a.server_id
        LEFT OUTER JOIN sys.server_principals c ON c.principal_id = b.local_principal_id
    "

    $connection = New-Object System.Data.OleDb.OleDbConnection $connectionDetails
    $command34 = New-Object System.Data.OleDb.OleDbCommand $linked_server,$connection
    $connection.Open()

    ##Get the results of our command into a DataSet object, and close the connection
    $dataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter $command34
    $dataSet34 = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet34)
    $connection.Close()


    $frag34 = $dataSet34.Tables | Select-Object -Expand Rows | select -Property server_id,name,product,provider,data_source,location,provider_string | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2> Linked Server Configuration </h2>'|Out-String

    #$colorTagTable.Keys | foreach { $frag34 = $frag34 -replace ">$_<",($colorTagTable.$_) }

    write-host $frag34

    ##**************************************
    ## Replication Server Details
    ##**************************************
    $Repl_server = "
       if db_id('Distribution') is not null
            BEGIN
                --SELECT 'database does exist'
                SELECT DISTINCT  
                srv.srvname publication_server  
                , a.publisher_db 
                , p.publication publication_name 
                , a.article 
                , a.destination_object 
                , ss.srvname subscription_server 
                , s.subscriber_db 
                , da.name AS distribution_agent_job_name 
                FROM Distribution..MSArticles a  
                JOIN Distribution..MSpublications p ON a.publication_id = p.publication_id 
                JOIN Distribution..MSsubscriptions s ON p.publication_id = s.publication_id 
                JOIN master..sysservers ss ON s.subscriber_id = ss.srvid 
                JOIN master..sysservers srv ON srv.srvid = p.publisher_id 
                JOIN Distribution..MSdistribution_agents da ON da.publisher_id = p.publisher_id  
                AND da.subscriber_id = s.subscriber_id 
                ORDER BY 1,2,3  
         END
        ELSE
            BEGIN
                select 'There Is No' as publication_server,
                'Distribution DB' as publisher_db,
                'It might dont have replciation' as publication_name,
                'Configuration' as article,
                '..' as destination_object,
                '..' as subscription_server,
                '..' as subscriber_db,
                '..' as distribution_agent_job_name
            END
    "

    

    $connection = New-Object System.Data.OleDb.OleDbConnection $connectionDetails
    $command3 = New-Object System.Data.OleDb.OleDbCommand $Repl_server,$connection
    $connection.Open()

    ##Get the results of our command into a DataSet object, and close the connection
    $dataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter $command3
    $dataSet3 = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet3)
    $connection.Close()
    


    $frag3 = $dataSet3.Tables | Select-Object -Expand Rows | select -Property publication_server,publisher_db,publication_name,article,destination_object,subscription_server,subscriber_db,distribution_agent_job_name | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2> Replication Configuration </h2>'|Out-String

    #$colorTagTable.Keys | foreach { $frag34 = $frag34 -replace ">$_<",($colorTagTable.$_) }

    write-host $frag3

    
    ##**************************************
    ## DB Mail Configuration
    ##**************************************

    $DB_Mail = "
    SELECT [sysmail_server].[account_id] AS [AccountID],
       [sysmail_account].[name] AS [AccountName],
       [servertype] AS [ServerType],
       [servername] AS [SMTPServesrAddress],
       [Port]
     FROM [msdb].[dbo].[sysmail_server]
     INNER JOIN [msdb].[dbo].[sysmail_account] ON [sysmail_server].[account_id] = [sysmail_account].[account_id];     
    "
    
    $connection = New-Object System.Data.OleDb.OleDbConnection $connectionDetails
    $command35 = New-Object System.Data.OleDb.OleDbCommand $DB_Mail,$connection
    $connection.Open()

    ##Get the results of our command into a DataSet object, and close the connection
    $dataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter $command35
    $dataSet35 = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet35)
    $connection.Close()


    $frag35 = $dataSet35.Tables | Select-Object -Expand Rows | select -Property AccountID,AccountName,ServerType,SMTPServesrAddress,Port | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2>Database Mail Configuration </h2>'|Out-String

    $colorTagTable.Keys | foreach { $frag35 = $frag35 -replace ">$_<",($colorTagTable.$_) }

    write-host $frag35

    ##**************************************
    ## DB Mail Configuration
    ##**************************************


    ##**************************************
    ##Final Code to Combine all fragments
    ##**************************************

    ConvertTo-HTML -head $a -PostContent $frag1,$frag33,$frag5,$frag2,$frag30,$frag19,$frag17,$frag31,$frag32,$frag16,$frag7,$frag20,$frag8,$frag10,$frag6,$frag35,$frag34,$frag3 -PreContent "<h1 align='Center'>SQL Server Heatlh Check Report</h1>" | Out-File $OutputFile_new

    $Stoptime = Get-Date
    Write-host $Stoptime

    }
    remove-variable starttime
    remove-variable servernames
    remove-variable servername
    remove-variable dataSource
    remove-variable database
    remove-variable path
    remove-variable name
    remove-variable OutputFile_new
    remove-variable a
    remove-variable colorTagTable
    remove-variable connectionDetails
    remove-variable connection
    remove-variable dataAdapter
    remove-variable sql_server_info
    remove-variable sql_server_info1
    remove-variable SQLServerDatabaseBackup
    remove-variable SQLServerErrorlog
    remove-variable SQLServerCPUInformation
    remove-variable SQLServerMemoryAllocated
    remove-variable sqlservermemorypressuredetection
    remove-variable WaitTimePercentage
    remove-variable Stoptime

    remove-variable dataSet1
    remove-variable dataSet5
    remove-variable dataSet6
    remove-variable dataSet7
    remove-variable dataSet8
    remove-variable dataSet10

    remove-variable command1
    remove-variable command5
    remove-variable command6
    remove-variable command7
    remove-variable command8
    remove-variable command10

    remove-variable frag1
    remove-variable frag5
    remove-variable frag6
    remove-variable frag7
    remove-variable frag8
    remove-variable frag10

    
    remove-variable Cluster_Info
    remove-variable frag2
    remove-variable command2
    remove-variable dataSet2
   
    remove-variable Repl_server
    remove-variable frag3
    remove-variable command3
    remove-variable dataSet3


    remove-variable frag16
    remove-variable command16
    remove-variable dataSet16

    remove-variable frag17
    remove-variable command17
    remove-variable dataSet17

    remove-variable frag19
    remove-variable command19
    remove-variable dataSet19

    remove-variable CPU_var
    remove-variable frag20
    remove-variable command20
    remove-variable dataSet20

    remove-variable Db_prop
    remove-variable frag30
    remove-variable command30
    remove-variable dataSet30

    remove-variable Db_job
    remove-variable frag31
    remove-variable command31
    remove-variable dataSet31

    remove-variable sp_config
    remove-variable frag32
    remove-variable command32
    remove-variable dataSet32

    remove-variable Db_Services
    remove-variable frag33
    remove-variable command33
    remove-variable dataSet33

     remove-variable linked_server
    remove-variable frag34
    remove-variable command34
    remove-variable dataSet34



    ##Powershell Code Ends##
