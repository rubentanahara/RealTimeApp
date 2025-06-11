using System;
using RealTimeApp.Domain.Entities;

namespace RealTimeApp.Domain.Events;

public class TripChangedEvent
{
    public required Trip Trip { get; set; }
    public Guid TripId { get; set; }
    public required string TripNumber { get; set; }
    public required string Status { get; set; }
    public DateTime LastModified { get; set; }
    public int Version { get; set; }
    public required string ChangeType { get; set; }

    // Parameterless constructor for deserialization
    public TripChangedEvent()
    {
        Trip = null!;
        TripNumber = string.Empty;
        Status = string.Empty;
        ChangeType = string.Empty;
    }

    public TripChangedEvent(Trip trip, string changeType)
    {
        Trip = trip;
        TripId = trip.Id;
        TripNumber = trip.TripNumber;
        Status = trip.Status;
        LastModified = trip.LastModified;
        Version = trip.Version;
        ChangeType = changeType;
    }
} 