--Ask some basic questions:- 
--What is the Server Name, IP Address (Inventory), What is the Application Name? What is the criticality to the Application? (Platinum/Gold/Silver/Bronze)
--How many users are getting impacted?
--Since when are you having this issue?
--Is something specific running slow? What do you mean by slow, how did you measure it? Is a query slow, application slow, data retrieval slow? 
--When was the last time the performance was good?
--Was there any change or major modification done to Code/Application from Developers Side?
--Verify if there was any patching/upgrade/change that has happenned on this server?


--1) Verify CPU utilization of the server.
--If CPU is 100% busy, follow troubleshooting steps accordingly.

--2) Verify Memory utilization of the server.
--If memory is 100% occupied, follow troubleshooting steps for memory issue.

--3) Verify if Disk utilization is normal. 
--Counters to be checked.

--4) Check Disk Space Availability on all the drives.

--5) Load on the system, Example average load is 2500 but we could see 10,000 connections.
select count(*) from sys.dm_exec_sessions where session_id>50

--6) Verify any jobs are running or not (Backups/Application Jobs/DBA Maintenance Jobs)

--7) Verify if any blockings exist

--8) What are the Top 5 queries running as per CPU & Memory & IO.

--9) Find out the total wait types in SQL Server.

--10) Find out the waiting tasks in SQL Server.
select * from sys.dm_os_waiting_tasks where session_id>50 
order by wait_duration_ms desc 