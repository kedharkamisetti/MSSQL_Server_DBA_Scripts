--Method 1_Auto Fix:
--if login exists
--this will work only when both loginname and username are same
exec sp_change_users_login 'auto_fix', 'username'

--or

--if login doesn't exist
exec sp_change_users_login 'auto_fix', 'username', null, 'password'

--Method 2_Update_one:
--if login exists
exec sp_change_users_login 'update_one', 'username', 'loginname'

--Method 3_Create login with User SID:
--if login doesn't exist
create login loginname with password = 'password',
sid = user_sid

--Method 4_sp_help_revlogin:
--step1: get the query from this link = https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/security/transfer-logins-passwords-between-instances
--step2: run the code in the source server
--step3: execute exec_sp_help_revlogin
--step4: copy the login script for the users
--step5: paste it in the user database in destination server

--Method 5_DMA Tool:
--step1: download DMA Tool using this link = https://www.microsoft.com/en-us/download/details.aspx?id=53595
--step2: users will move along with their logins
--step3: we have an option to migrate selected logins using data migration assistant. (we don't have an option to choose users of the database to be migrated.)
--step4: server level permissions also get migrated