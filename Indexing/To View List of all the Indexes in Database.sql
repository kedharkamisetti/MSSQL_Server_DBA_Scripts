Declare @DBName varchar(100)='DemoDB';
Declare @sql varchar(max)='
select
schema_name(t.schema_id) + ''.'' + t.[name] as table_view, 
 si.[name] as index_name,
    case when t.[type] = ''U'' then ''Table''
        when t.[type] = ''V'' then ''View''
        end as [object_type],
   substring(column_names, 1, len(column_names)-1) as [columns],
          case when si.[type] = 1 then ''Clustered index''
        when si.[type] = 2 then ''Nonclustered unique index''
        when si.[type] = 3 then ''XML index''
        when si.[type] = 4 then ''Spatial index''
        when si.[type] = 5 then ''Clustered columnstore index''
        when si.[type] = 6 then ''Nonclustered columnstore index''
        when si.[type] = 7 then ''Nonclustered hash index''
        end as index_type
    
from sys.objects t
    inner join sys.indexes si
        on t.object_id = si.object_id
    cross apply (select col.[name] + '', ''
                    from sys.index_columns ic
                       inner join sys.columns col
                           on ic.object_id = col.object_id
                           and ic.column_id = col.column_id
                    where ic.object_id = t.object_id
                       and ic.index_id = si.index_id
                           order by key_ordinal
                           for xml path ('''') ) D (column_names)
where t.is_ms_shipped <> 1
and index_id > 0
order by table_view'
exec ('USE ' + @DBName + @sql)