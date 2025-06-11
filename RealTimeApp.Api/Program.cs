using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using RealTimeApp.Api.Hubs;
using RealTimeApp.Application.Interfaces;
using RealTimeApp.Infrastructure.Data;
using RealTimeApp.Infrastructure.Repositories;
using RealTimeApp.Infrastructure.Services;
using StackExchange.Redis;
using RealTimeApp.Domain.Interfaces;
using Azure.Identity;

var builder = WebApplication.CreateBuilder(args);

// Add Key Vault configuration
var keyVaultName = builder.Configuration["KeyVaultName"] ?? "realtime-app-kv";
var keyVaultUri = new Uri($"https://{keyVaultName}.vault.azure.net/");
Console.WriteLine("Before Key Vault");
builder.Configuration.AddAzureKeyVault(keyVaultUri, new DefaultAzureCredential());
Console.WriteLine("After Key Vault");

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "RealTimeApp API",
        Version = "v1",
        Description = "API for managing real-time trips and updates",
        Contact = new Microsoft.OpenApi.Models.OpenApiContact
        {
            Name = "RealTimeApp Team",
            Email = "support@realtimeapp.com"
        }
    });
});

// Configure CORS before SignalR
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowReactApp",
        builder => builder
            .WithOrigins("http://localhost:3000", "http://localhost:5173") // Add both Vite and React dev server ports
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials()
            .SetIsOriginAllowed(origin => true)); // For development only
});

// Validate required configuration
var requiredConfigs = new Dictionary<string, string>
{
    { "SqlConnectionString", "SQL Server connection string" },
    { "RedisConnectionString", "Redis connection string" },
    { "SignalRConnectionString", "SignalR connection string" },
    { "EventGridTopicEndpoint", "Event Grid topic endpoint" },
    { "EventGridTopicKey", "Event Grid topic key" }
};

var missingConfigs = requiredConfigs
    .Where(config => string.IsNullOrEmpty(builder.Configuration[config.Key]))
    .Select(config => config.Value)
    .ToList();

if (missingConfigs.Any())
{
    throw new InvalidOperationException(
        $"Missing required configuration in Key Vault: {string.Join(", ", missingConfigs)}");
}

// Configure SQL Server
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration["SqlConnectionString"]));

// Configure Redis
var redisConfig = builder.Configuration["RedisConnectionString"];
if (string.IsNullOrEmpty(redisConfig))
    throw new InvalidOperationException("Missing Redis connection string in configuration.");
builder.Services.AddSingleton<IConnectionMultiplexer>(sp =>
    ConnectionMultiplexer.Connect(redisConfig));
builder.Services.AddScoped<IRedisCacheService, RedisCacheService>();

// Configure SignalR
var signalRBuilder = builder.Services.AddSignalR(options =>
{
    options.EnableDetailedErrors = true;
    options.MaximumReceiveMessageSize = 102400; // 100 KB
});

// Use Azure SignalR in production, local SignalR in development
if (!builder.Environment.IsDevelopment())
{
    signalRBuilder.AddAzureSignalR(builder.Configuration["SignalRConnectionString"]);
}

// Configure Repositories
builder.Services.AddScoped<ITripRepository, TripRepository>();
builder.Services.AddScoped<IDriverRepository, DriverRepository>();
builder.Services.AddScoped<IVehicleRepository, VehicleRepository>();

// Configure Services
builder.Services.AddScoped<ITripService, TripService>();
builder.Services.AddScoped<IDriverService, DriverService>();
builder.Services.AddScoped<IVehicleService, VehicleService>();
builder.Services.AddScoped<IEventGridService, EventGridService>();

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "RealTimeApp API V1");
        c.RoutePrefix = "swagger";
    });
}

// Important: Use CORS before other middleware
app.UseCors("AllowReactApp");

// Only use HTTPS redirection in production
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseAuthorization();

// Map controllers and SignalR hub
app.MapControllers();
app.MapHub<TripHub>("/tripHub");

app.Run();
