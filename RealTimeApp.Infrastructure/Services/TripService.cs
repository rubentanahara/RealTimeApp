using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using RealTimeApp.Application.DTOs;
using RealTimeApp.Application.Interfaces;
using RealTimeApp.Domain.Entities;
using RealTimeApp.Domain.Interfaces;

namespace RealTimeApp.Infrastructure.Services;

public class TripService : ITripService
{
    private readonly ITripRepository _tripRepository;
    private readonly IRedisCacheService _cacheService;

    public TripService(ITripRepository tripRepository, IRedisCacheService cacheService)
    {
        _tripRepository = tripRepository;
        _cacheService = cacheService;
    }

    public async Task<TripDto?> GetTripByIdAsync(Guid id)
    {
        // Try cache first - get all trips from cache and find by ID
        try
        {
            var cachedTrips = await _cacheService.GetAllTripsAsync();
            var cachedTrip = cachedTrips?.FirstOrDefault(t => t.Id == id);
            if (cachedTrip != null)
            {
                return MapToDto(cachedTrip);
            }
        }
        catch (Exception)
        {
            // If cache fails, continue to database fallback
        }

        // Fallback to database
        var trip = await _tripRepository.GetByIdAsync(id);
        return trip == null ? null : MapToDto(trip);
    }

    public async Task<IEnumerable<TripDto>> GetAllTripsAsync()
    {
        // Try cache first
        try
        {
            var cachedTrips = await _cacheService.GetAllTripsAsync();
            if (cachedTrips?.Any() == true)
            {
                return cachedTrips.Select(MapToDto);
            }
        }
        catch (Exception)
        {
            // If cache fails, continue to database fallback
        }

        // Fallback to database
        var trips = await _tripRepository.GetAllAsync();
        return trips.Select(MapToDto);
    }

    public async Task<TripDto> CreateTripAsync(string tripNumber, Guid driverId, Guid vehicleId)
    {
        var trip = new Trip
        {
            TripNumber = tripNumber,
            Status = "Created",
            StartTime = DateTime.UtcNow,
            EndTime = DateTime.UtcNow,
            DriverId = driverId,
            VehicleId = vehicleId,
            LastModified = DateTime.UtcNow,
            Version = 1
        };
        await _tripRepository.AddAsync(trip);
        
        // Cache will be updated via Service Bus flow for consistency and sequential processing
        return MapToDto(trip);
    }

    public async Task<TripDto> UpdateTripStatusAsync(Guid id, string newStatus, Guid driverId, Guid vehicleId)
    {
        var trip = await _tripRepository.GetByIdAsync(id);
        if (trip == null)
            throw new KeyNotFoundException($"Trip with ID {id} not found");

        // If driverId and vehicleId are empty/default, just update status (preserve existing IDs)
        if (driverId == Guid.Empty && vehicleId == Guid.Empty)
        {
            trip.UpdateStatus(newStatus);
        }
        else
        {
            trip.Update(newStatus, driverId, vehicleId);
        }
        
        await _tripRepository.UpdateAsync(trip);
        
        // Cache will be updated via Service Bus flow for consistency and sequential processing
        return MapToDto(trip);
    }

    public async Task<TripDto> CompleteTripAsync(Guid id)
    {
        var trip = await _tripRepository.GetByIdAsync(id);
        if (trip == null)
            throw new KeyNotFoundException($"Trip with ID {id} not found");

        trip.Complete();
        await _tripRepository.UpdateAsync(trip);
        
        // Cache will be updated via Service Bus flow for consistency and sequential processing
        return MapToDto(trip);
    }

    public async Task<TripDto?> GetTripByNumberAsync(string tripNumber)
    {
        // Try cache first, then fallback to database
        var cachedTrip = await _cacheService.GetTripAsync(tripNumber);
        if (cachedTrip != null)
        {
            return MapToDto(cachedTrip);
        }

        var trip = await _tripRepository.GetByTripNumberAsync(tripNumber);
        return trip == null ? null : MapToDto(trip);
    }

    private static TripDto MapToDto(Trip trip)
    {
        if (trip == null)
            throw new KeyNotFoundException("Trip not found");

        return new TripDto
        {
            Id = trip.Id,
            TripNumber = trip.TripNumber,
            Status = trip.Status,
            StartTime = trip.StartTime,
            EndTime = trip.EndTime,
            DriverId = trip.DriverId,
            VehicleId = trip.VehicleId,
            LastModified = trip.LastModified,
            Version = trip.Version
        };
    }
} 