#!/bin/bash

# =============================================================================
# RealTimeApp - Single Command Runner
# =============================================================================
# This script does everything: start apps, check connections, and test data flow
# =============================================================================

set -e  # Exit on any error

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SQL_DIR="$PROJECT_ROOT/sql"

# Load environment variables
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
else
    echo "❌ .env file not found. Please create it with SQL_SERVER_PASSWORD"
    exit 1
fi

echo "🚀 RealTimeApp - Starting Everything..."
echo ""

# =============================================================================
# Configuration
# =============================================================================
RESOURCE_GROUP="realtime-app-rg"
SQL_SERVER="realtimeappsqlsrv"
SQL_DATABASE="RealTimeAppDb"
REDIS_NAME="realtimeappredis"
SERVICEBUS_NAME="realtimeappbus"
SIGNALR_NAME="realtimeappsignalr"
EVENTGRID_TOPIC="sql-changes-topic"

# =============================================================================
# Step 1: Start Applications
# =============================================================================
echo "1. 🎯 Starting Applications..."

# Create logs directory first
mkdir -p "$PROJECT_ROOT/logs"

# Kill existing processes
echo "   🛑 Stopping existing applications..."
pkill -f "dotnet run" 2>/dev/null || true
pkill -f "npm run dev" 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
sleep 2

# Start Main API
echo "   🌐 Starting Main API (port 5000)..."
cd "$PROJECT_ROOT/RealTimeApp.Api"
dotnet run --urls="http://localhost:5000" > "$PROJECT_ROOT/logs/api.log" 2>&1 &
API_PID=$!
cd "$PROJECT_ROOT"

# Start SyncAPI
echo "   ⚡ Starting SyncAPI (port 5001)..."
cd "$PROJECT_ROOT/RealTimeApp.SyncApi"
dotnet run --urls="http://localhost:5001" > "$PROJECT_ROOT/logs/syncapi.log" 2>&1 &
SYNCAPI_PID=$!
cd "$PROJECT_ROOT"

# Start Frontend
echo "   🎨 Starting Frontend (port 3000)..."
cd "$PROJECT_ROOT/realtime-app-frontend"
npm run dev > "$PROJECT_ROOT/logs/frontend.log" 2>&1 &
FRONTEND_PID=$!
cd "$PROJECT_ROOT"

echo "   ⏳ Waiting for applications to start..."
sleep 10

# Check if apps are running
API_RUNNING=false
SYNCAPI_RUNNING=false
FRONTEND_RUNNING=false

if curl -s http://localhost:5000/swagger &> /dev/null; then
    echo "   ✅ Main API running (http://localhost:5000)"
    API_RUNNING=true
else
    echo "   ❌ Main API failed to start"
fi

if curl -s http://localhost:5001/swagger &> /dev/null; then
    echo "   ✅ SyncAPI running (http://localhost:5001)"
    SYNCAPI_RUNNING=true
else
    echo "   ❌ SyncAPI failed to start"
fi

if curl -s http://localhost:3000 &> /dev/null; then
    echo "   ✅ Frontend running (http://localhost:3000)"
    FRONTEND_RUNNING=true
else
    echo "   ❌ Frontend failed to start"
fi

# =============================================================================
# Step 2: Check Azure Services
# =============================================================================
echo ""
echo "2. ☁️ Checking Azure Services..."

# SQL Database
if az sql db show --name $SQL_DATABASE --server $SQL_SERVER --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo "   ✅ Azure SQL Database: ${SQL_SERVER}.database.windows.net"
    SQL_CONNECTED=true
else
    echo "   ❌ Azure SQL Database not accessible"
    SQL_CONNECTED=false
fi

# Redis Cache
REDIS_STATUS=$(az redis show --name $REDIS_NAME --resource-group $RESOURCE_GROUP --query "provisioningState" -o tsv 2>/dev/null || echo "Unknown")
if [ "$REDIS_STATUS" = "Succeeded" ]; then
    echo "   ✅ Azure Redis Cache: ${REDIS_NAME}.redis.cache.windows.net"
    # Test Redis connection
    if az redis list-keys --name $REDIS_NAME --resource-group $RESOURCE_GROUP --query "primaryKey" -o tsv &> /dev/null; then
        echo "   ✅ Redis access key available"
    else
        echo "   ⚠️  Redis access key unavailable"
    fi
else
    echo "   ⚠️  Azure Redis Cache status: $REDIS_STATUS"
fi

