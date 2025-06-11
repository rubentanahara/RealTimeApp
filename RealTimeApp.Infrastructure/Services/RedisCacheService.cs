using System;
using System.Text.Json;
using System.Threading.Tasks;
using StackExchange.Redis;
using RealTimeApp.Domain.Entities;
using RealTimeApp.Domain.Interfaces;

namespace RealTimeApp.Infrastructure.Services;

public class RedisCacheService : IRedisCacheService
{
    private readonly IConnectionMultiplexer _redis;
    private readonly IDatabase _db;
    private const string TripKeyPrefix = "trip:";

    public RedisCacheService(IConnectionMultiplexer redis)
    {
        _redis = redis;
        _db = redis.GetDatabase();
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
        var key = $"{TripKeyPrefix}{trip.TripNumber}";
        var value = JsonSerializer.Serialize(trip);
        
        await _db.StringSetAsync(key, value);
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
} 