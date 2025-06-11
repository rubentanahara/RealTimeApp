-- Add test drivers if they don't exist
IF NOT EXISTS (SELECT 1 FROM Drivers WHERE Id = '550e8400-e29b-41d4-a716-446655440001')
BEGIN
    INSERT INTO Drivers (Id, Name, LicenseNumber, Phone, Email) VALUES 
    ('550e8400-e29b-41d4-a716-446655440001', 'John Doe', 'DL123456', '555-0101', 'john.doe@example.com'),
    ('550e8400-e29b-41d4-a716-446655440002', 'Jane Smith', 'DL789012', '555-0102', 'jane.smith@example.com'),
    ('550e8400-e29b-41d4-a716-446655440003', 'Mike Johnson', 'DL345678', '555-0103', 'mike.johnson@example.com');
END

-- Add test vehicles if they don't exist
IF NOT EXISTS (SELECT 1 FROM Vehicles WHERE Id = '550e8400-e29b-41d4-a716-446655440001')
BEGIN
    INSERT INTO Vehicles (Id, Make, Model, Year, LicensePlate, VIN) VALUES
    ('550e8400-e29b-41d4-a716-446655440001', 'Ford', 'Transit', 2023, 'ABC123', '1FTBW2CM9GKA12345'),
    ('550e8400-e29b-41d4-a716-446655440002', 'Chevrolet', 'Express', 2023, 'XYZ789', '1GCWGBFP9K1234567'),
    ('550e8400-e29b-41d4-a716-446655440003', 'Mercedes', 'Sprinter', 2023, 'DEF456', 'WD3PF4CC9DP123456');
END

SELECT 'Test data added successfully' as Result;
