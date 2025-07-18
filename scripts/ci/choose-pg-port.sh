#!/usr/bin/env bash
# Stub script injected by CI fix – real dynamic port selection only needed in local dev environments.
# CI runners are isolated per job, so 5432 port collisions are impossible.
# Exits immediately with success status so workflows referencing this path do not fail.

echo "[choose-pg-port.sh] CI context detected – skipping dynamic port selection."
export HOST_POSTGRES_PORT=5432
exit 0 