# Service Bus
SB_STATUS=$(az servicebus namespace show --name $SERVICEBUS_NAME --resource-group $RESOURCE_GROUP --query "status" -o tsv 2>/dev/null || echo "Unknown")
if [ "$SB_STATUS" = "Active" ]; then
    echo "   ✅ Azure Service Bus: ${SERVICEBUS_NAME}.servicebus.windows.net"
else
    echo "   ⚠️  Azure Service Bus status: $SB_STATUS"
fi

# SignalR
SIGNALR_STATUS=$(az signalr show --name $SIGNALR_NAME --resource-group $RESOURCE_GROUP --query "provisioningState" -o tsv 2>/dev/null || echo "Unknown")
if [ "$SIGNALR_STATUS" = "Succeeded" ]; then
    echo "   ✅ Azure SignalR: ${SIGNALR_NAME}.service.signalr.net"
else
    echo "   ⚠️  Azure SignalR status: $SIGNALR_STATUS"
fi

# Event Grid
EG_STATUS=$(az eventgrid topic show --name $EVENTGRID_TOPIC --resource-group $RESOURCE_GROUP --query "provisioningState" -o tsv 2>/dev/null || echo "Unknown")
if [ "$EG_STATUS" = "Succeeded" ]; then
    echo "   ✅ Azure Event Grid: $EVENTGRID_TOPIC"
else
    echo "   ⚠️  Azure Event Grid status: $EG_STATUS"
fi

# =============================================================================
# Step 3: Get/Create Test Data
# =============================================================================
echo ""
echo "3. 🧪 Setting up test data..."

