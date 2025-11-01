# ADR-001: Digest-Driven Integration Testing

## Status
Accepted

## Context
Integration repo previously used git submodules and root npm workspaces. To achieve hermetic, reproducible integration tests, we must:
1. Remove submodules/workspaces
2. Consume backend/frontend images by digest only
3. Run all test logic inside containers (no root npm)

## Decision
1. Remove `.gitmodules` and submodule directories
2. Remove root `package.json` workspaces (keep minimal for CI tools only)
3. Integration CI workflow accepts digests as inputs
4. Generate `compose.override.yml` dynamically with digest references
5. Run migrations, seeding, token generation inside backend container
6. Run k6 and Cypress via official actions (no local npm)
7. Orchestrator workflow calls producer workflows, passes digests to integration

## Implementation
- Workflow: `.github/workflows/integration-ci.yml`
- Orchestrator: `.github/workflows/orchestrate-publish-and-integration.yml`
- Env: `config/integration.env` (owned by integration repo)
- Compose override: Generated at runtime with digest-based image refs
- Backend healthcheck: Added to override for `docker compose up -d --wait` gating

## Consequences
### Positive
- No submodule sync issues
- Reproducible tests (digest-based)
- Faster CI (no root npm installs)
- Hermetic: all logic in containers

### Negative
- Must update orchestrator when producer workflows change
- Integration depends on producer repos being accessible

## Migration Notes
- Old package `ghcr.io/apesensei/nightbff-frontend` deleted
- New package: `ghcr.io/apesensei/nightbff-frontend-web`
- Integration CI updated to use new package name

## References
- Plan: `docs/plans/Digest.plan.md`
- Integration CI: `.github/workflows/integration-ci.yml`
- Orchestrator: `.github/workflows/orchestrate-publish-and-integration.yml`

