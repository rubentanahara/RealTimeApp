# RealTimeApp Local Development Guide

This guide explains how to set up, run, and test the RealTimeApp locally on your development machine before deploying to Azure.

## 📋 Prerequisites

### Required Software
- **Docker Desktop**: For running local services
- **.NET SDK 9.0+**: For building and running the APIs
- **Node.js 18+**: For running the React frontend
- **Git**: For source code management

### Installation
```bash
# macOS (using Homebrew)
brew install docker
brew install dotnet
brew install node

# Windows (using Chocolatey)
choco install docker-desktop
choco install dotnet-sdk
choco install nodejs

# Verify installations
docker --version
dotnet --version
node --version
```

## 🚀 Quick Start (3 Commands)

```bash
# 1. Set up local environment
./setup-local.sh

# 2. Start all services
./start-all.sh

# 3. Test everything
./test-local.sh
```

That's it! Your local environment will be running with:
- **Frontend**: http://localhost:3000
- **API**: http://localhost:5000
- **SyncAPI**: http://localhost:5001

## 🏗️ Architecture Overview

### Local Services Stack
```
Frontend (React)     →  API (.NET)         →  SignalR Hub
http://localhost:3000   http://localhost:5000   Real-time updates
                              ↓
                        SQL Server          →   Redis Cache
                        localhost:1433          localhost:6379
                              ↓
                        Change Tracking     →   Event Grid Simulator
                        Database triggers       http://localhost:8080
                              ↓
                        SyncAPI (.NET)      →   Service Bus (Azurite)
                        localhost:5001          localhost:10001
```

### Docker Services
- **SQL Server**: Microsoft SQL Server 2022 for data storage
- **Redis**: In-memory cache for fast data access
- **Azurite**: Azure Storage emulator for Service Bus queues
- **Event Grid Simulator**: Simple webhook receiver for testing

## 📦 Detailed Setup Process

### Step 1: Initial Setup

```bash
# Clone the repository (if not already done)
git clone [your-repo-url]
cd RealTimeApp

# Make scripts executable
chmod +x *.sh

# Run the setup script
./setup-local.sh
```

The setup script will:
1. ✅ Check all prerequisites
2. ✅ Start Docker services
3. ✅ Create SQL database and tables
4. ✅ Configure frontend environment
5. ✅ Build .NET applications
6. ✅ Create launch scripts

### Step 2: Understanding the Services

#### Docker Services (Always Running)
```bash
# View running services
docker-compose -f docker-compose.local.yml ps

# View service logs
docker-compose -f docker-compose.local.yml logs [service-name]

# Stop all services
docker-compose -f docker-compose.local.yml down

# Start all services
docker-compose -f docker-compose.local.yml up -d
```

#### .NET Applications (Manual Start)
```bash
# Start API only
./start-api.sh

# Start SyncAPI only  
./start-syncapi.sh

# Start Frontend only
./start-frontend.sh

# Start all applications
./start-all.sh
```

## 🧪 Testing Your Local Setup

### Automated Testing
```bash
# Run comprehensive test suite
./test-local.sh
```

This tests:
- ✅ All Docker services connectivity
- ✅ Database creation and operations
- ✅ API endpoints and health checks
- ✅ Frontend accessibility
- ✅ End-to-end data flow

### Manual Testing

#### 1. Test Frontend
```bash
# Open the frontend
open http://localhost:3000

# Or in browser:
# http://localhost:3000
```

**What to test:**
- Create a new trip
- View trip list
- Monitor real-time updates
- Check AI recommendations (demo mode)

#### 2. Test API
```bash
# Open API documentation
open http://localhost:5000/swagger

# Test trip creation via curl
curl -X POST http://localhost:5000/api/trip \
  -H "Content-Type: application/json" \
  -d '{
    "tripNumber": "TEST001",
    "driverId": "550e8400-e29b-41d4-a716-446655440001",
    "vehicleId": "550e8400-e29b-41d4-a716-446655440002"
  }'
```

