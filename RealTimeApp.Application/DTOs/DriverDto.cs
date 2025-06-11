using System;

namespace RealTimeApp.Application.DTOs;

public class DriverDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string LicenseNumber { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime LastModified { get; set; }
    public int Version { get; set; }
} 