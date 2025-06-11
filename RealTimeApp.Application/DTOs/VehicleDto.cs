using System;

namespace RealTimeApp.Application.DTOs;

public class VehicleDto
{
    public Guid Id { get; set; }
    public string LicensePlate { get; set; } = string.Empty;
    public string Model { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime LastModified { get; set; }
    public int Version { get; set; }
} 