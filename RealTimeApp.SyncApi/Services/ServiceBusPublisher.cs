using System.Text;
using System.Text.Json;
using Azure.Messaging.ServiceBus;
using RealTimeApp.Domain.Events;
using RealTimeApp.Domain.Interfaces;

namespace RealTimeApp.SyncApi.Services;

public class ServiceBusPublisher : IServiceBusPublisher
{
    private readonly ServiceBusClient _client;
    private readonly string _queueName;
    private readonly ILogger<ServiceBusPublisher> _logger;
    private ServiceBusSender? _sender;

    public ServiceBusPublisher(ServiceBusClient client, string queueName, ILogger<ServiceBusPublisher> logger)
    {
        _client = client ?? throw new ArgumentNullException(nameof(client));
        _queueName = queueName ?? throw new ArgumentNullException(nameof(queueName));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    public async Task PublishTripChangeAsync(TripChangedEvent tripEvent)
    {
        try
        {
            _sender ??= _client.CreateSender(_queueName);

            var messageBody = JsonSerializer.Serialize(tripEvent);
            var message = new ServiceBusMessage(Encoding.UTF8.GetBytes(messageBody))
            {
                MessageId = Guid.NewGuid().ToString(),
                ContentType = "application/json",
                Subject = $"Trip.{tripEvent.ChangeType}",
                ApplicationProperties =
                {
                    { "EventType", "TripChanged" },
                    { "TripId", tripEvent.TripId.ToString() },
                    { "TripNumber", tripEvent.TripNumber },
                    { "ChangeType", tripEvent.ChangeType }
                }
            };

            await _sender.SendMessageAsync(message);
            _logger.LogInformation(
                "Published trip change event to Service Bus. TripId: {TripId}, ChangeType: {ChangeType}",
                tripEvent.TripId,
                tripEvent.ChangeType);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Error publishing trip change event to Service Bus. TripId: {TripId}, ChangeType: {ChangeType}",
                tripEvent.TripId,
                tripEvent.ChangeType);
            throw;
        }
    }
} 
