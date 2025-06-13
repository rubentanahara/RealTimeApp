#!/bin/bash

# =============================================================================
# Generate .env file for RealTimeApp
# =============================================================================

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Generating .env file for RealTimeApp...${NC}"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo -e "${RED}❌ Not logged in to Azure. Please run 'az login' first.${NC}"
    exit 1
fi

# Resource Group
RESOURCE_GROUP="realtime-app-rg"

# SQL Server Configuration
SQL_SERVER="realtimeappsqlsrv"
SQL_DATABASE="RealTimeAppDb"
echo -e "${YELLOW}⚠️  SQL Server password needs to be set manually in Azure Portal or using Azure CLI${NC}"
echo -e "${YELLOW}   Command to reset password: az sql server update --name $SQL_SERVER --resource-group $RESOURCE_GROUP --admin-password \"YourNewPassword\"${NC}"
read -p "Enter SQL Server password: " SQL_SERVER_PASSWORD

# Redis Configuration
echo -e "${BLUE}Getting Redis configuration...${NC}"
REDIS_NAME="realtimeappredis"
REDIS_PASSWORD=$(az redis list-keys --name $REDIS_NAME --resource-group $RESOURCE_GROUP --query "primaryKey" -o tsv)

# Service Bus Configuration
echo -e "${BLUE}Getting Service Bus configuration...${NC}"
SERVICEBUS_NAME="realtimeappbus"
SERVICEBUS_QUEUE="trip-changes-queue"
SERVICEBUS_CONNECTION=$(az servicebus namespace authorization-rule keys list \
    --resource-group $RESOURCE_GROUP \
    --namespace-name $SERVICEBUS_NAME \
    --name RootManageSharedAccessKey \
    --query "primaryConnectionString" -o tsv)

# SignalR Configuration
echo -e "${BLUE}Getting SignalR configuration...${NC}"
SIGNALR_NAME="realtimeappsignalr"
SIGNALR_CONNECTION=$(az signalr key list \
    --name $SIGNALR_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "primaryConnectionString" -o tsv)

# Event Grid Configuration
echo -e "${BLUE}Getting Event Grid configuration...${NC}"
EVENTGRID_TOPIC="sql-changes-topic"
EVENTGRID_TOPIC_ENDPOINT=$(az eventgrid topic show \
    --name $EVENTGRID_TOPIC \
    --resource-group $RESOURCE_GROUP \
    --query "endpoint" -o tsv)
EVENTGRID_TOPIC_KEY=$(az eventgrid topic key list \
    --name $EVENTGRID_TOPIC \
    --resource-group $RESOURCE_GROUP \
    --query "key1" -o tsv)

# Key Vault Configuration
KEY_VAULT_NAME="realtime-app-kv"

# Application Ports
API_PORT=5000
SYNCAPI_PORT=5001
FRONTEND_PORT=3000

# Create .env file
echo -e "${BLUE}Creating .env file...${NC}"
cat > "$ENV_FILE" << EOL
# Azure Resource Group
RESOURCE_GROUP="$RESOURCE_GROUP"

# SQL Server Configuration
SQL_SERVER="$SQL_SERVER"
SQL_DATABASE="$SQL_DATABASE"
SQL_SERVER_PASSWORD="$SQL_SERVER_PASSWORD"

# Redis Configuration
REDIS_NAME="$REDIS_NAME"
REDIS_PASSWORD="$REDIS_PASSWORD"

# Service Bus Configuration
SERVICEBUS_NAME="$SERVICEBUS_NAME"
SERVICEBUS_QUEUE="$SERVICEBUS_QUEUE"
SERVICEBUS_CONNECTION="$SERVICEBUS_CONNECTION"

# SignalR Configuration
SIGNALR_NAME="$SIGNALR_NAME"
SIGNALR_CONNECTION="$SIGNALR_CONNECTION"

# Event Grid Configuration
EVENTGRID_TOPIC="$EVENTGRID_TOPIC"
EVENTGRID_TOPIC_ENDPOINT="$EVENTGRID_TOPIC_ENDPOINT"
EVENTGRID_TOPIC_KEY="$EVENTGRID_TOPIC_KEY"

# Key Vault Configuration
KEY_VAULT_NAME="$KEY_VAULT_NAME"

# Application Ports
API_PORT=$API_PORT
SYNCAPI_PORT=$SYNCAPI_PORT
FRONTEND_PORT=$FRONTEND_PORT
EOL

echo -e "${GREEN}✅ .env file created successfully at: $ENV_FILE${NC}"
echo -e "${YELLOW}⚠️  Make sure to add .env to your .gitignore file${NC}" 