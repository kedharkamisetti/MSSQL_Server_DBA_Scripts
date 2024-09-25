select * , count(*) from tablename
group by name, id
having count(*) > 1