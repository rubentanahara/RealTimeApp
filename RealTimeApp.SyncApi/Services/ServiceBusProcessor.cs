using System;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using RealTimeApp.Domain.Events;
using RealTimeApp.Domain.Interfaces;
using RealTimeApp.Infrastructure.Services;

namespace RealTimeApp.SyncApi.Services;

public class TripServiceBusProcessor : BackgroundService
{
    private readonly ILogger<TripServiceBusProcessor> _logger;
    private readonly IRedisCacheService _cacheService;
    private readonly ServiceBusClient _client;
    private readonly ServiceBusProcessor _processor;

    public TripServiceBusProcessor(
        ILogger<TripServiceBusProcessor> logger,
        IRedisCacheService cacheService,
        ServiceBusClient client,
        string queueName)
    {
        _logger = logger;
        _cacheService = cacheService;
        _client = client;

        var options = new ServiceBusProcessorOptions
        {
            MaxConcurrentCalls = 1,
            AutoCompleteMessages = false
        };

        _processor = _client.CreateProcessor(queueName, options);
        _processor.ProcessMessageAsync += ProcessMessagesAsync;
        _processor.ProcessErrorAsync += ProcessErrorAsync;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await _processor.StartProcessingAsync(stoppingToken);
    }

    private async Task ProcessMessagesAsync(ProcessMessageEventArgs args)
    {
        try
        {
            var messageBody = Encoding.UTF8.GetString(args.Message.Body);
            _logger.LogInformation("Received message: {MessageBody}", messageBody);

            // Parse as Event Grid event first
            using JsonDocument document = JsonDocument.Parse(messageBody);
            var root = document.RootElement;

            _logger.LogInformation("Message parsed. Root element kind: {Kind}", root.ValueKind);
            
            // Check if this is an Event Grid event
            var hasEventType = root.TryGetProperty("eventType", out var eventTypeElement);
            var hasData = root.TryGetProperty("data", out var dataElement);
            
            _logger.LogInformation("Event Grid detection: hasEventType={HasEventType}, hasData={HasData}", hasEventType, hasData);
            
            if (hasEventType && hasData)
            {
                var eventType = eventTypeElement.GetString();
                _logger.LogInformation("Processing Event Grid event of type: {EventType}", eventType);

                // Extract the trip data from the 'data' property
                var tripDataJson = dataElement.GetRawText();
                _logger.LogInformation("Trip data: {TripData}", tripDataJson);

                // Deserialize the trip data as TripChangedEvent
                var tripEvent = JsonSerializer.Deserialize<TripEventData>(tripDataJson, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                if (tripEvent == null)
                {
                    _logger.LogError("Failed to deserialize trip data");
                    await args.DeadLetterMessageAsync(args.Message);
                    return;
                }

                // Create Trip object from the event data
                var trip = new Domain.Entities.Trip
                {
                    Id = tripEvent.TripId,
                    TripNumber = tripEvent.TripNumber,
                    Status = tripEvent.Status,
                    DriverId = tripEvent.DriverId,
                    VehicleId = tripEvent.VehicleId,
                    LastModified = tripEvent.LastModified,
                    Version = tripEvent.Version
                };

                switch (tripEvent.ChangeType?.ToLowerInvariant())
                {
                    case "insert":
                    case "update":
                        await _cacheService.SetTripAsync(trip);
                        _logger.LogInformation("Successfully processed {ChangeType} event for trip {TripNumber}", 
                            tripEvent.ChangeType, tripEvent.TripNumber);
                        break;
                    case "delete":
                        await _cacheService.RemoveTripAsync(tripEvent.TripNumber);
                        _logger.LogInformation("Successfully processed delete event for trip {TripNumber}", 
                            tripEvent.TripNumber);
                        break;
                    default:
                        _logger.LogWarning("Unknown change type: {ChangeType}", tripEvent.ChangeType);
                        await args.DeadLetterMessageAsync(args.Message);
                        return;
                }
            }
            else
            {
                // Try to deserialize as direct TripChangedEvent (fallback)
                var tripEvent = JsonSerializer.Deserialize<TripChangedEvent>(messageBody, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                if (tripEvent?.Trip == null)
                {
                    _logger.LogError("Failed to deserialize message as TripChangedEvent or Trip is null");
                    await args.DeadLetterMessageAsync(args.Message);
                    return;
                }

                switch (tripEvent.ChangeType?.ToLowerInvariant())
                {
                    case "insert":
                    case "update":
                        await _cacheService.SetTripAsync(tripEvent.Trip);
                        _logger.LogInformation("Successfully processed {ChangeType} event for trip {TripNumber}", 
                            tripEvent.ChangeType, tripEvent.TripNumber);
                        break;
                    case "delete":
                        await _cacheService.RemoveTripAsync(tripEvent.TripNumber);
                        _logger.LogInformation("Successfully processed delete event for trip {TripNumber}", 
                            tripEvent.TripNumber);
                        break;
                    default:
                        _logger.LogWarning("Unknown change type: {ChangeType}", tripEvent.ChangeType);
                        await args.DeadLetterMessageAsync(args.Message);
                        return;
                }
            }

            await args.CompleteMessageAsync(args.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing message");
            await args.DeadLetterMessageAsync(args.Message);
        }
    }

    private Task ProcessErrorAsync(ProcessErrorEventArgs args)
    {
        _logger.LogError(args.Exception, "Error processing message: {ErrorSource}", args.ErrorSource);
        return Task.CompletedTask;
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        await _processor.StopProcessingAsync(cancellationToken);
        await base.StopAsync(cancellationToken);
    }
}

// Helper class to deserialize the Event Grid data payload
public class TripEventData
{
    public Guid TripId { get; set; }
    public string TripNumber { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public Guid DriverId { get; set; }
    public Guid VehicleId { get; set; }
    public DateTime LastModified { get; set; }
    public int Version { get; set; }
    public string ChangeType { get; set; } = string.Empty;
} 