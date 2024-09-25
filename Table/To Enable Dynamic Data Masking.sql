--default type
alter table tablaname
alter column columnname add masked with (function = 'default()')
--or
alter table tablaname
alter column columnname newdatatype masked with (function = 'default()')

--email type
alter table tablename
alter column columnname add masked with (function = 'email()')

--partial or custom type
alter table tablename
alter column columnname add masked
with (function = 'partial (2, "xx-xxxx-xxxx-", 4)' )

--random type
alter table tablename
alter column columnname add masked with (function = 'random(111,999)')

--datetime type (this is available from sql server 2022)
alter table tablename
alter column columnname add masked with (function = 'datetime("M")')
--year = datetype("Y")
--month = datetype("M")
--day = datetype("D")
--hour = datetype("h")
--minute = datetype("m")
--seconds = datetype("s")