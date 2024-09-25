--this one will only work from sql server 2014
CREATE CLUSTERED COLUMNSTORE INDEX [indexname] ON [tablename]
([column1],[column2],[column3],[column4])
GO

--this one will only work from sql server 2012
CREATE NONCLUSTERED COLUMNSTORE INDEX [indexname] ON [tablename]
([column1],[column2],[column3],[column4])
GO