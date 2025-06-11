using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.Options;
using StackExchange.Redis;
using RealTimeApp.Domain.Entities;
using RealTimeApp.Domain.Interfaces;
using RealTimeApp.Infrastructure.Configuration;

namespace RealTimeApp.Infrastructure.Services;

public class RedisCacheService : IRedisCacheService
{
    private readonly IConnectionMultiplexer _redis;
    private readonly IDatabase _db;
    private readonly RedisCacheOptions _options;
    private const string TripKeyPrefix = "trip:";

    public RedisCacheService(IConnectionMultiplexer redis, IOptions<RedisCacheOptions> options)
    {
        _redis = redis;
        _db = redis.GetDatabase();
        _options = options.Value;
    }

    public async Task<Trip?> GetTripAsync(string tripNumber)
    {
        var key = $"{TripKeyPrefix}{tripNumber}";
        var value = await _db.StringGetAsync(key);
        
        if (value.IsNull)
            return null;

        return JsonSerializer.Deserialize<Trip>(value!);
    }

    public async Task SetTripAsync(Trip trip)
    {
        // Use dynamic TTL based on trip status
        var ttl = GetTtlForTrip(trip);
        await SetTripAsync(trip, ttl);
    }

    public async Task SetTripAsync(Trip trip, TimeSpan? expiry)
    {
        var key = $"{TripKeyPrefix}{trip.TripNumber}";
        var value = JsonSerializer.Serialize(trip);
        
        await _db.StringSetAsync(key, value, expiry);
    }

    public async Task RemoveTripAsync(string tripNumber)
    {
        var key = $"{TripKeyPrefix}{tripNumber}";
        await _db.KeyDeleteAsync(key);
    }

    public async Task<IEnumerable<Trip>> GetAllTripsAsync()
    {
        var server = _redis.GetServer(_redis.GetEndPoints().First());
        var keys = server.Keys(pattern: $"{TripKeyPrefix}*");
        
        var trips = new List<Trip>();
        foreach (var key in keys)
        {
            var value = await _db.StringGetAsync(key);
            if (!value.IsNull)
            {
                var trip = JsonSerializer.Deserialize<Trip>(value!);
                if (trip != null)
                    trips.Add(trip);
            }
        }
        
        return trips;
    }
    
    /// <summary>
    /// Determines appropriate TTL based on trip status and business logic
    /// </summary>
    private TimeSpan GetTtlForTrip(Trip trip)
    {
        return trip.Status?.ToLowerInvariant() switch
        {
            "created" or "started" or "in-progress" => _options.ActiveTripTtl,     // Short TTL for active trips (frequent updates)
            "completed" or "cancelled" => _options.CompletedTripTtl,               // Longer TTL for completed trips (rarely change)
            _ => _options.DefaultTripTtl                                           // Default TTL for unknown statuses
        };
    }
} 