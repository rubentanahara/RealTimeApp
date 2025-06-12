-- Verify Change Tracking is enabled for tables
SELECT t.name AS TableName, ct.is_track_columns_updated_on, ct.begin_version
FROM sys.change_tracking_tables ct
JOIN sys.tables t ON ct.object_id = t.object_id; 