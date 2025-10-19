# Environment Contracts (Integration)

This document captures the canonical environment contract required by the NightBFF integration stack.

## Variables (integration stack)
- NODE_ENV: integration
- POSTGRES_HOST: db
- POSTGRES_PORT: 5432
- POSTGRES_USER: admin
- POSTGRES_PASSWORD: (GitHub Secret)
- POSTGRES_DB: nightbff_integration_db
- REDIS_HOST: redis
- REDIS_PORT: 6379
- JWT_SECRET: (GitHub Secret; min 32 chars)
- DISABLE_EXTERNAL_APIS: true

## Health endpoints
- Backend: GET http://localhost:3000/health → 200
- Frontend (web build): GET http://localhost:8081/ → HTML served (nginx)

## Enforcement
- env schema validated in backend image via `npm run env:lint`
- ADR-016: forbid DB_* variables (use POSTGRES_*)
