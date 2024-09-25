--1) Failed Logins option should be enabled for tracking error in the SQL Server Error logs.
--Review the error logs for 18456 and track the STATE of the error.
--Error 18456, Severity 14, State X
--X can vary from 1 to 65 (or even greater) value based on the error and situation.

--2) Verify if machine ping is happenning or not.
ping 10.10.10.1

--3) Protocols are enabled or not on both Client and Server side.

--4) Validate Browser service (As per general standards don't start Browser service). If Browser service is enabled then developers can connect directly to instance with help of Browser and port number. If it is not there then DBA's should provide complete connection details including port number to connect from another machine.

--5) Verify Remote connections for the instance. Actually we need to validate "Remote Access" setting if enabled or not. Check Remote Connection timeout interval as well.

--6) Telnet and identify Port is open or not.
telnet 10.10.10.1 1433

--7) Verify if Ports are listening both on Client and Server.
netstat -abn
netstat -abo

--8) Verify if firewall is enabled or not, if enabled set the Firewall Exception for SQL Server Port.

--9) Verify if Login has proper permissions to connect to the instance. Also if he is mapped to respective databases for performing operations.
--If connect permissions are Denied and if Login is Disabled.

--10) Verify if endpoints are started or not.

--11) Verify if connection limit has reached. If reached then connect through DAC and accordingly increase the limit or free up sessions if approved.

--12) Verify if the login connecting is part of same domain or if the login belongs to any untrusted domain. 

--13) A windows mapped login cannot connect to SQL Server, if the Windows User gets deleted (Orphan Login). Remapping the user with same SID is the solution.

--14) If the user is a contained database user and it is attempting to connect to another database as a normal login.

--15) SSPI Handshake Error.