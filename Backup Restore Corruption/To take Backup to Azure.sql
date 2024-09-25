--create credential
create credential credentialname
with identity = N'storageaccountname',
secret = N'accesskeytostorageaccount'

--backup database to storage account
backup database databasename
to url = N'containerurl/filename.bak'
with credential = 'credentialname'