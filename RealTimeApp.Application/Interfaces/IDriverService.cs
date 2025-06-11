using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using RealTimeApp.Application.DTOs;

namespace RealTimeApp.Application.Interfaces;

public interface IDriverService
{
    Task<DriverDto?> GetDriverByIdAsync(Guid id);
    Task<IEnumerable<DriverDto>> GetAllDriversAsync();
    Task<IEnumerable<DriverDto>> GetAvailableDriversAsync();
} 