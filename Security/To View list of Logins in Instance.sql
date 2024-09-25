-select * from sys.syslogins

--or

select * from sys.server_principals

--or

select sp.name as login,
       sp.type_desc as login_type,
       sl.password_hash,
       sp.create_date,
       sp.modify_date,
       case when sp.is_disabled = 1 then 'Disabled'
            else 'Enabled' end as status
from sys.server_principals sp
left join sys.sql_logins sl
          on sp.principal_id = sl.principal_id
where sp.type not in ('G', 'R','A','C','U')
order by sp.name;

====================
--Type of principal
--S = SQL Server user
--U = Windows user
--G = Windows group
--A = Application role
--R = Database role
--C = Certificate mapped
--K = Asymmetric key mapped