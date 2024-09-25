--for basic settings:
sp_configure

--for advanced settings:
sp_configure 'show advanced options', 1
--then run the following to refresh the settings
reconfigure
--and now if you run 'sp_configure', we can see all the settings