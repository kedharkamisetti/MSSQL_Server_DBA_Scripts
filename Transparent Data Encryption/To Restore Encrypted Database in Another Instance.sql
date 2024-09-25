--first create a master key
use master
create master key encryption by password = 'complexpassword'

--then create a certificate using the backups of source certificate and key
create certificate newcertificatename
from file = 'path\filename.cer'
with private key (file = 'path\filename.key', decryption by password = 'samecomplexpasswordasinpreviousinstance')

--now you can restore the database from the backup normally