#!/bin/bash

# Real-Time Architecture Flow Test Script
# Tests: Trip Creation → Database → Event Grid → Service Bus → SyncAPI → Redis Cache
# Tests: Status Updates: Created → Started → Complete

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
API_URL="http://localhost:5000"
SYNC_API_URL="http://localhost:5001"

echo -e "${BLUE}🚀 Real-Time Architecture Flow Test${NC}"
echo -e "${BLUE}======================================${NC}"

# Function to check if services are running
check_services() {
    echo -e "\n${YELLOW}🔍 Checking Services...${NC}"
    
    # Check API
    if curl -s "$API_URL/health" > /dev/null; then
        echo -e "${GREEN}✅ API is running on $API_URL${NC}"
    else
        echo -e "${RED}❌ API is not responding on $API_URL${NC}"
        exit 1
    fi
    
    # Check SyncAPI
    if curl -s "$SYNC_API_URL/health" > /dev/null; then
        echo -e "${GREEN}✅ SyncAPI is running on $SYNC_API_URL${NC}"
    else
        echo -e "${RED}❌ SyncAPI is not responding on $SYNC_API_URL${NC}"
        exit 1
    fi
}

# Function to get database connection details
get_db_connection() {
    echo -e "\n${YELLOW}🔗 Getting Database Connection...${NC}"
    
    # Get Key Vault name
    KEYVAULT_NAME=$(az keyvault list --query "[0].name" -o tsv 2>/dev/null || echo "realtime-app-kv")
    
    # Get connection string from Key Vault
    DB_CONNECTION=$(az keyvault secret show --vault-name "$KEYVAULT_NAME" --name "SqlConnectionString" --query "value" -o tsv 2>/dev/null)
    
    if [ -z "$DB_CONNECTION" ]; then
        echo -e "${RED}❌ Could not get database connection string${NC}"
        exit 1
    fi
    
    # Extract server and database from connection string
    DB_SERVER=$(echo "$DB_CONNECTION" | grep -o 'Server=[^;]*' | cut -d'=' -f2)
    DB_NAME=$(echo "$DB_CONNECTION" | grep -o 'Database=[^;]*' | cut -d'=' -f2)
    DB_USER=$(echo "$DB_CONNECTION" | grep -o 'User Id=[^;]*' | cut -d'=' -f2)
    
    echo -e "${GREEN}✅ Database: $DB_NAME on $DB_SERVER${NC}"
}

# Function to clear database
clear_database() {
    echo -e "\n${YELLOW}🧹 Clearing Database...${NC}"
    
    # Clear trips first (foreign key constraints) - suppress output
    sqlcmd -S "$DB_SERVER" -d "$DB_NAME" -U "$DB_USER" -P "NewS3cureP@ssw0rd" -Q "SET NOCOUNT ON; DELETE FROM Trips;" -h -1 -W > /dev/null
    sqlcmd -S "$DB_SERVER" -d "$DB_NAME" -U "$DB_USER" -P "NewS3cureP@ssw0rd" -Q "SET NOCOUNT ON; DELETE FROM Vehicles;" -h -1 -W > /dev/null
    sqlcmd -S "$DB_SERVER" -d "$DB_NAME" -U "$DB_USER" -P "NewS3cureP@ssw0rd" -Q "SET NOCOUNT ON; DELETE FROM Drivers;" -h -1 -W > /dev/null
    
    echo -e "${GREEN}✅ Database cleared${NC}"
}

