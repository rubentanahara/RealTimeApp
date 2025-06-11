using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using RealTimeApp.Application.DTOs;
using RealTimeApp.Application.Interfaces;
using RealTimeApp.Domain.Entities;
using RealTimeApp.Domain.Interfaces;

namespace RealTimeApp.Infrastructure.Services;

public class DriverService : IDriverService
{
    private readonly IDriverRepository _driverRepository;

    public DriverService(IDriverRepository driverRepository)
    {
        _driverRepository = driverRepository;
    }

    public async Task<DriverDto?> GetDriverByIdAsync(Guid id)
    {
        var driver = await _driverRepository.GetByIdAsync(id);
        return driver == null ? null : MapToDto(driver);
    }

    public async Task<IEnumerable<DriverDto>> GetAllDriversAsync()
    {
        var drivers = await _driverRepository.GetAllAsync();
        return drivers.Select(MapToDto);
    }

    public async Task<IEnumerable<DriverDto>> GetAvailableDriversAsync()
    {
        var drivers = await _driverRepository.GetAvailableAsync();
        return drivers.Select(MapToDto);
    }

    private static DriverDto MapToDto(Driver driver)
    {
        return new DriverDto
        {
            Id = driver.Id,
            Name = driver.Name,
            LicenseNumber = driver.LicenseNumber,
            Status = driver.Status,
            LastModified = driver.LastModified,
            Version = driver.Version
        };
    }
} 