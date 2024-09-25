--modify the command accordingly
select 'ALTER DATABASE' + ' '+ name + ' '+'SET RECOVERY SIMPLE WITH NO_WAIT' from sys.databases where recovery_model_desc = 'FULL' and name not in ('model')