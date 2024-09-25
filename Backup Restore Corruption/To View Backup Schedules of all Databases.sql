USE msdb;
GO

SELECT 
    jobs.name AS JobName,
    jobs.description AS JobDescription,
    schedules.name AS ScheduleName,
    schedules.enabled AS ScheduleEnabled,
    schedules.freq_type AS FrequencyType,
    schedules.freq_interval AS FrequencyInterval,
    schedules.freq_subday_type AS FrequencySubdayType,
    schedules.freq_subday_interval AS FrequencySubdayInterval,
    schedules.active_start_date AS ActiveStartDate,
    schedules.active_end_date AS ActiveEndDate,
    schedules.active_start_time AS ActiveStartTime,
    schedules.active_end_time AS ActiveEndTime
FROM 
    dbo.sysjobs AS jobs
    INNER JOIN dbo.sysjobschedules AS jobSchedules ON jobs.job_id = jobSchedules.job_id
    INNER JOIN dbo.sysschedules AS schedules ON jobSchedules.schedule_id = schedules.schedule_id
WHERE 
    jobs.name LIKE '%Backup%'
ORDER BY 
    jobs.name;
