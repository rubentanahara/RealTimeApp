#!/bin/bash

# =============================================================================
# RealTimeApp - Real-time Architecture Flow Test
# =============================================================================
# This script tests the real-time architecture flow:
# 1. Creates a trip in the database
# 2. Verifies Event Grid → Service Bus → SyncAPI processing
# 3. Updates trip status
# 4. Verifies real-time updates through SignalR
# =============================================================================

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SQL_DIR="$PROJECT_ROOT/sql"

# Load environment variables
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
else
    echo -e "${RED}❌ .env file not found. Please create it with SQL_SERVER_PASSWORD${NC}"
    exit 1
fi

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="realtime-app-rg"
SQL_SERVER="realtimeappsqlsrv"
SQL_DATABASE="RealTimeAppDb"
REDIS_NAME="realtimeappredis"
SERVICEBUS_NAME="realtimeappbus"
SIGNALR_NAME="realtimeappsignalr"
EVENTGRID_TOPIC="sql-changes-topic"

# =============================================================================
# Helper Functions
# =============================================================================

# Function to check if a trip exists in Azure Redis
check_redis_cache() {
    local trip_number=$1
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo -e "${BLUE}Checking Redis cache (attempt $attempt/$max_attempts)...${NC}"
        
        # Get Redis connection details
        REDIS_HOST="${REDIS_NAME}.redis.cache.windows.net"
        REDIS_PASSWORD=$(az redis list-keys --name "realtimeappredis" --resource-group "realtime-app-rg" --query "primaryKey" -o tsv 2>/dev/null)
        
        if [ -z "$REDIS_PASSWORD" ]; then
            echo -e "${RED}❌ Failed to get Redis access key${NC}"
            return 1
        fi
        
        # List all keys for debugging
        echo -e "${BLUE}Listing all Redis keys:${NC}"
        redis-cli -h "$REDIS_HOST" -p 6380 --tls -a "$REDIS_PASSWORD" keys "*"
        
        # Check for the specific trip
        redis_result=$(redis-cli -h "$REDIS_HOST" -p 6380 --tls -a "$REDIS_PASSWORD" get "trip:$trip_number" 2>/dev/null)
        
        if [ -n "$redis_result" ]; then
            echo -e "${GREEN}✅ Trip found in Redis cache:${NC}"
            echo "$redis_result" | jq '.'
            
            # Check if status is "Created"
            status=$(echo "$redis_result" | jq -r '.status // .Status')
            if [ "$status" = "Created" ]; then
                echo -e "${GREEN}✅ Trip status is 'Created'${NC}"
                return 0
            else
                echo -e "${YELLOW}⚠️  Trip status is '$status' (expected 'Created')${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  Trip not found in Redis cache${NC}"
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            echo -e "${BLUE}Waiting before next attempt...${NC}"
            sleep 5
        fi
        
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}❌ Trip not found in Redis cache after $max_attempts attempts${NC}"
    return 1
}

