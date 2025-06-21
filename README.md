# 🧪 NightBFF Integration Testing Repository

[![Integration CI](https://github.com/Apesensei/nightbff-integration/actions/workflows/integration-ci.yml/badge.svg)](https://github.com/Apesensei/nightbff-integration/actions/workflows/integration-ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **Status:** ✅ Active - CI Pipeline Enabled  
> **Owner:** DevOps / Platform Team  
> **Source Plan:** [HYBRID_INTEGRATION_DEV_PLAN.md](../HYBRID_INTEGRATION_DEV_PLAN.md)

## 1. Purpose

This repository is the **single source of truth** for end-to-end (E2E), contract, and performance testing for the NightBFF platform. It provides a hermetic, Docker-based environment to validate the integration between the backend (`nightbff-backend`) and frontend (`nightbff-ios-frontend`) repositories before any code is merged into their respective `main` branches.

**Do not commit application source code here.** This repository consumes the backend and frontend applications as Git submodules and runs tests against them in a black-box manner.

## 2. CI Pipeline Overview

The integration CI pipeline implements a comprehensive job matrix:

```
setup_cache → unit_backend + unit_frontend + contract_backend → compose_up → cypress_e2e + k6_load → publish_reports → notify_completion
```

### Pipeline Jobs

| Job | Purpose | Required | Timeout |
|-----|---------|----------|---------|
| `setup_cache` | Node.js dependency caching | ✅ | 5 min |
| `unit_backend` | Backend unit tests + coverage | ✅ | 10 min |
| `unit_frontend` | Frontend unit tests + coverage | ✅ | 10 min |
| `contract_backend` | Pact contract tests | ✅ | 5 min |
| `compose_up` | Docker stack validation | ✅ | 15 min |
| `cypress_e2e` | End-to-end smoke tests | ✅ | 20 min |
| `k6_load` | Performance load tests | ⚠️ | 15 min |
| `publish_reports` | Artifact consolidation | ✅ | 5 min |

**Legend:** ✅ Required (blocks merge) | ⚠️ Optional (can fail without blocking)

### Performance Thresholds

- **HTTP Error Rate:** < 10% for integration tests
- **Response Time P95:** < 250ms for all endpoints
- **Health Check P95:** < 100ms
- **Auth Endpoint P95:** < 500ms
- **Plan Endpoint P95:** < 300ms

## 3. Quick Start

### Prerequisites
- Docker & Docker Compose
- Node.js 18+ (for local development)
- Git with submodule support

### Running Tests Locally

```bash
# 1. Clone and setup
git clone https://github.com/Apesensei/nightbff-integration.git
cd nightbff-integration
git submodule update --init --recursive

# 2. Start the integration stack
docker-compose up -d --wait

# 3. Wait for backend health
timeout 120 bash -c 'until curl -f http://localhost:3000/health; do sleep 2; done'

# 4. Run tests
# Cypress E2E tests
npx cypress run --spec "tests/e2e-cypress/**/*.cy.js"

# k6 Load tests  
k6 run tests/load-k6/integration-smoke.js

# 5. Cleanup
docker-compose down -v --remove-orphans
```

### Environment Configuration

Copy `.env.integration` and adjust for your environment:

```bash
# Database
DATABASE_URL=postgresql://admin:password@postgres_integration:5432/defaultdb

# Redis
REDIS_HOST=redis_integration
REDIS_PORT=6379

# Backend
NODE_ENV=integration
JWT_SECRET=integration-test-secret

# Performance Testing
VUS=5                    # Virtual users for k6
DURATION=30s            # Test duration
BASE_URL=http://localhost:3000
```

## 4. Workflow Integration

### Integration Branch Lifecycle

1. **Create Integration Branches**
   ```bash
   # In backend repo
   git checkout -b integration/YYMMDD-feature-name
   
   # In frontend repo  
   git checkout -b integration/YYMMDD-feature-name
   ```

2. **Update Submodule References**
   ```bash
   # In this repo
   git submodule update --remote app
   git submodule update --remote nightbff-frontend
   git add .gitmodules app nightbff-frontend
   git commit -m "Update submodules to integration branches"
   ```

3. **Push and Monitor CI**
   - Push triggers automatic CI pipeline
   - Monitor job progress in GitHub Actions
   - All required jobs must pass for merge approval

4. **Merge and Cleanup**
   - Merge integration branches to main in both repos
   - Delete integration branches within 5 days
   - Archive integration repo branch

## 5. Test Structure

### Cypress E2E Tests (`tests/e2e-cypress/`)
- **smoke.cy.js** - Basic endpoint and health validation
- Focuses on API integration and service connectivity
- Validates authentication flow and error handling

### k6 Load Tests (`tests/load-k6/`)
- **integration-smoke.js** - Performance validation under load
- Tests response times and error rates
- Validates database and cache connectivity under stress

### Contract Tests (Backend Repo)
- Pact files generated in backend CI
- Uploaded as artifacts for consumer verification
- Validates API contract compliance

## 6. Monitoring and Alerts

### Metrics Collection
- Coverage reports uploaded to artifacts
- k6 performance metrics exported as JSON
- Docker compose logs captured on failure

### Failure Notifications
- Slack alerts for failed required jobs
- GitHub status checks block merge when red
- Detailed logs available in Actions artifacts

## 7. Development Guidelines

### Adding New Tests

**Cypress Tests:**
```javascript
// tests/e2e-cypress/new-feature.cy.js
describe('New Feature Integration', () => {
  it('should validate new endpoint', () => {
    cy.request('GET', 'http://localhost:3000/api/new-feature')
      .then((response) => {
        expect(response.status).to.eq(200);
      });
  });
});
```

**k6 Load Tests:**
```javascript
// tests/load-k6/new-feature-load.js
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  stages: [{ duration: '30s', target: 10 }],
  thresholds: { 'http_req_duration': ['p(95)<500'] },
};

export default function () {
  const res = http.get('http://localhost:3000/api/new-feature');
  check(res, { 'status is 200': (r) => r.status === 200 });
}
```

### Debugging Failed Tests

1. **Check Docker Logs**
   ```bash
   docker-compose logs backend
   docker-compose logs db
   ```

2. **Download CI Artifacts**
   - Coverage reports
   - Cypress videos/screenshots  
   - k6 performance results
   - Docker compose logs

3. **Local Reproduction**
   ```bash
   # Use exact same image tags as CI
   docker-compose up -d
   # Run specific failing test
   npx cypress run --spec "tests/e2e-cypress/failing-test.cy.js"
   ```

## 8. Architecture

### Service Dependencies
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │     Redis        │    │   Backend API   │
│   (Database)    │◄───┤   (Cache)        │◄───┤   (NestJS)      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                                                         ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Cypress       │    │      k6          │    │   Test Runner   │
│   (E2E Tests)   │◄───┤  (Load Tests)    │◄───┤   (CI Pipeline) │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Image Management
- Backend: `ghcr.io/apesensei/nightbff-backend:int-<sha>`
- Frontend: `ghcr.io/apesensei/nightbff-frontend:int-<sha>`
- Images auto-updated in CI with commit SHA

## 9. Contributing

1. **Fork and Branch**: Create feature branch from `main`
2. **Test Locally**: Ensure tests pass with your changes
3. **Submit PR**: Include test updates for new features
4. **Code Review**: Requires approval from CODEOWNERS
5. **Merge**: Squash and merge after CI passes

## 10. Support

- **Issues**: GitHub Issues in this repository
- **Documentation**: See [HYBRID_INTEGRATION_DEV_PLAN.md](../HYBRID_INTEGRATION_DEV_PLAN.md)
- **Slack**: #nightbff-integration channel
- **On-call**: DevOps team rotation

---

**Last Updated:** 2025-06-19  
**CI Pipeline Version:** v1.0  
**Maintained by:** @nightbff/devops