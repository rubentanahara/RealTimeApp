using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using RealTimeApp.Api.Hubs;
using RealTimeApp.Application.DTOs;
using RealTimeApp.Application.Interfaces;
using RealTimeApp.Domain.Events;

namespace RealTimeApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TripController : ControllerBase
{
    private readonly ITripService _tripService;
    private readonly IHubContext<TripHub, ITripHubClient> _hubContext;
    private readonly IEventGridService _eventGridService;

    public TripController(
        ITripService tripService, 
        IHubContext<TripHub, ITripHubClient> hubContext,
        IEventGridService eventGridService)
    {
        _tripService = tripService;
        _hubContext = hubContext;
        _eventGridService = eventGridService;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<TripDto>>> GetAllTrips()
    {
        // Uses Redis cache-first strategy with database fallback
        // Cache updates handled via Service Bus for consistency across services
        var trips = await _tripService.GetAllTripsAsync();
        return Ok(trips);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<TripDto>> GetTripById(Guid id)
    {
        // Uses Redis cache-first strategy with database fallback
        // Cache updates handled via Service Bus for consistency across services
        var trip = await _tripService.GetTripByIdAsync(id);
        if (trip == null)
            return NotFound();

        return Ok(trip);
    }

    [HttpGet("number/{tripNumber}")]
    public async Task<ActionResult<TripDto>> GetTripByNumber(string tripNumber)
    {
        // Uses Redis cache-first strategy with database fallback
        // Cache updates handled via Service Bus for consistency across services
        var trip = await _tripService.GetTripByNumberAsync(tripNumber);
        if (trip == null)
            return NotFound();

        return Ok(trip);
    }

    [HttpPost]
    public async Task<ActionResult<TripDto>> CreateTrip([FromBody] CreateTripRequest request)
    {
        var trip = await _tripService.CreateTripAsync(request.TripNumber, request.DriverId, request.VehicleId);
        await NotifyTripChangeAsync(trip, "Insert");
        return CreatedAtAction(nameof(GetTripById), new { id = trip.Id }, trip);
    }

    [HttpPut("{id}/status")]
    public async Task<ActionResult<TripDto>> UpdateTripStatus(Guid id, [FromBody] UpdateTripStatusRequest request)
    {
        try
        {
            var driverId = request.DriverId ?? Guid.Empty;
            var vehicleId = request.VehicleId ?? Guid.Empty;
            var trip = await _tripService.UpdateTripStatusAsync(id, request.Status, driverId, vehicleId);
            await NotifyTripChangeAsync(trip, "Update");
            return Ok(trip);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    [HttpPut("{id}/complete")]
    public async Task<ActionResult<TripDto>> CompleteTrip(Guid id)
    {
        try
        {
            var trip = await _tripService.CompleteTripAsync(id);
            await NotifyTripChangeAsync(trip, "Update");
            return Ok(trip);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    private async Task NotifyTripChangeAsync(TripDto trip, string changeType)
    {
        var tripEvent = new TripChangedEvent
        {
            Trip = new Domain.Entities.Trip
            {
                TripNumber = trip.TripNumber,
                Status = trip.Status,
                StartTime = trip.StartTime,
                EndTime = trip.EndTime,
                DriverId = trip.DriverId,
                VehicleId = trip.VehicleId,
                LastModified = trip.LastModified,
                Version = trip.Version
            },
            TripId = trip.Id,
            TripNumber = trip.TripNumber,
            Status = trip.Status,
            LastModified = trip.LastModified,
            Version = trip.Version,
            ChangeType = changeType
        };

        // Send to SignalR for real-time updates
        await _hubContext.Clients.Group($"trip-{trip.TripNumber}").ReceiveTripUpdate(tripEvent);
        
        // Publish to Event Grid for backend processing
        await _eventGridService.PublishTripEventAsync(tripEvent);
    }
}

public class CreateTripRequest
{
    public required string TripNumber { get; set; }
    public Guid DriverId { get; set; }
    public Guid VehicleId { get; set; }
}

public class UpdateTripStatusRequest
{
    public required string Status { get; set; }
    public Guid? DriverId { get; set; }
    public Guid? VehicleId { get; set; }
} 