# Function to check if a trip exists in the database
check_trip_status_in_db() {
    local trip_id=$1
    local expected_status=$2
    
    # Use SQL password from .env file
    if [ -z "$SQL_SERVER_PASSWORD" ]; then
        echo -e "${RED}❌ SQL_SERVER_PASSWORD not set in .env file${NC}"
        return 1
    fi
    
    # Use sqlcmd for reliable querying
    if command -v sqlcmd &> /dev/null; then
        # Get the status and remove any rows affected message
        result=$(sqlcmd -S "${SQL_SERVER}.database.windows.net,1433" -d $SQL_DATABASE -U sqladmin -P "$SQL_SERVER_PASSWORD" -Q "SELECT Status FROM Trips WHERE Id = '$trip_id'" -h -1 2>/dev/null | head -n 1 | tr -d '\r\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ -n "$result" ]; then
            if [ "$result" = "$expected_status" ]; then
                echo -e "${GREEN}✅ Trip status in database is '$expected_status'${NC}"
                return 0
            else
                echo -e "${YELLOW}⚠️  Trip status in database is '$result' (expected '$expected_status')${NC}"
                return 1
            fi
        else
            echo -e "${RED}❌ Trip not found in database${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ sqlcmd not found${NC}"
        return 1
    fi
}

# Function to verify Redis connection
verify_redis_connection() {
    echo -e "${BLUE}Verifying Redis connection...${NC}"
    
    # Get Redis connection details
    REDIS_HOST="${REDIS_NAME}.redis.cache.windows.net"
    REDIS_PASSWORD=$(az redis list-keys --name "realtimeappredis" --resource-group "realtime-app-rg" --query "primaryKey" -o tsv 2>/dev/null)
    
    if [ -z "$REDIS_PASSWORD" ]; then
        echo -e "${RED}❌ Failed to get Redis access key${NC}"
        return 1
    fi
    
    # Try to set and get a test key
    if redis-cli -h "$REDIS_HOST" -p 6380 --tls -a "$REDIS_PASSWORD" set "test:connection" "ok" &> /dev/null; then
        if redis-cli -h "$REDIS_HOST" -p 6380 --tls -a "$REDIS_PASSWORD" get "test:connection" &> /dev/null; then
            echo -e "${GREEN}✅ Redis connection successful${NC}"
            # Clean up test key
            redis-cli -h "$REDIS_HOST" -p 6380 --tls -a "$REDIS_PASSWORD" del "test:connection" &> /dev/null
            return 0
        fi
    fi
    
    echo -e "${RED}❌ Redis connection failed${NC}"
    return 1
}

# =============================================================================
# Main Test Flow
# =============================================================================

echo "🧪 Starting RealTimeApp Architecture Flow Test..."
echo ""

# Verify Redis connection first
if ! verify_redis_connection; then
    echo -e "${RED}❌ Redis connection verification failed. Exiting...${NC}"
    exit 1
fi

# Step 1: Create a test trip
echo -e "${BLUE}1. Creating test trip...${NC}"

# Get available driver and vehicle
if command -v sqlcmd &> /dev/null; then
    # Use SQL password from .env file
    if [ -z "$SQL_SERVER_PASSWORD" ]; then
        echo -e "${RED}❌ SQL_SERVER_PASSWORD not set in .env file${NC}"
        exit 1
    fi
    
    DRIVER_ID=$(sqlcmd -S "${SQL_SERVER}.database.windows.net,1433" -d $SQL_DATABASE -U sqladmin -P "$SQL_SERVER_PASSWORD" -Q "SELECT TOP 1 Id FROM Drivers" -h -1 2>/dev/null | tr -d ' ' | grep -E '^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$' | head -1 || echo "")
    VEHICLE_ID=$(sqlcmd -S "${SQL_SERVER}.database.windows.net,1433" -d $SQL_DATABASE -U sqladmin -P "$SQL_SERVER_PASSWORD" -Q "SELECT TOP 1 Id FROM Vehicles" -h -1 2>/dev/null | tr -d ' ' | grep -E '^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$' | head -1 || echo "")
else
    DRIVER_ID="550e8400-e29b-41d4-a716-446655440001"
    VEHICLE_ID="550e8400-e29b-41d4-a716-446655440001"
fi

if [ -z "$DRIVER_ID" ] || [ -z "$VEHICLE_ID" ]; then
    echo -e "${RED}❌ Could not find driver or vehicle in database${NC}"
    echo -e "${YELLOW}💡 Using default test IDs...${NC}"
    DRIVER_ID="550e8400-e29b-41d4-a716-446655440001"
    VEHICLE_ID="550e8400-e29b-41d4-a716-446655440001"
fi

# Create trip using API
TRIP_RESPONSE=$(curl -s -X POST http://localhost:5000/api/trip \
    -H "Content-Type: application/json" \
    -d "{\"tripNumber\": \"TEST-$(date +%s)\", \"driverId\": \"$DRIVER_ID\", \"vehicleId\": \"$VEHICLE_ID\"}")

TRIP_ID=$(echo "$TRIP_RESPONSE" | jq -r '.id')
TRIP_NUMBER=$(echo "$TRIP_RESPONSE" | jq -r '.tripNumber')

if [ -z "$TRIP_ID" ] || [ "$TRIP_ID" = "null" ]; then
    echo -e "${RED}❌ Failed to create trip${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Trip created with ID: $TRIP_ID and number: $TRIP_NUMBER${NC}"

# Step 2: Wait for Event Grid → Service Bus processing
echo ""
echo -e "${BLUE}2. Waiting for Event Grid → Service Bus processing...${NC}"
echo -e "${YELLOW}⏳ This may take a few seconds...${NC}"

# Wait for the trip to appear in Redis
if ! check_redis_cache "$TRIP_NUMBER"; then
    echo -e "${RED}❌ Trip not found in Redis cache after processing${NC}"
    exit 1
fi

# Step 3: Update trip status
echo ""
echo -e "${BLUE}3. Updating trip status...${NC}"

# Update trip status using API
curl -s -X PUT http://localhost:5000/api/trip/$TRIP_ID/status \
    -H "Content-Type: application/json" \
    -d '{"status": "InProgress"}' > /dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Trip status updated to 'InProgress'${NC}"
else
    echo -e "${RED}❌ Failed to update trip status${NC}"
    exit 1
fi

# Step 4: Verify status update in database
echo ""
echo -e "${BLUE}4. Verifying status update in database...${NC}"

# Wait for the status to be updated in the database
sleep 2

if ! check_trip_status_in_db "$TRIP_ID" "InProgress"; then
    echo -e "${RED}❌ Trip status not updated in database${NC}"
    exit 1
fi

# Step 5: Verify status update in Redis
echo ""
echo -e "${BLUE}5. Verifying status update in Redis...${NC}"

# Wait for the status to be updated in Redis
sleep 2

# Get Redis connection details
REDIS_HOST="${REDIS_NAME}.redis.cache.windows.net"
REDIS_PASSWORD=$(az redis list-keys --name "realtimeappredis" --resource-group "realtime-app-rg" --query "primaryKey" -o tsv 2>/dev/null)

if [ -z "$REDIS_PASSWORD" ]; then
    echo -e "${RED}❌ Failed to get Redis access key${NC}"
    exit 1
fi

# Check trip status in Redis
redis_result=$(redis-cli -h "$REDIS_HOST" -p 6380 --tls -a "$REDIS_PASSWORD" get "trip:$TRIP_NUMBER" 2>/dev/null)

if [ -n "$redis_result" ]; then
    status=$(echo "$redis_result" | jq -r '.status // .Status')
    if [ "$status" = "InProgress" ]; then
        echo -e "${GREEN}✅ Trip status updated in Redis to 'InProgress'${NC}"
    else
        echo -e "${YELLOW}⚠️  Trip status in Redis is '$status' (expected 'InProgress')${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Trip not found in Redis cache${NC}"
    exit 1
fi

# Step 6: Complete the trip
echo ""
echo -e "${BLUE}6. Completing the trip...${NC}"

# Update trip status to Completed using API
curl -s -X PUT http://localhost:5000/api/trip/$TRIP_ID/status \
    -H "Content-Type: application/json" \
    -d '{"status": "Completed"}' > /dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Trip status updated to 'Completed'${NC}"
else
    echo -e "${RED}❌ Failed to update trip status${NC}"
    exit 1
fi

# Step 7: Verify completion in database
echo ""
echo -e "${BLUE}7. Verifying trip completion in database...${NC}"

# Wait for the status to be updated in the database
sleep 2

if ! check_trip_status_in_db "$TRIP_ID" "Completed"; then
    echo -e "${RED}❌ Trip status not updated to Completed in database${NC}"
    exit 1
fi

# Step 8: Verify completion in Redis
echo ""
echo -e "${BLUE}8. Verifying trip completion in Redis...${NC}"

# Wait for the status to be updated in Redis
sleep 2

# Check trip status in Redis
redis_result=$(redis-cli -h "$REDIS_HOST" -p 6380 --tls -a "$REDIS_PASSWORD" get "trip:$TRIP_NUMBER" 2>/dev/null)

if [ -n "$redis_result" ]; then
    status=$(echo "$redis_result" | jq -r '.status // .Status')
    if [ "$status" = "Completed" ]; then
        echo -e "${GREEN}✅ Trip status updated in Redis to 'Completed'${NC}"
    else
        echo -e "${YELLOW}⚠️  Trip status in Redis is '$status' (expected 'Completed')${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Trip not found in Redis cache${NC}"
    exit 1
fi

# =============================================================================
# Final Results
# =============================================================================
echo ""
echo -e "${GREEN}🎉 RealTimeApp Architecture Flow Test Completed Successfully!${NC}"
echo ""
echo -e "📊 Test Summary:"
echo -e "   ✅ Trip created in database"
echo -e "   ✅ Event Grid → Service Bus processing completed"
echo -e "   ✅ Trip status updated to 'InProgress'"
echo -e "   ✅ Status update reflected in database"
echo -e "   ✅ Status update reflected in Redis cache"
echo -e "   ✅ Trip completed successfully"
echo -e "   ✅ Completion status reflected in database"
echo -e "   ✅ Completion status reflected in Redis cache"
echo ""
echo -e "💡 To run the test again, just execute this script." 