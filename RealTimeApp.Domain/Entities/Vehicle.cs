using System;

namespace RealTimeApp.Domain.Entities;

public class Vehicle
{
    public Guid Id { get; private set; }
    public required string LicensePlate { get; set; }
    public required string Model { get; set; }
    public required string Status { get; set; }
    public DateTime LastModified { get; private set; }
    public int Version { get; private set; }

    private Vehicle() { LicensePlate = string.Empty; Model = string.Empty; Status = string.Empty; } // For EF Core

    public Vehicle(Guid id, string licensePlate, string model, string status)
    {
        Id = id;
        LicensePlate = licensePlate;
        Model = model;
        Status = status;
        LastModified = DateTime.UtcNow;
        Version = 1;
    }

    public void Update(string licensePlate, string model, string status)
    {
        LicensePlate = licensePlate;
        Model = model;
        Status = status;
        LastModified = DateTime.UtcNow;
        Version++;
    }
} 