using Azure.Messaging.ServiceBus;
using Microsoft.Extensions.Logging;
using RealTimeApp.Domain.Events;
using RealTimeApp.Domain.Interfaces;
using RealTimeApp.Infrastructure.Services;
using System.Text.Json;

namespace RealTimeApp.Infrastructure.Services;

public class ServiceBusSessionHandler
{
    private readonly ServiceBusClient _client;
    private readonly ServiceBusProcessor _processor;
    private readonly IRedisCacheService _cacheService;
    private readonly ILogger<ServiceBusSessionHandler> _logger;

    public ServiceBusSessionHandler(
        ServiceBusClient client,
        string queueName,
        IRedisCacheService cacheService,
        ILogger<ServiceBusSessionHandler> logger)
    {
        _client = client;
        _cacheService = cacheService;
        _logger = logger;

        var options = new ServiceBusProcessorOptions
        {
            MaxConcurrentCalls = 1,
            AutoCompleteMessages = false
        };

        _processor = _client.CreateProcessor(queueName, options);
        _processor.ProcessMessageAsync += ProcessMessagesAsync;
        _processor.ProcessErrorAsync += ProcessErrorAsync;
    }

    public async Task StartProcessingAsync()
    {
        await _processor.StartProcessingAsync();
    }

    public async Task StopProcessingAsync()
    {
        await _processor.StopProcessingAsync();
    }

    private async Task ProcessMessagesAsync(ProcessMessageEventArgs args)
    {
        try
        {
            var message = args.Message;
            var sessionId = message.SessionId;

            _logger.LogInformation("Processing message for session {SessionId}", sessionId);

            var tripChangedEvent = JsonSerializer.Deserialize<TripChangedEvent>(message.Body);
            if (tripChangedEvent == null)
            {
                _logger.LogWarning("Failed to deserialize message for session {SessionId}", sessionId);
                await args.CompleteMessageAsync(message);
                return;
            }

            switch (tripChangedEvent.ChangeType)
            {
                case "Insert":
                case "Update":
                    await _cacheService.SetTripAsync(tripChangedEvent.Trip);
                    break;
                case "Delete":
                    await _cacheService.RemoveTripAsync(tripChangedEvent.Trip.TripNumber);
                    break;
            }

            await args.CompleteMessageAsync(message);
            _logger.LogInformation("Successfully processed message for session {SessionId}", sessionId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing message for session {SessionId}", args.Message.SessionId);
            await args.DeadLetterMessageAsync(args.Message, "ProcessingError", ex.Message);
        }
    }

    private Task ProcessErrorAsync(ProcessErrorEventArgs args)
    {
        _logger.LogError(args.Exception, "Error processing message: {ErrorSource}", args.ErrorSource);
        return Task.CompletedTask;
    }
} 