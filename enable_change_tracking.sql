-- Enable change tracking at database level
ALTER DATABASE RealTimeAppDb
SET CHANGE_TRACKING = ON
(CHANGE_RETENTION = 2 DAYS, AUTO_CLEANUP = ON);

-- Enable change tracking for Trips table
ALTER TABLE Trips ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);

-- Enable change tracking for TripStatuses table
ALTER TABLE TripStatuses ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);

-- Verify change tracking is enabled
SELECT name, is_tracked_by_cdc 
FROM sys.tables 
WHERE name IN ('Trips', 'TripStatuses'); 