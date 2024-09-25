--windows authentication:
--single user mapping:
CREATE LOGIN [domainname\loginname] FROM WINDOWS
GO
--group mapping:
CREATE LOGIN [domainname\groupname] FROM WINDOWS
--builtin administrator mapping:
CREATE LOGIN [BUILTIN\Administrators] FROM WINDOWS

--sql authentication:
CREATE LOGIN [loginname] WITH PASSWORD=N'password'
GO