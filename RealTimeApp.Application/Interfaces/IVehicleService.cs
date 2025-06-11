using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using RealTimeApp.Application.DTOs;

namespace RealTimeApp.Application.Interfaces;

public interface IVehicleService
{
    Task<VehicleDto?> GetVehicleByIdAsync(Guid id);
    Task<IEnumerable<VehicleDto>> GetAllVehiclesAsync();
    Task<IEnumerable<VehicleDto>> GetAvailableVehiclesAsync();
} 