--create a master key
use master
create master key encryption by password = 'complexpassword'

--create a certificate
create certificate certificatename with subject = 'certificateinfo'

--create a database encryption key
use databasename
create database encryption key
with algorithm = aes_256
encryption by server certificate certificatename

--backup the certificate and key
backup certificate certificatename
to file = 'path\filename.cer'
with private key (file = 'path\filename.key', encryption by password = 'complexpassword')

--to turn on encryption for a database
alter database databasename set encryption on