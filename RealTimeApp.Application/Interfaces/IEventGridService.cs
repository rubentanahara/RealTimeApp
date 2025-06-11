using RealTimeApp.Domain.Events;

namespace RealTimeApp.Application.Interfaces;

public interface IEventGridService
{
    Task PublishTripEventAsync(TripChangedEvent tripEvent);
} 