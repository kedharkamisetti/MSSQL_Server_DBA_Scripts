declare @databasename nvarchar(255)
declare @alldatabases cursor

-- Only select principal databases (mirroring_role).
set @alldatabases = cursor for 
        select d.name
        from sys.databases d, sys.database_mirroring m
        where m.database_id = d.database_id
        and m.mirroring_role_desc = 'PRINCIPAL'

-- Execute the failover.
open @alldatabases
fetch next from @alldatabases into @databasename
while @@FETCH_STATUS = 0
begin
        print @databasename
        exec('alter database [' + @databasename + '] set partner failover')
        fetch next from @alldatabases into @databasename
end
close @alldatabases
deallocate @alldatabases