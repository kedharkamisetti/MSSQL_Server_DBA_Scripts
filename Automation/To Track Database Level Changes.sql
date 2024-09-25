--first create a table to collect the data in master or desired database
--configure stored procedure to track the changes
--create a job to insert the data into table and schedule it to run accordingly


-------------------------------------------------
--to create a table
-------------------------------------------------
IF OBJECT_ID(N'dbo.SQLskills_DBData', N'U') IS NULL
BEGIN
  CREATE TABLE [dbo].[SQLskills_DBData]
  (
    [name] [sysname] NOT NULL,
    [database_id] [int] NOT NULL,
    [source_database_id] [int] NULL,
    [owner_sid] [varbinary](85) NULL,
    [create_date] [datetime] NOT NULL,
    [compatibility_level] [tinyint] NOT NULL,
    [collation_name] [sysname] NULL,
    [user_access] [tinyint] NULL,
    [user_access_desc] [nvarchar](60) NULL,
    [is_read_only] [bit] NULL,
    [is_auto_close_on] [bit] NOT NULL,
    [is_auto_shrink_on] [bit] NULL,
    [state] [tinyint] NULL,
    [state_desc] [nvarchar](60) NULL,
    [is_in_standby] [bit] NULL,
    [is_cleanly_shutdown] [bit] NULL,
    [is_supplemental_logging_enabled] [bit] NULL,
    [snapshot_isolation_state] [tinyint] NULL,
    [snapshot_isolation_state_desc] [nvarchar](60) NULL,
    [is_read_committed_snapshot_on] [bit] NULL,
    [recovery_model] [tinyint] NULL,
    [recovery_model_desc] [nvarchar](60) NULL,
    [page_verify_option] [tinyint] NULL,
    [page_verify_option_desc] [nvarchar](60) NULL,
    [is_auto_create_stats_on] [bit] NULL,
    [is_auto_update_stats_on] [bit] NULL,
    [is_auto_update_stats_async_on] [bit] NULL,
    [is_ansi_null_default_on] [bit] NULL,
    [is_ansi_nulls_on] [bit] NULL,
    [is_ansi_padding_on] [bit] NULL,
    [is_ansi_warnings_on] [bit] NULL,
    [is_arithabort_on] [bit] NULL,
    [is_concat_null_yields_null_on] [bit] NULL,
    [is_numeric_roundabort_on] [bit] NULL,
    [is_quoted_identifier_on] [bit] NULL,
    [is_recursive_triggers_on] [bit] NULL,
    [is_cursor_close_on_commit_on] [bit] NULL,
    [is_local_cursor_default] [bit] NULL,
    [is_fulltext_enabled] [bit] NULL,
    [is_trustworthy_on] [bit] NULL,
    [is_db_chaining_on] [bit] NULL,
    [is_parameterization_forced] [bit] NULL,
    [is_master_key_encrypted_by_server] [bit] NOT NULL,
    [is_published] [bit] NOT NULL,
    [is_subscribed] [bit] NOT NULL,
    [is_merge_published] [bit] NOT NULL,
    [is_distributor] [bit] NOT NULL,
    [is_sync_with_backup] [bit] NOT NULL,
    [service_broker_guid] [uniqueidentifier] NOT NULL,
    [is_broker_enabled] [bit] NOT NULL,
    [log_reuse_wait] [tinyint] NULL,
    [log_reuse_wait_desc] [nvarchar](60) NULL,
    [is_date_correlation_on] [bit] NOT NULL,
    [is_cdc_enabled] [bit] NOT NULL,
    [is_encrypted] [bit] NULL,
    [is_honor_broker_priority_on] [bit] NULL,
    [replica_id] [uniqueidentifier] NULL,
    [group_database_id] [uniqueidentifier] NULL,
    [default_language_lcid] [smallint] NULL,
    [default_language_name] [nvarchar](128) NULL,
    [default_fulltext_language_lcid] [int] NULL,
    [default_fulltext_language_name] [nvarchar](128) NULL,
    [is_nested_triggers_on] [bit] NULL,
    [is_transform_noise_words_on] [bit] NULL,
    [two_digit_year_cutoff] [smallint] NULL,
    [containment] [tinyint] NULL,
    [containment_desc] [nvarchar](60) NULL,
    [target_recovery_time_in_seconds] [int] NULL,
    [CaptureDate] [datetime] NOT NULL DEFAULT SYSDATETIME()
) ON [PRIMARY];
End

