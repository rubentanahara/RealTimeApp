using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using RealTimeApp.Application.DTOs;
using RealTimeApp.Application.Interfaces;

namespace RealTimeApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class VehicleController : ControllerBase
{
    private readonly IVehicleService _vehicleService;

    public VehicleController(IVehicleService vehicleService)
    {
        _vehicleService = vehicleService;
    }

    /// <summary>
    /// Get all vehicles
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<VehicleDto>>> GetAllVehicles()
    {
        var vehicles = await _vehicleService.GetAllVehiclesAsync();
        return Ok(vehicles);
    }

    /// <summary>
    /// Get available vehicles for trip assignment
    /// </summary>
    [HttpGet("available")]
    public async Task<ActionResult<IEnumerable<VehicleDto>>> GetAvailableVehicles()
    {
        var vehicles = await _vehicleService.GetAvailableVehiclesAsync();
        return Ok(vehicles);
    }

    /// <summary>
    /// Get vehicle by ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<VehicleDto>> GetVehicleById(Guid id)
    {
        var vehicle = await _vehicleService.GetVehicleByIdAsync(id);
        if (vehicle == null)
            return NotFound();

        return Ok(vehicle);
    }
} 