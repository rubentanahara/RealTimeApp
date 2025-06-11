using Microsoft.AspNetCore.SignalR;

namespace RealTimeApp.Api.Hubs;

public class TripHub : Hub<ITripHubClient>
{
    public async Task JoinTripGroup(string tripNumber)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"trip-{tripNumber}");
    }

    public async Task LeaveTripGroup(string tripNumber)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"trip-{tripNumber}");
    }
} 