--to create clustered index, if needed
CREATE CLUSTERED INDEX [CI_SQLskills_DBData] 
  ON [dbo].[SQLskills_DBData] ([CaptureDate],[database_id]);
GO


-------------------------------------------------
--to create stored procedure
-------------------------------------------------
CREATE PROCEDURE [dbo].[usp_FindDBSettingChanges2]
AS
BEGIN
;WITH f AS 
(
  SELECT 
    ROW_NUMBER() OVER (PARTITION BY database_id ORDER BY CaptureDate ASC) AS RowNumber,
    [name],
    [database_id],
    [source_database_id],
    [owner_sid],
    [create_date],
    [compatibility_level],
    [collation_name],
    [user_access],
    [user_access_desc],
    [is_read_only],
    [is_auto_close_on],
    [is_auto_shrink_on],
    [state],
    [state_desc],
    [is_in_standby],
    [is_cleanly_shutdown],
    [is_supplemental_logging_enabled],
    [snapshot_isolation_state],
    [snapshot_isolation_state_desc],
    [is_read_committed_snapshot_on],
    [recovery_model],
    [recovery_model_desc],
    [page_verify_option],
    [page_verify_option_desc],
    [is_auto_create_stats_on],
    [is_auto_update_stats_on],
    [is_auto_update_stats_async_on],
    [is_ansi_null_default_on],
    [is_ansi_nulls_on],
    [is_ansi_padding_on],
    [is_ansi_warnings_on],
    [is_arithabort_on],
    [is_concat_null_yields_null_on],
    [is_numeric_roundabort_on],
    [is_quoted_identifier_on],
    [is_recursive_triggers_on],
    [is_cursor_close_on_commit_on],
    [is_local_cursor_default],
    [is_fulltext_enabled],
    [is_trustworthy_on],
    [is_db_chaining_on],
    [is_parameterization_forced],
    [is_master_key_encrypted_by_server],
    [is_published],
    [is_subscribed],
    [is_merge_published],
    [is_distributor],
    [is_sync_with_backup],
    [service_broker_guid],
    [is_broker_enabled],
    [log_reuse_wait],
    [log_reuse_wait_desc],
    [is_date_correlation_on],
    [is_cdc_enabled],
    [is_encrypted],
    [is_honor_broker_priority_on],
    [replica_id],
    [group_database_id],
    [default_language_lcid],
    [default_language_name],
    [default_fulltext_language_lcid],
    [default_fulltext_language_name],
    [is_nested_triggers_on],
    [is_transform_noise_words_on],
    [two_digit_year_cutoff],
    [containment],
    [containment_desc],
    [target_recovery_time_in_seconds], 
    [CaptureDate]
  FROM [dbo].[SQLskills_DBData]
)
SELECT 
    f.database_id,
    f.name,
    f.CaptureDate AS OriginalCaptureDate,
    n.CaptureDate AS ChangedCaptureDate,
    CASE
        WHEN f.owner_sid <> n.owner_sid THEN '[owner_sid]'
        WHEN f.create_date <> n.create_date THEN '[create_date]'
        WHEN f.compatibility_level <> n.compatibility_level THEN '[compatibility_level]'
        WHEN f.collation_name <> n.collation_name THEN '[collation_name]'
        WHEN f.user_access <> n.user_access THEN '[user_access]'
        WHEN f.is_read_only <> n.is_read_only THEN '[is_read_only]'
        WHEN f.is_auto_close_on <> n.is_auto_close_on THEN '[is_auto_close_on]'
        WHEN f.is_auto_shrink_on <> n.is_auto_shrink_on THEN '[is_auto_shrink_on]'
        WHEN f.state <> n.state THEN '[state]'
        WHEN f.is_in_standby <> n.is_in_standby THEN '[is_in_standby]'
        WHEN f.is_cleanly_shutdown <> n.is_cleanly_shutdown THEN '[is_cleanly_shutdown]'
        WHEN f.is_supplemental_logging_enabled <> n.is_supplemental_logging_enabled THEN '[is_supplemental_logging_enabled]'
        WHEN f.snapshot_isolation_state <> n.snapshot_isolation_state THEN '[snapshot_isolation_state]'
        WHEN f.is_read_committed_snapshot_on <> n.is_read_committed_snapshot_on THEN '[is_read_committed_snapshot_on]'
        WHEN f.recovery_model <> n.recovery_model THEN '[recovery_model]'
        WHEN f.page_verify_option <> n.page_verify_option THEN '[page_verify_option]'
        WHEN f.is_auto_create_stats_on <> n.is_auto_create_stats_on THEN '[is_auto_create_stats_on]'
        WHEN f.is_auto_update_stats_on <> n.is_auto_update_stats_on THEN '[is_auto_update_stats_on]'
        WHEN f.is_auto_update_stats_async_on <> n.is_auto_update_stats_async_on THEN '[is_auto_update_stats_async_on]'
        WHEN f.is_ansi_null_default_on <> n.is_ansi_null_default_on THEN '[is_ansi_null_default_on]'
        WHEN f.is_ansi_nulls_on <> n.is_ansi_nulls_on THEN '[is_ansi_nulls_on]'
        WHEN f.is_ansi_padding_on <> n.is_ansi_padding_on THEN '[is_ansi_padding_on]'
        WHEN f.is_ansi_warnings_on <> n.is_ansi_warnings_on THEN '[is_ansi_warnings_on]'
        WHEN f.is_arithabort_on <> n.is_arithabort_on THEN '[is_arithabort_on]'
        WHEN f.is_concat_null_yields_null_on <> n.is_concat_null_yields_null_on THEN '[is_concat_null_yields_null_on]'
        WHEN f.is_numeric_roundabort_on <> n.is_numeric_roundabort_on THEN '[is_numeric_roundabort_on]'
        WHEN f.is_quoted_identifier_on <> n.is_quoted_identifier_on THEN '[is_quoted_identifier_on]'
        WHEN f.is_recursive_triggers_on <> n.is_recursive_triggers_on THEN '[is_recursive_triggers_on]'
        WHEN f.is_cursor_close_on_commit_on <> n.is_cursor_close_on_commit_on THEN '[is_cursor_close_on_commit_on]'
        WHEN f.is_local_cursor_default <> n.is_local_cursor_default THEN '[is_local_cursor_default]'
        WHEN f.is_fulltext_enabled <> n.is_fulltext_enabled THEN '[is_fulltext_enabled]'
        WHEN f.is_trustworthy_on <> n.is_trustworthy_on THEN '[is_trustworthy_on]'
        WHEN f.is_db_chaining_on <> n.is_db_chaining_on THEN '[is_db_chaining_on]'
        WHEN f.is_parameterization_forced <> n.is_parameterization_forced THEN '[is_parameterization_forced]'
        WHEN f.is_master_key_encrypted_by_server <> n.is_master_key_encrypted_by_server THEN '[is_master_key_encrypted_by_server]'
        WHEN f.is_published <> n.is_published THEN '[is_published]'
        WHEN f.is_subscribed <> n.is_subscribed THEN '[is_subscribed]'
        WHEN f.is_merge_published <> n.is_merge_published THEN '[is_merge_published]'
        WHEN f.is_distributor <> n.is_distributor THEN '[is_distributor]'
        WHEN f.is_sync_with_backup <> n.is_sync_with_backup THEN '[is_sync_with_backup]'
        WHEN f.service_broker_guid <> n.service_broker_guid THEN '[service_broker_guid]'
        WHEN f.is_broker_enabled <> n.is_broker_enabled THEN '[is_broker_enabled]'
        WHEN f.is_date_correlation_on <> n.is_date_correlation_on THEN '[is_date_correlation_on]'
        WHEN f.is_cdc_enabled <> n.is_cdc_enabled THEN '[is_cdc_enabled]'
        WHEN f.is_encrypted <> n.is_encrypted THEN '[is_encrypted]'
        WHEN f.is_honor_broker_priority_on <> n.is_honor_broker_priority_on THEN '[is_honor_broker_priority_on]'
        WHEN f.replica_id <> n.replica_id THEN '[replica_id]'
        WHEN f.group_database_id <> n.group_database_id THEN '[group_database_id]'
        WHEN f.default_language_lcid <> n.default_language_lcid THEN '[default_language_lcid]'
        WHEN f.default_language_name <> n.default_language_name THEN '[default_language_name]'
        WHEN f.default_fulltext_language_lcid <> n.default_fulltext_language_lcid THEN '[default_fulltext_language_lcid]'
        WHEN f.default_fulltext_language_name <> n.default_fulltext_language_name THEN '[default_fulltext_language_name]'
        WHEN f.is_nested_triggers_on <> n.is_nested_triggers_on THEN '[is_nested_triggers_on]'
        WHEN f.is_transform_noise_words_on <> n.is_transform_noise_words_on THEN '[is_transform_noise_words_on]'
        WHEN f.two_digit_year_cutoff <> n.two_digit_year_cutoff THEN '[two_digit_year_cutoff]'
        WHEN f.containment <> n.containment THEN '[containment]'
        WHEN f.target_recovery_time_in_seconds <> n.target_recovery_time_in_seconds THEN '[target_recovery_time_in_seconds]'
        ELSE NULL
    END AS ChangedColumn,
    f.owner_sid AS Original_owner_sid, n.owner_sid AS Changed_owner_sid,
    f.create_date AS Original_create_date, n.create_date AS Changed_create_date,
    f.compatibility_level AS Original_compatibility_level, n.compatibility_level AS Changed_compatibility_level,
    f.collation_name AS Original_collation_name, n.collation_name AS Changed_collation_name,
    f.user_access AS Original_user_access, n.user_access AS Changed_user_access,
    f.is_read_only AS Original_is_read_only, n.is_read_only AS Changed_is_read_only,
    f.is_auto_close_on AS Original_is_auto_close_on, n.is_auto_close_on AS Changed_is_auto_close_on,
    f.is_auto_shrink_on AS Original_is_auto_shrink_on, n.is_auto_shrink_on AS Changed_is_auto_shrink_on,
    f.state AS Original_state, n.state AS Changed_state,
    f.is_in_standby AS Original_is_in_standby, n.is_in_standby AS Changed_is_in_standby,
    f.is_cleanly_shutdown AS Original_is_cleanly_shutdown, n.is_cleanly_shutdown AS Changed_is_cleanly_shutdown,
    f.is_supplemental_logging_enabled AS Original_is_supplemental_logging_enabled, n.is_supplemental_logging_enabled AS Changed_is_supplemental_logging_enabled,
    f.snapshot_isolation_state AS Original_snapshot_isolation_state, n.snapshot_isolation_state AS Changed_snapshot_isolation_state,
    f.is_read_committed_snapshot_on AS Original_is_read_committed_snapshot_on, n.is_read_committed_snapshot_on AS Changed_is_read_committed_snapshot_on,
    f.recovery_model AS Original_recovery_model, n.recovery_model AS Changed_recovery_model,
    f.page_verify_option AS Original_page_verify_option, n.page_verify_option AS Changed_page_verify_option,
    f.is_auto_create_stats_on AS Original_is_auto_create_stats_on, n.is_auto_create_stats_on AS Changed_is_auto_create_stats_on,
    f.is_auto_update_stats_on AS Original_is_auto_update_stats_on, n.is_auto_update_stats_on AS Changed_is_auto_update_stats_on,
    f.is_auto_update_stats_async_on AS Original_is_auto_update_stats_async_on, n.is_auto_update_stats_async_on AS Changed_is_auto_update_stats_async_on,
    f.is_ansi_null_default_on AS Original_is_ansi_null_default_on, n.is_ansi_null_default_on AS Changed_is_ansi_null_default_on,
    f.is_ansi_nulls_on AS Original_is_ansi_nulls_on, n.is_ansi_nulls_on AS Changed_is_ansi_nulls_on,
    f.is_ansi_padding_on AS Original_is_ansi_padding_on, n.is_ansi_padding_on AS Changed_is_ansi_padding_on,
    f.is_ansi_warnings_on AS Original_is_ansi_warnings_on, n.is_ansi_warnings_on AS Changed_is_ansi_warnings_on,
    f.is_arithabort_on AS Original_is_arithabort_on, n.is_arithabort_on AS Changed_is_arithabort_on,
    f.is_concat_null_yields_null_on AS Original_is_concat_null_yields_null_on, n.is_concat_null_yields_null_on AS Changed_is_concat_null_yields_null_on,
    f.is_numeric_roundabort_on AS Original_is_numeric_roundabort_on, n.is_numeric_roundabort_on AS Changed_is_numeric_roundabort_on,
    f.is_quoted_identifier_on AS Original_is_quoted_identifier_on, n.is_quoted_identifier_on AS Changed_is_quoted_identifier_on,
    f.is_recursive_triggers_on AS Original_is_recursive_triggers_on, n.is_recursive_triggers_on AS Changed_is_recursive_triggers_on,
    f.is_cursor_close_on_commit_on AS Original_is_cursor_close_on_commit_on, n.is_cursor_close_on_commit_on AS Changed_is_cursor_close_on_commit_on,
    f.is_local_cursor_default AS Original_is_local_cursor_default, n.is_local_cursor_default AS Changed_is_local_cursor_default,
    f.is_fulltext_enabled AS Original_is_fulltext_enabled, n.is_fulltext_enabled AS Changed_is_fulltext_enabled,
    f.is_trustworthy_on AS Original_is_trustworthy_on, n.is_trustworthy_on AS Changed_is_trustworthy_on,
    f.is_db_chaining_on AS Original_is_db_chaining_on, n.is_db_chaining_on AS Changed_is_db_chaining_on,
    f.is_parameterization_forced AS Original_is_parameterization_forced, n.is_parameterization_forced AS Changed_is_parameterization_forced,
    f.is_master_key_encrypted_by_server AS Original_is_master_key_encrypted_by_server, n.is_master_key_encrypted_by_server AS Changed_is_master_key_encrypted_by_server,
    f.is_published AS Original_is_published, n.is_published AS Changed_is_published,
    f.is_subscribed AS Original_is_subscribed, n.is_subscribed AS Changed_is_subscribed,
    f.is_merge_published AS Original_is_merge_published, n.is_merge_published AS Changed_is_merge_published,
    f.is_distributor AS Original_is_distributor, n.is_distributor AS Changed_is_distributor,
    f.is_sync_with_backup AS Original_is_sync_with_backup, n.is_sync_with_backup AS Changed_is_sync_with_backup,
    f.service_broker_guid AS Original_service_broker_guid, n.service_broker_guid AS Changed_service_broker_guid,
    f.is_broker_enabled AS Original_is_broker_enabled, n.is_broker_enabled AS Changed_is_broker_enabled,
    f.is_date_correlation_on AS Original_is_date_correlation_on, n.is_date_correlation_on AS Changed_is_date_correlation_on,
    f.is_cdc_enabled AS Original_is_cdc_enabled, n.is_cdc_enabled AS Changed_is_cdc_enabled,
    f.is_encrypted AS Original_is_encrypted, n.is_encrypted AS Changed_is_encrypted,
    f.is_honor_broker_priority_on AS Original_is_honor_broker_priority_on, n.is_honor_broker_priority_on AS Changed_is_honor_broker_priority_on,
    f.replica_id AS Original_replica_id, n.replica_id AS Changed_replica_id,
    f.group_database_id AS Original_group_database_id, n.group_database_id AS Changed_group_database_id,
    f.default_language_lcid AS Original_default_language_lcid, n.default_language_lcid AS Changed_default_language_lcid,
    f.default_language_name AS Original_default_language_name, n.default_language_name AS Changed_default_language_name,
    f.default_fulltext_language_lcid AS Original_default_fulltext_language_lcid, n.default_fulltext_language_lcid AS Changed_default_fulltext_language_lcid,
    f.default_fulltext_language_name AS Original_default_fulltext_language_name, n.default_fulltext_language_name AS Changed_default_fulltext_language_name,
    f.is_nested_triggers_on AS Original_is_nested_triggers_on, n.is_nested_triggers_on AS Changed_is_nested_triggers_on,
    f.is_transform_noise_words_on AS Original_is_transform_noise_words_on, n.is_transform_noise_words_on AS Changed_is_transform_noise_words_on,
    f.two_digit_year_cutoff AS Original_two_digit_year_cutoff, n.two_digit_year_cutoff AS Changed_two_digit_year_cutoff,
    f.containment AS Original_containment, n.containment AS Changed_containment,
    f.target_recovery_time_in_seconds AS Original_target_recovery_time_in_seconds, n.target_recovery_time_in_seconds AS Changed_target_recovery_time_in_seconds
