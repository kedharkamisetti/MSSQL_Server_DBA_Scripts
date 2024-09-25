select object_name(object_id) tablename, name as column_name, is_masked, masking_function
from sys.masked_columns
order by tablename, column_name