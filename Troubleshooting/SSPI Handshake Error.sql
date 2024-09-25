--There can be 2 variants in SSPI errors: 
--"Cannot generate SSPI context" and "SSPI Handshake Failed".

--1) SSPI handshake failed: We get this when the user is not authenticated.

--From the client machine to verify if domain connectivity is good we can run 
nltest /SC_QUERY:YourDomainName

--Go to event viewer and under SYSTEM, filter for NETLOGON events and see if there are any connection failures.

--Some times we may see errors like below, then contact Windows/AD team for resolution.
--Log Name: System
--Source: NETLOGON
--Event ID: 5719
--Task Category: None
--Level: Error
--Keywords: Classic
--User: N/A
--Computer: client.Contoso.com
--Description: This computer was not able to set up a secure session with a domain controller in domain CONTOSO due to the following:
--There are currently no logon servers available to service the logon request.

--This may lead to authentication problems. Make sure that this computer is connected to the network. If the problem persists, please contact your domain administrator.}


--2) Cannot generate SSPI context:  We generally get this error when the client is trying a Kerberos authentication and that fails but it does not fall back to NTLM. 

--Listing SPNs:-
setspn -l KDSSG\SQLService

--Adding SPNs Manually:-
setspn -S MSSQLSvc/myhost.redmond.microsoft.com:1433 redmond\serviceaccount
--Example: setspn -s MSSQLSvc/kd-clus-node2.kdssg2.com:1433 KDSSG2\SQLService

--Deleting SPNs Manually:-
setspn -d MSSQLSvc/myhost.redmond.microsoft.com:1433

setspn -S MSSQLSvc/KD-Clus-N2.KDSSG.com:1433 KDSSG\SQLService