using System;

namespace RealTimeApp.Infrastructure.Configuration;

public class RedisCacheOptions
{
    public const string SectionName = "RedisCache";
    
    /// <summary>
    /// Default TTL for trips when status is unknown
    /// </summary>
    public TimeSpan DefaultTripTtl { get; set; } = TimeSpan.FromHours(24);
    
    /// <summary>
    /// TTL for active trips (Created, Started, In-Progress)
    /// Shorter TTL because these trips change frequently
    /// </summary>
    public TimeSpan ActiveTripTtl { get; set; } = TimeSpan.FromHours(1);
    
    /// <summary>
    /// TTL for completed trips (Completed, Cancelled)
    /// Longer TTL because these trips rarely change
    /// </summary>
    public TimeSpan CompletedTripTtl { get; set; } = TimeSpan.FromHours(72);
    
    /// <summary>
    /// TTL for trip lists/collections
    /// </summary>
    public TimeSpan TripListTtl { get; set; } = TimeSpan.FromMinutes(30);
} 