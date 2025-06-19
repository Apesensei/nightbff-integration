# 🧪 NightBFF Integration Testing Repository

> **Status:** Scaffolding in Progress 🏗️  
> **Owner:** DevOps / Platform Team  
> **Source Plan:** [HYBRID_INTEGRATION_DEV_PLAN.md](../HYBRID_INTEGRATION_DEV_PLAN.md)

## 1. Purpose

This repository is the single source of truth for end-to-end (E2E), contract, and performance testing for the NightBFF platform. It provides a hermetic, Docker-based environment to validate the integration between the backend (`nightbff-backend`) and frontend (`nightbff-ios-frontend`) repositories before any code is merged into their respective `main` branches.

**Do not commit application source code here.** This repository consumes the backend and frontend applications as Git submodules and runs tests against them in a black-box manner.

## 2. Quick Start

### Prerequisites
- Docker & Docker Compose
- `gh` CLI

### Running the Test Suite
1. **Clone this repository.**
2. **Initialize submodules:** `git submodule update --init --recursive`
3. **Set up environment:** `cp .env.integration.example .env` and fill in any required values.
4. **Run the stack:** `docker-compose up -d`
5. **Execute tests:** 
   - `docker-compose exec cypress-runner yarn test` (for E2E tests)
   - `docker-compose run k6 run /scripts/main.js` (for load tests)

## 3. Workflow

Refer to **Section 4: Branching Workflow** in the [main integration plan](../HYBRID_INTEGRATION_DEV_PLAN.md) for a detailed breakdown of how integration branches are created, tested, and merged. 