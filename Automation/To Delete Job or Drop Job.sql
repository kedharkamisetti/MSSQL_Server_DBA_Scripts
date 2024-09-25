USE msdb ;  
GO  

EXEC sp_delete_job  
    @job_name = N'jobname' ;  
GO