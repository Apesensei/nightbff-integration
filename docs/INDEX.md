# NightBFF Integration Documentation Index

## Overview

This document provides a centralized index of all documentation in the NightBFF Integration repository.

## Core Documentation

### Development & Setup

- [Local Development Setup](./LOCAL_DEVELOPMENT_SETUP.md) - Complete local development environment setup
- [Team Protocol](./TEAM_PROTOCOL.md) - Team collaboration guidelines and protocols

### CI/CD & Infrastructure

- [Branch Protection Setup](./BRANCH_PROTECTION_SETUP.md) - GitHub branch protection configuration
- [Renovate Setup](./RENOVATE_SETUP.md) - Automated dependency update configuration
- [Security Audit Implementation](./SECURITY_AUDIT_IMPLEMENTATION.md) - Security audit CI integration
- [ADR-001: Digest-Driven Integration](./adr/ADR-001-digest-integration.md) - Integration by digest, no submodules

### Technical Debt & Fixes

- [TDL-001 Fix Summary](./TDL-001-FIX-SUMMARY.md) - Technical debt list item 1
- [TDL-003 Fix Summary](./TDL-003-FIX-SUMMARY.md) - Technical debt list item 3
- [TDL-004 Fix Summary](./TDL-004-FIX-SUMMARY.md) - Technical debt list item 4
- [TDL-005 Fix Summary](./TDL-005-FIX-SUMMARY.md) - Technical debt list item 5
- [TDL-006 Security Audit Implementation](./TDL-006-SECURITY-AUDIT-IMPLEMENTATION.md) - **NEW** - Security audit implementation summary

## Security Documentation

### Security Implementation

- [Security Audit Implementation](./SECURITY_AUDIT_IMPLEMENTATION.md) - **NEW** - Comprehensive security audit documentation
- [TDL-006 Security Audit](./TDL-006-SECURITY-AUDIT-IMPLEMENTATION.md) - **NEW** - Security audit implementation summary

### Security Status

- **Current Security Level**: 🟢 PRODUCTION READY
- **Vulnerability Status**: 5 low-severity vulnerabilities (acceptable)
- **Security Coverage**: Real-time CI scanning active
- **Next Steps**: HTTPS implementation, additional hardening

## Quick Reference

### Common Commands

```bash
# Local development
npm run dev:db          # Start local database
npm run start:dev       # Start backend server

# Integration testing
docker compose up -d    # Start integration stack
npm run test           # Run tests

# Security audit
npm audit              # Check vulnerabilities
npm audit fix          # Fix vulnerabilities
```

### Health Checks

- Integration backend: `GET http://localhost:3000/health`
- Local backend: `GET http://localhost:3001/health`

### Important Files

- CI Configuration: `.github/workflows/integration-ci.yml`
- Orchestrator: `.github/workflows/orchestrate-publish-and-integration.yml`
- Security Audit: `docs/SECURITY_AUDIT_IMPLEMENTATION.md`
- Environment: `config/integration.env`
- ADRs: `docs/adr/` (integration digest architecture)

### Image References
- Backend: `ghcr.io/apesensei/nightbff-backend` (digest-based)
- Frontend: `ghcr.io/apesensei/nightbff-frontend-web` (digest-based)
- Producer ADRs: See backend/frontend repos (`docs/adr/`)

---

**Last Updated**: September 4, 2025  
**Maintained By**: Development Team  
**Review Cycle**: Monthly
