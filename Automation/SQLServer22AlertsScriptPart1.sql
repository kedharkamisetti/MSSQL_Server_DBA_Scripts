USE [msdb]
GO

/****** Object:  Alert [Blocking >15Min Alert]    Script Date: 9/24/2024 10:20:59 PM ******/
EXEC msdb.dbo.sp_add_alert @name=N'Blocking >15Min Alert', 
		@message_id=0, 
		@severity=0, 
		@enabled=0, 
		@delay_between_responses=900, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'Locks|Average Wait Time (ms)|_Total|>|900000', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

/****** Object:  Alert [Buffer Cache <80% Alert]    Script Date: 9/24/2024 10:20:59 PM ******/
EXEC msdb.dbo.sp_add_alert @name=N'Buffer Cache <80% Alert', 
		@message_id=0, 
		@severity=0, 
		@enabled=0, 
		@delay_between_responses=900, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'Buffer Manager|Buffer cache hit ratio||<|0.8', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

/****** Object:  Alert [Connections >80% Alert]    Script Date: 9/24/2024 10:20:59 PM ******/
EXEC msdb.dbo.sp_add_alert @name=N'Connections >80% Alert', 
		@message_id=0, 
		@severity=0, 
		@enabled=0, 
		@delay_between_responses=900, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'General Statistics|User Connections||>|160', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

/****** Object:  Alert [CPU >80% Alert]    Script Date: 9/24/2024 10:20:59 PM ******/
EXEC msdb.dbo.sp_add_alert @name=N'CPU >80% Alert', 
		@message_id=0, 
		@severity=0, 
		@enabled=0, 
		@delay_between_responses=900, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'Resource Pool Stats|CPU usage target %|internal|>|0.8', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

/****** Object:  Alert [Data File >80% Alert]    Script Date: 9/24/2024 10:20:59 PM ******/
EXEC msdb.dbo.sp_add_alert @name=N'Data File >80% Alert', 
		@message_id=0, 
		@severity=0, 
		@enabled=0, 
		@delay_between_responses=900, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'Databases|Data File(s) Size (KB)|_Total|>|80', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

/****** Object:  Alert [Deadlock Alert]    Script Date: 9/24/2024 10:20:59 PM ******/
EXEC msdb.dbo.sp_add_alert @name=N'Deadlock Alert', 
		@message_id=0, 
		@severity=0, 
		@enabled=0, 
		@delay_between_responses=900, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'Locks|Number of Deadlocks/sec|_Total|>|0', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

/****** Object:  Alert [IO Read 20ms Alert]    Script Date: 9/24/2024 10:20:59 PM ******/
EXEC msdb.dbo.sp_add_alert @name=N'IO Read 20ms Alert', 
		@message_id=0, 
		@severity=0, 
		@enabled=0, 
		@delay_between_responses=900, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'Resource Pool Stats|Avg Disk Read IO (ms)|default|>|20', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

/****** Object:  Alert [IO Write 20ms Alert]    Script Date: 9/24/2024 10:20:59 PM ******/
EXEC msdb.dbo.sp_add_alert @name=N'IO Write 20ms Alert', 
		@message_id=0, 
		@severity=0, 
		@enabled=0, 
		@delay_between_responses=900, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'Resource Pool Stats|Avg Disk Write IO (ms)|default|>|20', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

/****** Object:  Alert [Log File >80% Alert]    Script Date: 9/24/2024 10:20:59 PM ******/
EXEC msdb.dbo.sp_add_alert @name=N'Log File >80% Alert', 
		@message_id=0, 
		@severity=0, 
		@enabled=0, 
		@delay_between_responses=900, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'Databases|Log File(s) Used Size (KB)|_Total|>|80', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

/****** Object:  Alert [Memory >80% Alert]    Script Date: 9/24/2024 10:20:59 PM ******/
EXEC msdb.dbo.sp_add_alert @name=N'Memory >80% Alert', 
		@message_id=0, 
		@severity=0, 
		@enabled=0, 
		@delay_between_responses=900, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'Memory Manager|Target Server Memory (KB)||>|0.8', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

/****** Object:  Alert [PLE <3000 Alert]    Script Date: 9/24/2024 10:20:59 PM ******/
EXEC msdb.dbo.sp_add_alert @name=N'PLE <3000 Alert', 
		@message_id=0, 
		@severity=0, 
		@enabled=0, 
		@delay_between_responses=900, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'Buffer Manager|Page life expectancy||<|3000', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