# Function to create test data
create_test_data() {
    echo -e "\n${YELLOW}🏗️ Creating Test Data...${NC}"
    
    # Generate UUIDs for test data
    DRIVER_ID=$(uuidgen)
    VEHICLE_ID=$(uuidgen)
    
    # Create Driver directly in database
    sqlcmd -S "$DB_SERVER" -d "$DB_NAME" -U "$DB_USER" -P "NewS3cureP@ssw0rd" -Q "
        SET NOCOUNT ON; INSERT INTO Drivers (Id, Name, LicenseNumber, Status, LastModified, Version) 
        VALUES ('$DRIVER_ID', 'Test Driver', 'DL12345', 'Available', GETUTCDATE(), 1);" -h -1 -W > /dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Driver created: $DRIVER_ID${NC}"
    else
        echo -e "${RED}❌ Failed to create driver${NC}"
        exit 1
    fi
    
    # Create Vehicle directly in database
    sqlcmd -S "$DB_SERVER" -d "$DB_NAME" -U "$DB_USER" -P "NewS3cureP@ssw0rd" -Q "
        SET NOCOUNT ON; INSERT INTO Vehicles (Id, LicensePlate, Model, Status, LastModified, Version) 
        VALUES ('$VEHICLE_ID', 'ABC123', 'Test Vehicle', 'Available', GETUTCDATE(), 1);" -h -1 -W > /dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Vehicle created: $VEHICLE_ID${NC}"
    else
        echo -e "${RED}❌ Failed to create vehicle${NC}"
        exit 1
    fi
}

