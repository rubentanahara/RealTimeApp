using Azure.Messaging.EventGrid;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using RealTimeApp.Infrastructure.Services;
using RealTimeApp.Domain.Entities;
using RealTimeApp.Domain.Events;
using RealTimeApp.Domain.Interfaces;
using System.Text.Json;

namespace RealTimeApp.SyncApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EventGridController : ControllerBase
{
    private readonly ILogger<EventGridController> _logger;
    private readonly IServiceBusPublisher _publisher;

    public EventGridController(ILogger<EventGridController> logger, IServiceBusPublisher publisher)
    {
        _logger = logger;
        _publisher = publisher;
    }

    [HttpPost]
    public async Task<IActionResult> Post([FromBody] JsonElement events)
    {
        _logger.LogInformation("Received Event Grid events: {Events}", events.ToString());

        // Event Grid sends an array of events
        foreach (var eventElement in events.EnumerateArray())
        {
            var eventType = eventElement.GetProperty("eventType").GetString();

            // Handle Event Grid subscription validation
            if (eventType == "Microsoft.EventGrid.SubscriptionValidationEvent")
            {
                var data = eventElement.GetProperty("data");
                var validationCode = data.GetProperty("validationCode").GetString();
                _logger.LogInformation("Event Grid subscription validation event received.");
                return Ok(new { validationResponse = validationCode });
            }

            // Handle SQL Database change events
            if (eventType == "Microsoft.SqlServer.DatabaseChange")
            {
                try
                {
                    var data = eventElement.GetProperty("data");
                    var operation = data.GetProperty("operation").GetString();
                    var tableName = data.GetProperty("tableName").GetString();

                    if (tableName == "Trips")
                    {
                        var tripData = data.GetProperty("data");
                        var tripNumber = tripData.GetProperty("TripNumber").GetString();
                        var status = tripData.GetProperty("Status").GetString();

                        if (string.IsNullOrEmpty(tripNumber) || string.IsNullOrEmpty(status))
                        {
                            _logger.LogWarning("Received trip data with null or empty TripNumber or Status");
                            continue;
                        }

                        var trip = new Trip
                        {
                            TripNumber = tripNumber,
                            Status = status,
                            StartTime = DateTime.UtcNow,
                            EndTime = null,
                            DriverId = tripData.GetProperty("DriverId").GetGuid(),
                            VehicleId = tripData.GetProperty("VehicleId").GetGuid(),
                            LastModified = DateTime.UtcNow,
                            Version = 1
                        };

                        var changeType = operation?.ToLowerInvariant() switch
                        {
                            "insert" => "Insert",
                            "update" => "Update",
                            "delete" => "Delete",
                            _ => "Unknown"
                        };

                        var tripChangedEvent = new TripChangedEvent
                        {
                            Trip = trip,
                            TripId = trip.Id,
                            TripNumber = trip.TripNumber,
                            Status = trip.Status,
                            LastModified = trip.LastModified,
                            Version = trip.Version,
                            ChangeType = changeType
                        };

                        await _publisher.PublishTripChangeAsync(tripChangedEvent);
                        _logger.LogInformation("Forwarded SQL Database change event to Service Bus: {Operation} on {TableName}", 
                            operation, tableName);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error processing SQL Database change event");
                    return StatusCode(500, "Error processing event");
                }
            }
        }
        return Ok();
    }
} 