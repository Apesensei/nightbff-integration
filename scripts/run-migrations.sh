#!/bin/sh
# scripts/run-migrations.sh
# Updated for Phase 3: Uses Phase 2 established migration commands with governance enforcement

# Exit immediately if a command exits with a non-zero status.
set -e

echo "🔧 NightBFF Integration Migration Runner - Phase 3"
echo "================================================="

# EXPORT the database URL to make it available to the TypeORM CLI
export DATABASE_URL="postgresql://admin:testpassword@db:5432/nightbff_integration_db?schema=public"

# Wait for the database to be ready
echo "⏳ Waiting for database connectivity (db:5432)..."
while ! nc -z db 5432; do
  echo "   Database not ready, waiting 1 second..."
  sleep 1
done
echo "✅ PostgreSQL connection established"

# Phase 3: Add migration validation step for governance enforcement
echo ""
echo "🔍 Step 1: Validating migration files (governance enforcement)..."
npm run migration:validate
if [ $? -eq 0 ]; then
    echo "✅ Migration validation passed"
else
    echo "❌ Migration validation failed - blocking deployment"
    exit 1
fi

# Show current migration status before running
echo ""
echo "📊 Step 2: Current migration status..."
npm run migration:show

# Run the migrations using Phase 2 established command
echo ""
echo "🚀 Step 3: Running database migrations..."
npm run migration:run

# Verify migrations completed successfully
echo ""
echo "✅ Step 4: Verifying migration completion..."
npm run migration:show

echo ""
echo "🎉 Migration process completed successfully!"
echo "   All governance checks passed"
echo "   Single source of truth maintained (backend repository)"
echo "=================================================" 