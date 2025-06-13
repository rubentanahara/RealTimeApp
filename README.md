# RealTimeApp

A real-time application built with .NET and Azure services, featuring real-time updates, event-driven architecture, and modern web technologies.

## Prerequisites

Before you begin, ensure you have the following installed:

- Azure CLI
- .NET SDK 9.0 or higher
- Node.js 16 or higher
- SQL Server Command Line Tools (sqlcmd)
- Redis CLI tools

## Project Structure

The solution consists of the following components:

- **RealTimeApp.Api**: Main API service (port 5000)
- **RealTimeApp.SyncApi**: Synchronization API service (port 5001)
- **RealTimeApp.Domain**: Core domain models and interfaces
- **RealTimeApp.Infrastructure**: Infrastructure implementations
- **RealTimeApp.Application**: Application services and business logic
- **realtime-app-frontend**: React-based frontend application (port 3000)

## Setup and Running the Application

The project includes several scripts to help you set up and run the application. Here's how to use them:

### 1. Check Prerequisites

First, run the prerequisites check script to ensure your environment is properly configured:

```bash
bash scripts/check-prerequisites.sh
```

This script will verify:
- Azure CLI installation and login status
- .NET SDK version
- Node.js version
- Required tools (sqlcmd, redis-cli)
- Project structure
- Azure permissions

### 2. Generate Environment Configuration

After verifying prerequisites, generate the environment configuration:

```bash
bash scripts/generate-env.sh
```

This script will:
- Create a `.env` file with necessary configuration
- Configure Azure services (SQL Server, Redis, Service Bus, SignalR, Event Grid)
- Set up application ports
- Prompt for SQL Server password

### 3. Run the Application

To start all components of the application:

```bash
bash scripts/run-realtime-app.sh
```

This will start:
- Main API (port 5000)
- SyncAPI (port 5001)
- Frontend (port 3000)

The script also:
- Checks port availability
- Verifies Azure service connections
- Adds test data to the database
- Starts all components in the correct order

### 4. Test Real-time Flow

To test the real-time architecture flow:

```bash
bash scripts/test-realtime-flow.sh
```

This test script:
1. Creates a test trip in the database
2. Verifies Event Grid → Service Bus → SyncAPI processing
3. Updates trip status
4. Verifies real-time updates through SignalR
5. Checks Redis cache and database consistency

## Architecture

The application uses several Azure services for real-time functionality:

- **Azure SQL Server**: Main database with change tracking enabled
- **Azure Redis Cache**: Caching layer for real-time data
- **Azure Service Bus**: Message queue for async processing
- **Azure SignalR**: Real-time communication hub
- **Azure Event Grid**: Event routing for database changes

## Troubleshooting

If you encounter issues:

1. Check the prerequisites script output for any missing requirements
2. Verify Azure service connections using the run script
3. Check the logs in the `logs` directory
4. Ensure all required ports are available
5. Verify Azure permissions for all services

## Contributing

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

# RealTimeApp

A real-time application built with .NET and Azure services, featuring real-time updates, event-driven architecture, and modern web technologies.

## Prerequisites

Before you begin, ensure you have the following installed:

- Azure CLI
- .NET SDK 7.0 or higher
- Node.js 16 or higher
- SQL Server Command Line Tools (sqlcmd)
- Redis CLI tools

## Setup and Running the Application

The project includes several scripts to help you set up and run the application. Here's how to use them:

### 1. Check Prerequisites

First, run the prerequisites check script to ensure your environment is properly configured:

```bash
bash scripts/check-prerequisites.sh
```

This script will verify:
- Azure CLI installation and login status
- .NET SDK version
- Node.js version
- Required tools (sqlcmd, redis-cli)
- Project structure
- Azure permissions

### 2. Generate Environment Configuration

After verifying prerequisites, generate the environment configuration:

```bash
bash scripts/generate-env.sh
```

This script will:
- Create a `.env` file with necessary configuration
- Configure Azure services (SQL Server, Redis, Service Bus, SignalR, Event Grid)
- Set up application ports
- Prompt for SQL Server password

### 3. Run the Application

To start all components of the application:

```bash
bash scripts/run-realtime-app.sh
```

This will start:
- Main API (port 5000)
- SyncAPI (port 5001)
- Frontend (port 3000)

The script also:
- Checks port availability
- Verifies Azure service connections
- Adds test data to the database
- Starts all components in the correct order

### 4. Test Real-time Flow

To test the real-time architecture flow:

```bash
bash scripts/test-realtime-flow.sh
```

This test script:
1. Creates a test trip in the database
2. Verifies Event Grid → Service Bus → SyncAPI processing
3. Updates trip status
4. Verifies real-time updates through SignalR
5. Checks Redis cache and database consistency

## Architecture

The application uses several Azure services for real-time functionality:

- **Azure SQL Server**: Main database
- **Azure Redis Cache**: Caching layer
- **Azure Service Bus**: Message queue for async processing
- **Azure SignalR**: Real-time communication
- **Azure Event Grid**: Event routing

## Troubleshooting

If you encounter issues:

1. Check the prerequisites script output for any missing requirements
2. Verify Azure service connections using the run script
3. Check the logs in the `logs` directory
4. Ensure all required ports are available
5. Verify Azure permissions for all services

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request 