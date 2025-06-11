using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using RealTimeApp.Domain.Entities;

namespace RealTimeApp.Domain.Interfaces;

public interface IDriverRepository
{
    Task<Driver?> GetByIdAsync(Guid id);
    Task<IEnumerable<Driver>> GetAllAsync();
    Task<IEnumerable<Driver>> GetAvailableAsync();
    Task<Driver> AddAsync(Driver driver);
    Task UpdateAsync(Driver driver);
    Task DeleteAsync(Guid id);
} 