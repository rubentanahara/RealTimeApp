using Microsoft.EntityFrameworkCore;
using RealTimeApp.Domain.Entities;

namespace RealTimeApp.Infrastructure.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<Trip> Trips { get; set; }
    public DbSet<Driver> Drivers { get; set; }
    public DbSet<Vehicle> Vehicles { get; set; }
    public DbSet<TripStatus> TripStatuses { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Trip>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.TripNumber).IsRequired();
            entity.Property(e => e.Status).IsRequired();
            entity.Property(e => e.DriverId).IsRequired();
            entity.Property(e => e.VehicleId).IsRequired();
            entity.Property(e => e.LastModified).IsRequired();
            entity.Property(e => e.Version).IsRequired();

            // Configure CDC
            entity.ToTable("Trips", schema: "dbo");
            entity.HasAnnotation("SqlServer:EnableCDC", true);

            // Configure relationships
            entity.HasOne<Driver>()
                .WithMany()
                .HasForeignKey(e => e.DriverId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne<Vehicle>()
                .WithMany()
                .HasForeignKey(e => e.VehicleId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Driver>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).IsRequired();
            entity.Property(e => e.LicenseNumber).IsRequired();
            entity.Property(e => e.Status).IsRequired();
            entity.Property(e => e.LastModified).IsRequired();
            entity.Property(e => e.Version).IsRequired();

            // Configure CDC
            entity.ToTable("Drivers", schema: "dbo");
            entity.HasAnnotation("SqlServer:EnableCDC", true);
        });

        modelBuilder.Entity<Vehicle>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.LicensePlate).IsRequired();
            entity.Property(e => e.Model).IsRequired();
            entity.Property(e => e.Status).IsRequired();
            entity.Property(e => e.LastModified).IsRequired();
            entity.Property(e => e.Version).IsRequired();

            // Configure CDC
            entity.ToTable("Vehicles", schema: "dbo");
            entity.HasAnnotation("SqlServer:EnableCDC", true);
        });

        modelBuilder.Entity<TripStatus>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).IsRequired();
            entity.Property(e => e.Description).IsRequired();
            entity.Property(e => e.CreatedAt).IsRequired();
            entity.Property(e => e.UpdatedAt).IsRequired();
            entity.ToTable("TripStatuses", schema: "dbo");
            entity.HasAnnotation("SqlServer:EnableCDC", true);
        });
    }
} 