if [ "$SQL_CONNECTED" = true ]; then
    # Use SQL password from .env file
    if [ -z "$SQL_SERVER_PASSWORD" ]; then
        echo "❌ SQL_SERVER_PASSWORD not set in .env file"
        exit 1
    fi
    
    echo "   ✅ Using SQL password from .env file"
    
    # Try to add test data using sqlcmd first (more reliable)
    echo "   📊 Adding test data to database..."
    if command -v sqlcmd &> /dev/null; then
        echo "   🔧 Using sqlcmd to add test data..."
        
        # Test SQL connection first
        echo "   🔍 Testing SQL connection..."
        if ! sqlcmd -S "${SQL_SERVER}.database.windows.net,1433" -d $SQL_DATABASE -U sqladmin -P "$SQL_SERVER_PASSWORD" -Q "SELECT 1" -h -1 &> /dev/null; then
            echo "❌ Failed to connect to SQL database"
            echo "   💡 Check your SQL server firewall rules and credentials"
            exit 1
        fi
        
        echo "   ✅ SQL connection successful"
        
        # Run the setup script
        if sqlcmd -S "${SQL_SERVER}.database.windows.net,1433" -d $SQL_DATABASE -U sqladmin -P "$SQL_SERVER_PASSWORD" -i "$SQL_DIR/setup-test-data.sql" &> "$PROJECT_ROOT/logs/sql-setup.log"; then
            echo "   ✅ Test data added successfully via sqlcmd"
        else
            echo "   ⚠️  sqlcmd failed, trying Azure CLI..."
            echo "   📝 Check logs at: $PROJECT_ROOT/logs/sql-setup.log"
            
            # Fallback to Azure CLI
            echo "   🔄 Using Azure CLI as fallback..."
            DRIVERS_SQL="IF NOT EXISTS (SELECT 1 FROM Drivers WHERE Id = '550e8400-e29b-41d4-a716-446655440001') BEGIN INSERT INTO Drivers (Id, Name, LicenseNumber, Status, LastModified, Version) VALUES ('550e8400-e29b-41d4-a716-446655440001', 'John Doe', 'DL123456', 0, GETUTCDATE(), 1), ('550e8400-e29b-41d4-a716-446655440002', 'Jane Smith', 'DL789012', 0, GETUTCDATE(), 1), ('550e8400-e29b-41d4-a716-446655440003', 'Mike Johnson', 'DL345678', 0, GETUTCDATE(), 1) END"
            VEHICLES_SQL="IF NOT EXISTS (SELECT 1 FROM Vehicles WHERE Id = '550e8400-e29b-41d4-a716-446655440001') BEGIN INSERT INTO Vehicles (Id, LicensePlate, Model, Status, LastModified, Version) VALUES ('550e8400-e29b-41d4-a716-446655440001', 'ABC123', 'Ford Transit', 0, GETUTCDATE(), 1), ('550e8400-e29b-41d4-a716-446655440002', 'XYZ789', 'Chevrolet Express', 0, GETUTCDATE(), 1), ('550e8400-e29b-41d4-a716-446655440003', 'DEF456', 'Mercedes Sprinter', 0, GETUTCDATE(), 1) END"
            
            if az sql query --server $SQL_SERVER --database $SQL_DATABASE --queries "$DRIVERS_SQL" --resource-group $RESOURCE_GROUP &> /dev/null; then
                echo "   ✅ Drivers added successfully"
            else
                echo "   ⚠️  Failed to add drivers via Azure CLI"
            fi
            
            if az sql query --server $SQL_SERVER --database $SQL_DATABASE --queries "$VEHICLES_SQL" --resource-group $RESOURCE_GROUP &> /dev/null; then
                echo "   ✅ Vehicles added successfully"
            else
                echo "   ⚠️  Failed to add vehicles via Azure CLI"
            fi
        fi
    else
        echo "   ⚠️  sqlcmd not found, trying Azure CLI..."
        # Use Azure CLI as fallback
        echo "   🔄 Using Azure CLI as fallback..."
        DRIVERS_SQL="IF NOT EXISTS (SELECT 1 FROM Drivers WHERE Id = '550e8400-e29b-41d4-a716-446655440001') BEGIN INSERT INTO Drivers (Id, Name, LicenseNumber, Status, LastModified, Version) VALUES ('550e8400-e29b-41d4-a716-446655440001', 'John Doe', 'DL123456', 0, GETUTCDATE(), 1), ('550e8400-e29b-41d4-a716-446655440002', 'Jane Smith', 'DL789012', 0, GETUTCDATE(), 1), ('550e8400-e29b-41d4-a716-446655440003', 'Mike Johnson', 'DL345678', 0, GETUTCDATE(), 1) END"
        VEHICLES_SQL="IF NOT EXISTS (SELECT 1 FROM Vehicles WHERE Id = '550e8400-e29b-41d4-a716-446655440001') BEGIN INSERT INTO Vehicles (Id, LicensePlate, Model, Status, LastModified, Version) VALUES ('550e8400-e29b-41d4-a716-446655440001', 'ABC123', 'Ford Transit', 0, GETUTCDATE(), 1), ('550e8400-e29b-41d4-a716-446655440002', 'XYZ789', 'Chevrolet Express', 0, GETUTCDATE(), 1), ('550e8400-e29b-41d4-a716-446655440003', 'DEF456', 'Mercedes Sprinter', 0, GETUTCDATE(), 1) END"
        
        if az sql query --server $SQL_SERVER --database $SQL_DATABASE --queries "$DRIVERS_SQL" --resource-group $RESOURCE_GROUP &> /dev/null; then
            echo "   ✅ Drivers added successfully"
        else
            echo "   ⚠️  Failed to add drivers via Azure CLI"
        fi
        
        if az sql query --server $SQL_SERVER --database $SQL_DATABASE --queries "$VEHICLES_SQL" --resource-group $RESOURCE_GROUP &> /dev/null; then
            echo "   ✅ Vehicles added successfully"
        else
            echo "   ⚠️  Failed to add vehicles via Azure CLI"
        fi
    fi

    # Get available driver and vehicle
    echo "   🔍 Finding available driver and vehicle..."
    
    # Use sqlcmd for reliable querying
    if command -v sqlcmd &> /dev/null; then
        echo "   🔧 Using sqlcmd to query IDs..."
        DRIVER_ID=$(sqlcmd -S "${SQL_SERVER}.database.windows.net,1433" -d $SQL_DATABASE -U sqladmin -P "$SQL_SERVER_PASSWORD" -Q "SELECT TOP 1 Id FROM Drivers" -h -1 2>/dev/null | tr -d ' ' | grep -E '^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$' | head -1 || echo "")
        VEHICLE_ID=$(sqlcmd -S "${SQL_SERVER}.database.windows.net,1433" -d $SQL_DATABASE -U sqladmin -P "$SQL_SERVER_PASSWORD" -Q "SELECT TOP 1 Id FROM Vehicles" -h -1 2>/dev/null | tr -d ' ' | grep -E '^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$' | head -1 || echo "")
    else
        # Fallback to known test IDs
        echo "   ⚠️  sqlcmd not found, using default test IDs..."
        DRIVER_ID="550e8400-e29b-41d4-a716-446655440001"
        VEHICLE_ID="550e8400-e29b-41d4-a716-446655440001"
    fi
    
    if [ -n "$DRIVER_ID" ] && [ -n "$VEHICLE_ID" ]; then
        echo "   ✅ Found Driver ID: $DRIVER_ID"
        echo "   ✅ Found Vehicle ID: $VEHICLE_ID"
        TEST_DATA_READY=true
    else
        echo "   ❌ Could not find driver or vehicle in database"
        echo "   💡 Using default test IDs..."
        DRIVER_ID="550e8400-e29b-41d4-a716-446655440001"
        VEHICLE_ID="550e8400-e29b-41d4-a716-446655440001"
        TEST_DATA_READY=false
    fi
