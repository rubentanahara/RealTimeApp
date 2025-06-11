-- Seed TripStatuses
INSERT INTO TripStatuses (Id, Name, Description, CreatedAt, UpdatedAt)
VALUES
  (NEWID(), 'Scheduled', 'Trip is scheduled', SYSDATETIME(), SYSDATETIME()),
  (NEWID(), 'InProgress', 'Trip is in progress', SYSDATETIME(), SYSDATETIME()),
  (NEWID(), 'Completed', 'Trip is completed', SYSDATETIME(), SYSDATETIME()),
  (NEWID(), 'Cancelled', 'Trip is cancelled', SYSDATETIME(), SYSDATETIME());

-- Seed a Driver
INSERT INTO Drivers (Id, Name, LicenseNumber, Status, LastModified, Version)
VALUES
  (NEWID(), 'John Doe', 'D1234567', 'Active', SYSDATETIME(), 1);

-- Seed a Vehicle
INSERT INTO Vehicles (Id, LicensePlate, Model, Status, LastModified, Version)
VALUES
  (NEWID(), 'ABC123', 'Toyota Prius', 'Available', SYSDATETIME(), 1); 