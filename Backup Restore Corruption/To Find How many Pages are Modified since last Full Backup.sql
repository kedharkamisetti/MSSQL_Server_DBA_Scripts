select file_id, total_page_count, modified_extent_page_count,
(modified_extent_page_count * 100) / total_page_count [%change]
from sys.dm_db_file_space_usage