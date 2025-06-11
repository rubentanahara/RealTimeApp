# Azure Integration Guide: Real-Time Application

This guide documents the integration of Azure services (Event Grid, Service Bus, and Key Vault) in our real-time application, including troubleshooting steps and monitoring commands.

## Table of Contents
1. [Service Bus Configuration](#service-bus-configuration)
2. [Event Grid Integration](#event-grid-integration)
3. [Key Vault Secrets Management](#key-vault-secrets-management)
4. [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
5. [Local Testing Guide](#local-testing-guide)

## Service Bus Configuration

### Issue: Queue Not Found
Initially, we encountered an error when trying to access the Service Bus queue:
```
The messaging entity 'sb://realtimeappbus.servicebus.windows.net/trip-changes' could not be found.
```

### Investigation
We checked the existing Service Bus namespace and queues:
```bash
# List Service Bus namespaces
az servicebus namespace list --query "[].{Name:name, ResourceGroup:resourceGroup}" -o table

# List queues in the namespace
az servicebus queue list --namespace-name realtimeappbus --resource-group realtime-app-rg --query "[].{Name:name}" -o table
```

### Resolution
We found that the queue was named `trip-changes-queue` instead of `trip-changes`. We updated our code to use the correct queue name:
```csharp
// In Program.cs
return new ServiceBusPublisher(client, "trip-changes-queue");
```

## Event Grid Integration

### Issue: Event Processing Errors
We encountered issues with event processing in the `EventGridController`:
1. Incorrect event type handling
2. Trip entity creation issues
3. JSON deserialization problems

### Investigation
We checked the Event Grid topic configuration:
```bash
# Get Event Grid topic endpoint
az eventgrid topic show --name sql-changes-topic --resource-group realtime-app-rg --query "endpoint" -o tsv

# Get Event Grid topic key
az eventgrid topic key list --name sql-changes-topic --resource-group realtime-app-rg --query "key1" -o tsv
```

### Resolution
1. Updated `TripChangedEvent` to support JSON deserialization:
```csharp
public class TripChangedEvent
{
    public Trip Trip { get; set; }
    public Guid TripId { get; set; }
    public string TripNumber { get; set; }
    public string Status { get; set; }
    public DateTime LastModified { get; set; }
    public int Version { get; set; }
    public string ChangeType { get; set; }

    // Added parameterless constructor for deserialization
    public TripChangedEvent() { }

    public TripChangedEvent(Trip trip, string changeType)
    {
        Trip = trip;
        TripId = trip.Id;
        TripNumber = trip.TripNumber;
        Status = trip.Status;
        LastModified = trip.LastModified;
        Version = trip.Version;
        ChangeType = changeType;
    }
}
```

2. Updated `EventGridController` to handle SQL Database change events correctly:
```csharp
if (eventType == "Microsoft.SqlServer.DatabaseChange")
{
    var data = eventElement.GetProperty("data");
    var operation = data.GetProperty("operation").GetString();
    var tableName = data.GetProperty("tableName").GetString();

    if (tableName == "Trips")
    {
        var tripData = data.GetProperty("data");
        var trip = new Trip(
            id: tripData.GetProperty("Id").GetGuid(),
            tripNumber: tripData.GetProperty("TripNumber").GetString(),
            status: tripData.GetProperty("Status").GetString(),
            lastModified: DateTime.UtcNow,
            version: 1,
            driverId: tripData.GetProperty("DriverId").GetString(),
            vehicleId: tripData.GetProperty("VehicleId").GetString()
        );
        // ... process the event
    }
}
```

## Key Vault Secrets Management

### Issue: Connection String Format
We encountered issues with the SignalR connection string format:
```
The connection string is missing the required 'Version=1.0;' part.
```

### Resolution
Updated the connection string in Key Vault:
```bash
# Update SignalR connection string
az keyvault secret set --vault-name realtime-app-kv --name SignalR --value "Version=1.0;Endpoint=..."

# Update Service Bus connection string
az keyvault secret set --vault-name realtime-app-kv --name ServiceBus --value "Endpoint=..."
```

## Monitoring and Troubleshooting

### Event Grid Monitoring
```bash
# Monitor Event Grid metrics
az monitor metrics list \
    --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/realtime-app-rg/providers/Microsoft.EventGrid/topics/sql-changes-topic" \
    --metric "PublishSuccessCount,PublishFailCount,DeliverySuccessCount,DeliveryAttemptFailCount" \
    --interval PT1H
```

### Service Bus Monitoring
```bash
# Check queue status
az servicebus queue show \
    --namespace-name realtimeappbus \
    --resource-group realtime-app-rg \
    --name trip-changes-queue \
    --query "{MessageCount:messageCount,SizeInBytes:sizeInBytes,Status:status,UpdatedAt:updatedAt}"
```

### Testing Event Grid Integration
```bash
# Send test event to Event Grid
curl -X POST \
    -H "aeg-sas-key: YOUR_KEY" \
    -H "Content-Type: application/json" \
    -d '[{
        "id": "test-event-id",
        "subject": "/subscriptions/.../databases/RealTimeAppDb",
        "eventType": "Microsoft.SqlServer.DatabaseChange",
        "eventTime": "2024-03-10T01:00:00Z",
        "dataVersion": "1.0",
        "data": {
            "operation": "INSERT",
            "tableName": "Trips",
            "data": {
                "Id": 1,
                "Name": "Test Trip",
                "Description": "Test Description",
                "StartDate": "2024-03-10T01:00:00Z",
                "EndDate": "2024-03-11T01:00:00Z",
                "Status": "Active"
            }
        }
    }]' \
    https://sql-changes-topic.westus2-1.eventgrid.azure.net/api/events
```

## Local Testing Guide

### Prerequisites

1. **Azure CLI**
   ```bash
   # Verify Azure CLI installation
   az --version
   
   # Login to Azure
   az login
   ```

2. **.NET SDK**
   ```bash
   # Verify .NET SDK installation
   dotnet --version
   ```

3. **Required Azure Resources**
   - Service Bus namespace with queue
   - Event Grid topic
   - Key Vault with secrets
   - SQL Database
   - Redis Cache

### Step 1: Verify Azure Resources

```bash
# Check Service Bus queue
az servicebus queue show \
    --namespace-name realtimeappbus \
    --resource-group realtime-app-rg \
    --name trip-changes-queue

# Check Event Grid topic
az eventgrid topic show \
    --name sql-changes-topic \
    --resource-group realtime-app-rg

# Check Key Vault secrets
az keyvault secret list \
    --vault-name realtime-app-kv \
    --query "[].{Name:name, Enabled:attributes.enabled}" -o table
```

### Step 2: Configure Local Environment

1. **Update appsettings.json**
   ```json
   {
     "ConnectionStrings": {
       "ServiceBus": "",
       "SignalR": "",
       "SqlServer": "",
       "Redis": ""
     },
     "EventGrid": {
       "TopicEndpoint": "",
       "TopicKey": ""
     }
   }
   ```

2. **Set up Key Vault references**
   ```bash
   # Get Service Bus connection string
   az keyvault secret show \
       --vault-name realtime-app-kv \
       --name ServiceBus \
       --query "value" -o tsv

   # Get SignalR connection string
   az keyvault secret show \
       --vault-name realtime-app-kv \
       --name SignalR \
       --query "value" -o tsv

   # Get SQL connection string
   az keyvault secret show \
       --vault-name realtime-app-kv \
       --name SqlServer \
       --query "value" -o tsv

   # Get Redis connection string
   az keyvault secret show \
       --vault-name realtime-app-kv \
       --name Redis \
       --query "value" -o tsv
   ```

### Step 3: Run the Applications

1. **Start the API Project**
   ```bash
   cd RealTimeApp.Api
   dotnet run
   ```

2. **Start the SyncApi Project**
   ```bash
   cd RealTimeApp.SyncApi
   dotnet run
   ```

3. **Start the Web Project**
   ```bash
   cd RealTimeApp.Web
   dotnet run
   ```

### Step 4: Test the Integration

1. **Test Event Grid Integration**
   ```bash
   # Get Event Grid topic endpoint and key
   ENDPOINT=$(az eventgrid topic show \
       --name sql-changes-topic \
       --resource-group realtime-app-rg \
       --query "endpoint" -o tsv)
   
   KEY=$(az eventgrid topic key list \
       --name sql-changes-topic \
       --resource-group realtime-app-rg \
       --query "key1" -o tsv)

   # Send test event
   curl -X POST \
       -H "aeg-sas-key: $KEY" \
       -H "Content-Type: application/json" \
       -d '[{
           "id": "test-event-id",
           "subject": "/subscriptions/.../databases/RealTimeAppDb",
           "eventType": "Microsoft.SqlServer.DatabaseChange",
           "eventTime": "2024-03-10T01:00:00Z",
           "dataVersion": "1.0",
           "data": {
               "operation": "INSERT",
               "tableName": "Trips",
               "data": {
                   "Id": 1,
                   "Name": "Test Trip",
                   "Description": "Test Description",
                   "StartDate": "2024-03-10T01:00:00Z",
                   "EndDate": "2024-03-11T01:00:00Z",
                   "Status": "Active"
               }
           }
       }]' \
       $ENDPOINT
   ```

2. **Monitor the Results**
   ```bash
   # Check Service Bus queue
   az servicebus queue show \
       --namespace-name realtimeappbus \
       --resource-group realtime-app-rg \
       --name trip-changes-queue \
       --query "{MessageCount:messageCount,SizeInBytes:sizeInBytes,Status:status,UpdatedAt:updatedAt}"

   # Check Event Grid metrics
   az monitor metrics list \
       --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/realtime-app-rg/providers/Microsoft.EventGrid/topics/sql-changes-topic" \
       --metric "PublishSuccessCount,PublishFailCount,DeliverySuccessCount,DeliveryAttemptFailCount" \
       --interval PT1H
   ```

### Step 5: Verify the Flow

1. **Event Grid to Service Bus**
   - Event Grid receives the test event
   - Event Grid delivers to SyncApi
   - SyncApi processes and publishes to Service Bus

2. **Service Bus to Redis**
   - Service Bus processor receives message
   - Updates Redis cache
   - Logs success/failure

3. **SignalR to Web Client**
   - API receives updates
   - Broadcasts to connected clients
   - Web client displays updates

### Troubleshooting

1. **Event Grid Issues**
   ```bash
   # Check Event Grid topic status
   az eventgrid topic show \
       --name sql-changes-topic \
       --resource-group realtime-app-rg \
       --query "provisioningState"
   ```

2. **Service Bus Issues**
   ```bash
   # Check queue status
   az servicebus queue show \
       --namespace-name realtimeappbus \
       --resource-group realtime-app-rg \
       --name trip-changes-queue \
       --query "status"
   ```

3. **Key Vault Issues**
   ```bash
   # Check secret status
   az keyvault secret show \
       --vault-name realtime-app-kv \
       --name SignalR \
       --query "attributes.enabled"
   ```

4. **Application Logs**
   - Check console output for each application
   - Look for error messages and exceptions
   - Verify connection strings and configurations

### Common Issues and Solutions

1. **Connection String Issues**
   - Verify Key Vault secrets are properly formatted
   - Check if secrets are enabled
   - Ensure proper access permissions

2. **Event Grid Delivery Issues**
   - Verify topic endpoint and key
   - Check event schema matches expected format
   - Monitor delivery metrics

3. **Service Bus Processing Issues**
   - Check queue exists and is active
   - Verify message format
   - Monitor queue metrics

4. **Redis Cache Issues**
   - Verify connection string
   - Check cache service is running
   - Monitor cache operations

## Common Issues and Solutions

1. **Service Bus Queue Not Found**
   - Cause: Incorrect queue name in code
   - Solution: Verify queue name using `az servicebus queue list`

2. **Event Grid Event Processing**
   - Cause: Incorrect event type and data structure
   - Solution: Update controller to handle correct event type and data format

3. **JSON Deserialization**
   - Cause: Missing parameterless constructor
   - Solution: Add parameterless constructor and make properties settable

4. **Connection String Format**
   - Cause: Missing required parts in connection string
   - Solution: Update connection string format in Key Vault

## Best Practices

1. **Service Bus**
   - Use consistent queue naming conventions
   - Monitor queue metrics regularly
   - Implement proper error handling and dead-letter queues

2. **Event Grid**
   - Validate event types and data structure
   - Implement proper error handling
   - Monitor delivery success/failure metrics

3. **Key Vault**
   - Use proper connection string formats
   - Rotate keys regularly
   - Monitor access patterns

4. **Monitoring**
   - Set up alerts for critical metrics
   - Monitor both success and failure metrics
   - Keep track of message counts and queue sizes

## Azure CLI Commands Reference

### Service Bus Commands

```bash
# List all Service Bus namespaces
az servicebus namespace list --query "[].{Name:name, ResourceGroup:resourceGroup}" -o table

# List all queues in a namespace
az servicebus queue list --namespace-name realtimeappbus --resource-group realtime-app-rg --query "[].{Name:name}" -o table

# Show queue details
az servicebus queue show \
    --namespace-name realtimeappbus \
    --resource-group realtime-app-rg \
    --name trip-changes-queue \
    --query "{MessageCount:messageCount,SizeInBytes:sizeInBytes,Status:status,UpdatedAt:updatedAt}"

# Create a new queue
az servicebus queue create \
    --namespace-name realtimeappbus \
    --resource-group realtime-app-rg \
    --name trip-changes-queue

# Delete a queue
az servicebus queue delete \
    --namespace-name realtimeappbus \
    --resource-group realtime-app-rg \
    --name trip-changes-queue
```

### Event Grid Commands

```bash
# List all Event Grid topics
az eventgrid topic list --query "[].{Name:name, ResourceGroup:resourceGroup}" -o table

# Get Event Grid topic endpoint
az eventgrid topic show \
    --name sql-changes-topic \
    --resource-group realtime-app-rg \
    --query "endpoint" -o tsv

# Get Event Grid topic key
az eventgrid topic key list \
    --name sql-changes-topic \
    --resource-group realtime-app-rg \
    --query "key1" -o tsv

# Create a new Event Grid topic
az eventgrid topic create \
    --name sql-changes-topic \
    --resource-group realtime-app-rg \
    --location westus2

# Delete an Event Grid topic
az eventgrid topic delete \
    --name sql-changes-topic \
    --resource-group realtime-app-rg
```

### Key Vault Commands

```bash
# List all Key Vaults
az keyvault list --query "[].{Name:name, ResourceGroup:resourceGroup}" -o table

# Set a secret in Key Vault
az keyvault secret set \
    --vault-name realtime-app-kv \
    --name SignalR \
    --value "Version=1.0;Endpoint=..."

# Get a secret from Key Vault
az keyvault secret show \
    --vault-name realtime-app-kv \
    --name SignalR \
    --query "value" -o tsv

# Update a secret in Key Vault
az keyvault secret set \
    --vault-name realtime-app-kv \
    --name SignalR \
    --value "Version=1.0;Endpoint=..."

# Delete a secret from Key Vault
az keyvault secret delete \
    --vault-name realtime-app-kv \
    --name SignalR
```

### Monitoring Commands

```bash
# Monitor Event Grid metrics
az monitor metrics list \
    --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/realtime-app-rg/providers/Microsoft.EventGrid/topics/sql-changes-topic" \
    --metric "PublishSuccessCount,PublishFailCount,DeliverySuccessCount,DeliveryAttemptFailCount" \
    --interval PT1H

# Monitor Service Bus metrics
az monitor metrics list \
    --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/realtime-app-rg/providers/Microsoft.ServiceBus/namespaces/realtimeappbus" \
    --metric "SuccessfulRequests,ServerErrors,UserErrors,ThrottledRequests,IncomingMessages,OutgoingMessages" \
    --interval PT1H

# Get subscription ID
az account show --query id -o tsv
```

### Common Query Parameters

```bash
# Format output as table
--query "[].{Name:name, ResourceGroup:resourceGroup}" -o table

# Format output as TSV (Tab-Separated Values)
--query "value" -o tsv

# Format output as JSON
--query "value" -o json

# Format output as YAML
--query "value" -o yaml
```

### Tips for Using Azure CLI

1. **Query Syntax**
   - Use JMESPath query syntax for filtering and formatting output
   - Example: `--query "[].{Name:name, ResourceGroup:resourceGroup}"`

2. **Output Formats**
   - `-o table`: Human-readable table format
   - `-o tsv`: Tab-separated values for scripting
   - `-o json`: JSON format for programmatic use
   - `-o yaml`: YAML format for configuration files

3. **Resource Identification**
   - Use resource IDs for cross-subscription operations
   - Use resource names and resource groups for simpler commands
   - Example: `--resource "/subscriptions/{id}/resourceGroups/{rg}/providers/..."`

4. **Error Handling**
   - Use `--debug` for detailed error information
   - Use `--verbose` for more detailed output
   - Check exit codes in scripts

5. **Best Practices**
   - Always specify resource group and location
   - Use consistent naming conventions
   - Document command parameters
   - Use query parameters to filter output
   - Use output formats appropriate for your use case 