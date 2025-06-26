#!/bin/sh
# scripts/run-migrations.sh

# Exit immediately if a command exits with a non-zero status.
set -e

# Wait for the database to be ready
# Note: nc (netcat) might not be in the base node image, a small utility might need to be added to the Dockerfile if so.
echo "Waiting for db:5432..."
while ! nc -z db 5432; do
  sleep 1
done
echo "PostgreSQL started"

# Run the migrations
echo "Running database migrations..."
npm run typeorm:migration:run -- -d dist/data-source.js
echo "Migrations finished." 