using System;

namespace RealTimeApp.Domain.Entities;

public class Trip
{
    public Guid Id { get; set; }
    public required string TripNumber { get; set; }
    public required string Status { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime? EndTime { get; set; }
    public Guid DriverId { get; set; }
    public Guid VehicleId { get; set; }
    public DateTime LastModified { get; set; }
    public int Version { get; set; }

    public Trip() { TripNumber = string.Empty; Status = string.Empty; } // Public parameterless constructor for object initializer
    private Trip(string tripNumber, string status) { TripNumber = tripNumber; Status = status; } // For EF Core

    public Trip(Guid id, string tripNumber, string status, Guid driverId, Guid vehicleId)
    {
        Id = id;
        TripNumber = tripNumber;
        Status = status;
        DriverId = driverId;
        VehicleId = vehicleId;
        LastModified = DateTime.UtcNow;
        Version = 1;
    }

    // Constructor for event creation
    public Trip(Guid id, string tripNumber, string status, DateTime lastModified, int version, Guid driverId, Guid vehicleId)
    {
        Id = id;
        TripNumber = tripNumber;
        Status = status;
        LastModified = lastModified;
        Version = version;
        DriverId = driverId;
        VehicleId = vehicleId;
        StartTime = DateTime.UtcNow;
    }

    public void Update(string status, Guid driverId, Guid vehicleId)
    {
        Status = status;
        DriverId = driverId;
        VehicleId = vehicleId;
        LastModified = DateTime.UtcNow;
        Version++;
    }

    public void UpdateStatus(string status)
    {
        Status = status;
        LastModified = DateTime.UtcNow;
        Version++;
    }

    public void Complete()
    {
        Status = "Completed";
        EndTime = DateTime.UtcNow;
        LastModified = DateTime.UtcNow;
        Version++;
    }
} 