#### 3. Test SyncAPI
```bash
# Open SyncAPI documentation
open http://localhost:5001/swagger

# Test Event Grid webhook
curl -X POST http://localhost:5001/api/eventgrid \
  -H "Content-Type: application/json" \
  -d '[{
    "id": "test-event",
    "subject": "test",
    "eventType": "Microsoft.SqlServer.DatabaseChange",
    "eventTime": "2024-01-01T00:00:00Z",
    "data": {"test": "data"}
  }]'
```

#### 4. Test Real-time Flow
1. Open multiple browser tabs to http://localhost:3000
2. Create a trip in one tab
3. Verify it appears in other tabs instantly
4. Update trip status and verify real-time updates

## 🔧 Development Workflow

### Daily Development Routine

```bash
# 1. Start your day
docker-compose -f docker-compose.local.yml up -d
./start-all.sh

# 2. Code changes (APIs automatically reload)
# Edit code in RealTimeApp.Api/ or RealTimeApp.SyncApi/

# 3. Frontend changes (hot reload enabled)
# Edit code in realtime-app-frontend/src/

# 4. Test changes
./test-local.sh

# 5. End your day
# Ctrl+C in the terminal running start-all.sh
docker-compose -f docker-compose.local.yml down
```

### Making Code Changes

#### .NET API Changes
- Hot reload is enabled in development mode
- Changes auto-compile and reload
- No need to restart unless changing dependencies

#### Frontend Changes  
- Vite hot reload is enabled
- Changes appear instantly in browser
- No need to restart development server

#### Database Changes
```bash
# Connect to SQL Server
docker exec -it realtime-sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P 'RealTime@Local2024!' -d RealTimeAppDb

# Make changes
1> SELECT * FROM Trips;
2> GO
```

## 🐛 Troubleshooting

### Common Issues

#### Issue: Docker services won't start
```bash
# Check Docker is running
docker info

# Check ports aren't in use
lsof -i :1433 -i :6379 -i :10001 -i :8080

# Restart Docker Desktop
# Or restart specific services
docker-compose -f docker-compose.local.yml restart [service-name]
```

#### Issue: SQL Server connection fails
```bash
# Check if SQL Server is ready
docker exec realtime-sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "RealTime@Local2024!" -Q "SELECT 1"

# If not ready, wait and retry
sleep 10
# Try again
```

#### Issue: Frontend can't connect to API
```bash
# Check API is running
curl http://localhost:5000/health

# Check CORS configuration
curl -I -X OPTIONS http://localhost:5000/api/trip \
  -H "Origin: http://localhost:3000"

# Should return Access-Control-Allow-Origin header
```

#### Issue: Real-time updates not working
```bash
# Check SignalR connection in browser console
# Look for WebSocket connection errors

# Check API logs
# SignalR Hub should show connections

# Test SignalR directly
curl http://localhost:5000/tripHub
```

### Service-Specific Troubleshooting

#### SQL Server
```bash
# View SQL Server logs
docker logs realtime-sqlserver

# Connect to SQL Server
docker exec -it realtime-sqlserver bash

# Check database exists
docker exec realtime-sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "RealTime@Local2024!" \
  -Q "SELECT name FROM sys.databases"
```

#### Redis
```bash
# View Redis logs
docker logs realtime-redis

# Connect to Redis CLI
docker exec -it realtime-redis redis-cli

# Test Redis operations
127.0.0.1:6379> ping
PONG
127.0.0.1:6379> set test value
OK
127.0.0.1:6379> get test
"value"
```

#### Azurite (Service Bus)
```bash
# View Azurite logs
docker logs realtime-azurite

# Test queue service
curl http://localhost:10001/devstoreaccount1?comp=list

# Should return XML response
```

### Log Monitoring

