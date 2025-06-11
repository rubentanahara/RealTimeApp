using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using RealTimeApp.Domain.Entities;

namespace RealTimeApp.Domain.Interfaces;

public interface ITripRepository
{
    Task<Trip?> GetByIdAsync(Guid id);
    Task<IEnumerable<Trip>> GetAllAsync();
    Task<Trip> AddAsync(Trip trip);
    Task UpdateAsync(Trip trip);
    Task DeleteAsync(Guid id);
    Task<Trip?> GetByTripNumberAsync(string tripNumber);
} 