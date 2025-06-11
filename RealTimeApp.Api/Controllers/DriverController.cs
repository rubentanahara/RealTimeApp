using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using RealTimeApp.Application.DTOs;
using RealTimeApp.Application.Interfaces;

namespace RealTimeApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DriverController : ControllerBase
{
    private readonly IDriverService _driverService;

    public DriverController(IDriverService driverService)
    {
        _driverService = driverService;
    }

    /// <summary>
    /// Get all drivers
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<DriverDto>>> GetAllDrivers()
    {
        var drivers = await _driverService.GetAllDriversAsync();
        return Ok(drivers);
    }

    /// <summary>
    /// Get available drivers for trip assignment
    /// </summary>
    [HttpGet("available")]
    public async Task<ActionResult<IEnumerable<DriverDto>>> GetAvailableDrivers()
    {
        var drivers = await _driverService.GetAvailableDriversAsync();
        return Ok(drivers);
    }

    /// <summary>
    /// Get driver by ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<DriverDto>> GetDriverById(Guid id)
    {
        var driver = await _driverService.GetDriverByIdAsync(id);
        if (driver == null)
            return NotFound();

        return Ok(driver);
    }
} 