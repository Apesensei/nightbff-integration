#!/usr/bin/env bash
# validate-workspace.sh - Validates workspace configuration
set -euo pipefail

echo "🔍 Validating workspace configuration..."

# Check package.json has workspaces field
if ! grep -q '"workspaces"' package.json; then
    echo "❌ No workspaces field found in package.json"
    exit 1
fi

# Check workspace paths exist
if ! grep -q '"backend/app"' package.json; then
    echo "❌ Backend workspace not found in package.json"
    exit 1
fi

if ! grep -q '"nightbff-frontend"' package.json; then
    echo "❌ Frontend workspace not found in package.json"
    exit 1
fi

# Check that dev script exists in package.json
if ! grep -q '"dev":' package.json; then
    echo "❌ Dev script not found in package.json"
    exit 1
fi

# Verify npm recognizes the workspaces
if [ ! -d "backend/app" ] || [ ! -f "backend/app/package.json" ]; then
    echo "❌ Backend workspace directory or package.json missing"
    exit 1
fi

if [ ! -d "nightbff-frontend" ] || [ ! -f "nightbff-frontend/package.json" ]; then
    echo "❌ Frontend workspace directory or package.json missing"
    exit 1
fi

echo "✅ Workspace configuration validation passed - ready for development" 