--this won't delete the table
--we still can access the table

--To Hide the Table
EXEC sp_addextendedproperty
@name = N'microsoft_database_tools_support',
@value = 'Hide',
@level0type = N'Schema', @level0name = 'schemaname',
@level1type = N'Table', @level1name = 'tablename';
GO

--To Unhide the Table
EXEC sp_dropextendedproperty
@name = N'microsoft_database_tools_support',
@level0type = N'Schema', @level0name = 'schemaname',
@level1type = N'Table', @level1name = 'tablename';
GO