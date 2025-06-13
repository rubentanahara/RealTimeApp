# RealTimeApp

A modern, cloud-native real-time trip monitoring system built with .NET and Azure services, featuring real-time updates, event-driven architecture, and AI-powered monitoring capabilities.

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

- Azure CLI
- .NET SDK 9.0 or higher
- Node.js 18+ and npm
- SQL Server Command Line Tools (sqlcmd)
- Redis CLI tools
- Azure subscription (for cloud services)

## 🔧 Required Azure Services

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

## 🛠️ Setup and Running

### 1. Check Prerequisites
```bash
bash scripts/check-prerequisites.sh
```

### 2. Generate Environment Configuration
```bash
bash scripts/generate-env.sh
```

### 3. Run the Application
```bash
bash scripts/run-realtime-app.sh
```

### 4. Test Real-time Flow
```bash
bash scripts/test-realtime-flow.sh
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

## 🔍 Access Points

- Frontend: http://localhost:3000
- Main API: http://localhost:5000/swagger
- SyncAPI: http://localhost:5001/swagger

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
- Production deployment requires proper Azure service configuration

## 📚 Additional Resources

- [Azure SQL Database Documentation](https://docs.microsoft.com/en-us/azure/azure-sql/)
- [Azure Redis Cache Documentation](https://docs.microsoft.com/en-us/azure/azure-cache-for-redis/)
- [Azure Service Bus Documentation](https://docs.microsoft.com/en-us/azure/service-bus-messaging/)
- [Azure SignalR Documentation](https://docs.microsoft.com/en-us/azure/azure-signalr/)
- [Azure Event Grid Documentation](https://docs.microsoft.com/en-us/azure/event-grid/) 