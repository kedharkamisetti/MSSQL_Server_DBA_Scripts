select 'alter database ' +name+ ' set offline with rollback immediate' from sys.databases
where name not in ('master','model','msdb','tempdb','distribution')