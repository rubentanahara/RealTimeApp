using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using RealTimeApp.Domain.Entities;

namespace RealTimeApp.Domain.Interfaces;

public interface IRedisCacheService
{
    Task<Trip?> GetTripAsync(string tripNumber);
    Task SetTripAsync(Trip trip);
    Task SetTripAsync(Trip trip, TimeSpan? expiry);
    Task RemoveTripAsync(string tripNumber);
    Task<IEnumerable<Trip>> GetAllTripsAsync();
} 