SELECT 
    j.name AS 'JobName',
    js.step_name AS 'StepName',
    msdb.dbo.agent_datetime(h.run_date, h.run_time) AS 'RunDateTime',
    h.run_duration,
    ((h.run_duration/10000*3600 + (h.run_duration/100)%100*60 + h.run_duration%100 + 31) / 60) AS 'RunDurationMinutes',
    CASE 
        WHEN h.run_status = 0 THEN 'Failed'
        WHEN h.run_status = 1 THEN 'Succeeded'
        WHEN h.run_status = 2 THEN 'Retry'
        WHEN h.run_status = 3 THEN 'Cancelled'
        WHEN h.run_status = 4 THEN 'In Progress'
        ELSE 'Unknown'
    END AS 'Status',
    h.message AS 'Message'
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
INNER JOIN msdb.dbo.sysjobsteps js ON h.job_id = js.job_id AND h.step_id = js.step_id
WHERE j.enabled = 1  -- Only Enabled Jobs
	--and j.name = 'DatabaseBackup - USER_DATABASES - FULL' --Uncomment to search for a single job
    AND msdb.dbo.agent_datetime(h.run_date, h.run_time) >= DATEADD(HOUR, -1, GETDATE())
	--and msdb.dbo.agent_datetime(run_date, run_time) BETWEEN '12/08/2012' and '12/10/2012'  --Uncomment for date range queries
	 AND h.run_status = 0 -- Filter for what type of jobs u need
	  AND j.name NOT LIKE '%distribution%' -- Exclude jobs related to distribution
    AND j.name NOT LIKE '%Replication%' -- Exclude jobs related to replication
ORDER BY JobName, RunDateTime DESC