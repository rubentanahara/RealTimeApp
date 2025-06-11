-- Create TripStatuses table
CREATE TABLE TripStatuses (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    Description NVARCHAR(200),
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE()
);

-- Create Trips table
CREATE TABLE Trips (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    TripNumber NVARCHAR(20) NOT NULL,
    StatusId INT NOT NULL,
    StartTime DATETIME2,
    EndTime DATETIME2,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_Trips_TripStatuses FOREIGN KEY (StatusId) REFERENCES TripStatuses(Id)
);

-- Insert default trip statuses
INSERT INTO TripStatuses (Name, Description) VALUES 
('Pending', 'Trip is pending to start'),
('InProgress', 'Trip is currently in progress'),
('Completed', 'Trip has been completed'),
('Cancelled', 'Trip has been cancelled'); 