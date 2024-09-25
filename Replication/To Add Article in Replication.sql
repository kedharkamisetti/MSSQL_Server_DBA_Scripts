--1. first add the table to the publication and then disable the settings
--settings to be diabled: 'allow_anonymous' and 'immediate_sync'

--to get the properties of a replication
use databasename
go
sp_helppublication 'replicationname'

--2. to disable the settings
exec sp_changepublication
@publication = 'replicationname',
@property = 'allow_anonymous',
@value = 'false'
go

exec sp_changepublication
@publication = 'replicationname',
@property = 'immediate_sync',
@value = 'false'
go

--3. now take a snapshot (through "view snapshot agent status")

--4. then turn the settings "on" again which we just diabled.
exec sp_changepublication
@publication = 'replicationname',
@property = 'allow_anonymous',
@value = 'true'
go

exec sp_changepublication
@publication = 'replicationname',
@property = 'immediate_sync',
@value = 'true'
go