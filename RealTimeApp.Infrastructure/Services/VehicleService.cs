using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using RealTimeApp.Application.DTOs;
using RealTimeApp.Application.Interfaces;
using RealTimeApp.Domain.Entities;
using RealTimeApp.Domain.Interfaces;

namespace RealTimeApp.Infrastructure.Services;

public class VehicleService : IVehicleService
{
    private readonly IVehicleRepository _vehicleRepository;

    public VehicleService(IVehicleRepository vehicleRepository)
    {
        _vehicleRepository = vehicleRepository;
    }

    public async Task<VehicleDto?> GetVehicleByIdAsync(Guid id)
    {
        var vehicle = await _vehicleRepository.GetByIdAsync(id);
        return vehicle == null ? null : MapToDto(vehicle);
    }

    public async Task<IEnumerable<VehicleDto>> GetAllVehiclesAsync()
    {
        var vehicles = await _vehicleRepository.GetAllAsync();
        return vehicles.Select(MapToDto);
    }

    public async Task<IEnumerable<VehicleDto>> GetAvailableVehiclesAsync()
    {
        var vehicles = await _vehicleRepository.GetAvailableAsync();
        return vehicles.Select(MapToDto);
    }

    private static VehicleDto MapToDto(Vehicle vehicle)
    {
        return new VehicleDto
        {
            Id = vehicle.Id,
            LicensePlate = vehicle.LicensePlate,
            Model = vehicle.Model,
            Status = vehicle.Status,
            LastModified = vehicle.LastModified,
            Version = vehicle.Version
        };
    }
} 