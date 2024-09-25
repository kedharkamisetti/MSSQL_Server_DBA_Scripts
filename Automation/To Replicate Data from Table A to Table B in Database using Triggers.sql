--Requirement:whenever data is inserterd,updated,or deleted in tablea that has to replicate to the tableb in same database.
--We can achieve this functionality using database level triggers. 
--Note:Server level triggers are not supported in Azure sql database.

--Demo:
--Step1: 
CREATE TABLE [dbo].[tableA](
	[ID] [int] NULL,
	[Name] [varchar](100) NULL,
	[Salary] [int] NULL
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[tableb](
	[ID] [int] NULL,
	[Name] [varchar](100) NULL,
	[Salary] [int] NULL
) ON [PRIMARY]
GO

--Step2:Create a Insert trigger
create trigger dbo.customize_insert
on dbo.tablea
after insert
as
begin
set nocount on
declare @id int,@name varchar(100), @salary int
select @id = id,@name =name,@salary = salary
from tableA

insert into tableb values(@id,@name,@salary)
end

--Step3:Create a delete trigger.
create trigger dbo.customize_delete
on dbo.tablea
after delete
as
begin
set nocount on
declare @id int,@name varchar(100), @salary int
select @id = deleted.id
from deleted

delete from tableb where @id = id 
end

--Step4:Create a update trigger 
create trigger dbo.customize_update
on dbo.tablea
after update
as
begin
set nocount on
declare @id int,@name varchar(100), @salary int,@idnew int,@newname varchar(100),@newsalary int
select @id = inserted.id from inserted
select @idnew = deleted.id from deleted

select @name = inserted.name from inserted
select @newname = deleted.name from deleted

select @Salary = inserted.Salary from inserted
select @newname = deleted.salary from deleted
IF UPDATE(id)
       BEGIN
              SET @id = @id
       END

IF UPDATE(name)
       BEGIN
              SET @Name = @name
       END
IF UPDATE(salary)
       BEGIN
              SET @salary = @salary
       END

 update tableb set ID = @id ,name= @name,salary = @salary where id = @idnew
end

--Final Step:insert,delete and update the data in table a and see the same is there or not in table b
insert into tablea values (1,'harsha','100')
insert into tablea values (2,'harsha','200')
insert into tablea values (3,'harsha','300')

select  * from tableA
go
select * from tableb

delete from tablea where id = 2

update tablea set ID = 10 where id = 1
update tablea set name ='super'  where id = 3
update tablea set Salary=3000 where id = 3

--Clean Up 
drop table tableA
drop table tableb

--you can use below dmv to find the triggers
Drop trigger dbo.customize_insert
Drop trigger dbo.customize_delete
Drop trigger dbo.customize_update
