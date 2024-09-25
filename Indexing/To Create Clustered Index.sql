--if table contains <=1000 rows, don't create an index.

--Creates Clustered Index on the table.
CREATE CLUSTERED INDEX clustername ON tablename(columnname)

--if we want to create composite clustered index use the following command
create clustered index clustername on tablename(columnname1, columnname2)

--Conditions for clustered index:
	--all rows together the value should not exceed 900 bytes.
	--we can configure upto 32 columns (composite)
	--we can only create 1 clustered index on a table