select 'Alter database' + ' ' + Name + ' '+'SET single_user with rollback immediate;' + char(13)+char(10)
+ 'Drop database' + ' ' + name  + char(13)+char(10)
from sys.databases where name Not in  ( 'master','msdb','tempdb','model','distribution')