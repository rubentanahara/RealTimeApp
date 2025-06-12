#!/bin/bash

# =============================================================================
# RealTimeApp - Prerequisites Checker
# =============================================================================
# This script checks if all prerequisites are installed and configured
# =============================================================================

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SQL_DIR="$PROJECT_ROOT/sql"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🔍 Checking RealTimeApp prerequisites..."
echo ""

# =============================================================================
# 1. Check Azure CLI
# =============================================================================
echo -e "${BLUE}1. Checking Azure CLI...${NC}"
if command -v az &> /dev/null; then
    AZ_VERSION=$(az --version | head -n 1)
    echo -e "   ✅ Azure CLI is installed: $AZ_VERSION"
    
    # Check if logged in
    if az account show &> /dev/null; then
        echo -e "   ✅ Logged into Azure"
        echo -e "   ℹ️  Current subscription: $(az account show --query name -o tsv)"
    else
        echo -e "   ❌ Not logged into Azure"
        echo -e "   💡 Run: az login"
    fi
else
    echo -e "   ❌ Azure CLI is not installed"
    echo -e "   💡 Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
fi

# =============================================================================
# 2. Check .NET SDK
# =============================================================================
echo ""
echo -e "${BLUE}2. Checking .NET SDK...${NC}"
if command -v dotnet &> /dev/null; then
    DOTNET_VERSION=$(dotnet --version)
    echo -e "   ✅ .NET SDK is installed: $DOTNET_VERSION"
    
    # Check if it's version 7.0 or higher
    if [[ $(echo "$DOTNET_VERSION" | cut -d. -f1) -ge 7 ]]; then
        echo -e "   ✅ .NET SDK version is compatible (7.0 or higher)"
    else
        echo -e "   ⚠️  .NET SDK version might be too old (need 7.0 or higher)"
        echo -e "   💡 Download from: https://dotnet.microsoft.com/download"
    fi
else
    echo -e "   ❌ .NET SDK is not installed"
    echo -e "   💡 Download from: https://dotnet.microsoft.com/download"
fi

# =============================================================================
# 3. Check Node.js
# =============================================================================
echo ""
echo -e "${BLUE}3. Checking Node.js...${NC}"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "   ✅ Node.js is installed: $NODE_VERSION"
    
    # Check if it's version 16 or higher
    if [[ $(echo "$NODE_VERSION" | cut -d. -f1 | tr -d 'v') -ge 16 ]]; then
        echo -e "   ✅ Node.js version is compatible (16 or higher)"
    else
        echo -e "   ⚠️  Node.js version might be too old (need 16 or higher)"
        echo -e "   💡 Download from: https://nodejs.org/"
    fi
else
    echo -e "   ❌ Node.js is not installed"
    echo -e "   💡 Download from: https://nodejs.org/"
fi

# =============================================================================
# 4. Check Additional Tools
# =============================================================================
echo ""
echo -e "${BLUE}4. Checking Additional Tools...${NC}"

# Check sqlcmd
if command -v sqlcmd &> /dev/null; then
    echo -e "   ✅ sqlcmd is installed"
else
    echo -e "   ⚠️  sqlcmd is not installed (optional, but recommended)"
    echo -e "   💡 Install SQL Server Command Line Tools"
fi

# Check redis-cli
if command -v redis-cli &> /dev/null; then
    echo -e "   ✅ redis-cli is installed"
else
    echo -e "   ⚠️  redis-cli is not installed (optional, but recommended)"
    echo -e "   💡 Install Redis CLI tools"
fi

# =============================================================================
# 5. Check Project Structure
# =============================================================================
echo ""
echo -e "${BLUE}5. Checking Project Structure...${NC}"

# Required directories
REQUIRED_DIRS=(
    "RealTimeApp.Api"
    "RealTimeApp.SyncApi"
    "RealTimeApp.Domain"
    "RealTimeApp.Infrastructure"
    "realtime-app-frontend"
)

# Required files
REQUIRED_FILES=(
    "RealTimeApp.sln"
    "realtime-app-frontend/package.json"
    "$SQL_DIR/create_tables.sql"
    "$SQL_DIR/enable_change_tracking.sql"
)

# Check directories
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$PROJECT_ROOT/$dir" ]; then
        echo -e "   ✅ Directory exists: $dir"
    else
        echo -e "   ❌ Missing directory: $dir"
    fi
done

# Check files
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$PROJECT_ROOT/$file" ]; then
        echo -e "   ✅ File exists: $file"
    else
        echo -e "   ❌ Missing file: $file"
    fi
done

# =============================================================================
# 6. Check Azure Permissions
# =============================================================================
echo ""
echo -e "${BLUE}6. Checking Azure Permissions...${NC}"

# Check if user has necessary permissions
if az account show &> /dev/null; then
    # Check SQL Server permissions
    if az sql server list &> /dev/null; then
        echo -e "   ✅ Has SQL Server permissions"
    else
        echo -e "   ❌ Missing SQL Server permissions"
    fi
    
    # Check Redis Cache permissions
    if az redis list &> /dev/null; then
        echo -e "   ✅ Has Redis Cache permissions"
    else
        echo -e "   ❌ Missing Redis Cache permissions"
    fi
    
    # Check Service Bus permissions
    if az servicebus namespace list &> /dev/null; then
        echo -e "   ✅ Has Service Bus permissions"
    else
        echo -e "   ❌ Missing Service Bus permissions"
    fi
    
    # Check SignalR permissions
    if az signalr list &> /dev/null; then
        echo -e "   ✅ Has SignalR permissions"
    else
        echo -e "   ❌ Missing SignalR permissions"
    fi
    
    # Check Event Grid permissions
    if az eventgrid topic list &> /dev/null; then
        echo -e "   ✅ Has Event Grid permissions"
    else
        echo -e "   ❌ Missing Event Grid permissions"
    fi
else
    echo -e "   ⚠️  Not logged into Azure"
    echo -e "   💡 Run: az login"
fi

echo ""
echo -e "${GREEN}✅ Prerequisites check completed!${NC}"
echo ""
echo -e "💡 If you see any ❌ or ⚠️, please fix those issues before proceeding."
echo -e "   After fixing, run this script again to verify everything is ready." 