# Function to verify database records
verify_database() {
    local table=$1
    local expected_count=$2
    
    local actual_count=$(sqlcmd -S "$DB_SERVER" -d "$DB_NAME" -U "$DB_USER" -P "NewS3cureP@ssw0rd" -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM $table;" -h -1 -W | tr -d '\r\n' | grep -o '[0-9]\+' | head -1)
    
    if [ "$actual_count" -eq "$expected_count" ]; then
        echo -e "${GREEN}✅ $table: $actual_count records (expected: $expected_count)${NC}"
        return 0
    else
        echo -e "${RED}❌ $table: $actual_count records (expected: $expected_count)${NC}"
        return 1
    fi
}

# Function to check trip status in database
check_trip_status_in_db() {
    local trip_id=$1
    local expected_status=$2
    
    # Use SET NOCOUNT ON to suppress "rows affected" message  
    local actual_status=$(sqlcmd -S "$DB_SERVER" -d "$DB_NAME" -U "$DB_USER" -P "NewS3cureP@ssw0rd" -Q "SET NOCOUNT ON; SELECT Status FROM Trips WHERE Id='$trip_id';" -h -1 -W | tr -d '\r\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [ "$actual_status" = "$expected_status" ]; then
        echo -e "${GREEN}✅ Database status: '$actual_status' (expected: '$expected_status')${NC}"
        return 0
    else
        echo -e "${RED}❌ Database status: '$actual_status' (expected: '$expected_status')${NC}"
        return 1
    fi
}

# Function to check Redis cache
check_redis_cache() {
    local trip_number=$1
    local expected_status=$2
    
    echo -e "\n${YELLOW}🔍 Checking Azure Redis Cache...${NC}"
    
    # Get Azure Redis details
    REDIS_HOST="realtimeappredis.redis.cache.windows.net"
    REDIS_KEY="trip:$trip_number"
    
    # Get Redis access key
    REDIS_PASSWORD=$(az redis list-keys --name "realtimeappredis" --resource-group "realtime-app-rg" --query "primaryKey" -o tsv 2>/dev/null)
    
    if [ -z "$REDIS_PASSWORD" ]; then
        echo -e "${RED}❌ Could not get Redis access key${NC}"
        return 1
    fi
    
    # Check if trip exists in Azure Redis
    REDIS_RESULT=$(redis-cli -h "$REDIS_HOST" -p 6380 --tls -a "$REDIS_PASSWORD" get "$REDIS_KEY" 2>/dev/null || echo "")
    
    if [ -n "$REDIS_RESULT" ] && [ "$REDIS_RESULT" != "(nil)" ]; then
        echo -e "${GREEN}✅ Trip found in Azure Redis cache${NC}"
        echo -e "${BLUE}Cache Key: $REDIS_KEY${NC}"
        
        # Check if status matches expected status (uppercase Status field)
        if [ -n "$expected_status" ]; then
            if echo "$REDIS_RESULT" | grep -q "\"Status\":\"$expected_status\""; then
                echo -e "${GREEN}✅ Redis cache status: '$expected_status'${NC}"
                return 0
            else
                echo -e "${RED}❌ Redis cache status doesn't match expected: '$expected_status'${NC}"
                echo -e "${BLUE}Cache Data: ${REDIS_RESULT:0:200}...${NC}"
                # Extract the actual status for debugging
                ACTUAL_STATUS=$(echo "$REDIS_RESULT" | grep -o '"Status":"[^"]*"' | cut -d'"' -f4)
                if [ -n "$ACTUAL_STATUS" ]; then
                    echo -e "${BLUE}Actual status in cache: '$ACTUAL_STATUS'${NC}"
                    # Check if it matches when we compare the actual values
                    if [ "$ACTUAL_STATUS" = "$expected_status" ]; then
                        echo -e "${GREEN}✅ Status values match - Redis sync successful${NC}"
                        return 0
                    fi
                fi
                return 1
            fi
        else
            echo -e "${BLUE}Cache Data: ${REDIS_RESULT:0:100}...${NC}"
            return 0
        fi
    else
        echo -e "${RED}❌ Trip not found in Azure Redis cache${NC}"
        return 1
    fi
}

# Function to monitor Service Bus
monitor_service_bus() {
    echo -e "\n${YELLOW}📊 Service Bus Status...${NC}"
    
    # Get Service Bus namespace
    SERVICEBUS_NAME=$(az servicebus namespace list --query "[0].name" -o tsv 2>/dev/null || echo "realtimeappbus")
    
    # Check queue message count
    MESSAGE_COUNT=$(az servicebus queue show --namespace-name "$SERVICEBUS_NAME" --name "trip-changes-queue" --resource-group "realtime-app-rg" --query "messageCount" -o tsv 2>/dev/null || echo "0")
    
    echo -e "${BLUE}Service Bus Queue Messages: $MESSAGE_COUNT${NC}"
}

# Function to update trip status
update_trip_status() {
    local trip_id=$1
    local new_status=$2
    local trip_number=$3
    
    echo -e "\n${PURPLE}🔄 Updating Trip Status: $new_status${NC}"
    echo -e "${PURPLE}================================${NC}"
    
    # Record start time
    START_TIME=$(date +%s)
    
    # Update trip status based on the new status
    if [ "$new_status" = "In Progress" ]; then
        # Use the start trip endpoint
        UPDATE_RESPONSE=$(curl -s -X PUT "$API_URL/api/trip/$trip_id/status" \
            -H "Content-Type: application/json" \
            -d "{
                \"status\": \"$new_status\"
            }")
    elif [ "$new_status" = "Completed" ]; then
        # Use the complete trip endpoint
        UPDATE_RESPONSE=$(curl -s -X PUT "$API_URL/api/trip/$trip_id/complete" \
            -H "Content-Type: application/json")
    else
        echo -e "${RED}❌ Unknown status: $new_status${NC}"
        return 1
    fi
    
    # Check if update was successful
    if echo "$UPDATE_RESPONSE" | grep -q '"status"'; then
        echo -e "${GREEN}✅ Trip status updated to: $new_status${NC}"
    else
        echo -e "${RED}❌ Failed to update trip status${NC}"
        echo -e "${RED}Response: $UPDATE_RESPONSE${NC}"
        return 1
    fi
    
    # Wait for processing (give it up to 10 seconds)
    echo -e "${BLUE}Waiting for Event Grid → Service Bus → SyncAPI processing...${NC}"
    for i in {1..10}; do
        sleep 1
        echo -n "."
        
        # Check if status update is reflected in database
        if check_trip_status_in_db "$trip_id" "$new_status" > /dev/null 2>&1; then
            break
        fi
    done
    echo ""
    
    # Verify status in database
    echo -e "\n${YELLOW}Step 1: Database Status Verification${NC}"
    if check_trip_status_in_db "$trip_id" "$new_status"; then
        echo -e "${GREEN}✅ Status updated in database${NC}"
    else
        echo -e "${RED}❌ Status not updated in database${NC}"
        return 1
    fi
    
    # Wait a bit more for Redis cache update
    echo -e "\n${BLUE}Waiting for Redis cache update...${NC}"
    for i in {1..5}; do
        sleep 1
        echo -n "."
        
        # Check if status update is reflected in Redis
        if check_redis_cache "$trip_number" "$new_status" > /dev/null 2>&1; then
            break
        fi
    done
    echo ""
    
    # Verify status in Redis cache
    echo -e "\n${YELLOW}Step 2: Redis Cache Status Verification${NC}"
    if check_redis_cache "$trip_number" "$new_status"; then
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        echo -e "${GREEN}✅ Status update flow completed in ${DURATION}s${NC}"
        return 0
    else
        echo -e "${RED}❌ Status update not reflected in Redis cache${NC}"
        return 1
    fi
}

# Function to create and test trip with full lifecycle
create_and_test_trip() {
    local trip_number=$1
    
    echo -e "\n${BLUE}🚗 Creating Trip #$trip_number${NC}"
    echo -e "${BLUE}========================${NC}"
    
    # Record start time
    START_TIME=$(date +%s)
    
    # Create trip
    TRIP_RESPONSE=$(curl -s -X POST "$API_URL/api/trip" \
        -H "Content-Type: application/json" \
        -d "{
            \"tripNumber\": \"TRIP-$trip_number\",
            \"driverId\": \"$DRIVER_ID\",
            \"vehicleId\": \"$VEHICLE_ID\"
        }")
    
    TRIP_ID=$(echo "$TRIP_RESPONSE" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$TRIP_ID" ]; then
        echo -e "${RED}❌ Failed to create trip${NC}"
        echo -e "${RED}Response: $TRIP_RESPONSE${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Trip created: $TRIP_ID${NC}"
    
    # Step 1: Verify initial creation in Database
    echo -e "\n${YELLOW}Step 1: Initial Database Verification${NC}"
    sleep 1
    
    if check_trip_status_in_db "$TRIP_ID" "Created"; then
        echo -e "${GREEN}✅ Trip created with 'Created' status${NC}"
    else
        echo -e "${RED}❌ Trip not found or wrong initial status${NC}"
        return 1
    fi
    
    # Wait for initial Event Grid → Service Bus → SyncAPI processing
    echo -e "\n${YELLOW}Step 2: Initial Event Processing Pipeline${NC}"
    echo -e "${BLUE}Waiting for initial Event Grid → Service Bus → SyncAPI...${NC}"
    
    for i in {1..10}; do
        sleep 1
        echo -n "."
        
        if check_redis_cache "TRIP-$trip_number" "Created" > /dev/null 2>&1; then
            break
        fi
    done
    echo ""
    
    # Verify initial Redis Cache
    echo -e "\n${YELLOW}Step 3: Initial Redis Cache Verification${NC}"
    if ! check_redis_cache "TRIP-$trip_number" "Created"; then
        echo -e "${RED}❌ Initial creation not reflected in Redis cache${NC}"
        return 1
    fi
    
    # Test Status Updates: Created → In Progress → Completed
    echo -e "\n${BLUE}🔄 Testing Status Update Lifecycle${NC}"
    echo -e "${BLUE}===================================${NC}"
    
    # Update 1: Created → In Progress
    if ! update_trip_status "$TRIP_ID" "In Progress" "TRIP-$trip_number"; then
        echo -e "${RED}❌ Failed to update to 'In Progress'${NC}"
        return 1
    fi
    
    echo -e "\n${BLUE}Waiting 3 seconds before next status update...${NC}"
    sleep 3
    
    # Update 2: In Progress → Completed
    if ! update_trip_status "$TRIP_ID" "Completed" "TRIP-$trip_number"; then
        echo -e "${RED}❌ Failed to update to 'Completed'${NC}"
        return 1
    fi
    
    # Final verification
    END_TIME=$(date +%s)
    TOTAL_DURATION=$((END_TIME - START_TIME))
    echo -e "\n${GREEN}🎉 Complete trip lifecycle tested successfully in ${TOTAL_DURATION}s${NC}"
    echo -e "${GREEN}   Created → In Progress → Completed${NC}"
    
    return 0
}

# Main execution
main() {
    echo -e "${BLUE}Starting Real-Time Architecture Test with Status Updates...${NC}"
    
    # Check services
    check_services
    
    # Get database connection
    get_db_connection
    
    # Clear existing data
    clear_database
    
    # Create test data
    create_test_data
    
    # Verify initial state
    echo -e "\n${YELLOW}📊 Initial Database State${NC}"
    verify_database "Drivers" 1
    verify_database "Vehicles" 1
    verify_database "Trips" 0
    
    # Test multiple trips with full lifecycle
    echo -e "\n${BLUE}🚀 Testing Real-Time Flow with Status Updates${NC}"
    
    SUCCESS_COUNT=0
    TOTAL_TESTS=2
    
    for i in $(seq 1 $TOTAL_TESTS); do
        if create_and_test_trip $i; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        fi
        
        if [ $i -lt $TOTAL_TESTS ]; then
            echo -e "\n${BLUE}Waiting 5 seconds before next test...${NC}"
            sleep 5
        fi
    done
    
    # Final verification
    echo -e "\n${BLUE}📊 Final Results${NC}"
    echo -e "${BLUE}===============${NC}"
    
    # Database counts
    verify_database "Drivers" 1
    verify_database "Vehicles" 1  
    verify_database "Trips" $TOTAL_TESTS
    
    # Service Bus status
    monitor_service_bus
    
    # Azure Redis verification
    echo -e "\n${YELLOW}🔍 Azure Redis Cache Summary${NC}"
    REDIS_PASSWORD=$(az redis list-keys --name "realtimeappredis" --resource-group "realtime-app-rg" --query "primaryKey" -o tsv 2>/dev/null)
    if [ -n "$REDIS_PASSWORD" ]; then
        REDIS_KEYS=$(redis-cli -h "realtimeappredis.redis.cache.windows.net" -p 6380 --tls -a "$REDIS_PASSWORD" keys "trip:*" 2>/dev/null | wc -l)
        echo -e "${BLUE}Total trips in Azure Redis cache: $REDIS_KEYS${NC}"
    else
        echo -e "${RED}❌ Could not access Azure Redis${NC}"
    fi
    
    # Show all trips in database with their final status
    echo -e "\n${YELLOW}📋 All Trips in Database (Final Status):${NC}"
    sqlcmd -S "$DB_SERVER" -d "$DB_NAME" -U "$DB_USER" -P "NewS3cureP@ssw0rd" -Q "SET NOCOUNT ON; SELECT Id, TripNumber, Status, LastModified FROM Trips ORDER BY LastModified;" -s "," -W
    
    # Summary
    echo -e "\n${BLUE}🎯 Test Summary${NC}"
    echo -e "${BLUE}==============${NC}"
    echo -e "${GREEN}✅ Successful tests: $SUCCESS_COUNT/$TOTAL_TESTS${NC}"
    
    if [ $SUCCESS_COUNT -eq $TOTAL_TESTS ]; then
        echo -e "${GREEN}🎉 ALL TESTS PASSED! Real-time architecture with status updates working perfectly!${NC}"
        echo -e "\n${BLUE}Complete Architecture Flow Confirmed:${NC}"
        echo -e "${GREEN}🎯 Trip Creation → Database (SQL Server)${NC}"
        echo -e "${GREEN}🔄 Status Updates: Created → In Progress → Completed${NC}"
        echo -e "${GREEN}📡 Event Publishing → Azure Event Grid${NC}"
        echo -e "${GREEN}🚌 Message Routing → Azure Service Bus${NC}"
        echo -e "${GREEN}⚡ Real-time Processing → SyncAPI → Redis Cache${NC}"
        echo -e "${GREEN}✨ Status Synchronization across all systems${NC}"
    else
        echo -e "${RED}❌ Some tests failed. Check the logs above.${NC}"
        exit 1
    fi
}

# Run main function
main "$@" 