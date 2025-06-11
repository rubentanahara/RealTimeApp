using System.Text.Json;
using Azure;
using Azure.Messaging.EventGrid;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using RealTimeApp.Application.Interfaces;
using RealTimeApp.Domain.Events;

namespace RealTimeApp.Infrastructure.Services;

public class EventGridService : IEventGridService
{
    private readonly EventGridPublisherClient _client;
    private readonly ILogger<EventGridService> _logger;
    private readonly string _topicEndpoint;

    public EventGridService(IConfiguration configuration, ILogger<EventGridService> logger)
    {
        _logger = logger;
        
        // Get Event Grid configuration from Key Vault
        _topicEndpoint = configuration["EventGridTopicEndpoint"] 
            ?? throw new InvalidOperationException("EventGridTopicEndpoint not found in configuration");
        
        var topicKey = configuration["EventGridTopicKey"] 
            ?? throw new InvalidOperationException("EventGridTopicKey not found in configuration");

        // Initialize Event Grid client
        _client = new EventGridPublisherClient(new Uri(_topicEndpoint), new AzureKeyCredential(topicKey));
        
        _logger.LogInformation("Event Grid service initialized with endpoint: {Endpoint}", _topicEndpoint);
    }

    public async Task PublishTripEventAsync(TripChangedEvent tripEvent)
    {
        try
        {
            // Create Event Grid event
            var eventGridEvent = new EventGridEvent(
                subject: $"trips/{tripEvent.TripNumber}",
                eventType: $"Trip.{tripEvent.ChangeType}",
                dataVersion: "1.0",
                data: new
                {
                    TripId = tripEvent.TripId,
                    TripNumber = tripEvent.TripNumber,
                    Status = tripEvent.Status,
                    DriverId = tripEvent.Trip?.DriverId,
                    VehicleId = tripEvent.Trip?.VehicleId,
                    LastModified = tripEvent.LastModified,
                    Version = tripEvent.Version,
                    ChangeType = tripEvent.ChangeType,
                    Timestamp = DateTime.UtcNow
                });

            // Publish to Event Grid
            await _client.SendEventAsync(eventGridEvent);
            
            _logger.LogInformation(
                "Published Event Grid event: TripId={TripId}, TripNumber={TripNumber}, ChangeType={ChangeType}", 
                tripEvent.TripId, 
                tripEvent.TripNumber, 
                tripEvent.ChangeType);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, 
                "Failed to publish Event Grid event: TripId={TripId}, TripNumber={TripNumber}, ChangeType={ChangeType}", 
                tripEvent.TripId, 
                tripEvent.TripNumber, 
                tripEvent.ChangeType);
            
            // Don't throw - we don't want Event Grid failures to break trip creation
            // Consider implementing retry logic or dead letter handling here
        }
    }
} 