SELECT 
    object_name, 
    counter_name, 
    instance_name, 
    cntr_value
FROM 
    sys.dm_os_performance_counters
WHERE 
    instance_name = '_Total' AND 
    (counter_name = 'Processor Queue Length' OR 
    counter_name = 'Batch Requests/sec');