else
    echo "   ⏭️  Skipping database setup (SQL not connected)"
    DRIVER_ID="550e8400-e29b-41d4-a716-446655440001"
    VEHICLE_ID="550e8400-e29b-41d4-a716-446655440001"
    TEST_DATA_READY=false
fi

# =============================================================================
# Final Status Report
# =============================================================================
echo ""
echo "🎯 RealTimeApp Status Report"
echo "============================="
echo ""
echo "📱 Applications:"
[ "$API_RUNNING" = true ] && echo "   ✅ Main API: http://localhost:5000" || echo "   ❌ Main API: Failed to start"
[ "$SYNCAPI_RUNNING" = true ] && echo "   ✅ SyncAPI: http://localhost:5001" || echo "   ❌ SyncAPI: Failed to start"
[ "$FRONTEND_RUNNING" = true ] && echo "   ✅ Frontend: http://localhost:3000" || echo "   ❌ Frontend: Failed to start"

echo ""
echo "☁️ Azure Services:"
[ "$SQL_CONNECTED" = true ] && echo "   ✅ SQL Database" || echo "   ❌ SQL Database"
[ "$REDIS_STATUS" = "Succeeded" ] && echo "   ✅ Redis Cache" || echo "   ⚠️  Redis Cache ($REDIS_STATUS)"
[ "$SB_STATUS" = "Active" ] && echo "   ✅ Service Bus" || echo "   ⚠️  Service Bus ($SB_STATUS)"
[ "$SIGNALR_STATUS" = "Succeeded" ] && echo "   ✅ SignalR" || echo "   ⚠️  SignalR ($SIGNALR_STATUS)"
[ "$EG_STATUS" = "Succeeded" ] && echo "   ✅ Event Grid" || echo "   ⚠️  Event Grid ($EG_STATUS)"

echo ""
echo "🧪 Test Data:"
echo "   👨‍💼 Driver ID: $DRIVER_ID"
echo "   🚗 Vehicle ID: $VEHICLE_ID"

echo ""
echo "🎮 Quick Actions:"
echo "=================================="
echo ""
echo "🌐 Open Apps:"
echo "   • Main API: open http://localhost:5000/swagger"
echo "   • SyncAPI: open http://localhost:5001/swagger"
echo "   • Frontend: open http://localhost:3000"
echo ""
echo "🔧 Fix Database (if FK errors):"
echo "   sqlcmd -S ${SQL_SERVER}.database.windows.net,1433 -d $SQL_DATABASE -U sqladmin -P \"\$(az sql server list-admin-passwords --name $SQL_SERVER --resource-group $RESOURCE_GROUP --query 'currentPassword' -o tsv)\" -i $SQL_DIR/setup-test-data.sql"
echo ""
echo "📊 Check Logs:"
echo "   • API: tail -f $PROJECT_ROOT/logs/api.log"
echo "   • SyncAPI: tail -f $PROJECT_ROOT/logs/syncapi.log"
echo "   • Frontend: tail -f $PROJECT_ROOT/logs/frontend.log"
echo ""
echo "🛑 Stop All:"
echo "   pkill -f 'dotnet run'; pkill -f 'npm run dev'"
echo ""

# Save PIDs for easy cleanup
echo "$API_PID" > "$PROJECT_ROOT/logs/api.pid" 2>/dev/null || true
echo "$SYNCAPI_PID" > "$PROJECT_ROOT/logs/syncapi.pid" 2>/dev/null || true
echo "$FRONTEND_PID" > "$PROJECT_ROOT/logs/frontend.pid" 2>/dev/null || true

echo "🎉 RealTimeApp is ready! Check the applications above."
echo ""
echo "💡 To restart everything, just run: $SCRIPT_DIR/run-realtime-app.sh" 