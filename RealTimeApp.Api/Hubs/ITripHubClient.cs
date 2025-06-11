using RealTimeApp.Domain.Events;

namespace RealTimeApp.Api.Hubs;

public interface ITripHubClient
{
    Task ReceiveTripUpdate(TripChangedEvent tripEvent);
} 