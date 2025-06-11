-- Setup Test Data for RealTimeApp
-- This script adds test drivers and vehicles to prevent FK constraint errors

-- Add test drivers if they don't exist
IF NOT EXISTS (SELECT 1 FROM Drivers WHERE Id = '550e8400-e29b-41d4-a716-446655440001')
BEGIN
    INSERT INTO Drivers (Id, Name, LicenseNumber, Status, LastModified, Version) VALUES 
    ('550e8400-e29b-41d4-a716-446655440001', 'John Doe', 'DL123456', 0, GETUTCDATE(), 1),
    ('550e8400-e29b-41d4-a716-446655440002', 'Jane Smith', 'DL789012', 0, GETUTCDATE(), 1),
    ('550e8400-e29b-41d4-a716-446655440003', 'Mike Johnson', 'DL345678', 0, GETUTCDATE(), 1);
    PRINT 'Test drivers added successfully';
END
ELSE
BEGIN
    PRINT 'Test drivers already exist';
END

-- Add test vehicles if they don't exist
IF NOT EXISTS (SELECT 1 FROM Vehicles WHERE Id = '550e8400-e29b-41d4-a716-446655440001')
BEGIN
    INSERT INTO Vehicles (Id, LicensePlate, Model, Status, LastModified, Version) VALUES
    ('550e8400-e29b-41d4-a716-446655440001', 'ABC123', 'Ford Transit', 0, GETUTCDATE(), 1),
    ('550e8400-e29b-41d4-a716-446655440002', 'XYZ789', 'Chevrolet Express', 0, GETUTCDATE(), 1),
    ('550e8400-e29b-41d4-a716-446655440003', 'DEF456', 'Mercedes Sprinter', 0, GETUTCDATE(), 1);
    PRINT 'Test vehicles added successfully';
END
ELSE
BEGIN
    PRINT 'Test vehicles already exist';
END

-- Verify the data
SELECT COUNT(*) as DriverCount FROM Drivers;
SELECT COUNT(*) as VehicleCount FROM Vehicles;

PRINT 'Test data setup completed!'; 