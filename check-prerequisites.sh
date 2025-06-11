#!/bin/bash

# =============================================================================
# RealTimeApp Prerequisites Checker
# =============================================================================
# This script checks if all prerequisites are met for Azure deployment
# =============================================================================

echo "🔍 Checking prerequisites for RealTimeApp Azure deployment..."
echo ""

# Track overall status
ALL_GOOD=true

# =============================================================================
# Check Azure CLI
# =============================================================================
echo "1. Checking Azure CLI..."
if command -v az &> /dev/null; then
    AZ_VERSION=$(az --version | head -n 1 | cut -d' ' -f2)
    echo "   ✅ Azure CLI installed: $AZ_VERSION"
    
    # Check if logged in
    if az account show &> /dev/null; then
        ACCOUNT_NAME=$(az account show --query name -o tsv)
        SUBSCRIPTION_ID=$(az account show --query id -o tsv)
        echo "   ✅ Logged in to Azure: $ACCOUNT_NAME ($SUBSCRIPTION_ID)"
    else
        echo "   ❌ Not logged in to Azure. Run: az login"
        ALL_GOOD=false
    fi
else
    echo "   ❌ Azure CLI not installed"
    echo "      Install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    ALL_GOOD=false
fi

# =============================================================================
# Check .NET SDK
# =============================================================================
echo ""
echo "2. Checking .NET SDK..."
if command -v dotnet &> /dev/null; then
    DOTNET_VERSION=$(dotnet --version)
    echo "   ✅ .NET SDK installed: $DOTNET_VERSION"
    
    # Check if .NET 9.0 or later
    MAJOR_VERSION=$(echo $DOTNET_VERSION | cut -d'.' -f1)
    if [ "$MAJOR_VERSION" -ge 9 ]; then
        echo "   ✅ .NET version is compatible (9.0+)"
    else
        echo "   ⚠️  .NET version may be incompatible. Recommended: 9.0+"
    fi
else
    echo "   ❌ .NET SDK not installed"
    echo "      Install: https://dotnet.microsoft.com/download"
    ALL_GOOD=false
fi

# =============================================================================
# Check Node.js
# =============================================================================
echo ""
echo "3. Checking Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "   ✅ Node.js installed: $NODE_VERSION"
    
    # Check if Node.js 18.0 or later
    MAJOR_VERSION=$(echo $NODE_VERSION | sed 's/v//' | cut -d'.' -f1)
    if [ "$MAJOR_VERSION" -ge 18 ]; then
        echo "   ✅ Node.js version is compatible (18.0+)"
    else
        echo "   ⚠️  Node.js version may be incompatible. Recommended: 18.0+"
    fi
    
    # Check npm
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        echo "   ✅ npm installed: $NPM_VERSION"
    else
        echo "   ❌ npm not found (should come with Node.js)"
        ALL_GOOD=false
    fi
else
    echo "   ❌ Node.js not installed"
    echo "      Install: https://nodejs.org/"
    ALL_GOOD=false
fi

# =============================================================================
# Check required tools
# =============================================================================
echo ""
echo "4. Checking additional tools..."

# Check zip
if command -v zip &> /dev/null; then
    echo "   ✅ zip command available"
else
    echo "   ❌ zip command not found"
    echo "      Install: apt-get install zip (Linux) or brew install zip (macOS)"
    ALL_GOOD=false
fi

# Check curl
if command -v curl &> /dev/null; then
    echo "   ✅ curl command available"
else
    echo "   ❌ curl command not found"
    echo "      Install: Usually pre-installed on most systems"
    ALL_GOOD=false
fi

# =============================================================================
# Check project structure
# =============================================================================
echo ""
echo "5. Checking project structure..."

REQUIRED_DIRS=(
    "RealTimeApp.Api"
    "RealTimeApp.SyncApi"
    "RealTimeApp.Domain"
    "RealTimeApp.Infrastructure"
    "RealTimeApp.Application"
    "realtime-app-frontend"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "   ✅ $dir directory found"
    else
        echo "   ❌ $dir directory not found"
        ALL_GOOD=false
    fi
done

# Check key files
REQUIRED_FILES=(
    "RealTimeApp.sln"
    "realtime-app-frontend/package.json"
    "create_tables.sql"
    "enable_change_tracking.sql"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file found"
    else
        echo "   ❌ $file not found"
        ALL_GOOD=false
    fi
done

# =============================================================================
# Check Azure permissions (basic check)
# =============================================================================
echo ""
echo "6. Checking Azure permissions..."

if az account show &> /dev/null; then
    # Try to list resource groups to test permissions
    if az group list --query "[0].name" -o tsv &> /dev/null; then
        echo "   ✅ Can list resource groups (basic permission check passed)"
    else
        echo "   ❌ Cannot list resource groups (insufficient permissions)"
        ALL_GOOD=false
    fi
else
    echo "   ⏭️  Skipping permission check (not logged in to Azure)"
fi

# =============================================================================
# Final summary
# =============================================================================
echo ""
echo "=========================================="
if [ "$ALL_GOOD" = true ]; then
    echo "🎉 All prerequisites are met!"
    echo ""
else
    echo "❌ Some prerequisites are missing or not properly configured."
    echo ""
    echo "🔧 Please fix the issues above before proceeding with deployment."
    echo ""
    echo "📚 Installation guides:"
    echo "   • Azure CLI: https://docs.microsoft.com/cli/azure/install-azure-cli"
    echo "   • .NET SDK: https://dotnet.microsoft.com/download"
    echo "   • Node.js: https://nodejs.org/"
    echo "   • Azure Login: az login"
fi

echo ""
echo "💡 Need help? Check the DEPLOYMENT_GUIDE.md for detailed instructions." 