FROM f 
INNER JOIN f n ON f.database_id = n.database_id AND f.RowNumber = n.RowNumber - 1
WHERE 
(
    f.owner_sid <> n.owner_sid OR
    f.create_date <> n.create_date OR
    f.compatibility_level <> n.compatibility_level OR
    f.collation_name <> n.collation_name OR
    f.user_access <> n.user_access OR
    f.is_read_only <> n.is_read_only OR
    f.is_auto_close_on <> n.is_auto_close_on OR
    f.is_auto_shrink_on <> n.is_auto_shrink_on OR
    f.state <> n.state OR
    f.is_in_standby <> n.is_in_standby OR
    f.is_cleanly_shutdown <> n.is_cleanly_shutdown OR
    f.is_supplemental_logging_enabled <> n.is_supplemental_logging_enabled OR
    f.snapshot_isolation_state <> n.snapshot_isolation_state OR
    f.is_read_committed_snapshot_on <> n.is_read_committed_snapshot_on OR
    f.recovery_model <> n.recovery_model OR
    f.page_verify_option <> n.page_verify_option OR
    f.is_auto_create_stats_on <> n.is_auto_create_stats_on OR
    f.is_auto_update_stats_on <> n.is_auto_update_stats_on OR
    f.is_auto_update_stats_async_on <> n.is_auto_update_stats_async_on OR
    f.is_ansi_null_default_on <> n.is_ansi_null_default_on OR
    f.is_ansi_nulls_on <> n.is_ansi_nulls_on OR
    f.is_ansi_padding_on <> n.is_ansi_padding_on OR
    f.is_ansi_warnings_on <> n.is_ansi_warnings_on OR
    f.is_arithabort_on <> n.is_arithabort_on OR
    f.is_concat_null_yields_null_on <> n.is_concat_null_yields_null_on OR
    f.is_numeric_roundabort_on <> n.is_numeric_roundabort_on OR
    f.is_quoted_identifier_on <> n.is_quoted_identifier_on OR
    f.is_recursive_triggers_on <> n.is_recursive_triggers_on OR
    f.is_cursor_close_on_commit_on <> n.is_cursor_close_on_commit_on OR
    f.is_local_cursor_default <> n.is_local_cursor_default OR
    f.is_fulltext_enabled <> n.is_fulltext_enabled OR
    f.is_trustworthy_on <> n.is_trustworthy_on OR
    f.is_db_chaining_on <> n.is_db_chaining_on OR
    f.is_parameterization_forced <> n.is_parameterization_forced OR
    f.is_master_key_encrypted_by_server <> n.is_master_key_encrypted_by_server OR
    f.is_published <> n.is_published OR
    f.is_subscribed <> n.is_subscribed OR
    f.is_merge_published <> n.is_merge_published OR
    f.is_distributor <> n.is_distributor OR
    f.is_sync_with_backup <> n.is_sync_with_backup OR
    f.service_broker_guid <> n.service_broker_guid OR
    f.is_broker_enabled <> n.is_broker_enabled OR
    f.is_date_correlation_on <> n.is_date_correlation_on OR
    f.is_cdc_enabled <> n.is_cdc_enabled OR
    f.is_encrypted <> n.is_encrypted OR
    f.is_honor_broker_priority_on <> n.is_honor_broker_priority_on OR
    f.replica_id <> n.replica_id OR
    f.group_database_id <> n.group_database_id OR
    f.default_language_lcid <> n.default_language_lcid OR
    f.default_language_name <> n.default_language_name OR
    f.default_fulltext_language_lcid <> n.default_fulltext_language_lcid OR
    f.default_fulltext_language_name <> n.default_fulltext_language_name OR
    f.is_nested_triggers_on <> n.is_nested_triggers_on OR
    f.is_transform_noise_words_on <> n.is_transform_noise_words_on OR
    f.two_digit_year_cutoff <> n.two_digit_year_cutoff OR
    f.containment <> n.containment OR
    f.target_recovery_time_in_seconds <> n.target_recovery_time_in_seconds
);
End


