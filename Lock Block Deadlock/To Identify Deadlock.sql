--old method
dbcc traceon(1204, -1)
--"1204" will record the deadlock in error log, when happened
--"-1" will apply this trace flag globally


--moderate method
--use sql server profiler
--by default sql server record these following events:
		--audit login
		--audit logout
		--existing connection
		--rpc competion
		--batch starting
		--batch completed
--it is not recommended to run sql server profiler for longer periods


--new method
--create an extended event


--Best Method
--go to the following location and identify the deadlock, becuase it is monitored by default in sql server.
--Management > Extended Events > Sessions > system_health > event_file
--then search for deadlock in event_ile table

--to send it as a report, use the following steps:
	--after finding the deadlock in event_file
	--right click on the value and then click on copy to copy the entire report
	--then paste it in notepad
	--then remove "xml_report" word in the beginning of the report
	--then save the file in ".xdl" format
	--then email the file to the respective developer
--in this way they can also view entire report in ssms.