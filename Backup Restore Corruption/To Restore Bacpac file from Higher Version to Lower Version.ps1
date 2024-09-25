--get the bacpac file
--install the bacpac data tier application
		--link = https://learn.microsoft.com/en-us/sql/tools/sqlpackage/sqlpackage-download?view=sql-server-ver16
--open powershell and go to the location where the application got installed
--execute the following command in powershell with appropriate names

\SqlPackage.exe /a:import /sf:path\filename.bacpac /tsn:machinename\instancename /tdn:databasename /TargetTrustServerCertificate:True