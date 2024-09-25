checkpoint
--or
checkpoint durationinseconds
--this means how long we want to run it.

--Checkpoint types: automatic, manual, internal, indirect

--note: by default it will run every 60 sec (Recovery Interval @ Instace Level)
--the following all are internal checkpoints:
--or whenever we run backup
--or whenever we run alter
--or whenever shutdown the sql server
--or whenever cluster failover
--or whenever snapshot is created
--or in simple recovery model, if log file is 70% full