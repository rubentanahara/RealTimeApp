using System.Threading.Tasks;
using RealTimeApp.Domain.Events;

namespace RealTimeApp.Domain.Interfaces;

public interface IServiceBusPublisher
{
    Task PublishTripChangeAsync(TripChangedEvent tripEvent);
} 