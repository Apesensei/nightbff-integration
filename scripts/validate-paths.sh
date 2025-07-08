#!/usr/bin/env bash
# validate-paths.sh - Validates the new backend path structure
set -euo pipefail

echo "🔍 Validating repository path structure..."

# Check .gitmodules
if ! grep -q "path = backend" .gitmodules; then
    echo "❌ Backend submodule path not updated in .gitmodules"
    exit 1
fi

# Check no app/app references in workflows
if grep -r "app/app" .github/workflows/ 2>/dev/null; then
    echo "❌ Found app/app references in workflows"
    exit 1
fi

# Check backend references exist in integration workflow
if ! grep -q "working-directory: ./backend" .github/workflows/integration-ci.yml; then
    echo "❌ Backend working directory not found in integration workflow"
    exit 1
fi

echo "✅ Path structure validation passed - ready for CI" 