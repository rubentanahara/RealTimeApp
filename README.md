# RealTimeApp - Real-time Trip Monitoring System

A modern, cloud-native application demonstrating real-time trip monitoring and management using Azure services. This application showcases event-driven architecture, real-time updates, and AI-powered trip monitoring capabilities.

## 🏗️ Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Frontend  │◄────┤    API      │◄────┤   SyncAPI   │
│  (React)    │     │  (.NET 9)   │     │  (.NET 9)   │
└─────────────┘     └─────────────┘     └─────────────┘
       ▲                   ▲                   ▲
       │                   │                   │
       │                   │                   │
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   SignalR   │     │    Redis    │     │ Service Bus │
└─────────────┘     └─────────────┘     └─────────────┘
                           ▲                   ▲
                           │                   │
                           │                   │
                    ┌─────────────┐     ┌─────────────┐
                    │    SQL      │     │ Event Grid  │
                    │  Database   │     │             │
                    └─────────────┘     └─────────────┘
```

## 🚀 Features

- Real-time trip status updates
- Driver and vehicle management
- AI-powered trip monitoring (POC)
- Real-time notifications
- Caching with different TTLs
- Swagger API documentation
- Comprehensive logging

## 📋 Prerequisites

- .NET 9.0 SDK
- Node.js 18+ and npm
- Azure CLI
- SQL Server (local or Azure)
- Redis (local or Azure)
- Azure subscription (for cloud services)

## 🔧 Azure Services Required

1. **Azure SQL Database**
   - Server: `realtimeappsqlsrv`
   - Database: `RealTimeAppDb`

2. **Azure Redis Cache**
   - Name: `realtimeappredis`

3. **Azure Service Bus**
   - Name: `realtimeappbus`
   - Queue: `trip-changes-queue`

4. **Azure SignalR**
   - Name: `realtimeappsignalr`

5. **Azure Event Grid**
   - Topic: `sql-changes-topic`

6. **Azure Key Vault**
   - Name: `realtime-app-kv`

## ⚙️ Configuration

### 1. Environment Variables

Create a `.env` file in the project root:

```bash
# SQL Server Configuration
SQL_SERVER_PASSWORD="your_sql_password_here"

# Redis Configuration
REDIS_PASSWORD="your_redis_password_here"

# Service Bus Configuration
SERVICE_BUS_CONNECTION="your_service_bus_connection_string"

# SignalR Configuration
SIGNALR_CONNECTION="your_signalr_connection_string"

# Event Grid Configuration
EVENT_GRID_TOPIC_ENDPOINT="your_event_grid_topic_endpoint"
EVENT_GRID_TOPIC_KEY="your_event_grid_topic_key"
```

### 2. Azure Key Vault Setup

1. Create a Key Vault in Azure
2. Add the following secrets:
   - `SqlConnectionString`
   - `RedisConnectionString`
   - `ServiceBusConnectionString`
   - `SignalRConnectionString`
   - `EventGridTopicEndpoint`
   - `EventGridTopicKey`

## 🛠️ Setup Scripts

The project includes several scripts in the `scripts/` directory:

### 1. `run-realtime-app.sh`

Starts all components of the application:
```bash
./scripts/run-realtime-app.sh
```

This script:
- Starts the Main API (port 5000)
- Starts the SyncAPI (port 5001)
- Starts the Frontend (port 3000)
- Verifies Azure service connections
- Sets up test data

### 2. `test-realtime-flow.sh`

Tests the real-time architecture flow:
```bash
./scripts/test-realtime-flow.sh
```

This script:
- Creates a test trip
- Verifies Event Grid → Service Bus → SyncAPI processing
- Updates trip status
- Verifies real-time updates through SignalR

## 🏃‍♂️ Running the Application

1. **Start the Application**
   ```bash
   ./scripts/run-realtime-app.sh
   ```

2. **Access the Applications**
   - Frontend: http://localhost:3000
   - Main API: http://localhost:5000/swagger
   - SyncAPI: http://localhost:5001/swagger

3. **Test the Real-time Flow**
   ```bash
   ./scripts/test-realtime-flow.sh
   ```

## 📁 Project Structure

```
RealTimeApp/
├── RealTimeApp.Api/           # Main API service
├── RealTimeApp.SyncApi/       # Synchronization API
├── RealTimeApp.Domain/        # Domain models and interfaces
├── RealTimeApp.Application/   # Application services
├── RealTimeApp.Infrastructure/# Infrastructure implementations
├── realtime-app-frontend/     # React frontend
├── scripts/                   # Utility scripts
└── sql/                       # Database scripts
```

## 🔍 Monitoring

- API Logs: `logs/api.log`
- SyncAPI Logs: `logs/syncapi.log`
- Frontend Logs: `logs/frontend.log`

## 🛑 Stopping the Application

```bash
pkill -f 'dotnet run'
pkill -f 'npm run dev'
```

## 🔐 Security Notes

- Never commit the `.env` file
- Keep your Azure credentials secure
- Use Azure Key Vault for production secrets
- Enable HTTPS in production

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## ⚠️ Important Notes

- The AI features are currently in POC/Demo stage
- Some features require Azure services
- Local development is supported with Docker
- Production deployment requires proper Azure service configuration

## 🆘 Troubleshooting

1. **Database Connection Issues**
   - Verify SQL Server firewall rules
   - Check connection string in Key Vault
   - Ensure SQL Server is running

2. **Redis Connection Issues**
   - Verify Redis connection string
   - Check Redis firewall rules
   - Ensure Redis is running

3. **Service Bus Issues**
   - Verify Service Bus connection string
   - Check queue exists
   - Ensure proper permissions

4. **SignalR Issues**
   - Verify SignalR connection string
   - Check CORS configuration
   - Ensure proper WebSocket support

## 📚 Additional Resources

- [Azure SQL Database Documentation](https://docs.microsoft.com/en-us/azure/azure-sql/)
- [Azure Redis Cache Documentation](https://docs.microsoft.com/en-us/azure/azure-cache-for-redis/)
- [Azure Service Bus Documentation](https://docs.microsoft.com/en-us/azure/service-bus-messaging/)
- [Azure SignalR Documentation](https://docs.microsoft.com/en-us/azure/azure-signalr/)
- [Azure Event Grid Documentation](https://docs.microsoft.com/en-us/azure/event-grid/) 