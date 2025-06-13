#!/bin/bash

# =============================================================================
# RealTimeApp - Start All Components
# =============================================================================
# This script starts all components of the RealTimeApp:
# 1. Main API (port 5000)
# 2. SyncAPI (port 5001)
# 3. Frontend (port 3000)
# =============================================================================

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load environment variables
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
else
    echo -e "${RED}❌ .env file not found. Please create it with required variables${NC}"
    exit 1
fi

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

# Function to check if a port is in use
check_port() {
    local port=$1
    if lsof -i :$port > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to check Azure service connection
check_azure_service() {
    local service_name=$1
    local service_type=$2
    local resource_group=$RESOURCE_GROUP
    
    echo -e "${BLUE}Checking $service_type connection...${NC}"
    
    case $service_type in
        "sql")
            if [ -z "$SQL_SERVER_PASSWORD" ]; then
                echo -e "${RED}❌ SQL_SERVER_PASSWORD not set in .env file${NC}"
                return 1
            fi
            
            # Try to connect to SQL Server
            if sqlcmd -S "${SQL_SERVER}.database.windows.net,1433" -d $SQL_DATABASE -U sqladmin -P "$SQL_SERVER_PASSWORD" -Q "SELECT 1" > /dev/null 2>&1; then
                echo -e "${GREEN}✅ SQL Server connection successful${NC}"
                return 0
            else
                echo -e "${RED}❌ SQL Server connection failed${NC}"
                return 1
            fi
            ;;
            
        "redis")
            if [ -z "$REDIS_PASSWORD" ]; then
                echo -e "${RED}❌ REDIS_PASSWORD not set in .env file${NC}"
                return 1
            fi
            
            # Try to connect to Redis
            if redis-cli -h "${REDIS_NAME}.redis.cache.windows.net" -p 6380 --tls -a "$REDIS_PASSWORD" ping > /dev/null 2>&1; then
                echo -e "${GREEN}✅ Redis connection successful${NC}"
                return 0
            else
                echo -e "${RED}❌ Redis connection failed${NC}"
                return 1
            fi
            ;;
            
        "servicebus")
            if [ -z "$SERVICEBUS_CONNECTION" ]; then
                echo -e "${RED}❌ SERVICEBUS_CONNECTION not set in .env file${NC}"
                return 1
            fi
            
            # Try to connect to Service Bus
            if az servicebus queue show --name $SERVICEBUS_QUEUE --namespace-name $SERVICEBUS_NAME --resource-group $resource_group > /dev/null 2>&1; then
                echo -e "${GREEN}✅ Service Bus connection successful${NC}"
                return 0
            else
                echo -e "${RED}❌ Service Bus connection failed${NC}"
                return 1
            fi
            ;;
            
        "signalr")
            if [ -z "$SIGNALR_CONNECTION" ]; then
                echo -e "${RED}❌ SIGNALR_CONNECTION not set in .env file${NC}"
                return 1
            fi
            
            # Try to connect to SignalR
            if az signalr show --name $SIGNALR_NAME --resource-group $resource_group > /dev/null 2>&1; then
                echo -e "${GREEN}✅ SignalR connection successful${NC}"
                return 0
            else
                echo -e "${RED}❌ SignalR connection failed${NC}"
                return 1
            fi
            ;;
            
        "eventgrid")
            if [ -z "$EVENTGRID_TOPIC_ENDPOINT" ] || [ -z "$EVENTGRID_TOPIC_KEY" ]; then
                echo -e "${RED}❌ EVENTGRID_TOPIC_ENDPOINT or EVENTGRID_TOPIC_KEY not set in .env file${NC}"
                return 1
            fi
            
            # Try to connect to Event Grid
            if az eventgrid topic show --name $EVENTGRID_TOPIC --resource-group $resource_group > /dev/null 2>&1; then
                echo -e "${GREEN}✅ Event Grid connection successful${NC}"
                return 0
            else
                echo -e "${RED}❌ Event Grid connection failed${NC}"
                return 1
            fi
            ;;
            
        *)
            echo -e "${RED}❌ Unknown service type: $service_type${NC}"
            return 1
            ;;
    esac
}

