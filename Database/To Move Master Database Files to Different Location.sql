--identify where the master database files are located
select file_id, name, physical_name
from master.sys.database_files
--or
select name, physical_name as currentlocation, state_desc
from sys.master_files
where database_id = db_id('master')

--now go to sql server configuration manager to update the startup parameters
--update the startup parameters (-d is for mdf and -l is for ldf)
--now stop the sql server services to move the files to a new location
--finally start the services