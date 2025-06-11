using System;

namespace RealTimeApp.Application.DTOs;

public class TripDto
{
    public Guid Id { get; set; }
    public string TripNumber { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime StartTime { get; set; }
    public DateTime? EndTime { get; set; }
    public Guid DriverId { get; set; }
    public Guid VehicleId { get; set; }
    public DateTime LastModified { get; set; }
    public int Version { get; set; }
} 