# Function to add test data to the database
add_test_data() {
    echo -e "${BLUE}Adding test data to the database...${NC}"
    
    if [ -z "$SQL_SERVER_PASSWORD" ]; then
        echo -e "${RED}❌ SQL_SERVER_PASSWORD not set in .env file${NC}"
        return 1
    fi
    
    # Try using sqlcmd first
    if command -v sqlcmd &> /dev/null; then
        # Add test driver
        sqlcmd -S "${SQL_SERVER}.database.windows.net,1433" -d $SQL_DATABASE -U sqladmin -P "$SQL_SERVER_PASSWORD" -Q "
        IF NOT EXISTS (SELECT 1 FROM Drivers WHERE Id = '550e8400-e29b-41d4-a716-446655440001')
        BEGIN
            INSERT INTO Drivers (Id, Name, LicenseNumber, Status)
            VALUES ('550e8400-e29b-41d4-a716-446655440001', 'Test Driver', 'TEST123', 'Active')
        END"
        
        # Add test vehicle
        sqlcmd -S "${SQL_SERVER}.database.windows.net,1433" -d $SQL_DATABASE -U sqladmin -P "$SQL_SERVER_PASSWORD" -Q "
        IF NOT EXISTS (SELECT 1 FROM Vehicles WHERE Id = '550e8400-e29b-41d4-a716-446655440001')
        BEGIN
            INSERT INTO Vehicles (Id, PlateNumber, Model, Status)
            VALUES ('550e8400-e29b-41d4-a716-446655440001', 'TEST123', 'Test Model', 'Active')
        END"
        
        echo -e "${GREEN}✅ Test data added successfully using sqlcmd${NC}"
        return 0
    else
        # Fallback to Azure CLI
        echo -e "${YELLOW}⚠️  sqlcmd not found, trying Azure CLI...${NC}"
        
        # Add test driver
        az sql db query \
            --server $SQL_SERVER \
            --name $SQL_DATABASE \
            --resource-group $RESOURCE_GROUP \
            --query "
            IF NOT EXISTS (SELECT 1 FROM Drivers WHERE Id = '550e8400-e29b-41d4-a716-446655440001')
            BEGIN
                INSERT INTO Drivers (Id, Name, LicenseNumber, Status)
                VALUES ('550e8400-e29b-41d4-a716-446655440001', 'Test Driver', 'TEST123', 'Active')
            END"
        
        # Add test vehicle
        az sql db query \
            --server $SQL_SERVER \
            --name $SQL_DATABASE \
            --resource-group $RESOURCE_GROUP \
            --query "
            IF NOT EXISTS (SELECT 1 FROM Vehicles WHERE Id = '550e8400-e29b-41d4-a716-446655440001')
            BEGIN
                INSERT INTO Vehicles (Id, PlateNumber, Model, Status)
                VALUES ('550e8400-e29b-41d4-a716-446655440001', 'TEST123', 'Test Model', 'Active')
            END"
        
        echo -e "${GREEN}✅ Test data added successfully using Azure CLI${NC}"
        return 0
    fi
}

# =============================================================================
# Main Script
# =============================================================================

echo "🚀 Starting RealTimeApp..."
echo ""

# Check if ports are available
echo -e "${BLUE}Checking port availability...${NC}"

if check_port $API_PORT; then
    echo -e "${RED}❌ Port $API_PORT is already in use${NC}"
    exit 1
fi

if check_port $SYNCAPI_PORT; then
    echo -e "${RED}❌ Port $SYNCAPI_PORT is already in use${NC}"
    exit 1
fi

if check_port $FRONTEND_PORT; then
    echo -e "${RED}❌ Port $FRONTEND_PORT is already in use${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All ports are available${NC}"

# Check Azure service connections
echo ""
echo -e "${BLUE}Checking Azure service connections...${NC}"

check_azure_service "$SQL_SERVER" "sql"
check_azure_service "$REDIS_NAME" "redis"
check_azure_service "$SERVICEBUS_NAME" "servicebus"
check_azure_service "$SIGNALR_NAME" "signalr"
check_azure_service "$EVENTGRID_TOPIC" "eventgrid"

# Add test data
echo ""
add_test_data

# Start the applications
echo ""
echo -e "${BLUE}Starting applications...${NC}"

# Start Main API
echo -e "${BLUE}Starting Main API on port $API_PORT...${NC}"
cd "$PROJECT_ROOT/RealTimeApp.Api" && dotnet run --urls "http://localhost:$API_PORT" > "$PROJECT_ROOT/logs/api.log" 2>&1 &
API_PID=$!

# Start SyncAPI
echo -e "${BLUE}Starting SyncAPI on port $SYNCAPI_PORT...${NC}"
cd "$PROJECT_ROOT/RealTimeApp.SyncApi" && dotnet run --urls "http://localhost:$SYNCAPI_PORT" > "$PROJECT_ROOT/logs/syncapi.log" 2>&1 &
SYNCAPI_PID=$!

# Start Frontend
echo -e "${BLUE}Starting Frontend on port $FRONTEND_PORT...${NC}"
cd "$PROJECT_ROOT/realtime-app-frontend" && npm run dev > "$PROJECT_ROOT/logs/frontend.log" 2>&1 &
FRONTEND_PID=$!

# Wait for applications to start
echo ""
echo -e "${BLUE}Waiting for applications to start...${NC}"
sleep 5

# Check if applications are running
if ps -p $API_PID > /dev/null; then
    echo -e "${GREEN}✅ Main API is running on port $API_PORT${NC}"
else
    echo -e "${RED}❌ Main API failed to start${NC}"
    exit 1
fi

if ps -p $SYNCAPI_PID > /dev/null; then
    echo -e "${GREEN}✅ SyncAPI is running on port $SYNCAPI_PORT${NC}"
else
    echo -e "${RED}❌ SyncAPI failed to start${NC}"
    exit 1
fi

if ps -p $FRONTEND_PID > /dev/null; then
    echo -e "${GREEN}✅ Frontend is running on port $FRONTEND_PORT${NC}"
else
    echo -e "${RED}❌ Frontend failed to start${NC}"
    exit 1
fi

# =============================================================================
# Final Status
# =============================================================================
echo ""
echo -e "${GREEN}🎉 RealTimeApp is running!${NC}"
echo ""
echo -e "📊 Status:"
echo -e "   ✅ Main API: http://localhost:$API_PORT"
echo -e "   ✅ SyncAPI: http://localhost:$SYNCAPI_PORT"
echo -e "   ✅ Frontend: http://localhost:$FRONTEND_PORT"
echo ""
echo -e "📝 Logs:"
echo -e "   📄 API: $PROJECT_ROOT/logs/api.log"
echo -e "   📄 SyncAPI: $PROJECT_ROOT/logs/syncapi.log"
echo -e "   📄 Frontend: $PROJECT_ROOT/logs/frontend.log"
echo ""
echo -e "🛑 To stop all applications, run:"
echo -e "   pkill -f 'dotnet run'"
echo -e "   pkill -f 'npm run dev'"
echo ""
echo -e "💡 To restart everything, just run this script again." 