--Creates NonClustered Index on the table.
CREATE NONCLUSTERED INDEX clustername ON tablename(columnname)

--if we want to create composite clustered index use the following command
create nonclustered index clustername on tablename(columnname1, columnname2)

--Conditions for nonclustered index:
	--all rows together the value should not exceed 1700 bytes.
	--we can configure upto 32 columns (composite)
	--we can create upto 999 nonclustered indexes on a table
	

--if we want to cover more than 32 columns, then we use inclued
CREATE NONCLUSTERED INDEX [indexname] ON [tablename] (column1)
INCLUDE (column2,column3) ON [PRIMARY] GO