-------------------------------------------------
--add the following script in the job step, create and schedule the job accordingly
-------------------------------------------------
INSERT INTO [dbo].[SQLskills_DBData]
(
  [name],
  [database_id],
  [source_database_id],
  [owner_sid],
  [create_date],
  [compatibility_level],
  [collation_name],
  [user_access],
  [user_access_desc],
  [is_read_only],
  [is_auto_close_on],
  [is_auto_shrink_on],
  [state],
  [state_desc],
  [is_in_standby],
  [is_cleanly_shutdown],
  [is_supplemental_logging_enabled],
  [snapshot_isolation_state],
  [snapshot_isolation_state_desc],
  [is_read_committed_snapshot_on],
  [recovery_model],
  [recovery_model_desc],
  [page_verify_option],
  [page_verify_option_desc],
  [is_auto_create_stats_on],
  [is_auto_update_stats_on],
  [is_auto_update_stats_async_on],
  [is_ansi_null_default_on],
  [is_ansi_nulls_on],
  [is_ansi_padding_on],
  [is_ansi_warnings_on],
  [is_arithabort_on],
  [is_concat_null_yields_null_on],
  [is_numeric_roundabort_on],
  [is_quoted_identifier_on],
  [is_recursive_triggers_on],
  [is_cursor_close_on_commit_on],
  [is_local_cursor_default],
  [is_fulltext_enabled],
  [is_trustworthy_on],
  [is_db_chaining_on],
  [is_parameterization_forced],
  [is_master_key_encrypted_by_server],
  [is_published],
  [is_subscribed],
  [is_merge_published],
  [is_distributor],
  [is_sync_with_backup],
  [service_broker_guid],
  [is_broker_enabled],
  [log_reuse_wait],
  [log_reuse_wait_desc],
  [is_date_correlation_on],
  [is_cdc_enabled],
  [is_encrypted],
  [is_honor_broker_priority_on],
  [replica_id],
  [group_database_id],
  [default_language_lcid],
  [default_language_name],
  [default_fulltext_language_lcid],
  [default_fulltext_language_name],
  [is_nested_triggers_on],
  [is_transform_noise_words_on],
  [two_digit_year_cutoff],
  [containment],
  [containment_desc],
  [target_recovery_time_in_seconds]
)
SELECT
  [name],
  [database_id],
  [source_database_id],
  [owner_sid],
  [create_date],
  [compatibility_level],
  [collation_name],
  [user_access],
  [user_access_desc],
  [is_read_only],
  [is_auto_close_on],
  [is_auto_shrink_on],
  [state],
  [state_desc],
  [is_in_standby],
  [is_cleanly_shutdown],
  [is_supplemental_logging_enabled],
  [snapshot_isolation_state],
  [snapshot_isolation_state_desc],
  [is_read_committed_snapshot_on],
  [recovery_model],
  [recovery_model_desc],
  [page_verify_option],
  [page_verify_option_desc],
  [is_auto_create_stats_on],
  [is_auto_update_stats_on],
  [is_auto_update_stats_async_on],
  [is_ansi_null_default_on],
  [is_ansi_nulls_on],
  [is_ansi_padding_on],
  [is_ansi_warnings_on],
  [is_arithabort_on],
  [is_concat_null_yields_null_on],
  [is_numeric_roundabort_on],
  [is_quoted_identifier_on],
  [is_recursive_triggers_on],
  [is_cursor_close_on_commit_on],
  [is_local_cursor_default],
  [is_fulltext_enabled],
  [is_trustworthy_on],
  [is_db_chaining_on],
  [is_parameterization_forced],
  [is_master_key_encrypted_by_server],
  [is_published],
  [is_subscribed],
  [is_merge_published],
  [is_distributor],
  [is_sync_with_backup],
  [service_broker_guid],
  [is_broker_enabled],
  [log_reuse_wait],
  [log_reuse_wait_desc],
  [is_date_correlation_on],
  [is_cdc_enabled],
  [is_encrypted],
  [is_honor_broker_priority_on],
  [replica_id],
  [group_database_id],
  [default_language_lcid],
  [default_language_name],
  [default_fulltext_language_lcid],
  [default_fulltext_language_name],
  [is_nested_triggers_on],
  [is_transform_noise_words_on],
  [two_digit_year_cutoff],
  [containment],
  [containment_desc],
  [target_recovery_time_in_seconds]
FROM [sys].[databases];
GO



-------------------------------------------------
--use the following command to view the data
-------------------------------------------------
exec dbo.usp_finddbsettingchanges2