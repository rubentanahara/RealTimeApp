using Azure.Messaging.ServiceBus;
using Microsoft.EntityFrameworkCore;
using RealTimeApp.Infrastructure.Configuration;
using RealTimeApp.Infrastructure.Data;
using RealTimeApp.Infrastructure.Services;
using RealTimeApp.SyncApi.Services;
using StackExchange.Redis;
using Azure.Identity;
using Microsoft.OpenApi.Models;
using Serilog;
using Serilog.Events;
using RealTimeApp.Domain.Interfaces;

var builder = WebApplication.CreateBuilder(args);

// Enable logging for Azure Identity
builder.Logging.AddConsole();
builder.Logging.SetMinimumLevel(LogLevel.Debug);

// Configure AzureCliCredential with diagnostics
var credentialOptions = new AzureCliCredentialOptions
{
    Diagnostics =
    {
         IsLoggingEnabled = true,
         IsLoggingContentEnabled = true
    }
};

var credential = new AzureCliCredential(credentialOptions);

// Add Key Vault configuration
var keyVaultName = builder.Configuration["KeyVaultName"] ?? "realtime-app-kv";
var keyVaultUri = new Uri($"https://{keyVaultName}.vault.azure.net/");

builder.Configuration.AddAzureKeyVault(keyVaultUri, credential);

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "RealTimeApp Sync API",
        Version = "v1",
        Description = "API for synchronizing trip data and handling real-time updates",
        Contact = new Microsoft.OpenApi.Models.OpenApiContact
        {
            Name = "RealTimeApp Team",
            Email = "support@realtimeapp.com"
        }
    });
});

// Validate required configuration
var requiredConfigs = new Dictionary<string, string>
{
    { "SqlConnectionString", "SQL Server connection string" },
    { "RedisConnectionString", "Redis connection string" },
    { "ServiceBusConnectionString", "Service Bus connection string" },
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
var redisConnectionString = builder.Configuration["RedisConnectionString"] 
    ?? throw new InvalidOperationException("Redis connection string is not configured");
builder.Services.AddSingleton<IConnectionMultiplexer>(sp =>
    ConnectionMultiplexer.Connect(redisConnectionString));

// Configure Redis Cache options
builder.Services.Configure<RedisCacheOptions>(
    builder.Configuration.GetSection(RedisCacheOptions.SectionName));
builder.Services.AddSingleton<IRedisCacheService, RedisCacheService>();

// Configure Azure Service Bus
builder.Services.AddSingleton(new ServiceBusClient(
    builder.Configuration["ServiceBusConnectionString"]));
builder.Services.AddSingleton<IServiceBusPublisher>(sp =>
{
    var client = sp.GetRequiredService<ServiceBusClient>();
    var logger = sp.GetRequiredService<ILogger<ServiceBusPublisher>>();
    return new ServiceBusPublisher(client, "trip-changes-queue", logger);
});

// Configure Service Bus Processor
builder.Services.AddHostedService(sp =>
{
    var logger = sp.GetRequiredService<ILogger<TripServiceBusProcessor>>();
    var cacheService = sp.GetRequiredService<IRedisCacheService>();
    var client = sp.GetRequiredService<ServiceBusClient>();
    return new TripServiceBusProcessor(
        logger,
        cacheService,
        client,
        "trip-changes-queue");
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "RealTimeApp Sync API V1");
    c.RoutePrefix = "swagger";
});

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();
