using System;

namespace RealTimeApp.Domain.Entities;

public class Driver
{
    public Guid Id { get; private set; }
    public required string Name { get; set; }
    public required string LicenseNumber { get; set; }
    public required string Status { get; set; }
    public DateTime LastModified { get; private set; }
    public int Version { get; private set; }

    private Driver() { Name = string.Empty; LicenseNumber = string.Empty; Status = string.Empty; } // For EF Core

    public Driver(Guid id, string name, string licenseNumber, string status)
    {
        Id = id;
        Name = name;
        LicenseNumber = licenseNumber;
        Status = status;
        LastModified = DateTime.UtcNow;
        Version = 1;
    }

    public void Update(string name, string licenseNumber, string status)
    {
        Name = name;
        LicenseNumber = licenseNumber;
        Status = status;
        LastModified = DateTime.UtcNow;
        Version++;
    }
} 