```bash
# All services
docker-compose -f docker-compose.local.yml logs -f

# Specific service
docker-compose -f docker-compose.local.yml logs -f sqlserver

# .NET application logs
# Check terminal where start-all.sh is running

# Frontend logs
# Check browser console (F12)
```

## 📊 Environment Configuration

### Local Environment Variables

The setup automatically creates these configurations:

#### API (`RealTimeApp.Api/appsettings.Development.json`)
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost,1433;Database=RealTimeAppDb;User Id=sa;Password=RealTime@Local2024!;TrustServerCertificate=true;",
    "RedisConnection": "localhost:6379"
  },
  "SignalRConnectionString": "",
  "ServiceBusConnectionString": "DefaultEndpointsProtocol=https;AccountName=devstoreaccount1;..."
}
```

#### SyncAPI (`RealTimeApp.SyncApi/appsettings.Development.json`)
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost,1433;Database=RealTimeAppDb;...",
    "RedisConnection": "localhost:6379"
  },
  "EventGridTopicEndpoint": "http://localhost:8080/webhook"
}
```

#### Frontend (`realtime-app-frontend/.env.development`)
```bash
VITE_API_URL=http://localhost:5000
VITE_SIGNALR_URL=http://localhost:5000/tripHub
VITE_SYNC_API_URL=http://localhost:5001
```

## 🚀 Performance Testing

### Load Testing
```bash
# Test API under load
for i in {1..10}; do
  curl -X POST http://localhost:5000/api/trip \
    -H "Content-Type: application/json" \
    -d "{\"tripNumber\": \"LOAD-$i\", \"driverId\": \"$(uuidgen)\", \"vehicleId\": \"$(uuidgen)\"}" &
done
wait
```

### Database Performance
```bash
# Check trip count
docker exec realtime-sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "RealTime@Local2024!" -d RealTimeAppDb \
  -Q "SELECT COUNT(*) as TripCount FROM Trips"

# Check database size
docker exec realtime-sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "RealTime@Local2024!" -d RealTimeAppDb \
  -Q "SELECT DB_NAME() AS DatabaseName, 
      SUM(size * 8.0 / 1024) AS SizeMB 
      FROM sys.master_files 
      WHERE database_id = DB_ID()"
```

## 📱 VS Code Integration

### Recommended Extensions
```json
{
  "recommendations": [
    "ms-dotnettools.csharp",
    "ms-vscode.vscode-typescript-next",
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    "ms-vscode.vscode-json"
  ]
}
```

### Debugging Setup
Create `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug API",
      "type": "coreclr",
      "request": "launch",
      "program": "${workspaceFolder}/RealTimeApp.Api/bin/Debug/net9.0/RealTimeApp.Api.dll",
      "args": [],
      "cwd": "${workspaceFolder}/RealTimeApp.Api",
      "env": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    }
  ]
}
```

## 🎯 Ready for Production?

Once your local development is working perfectly:

1. **Run full test suite**: `./test-local.sh`
2. **Verify all features work**: Manual testing checklist
3. **Clean up test data**: Remove any test trips
4. **Deploy to Azure**: Follow `DEPLOYMENT_GUIDE.md`

## 📞 Need Help?

### Quick Commands Reference
```bash
# Setup
./setup-local.sh

# Start/Stop
./start-all.sh
docker-compose -f docker-compose.local.yml down

# Test
./test-local.sh

# Logs
docker-compose -f docker-compose.local.yml logs -f

# Database
docker exec -it realtime-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'RealTime@Local2024!' -d RealTimeAppDb

# Redis
docker exec -it realtime-redis redis-cli
```

### Service URLs
- **Frontend**: http://localhost:3000
- **API Swagger**: http://localhost:5000/swagger  
- **SyncAPI Swagger**: http://localhost:5001/swagger
- **Event Grid Simulator**: http://localhost:8080

**Happy local development! 🚀 Your changes will automatically sync, and you can test the complete real-time flow locally before deploying to Azure.** 