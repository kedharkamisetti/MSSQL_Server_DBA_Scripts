--create a master key
create master key encryption by password = 'complexpassword'

--create a backup certificate
create certificate certificatename with subject = 'certificateinfo'

--backup certificate and key
backup certificate certificatename to file = 'path\filename.cer'
with private key (file = 'path\filename.key', encryption by password = 'complexpassword')

--backup database
backup database database name to disk = 'path\filename.bak'
with encryption (algorithm = aes_256, server certificate = certificatename)