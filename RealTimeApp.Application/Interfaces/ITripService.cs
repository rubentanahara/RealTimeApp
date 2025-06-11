using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using RealTimeApp.Application.DTOs;

namespace RealTimeApp.Application.Interfaces;

public interface ITripService
{
    Task<TripDto?> GetTripByIdAsync(Guid id);
    Task<IEnumerable<TripDto>> GetAllTripsAsync();
    Task<TripDto> CreateTripAsync(string tripNumber, Guid driverId, Guid vehicleId);
    Task<TripDto> UpdateTripStatusAsync(Guid id, string newStatus, Guid driverId, Guid vehicleId);
    Task<TripDto> CompleteTripAsync(Guid id);
    Task<TripDto?> GetTripByNumberAsync(string tripNumber);
} 