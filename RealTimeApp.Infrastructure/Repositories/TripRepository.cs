using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using RealTimeApp.Domain.Entities;
using RealTimeApp.Domain.Interfaces;
using RealTimeApp.Infrastructure.Data;

namespace RealTimeApp.Infrastructure.Repositories;

public class TripRepository : ITripRepository
{
    private readonly ApplicationDbContext _context;

    public TripRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Trip?> GetByIdAsync(Guid id)
    {
        return await _context.Trips.FindAsync(id);
    }

    public async Task<IEnumerable<Trip>> GetAllAsync()
    {
        return await _context.Trips.ToListAsync();
    }

    public async Task<Trip> AddAsync(Trip trip)
    {
        await _context.Trips.AddAsync(trip);
        await _context.SaveChangesAsync();
        return trip;
    }

    public async Task UpdateAsync(Trip trip)
    {
        _context.Trips.Update(trip);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteAsync(Guid id)
    {
        var trip = await _context.Trips.FindAsync(id);
        if (trip != null)
        {
            _context.Trips.Remove(trip);
            await _context.SaveChangesAsync();
        }
    }

    public async Task<Trip?> GetByTripNumberAsync(string tripNumber)
    {
        return await _context.Trips.FirstOrDefaultAsync(t => t.TripNumber == tripNumber);
    }
} 