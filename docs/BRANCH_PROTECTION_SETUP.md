# Branch Protection Setup Guide

## Overview

This document provides step-by-step instructions for implementing branch protection rules in the NightBFF Integration repository, as required by Task 1.3 of the Evergreen CI initiative.

## 🎯 Objectives

- Protect `main` branch with comprehensive CI requirements
- Implement lighter protection for `integration/**` branches
- Ensure all merges require green CI status
- Maintain development agility while enforcing quality gates

## 📋 Prerequisites

1. Repository admin access to `Apesensei/nightbff-integration`
2. Verified CI workflow (`integration-ci.yml`) is functional
3. Understanding of team's current Git workflow

## 🔐 Protection Rules Summary

### Main Branch (`main`)

**Protection Level:** 🔴 **STRICT**

**Required Status Checks:**

- `sanity` - Submodule sanity verification
- `unit_backend` - Backend unit tests with coverage
- `unit_frontend` - Frontend unit tests
- `contract_backend` - API contract validation
- `integration_tests` - End-to-end integration tests

**Additional Rules:**

- ✅ Require branches to be up to date before merging
- ✅ Require conversation resolution before merging
- ✅ Require linear history (supports fast-forward merge strategy)
- ✅ Restrict push access to repository administrators only
- ❌ No force pushes allowed
- ❌ No deletions allowed
- ⚠️ Signed commits: **Optional - not required initially**

### Integration Branches (`integration/**`)

**Protection Level:** 🟡 **BALANCED**

**Required Status Checks:**

- `sanity` - Minimum safety check for submodule integrity
- `unit_backend` - Core backend functionality verification

**Rationale:** integration branches are short-lived (≤5 days) and experimental in nature, used for cross-team collaboration. Lighter protection maintains development agility while ensuring basic safety.

## 🛠️ Implementation Methods

### Method 1: GitHub Web UI (Recommended)

1. Navigate to repository: `https://github.com/Apesensei/nightbff-integration`
2. Go to **Settings** → **Branches**
3. Click **Add rule**

#### For Main Branch:

- **Branch name pattern:** `main`
- ✅ **Require status checks to pass before merging**
  - ✅ **Require branches to be up to date before merging**
  - **Status checks found in the last week for this repository:**
    - ✅ `sanity`
    - ✅ `unit_backend`
    - ✅ `unit_frontend`
    - ✅ `contract_backend`
    - ✅ `integration_tests`
- ✅ **Require conversation resolution before merging**
- ✅ **Require linear history**
- ✅ **Restrict pushes that create files**
  - ✅ **Restrict who can push to matching branches**
    - Select: "Restrict pushes that create files"
- ❌ **Allow force pushes** (keep unchecked)
- ❌ **Allow deletions** (keep unchecked)

#### For Integration Branches:

- **Branch name pattern:** `integration/**`
- ✅ **Require status checks to pass before merging**
  - ❌ **Require branches to be up to date before merging** (unchecked)
  - **Status checks:**
    - ✅ `sanity`
    - ✅ `unit_backend`
- ❌ All other options unchecked

### Method 2: GitHub CLI (Advanced)

```bash
# Install GitHub CLI if not available
# https://cli.github.com/

# Authenticate
gh auth login

# Run the generated commands from setup script
./scripts/setup-branch-protection.sh

# Example GitHub CLI commands:
gh api repos/Apesensei/nightbff-integration/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["sanity","unit_backend","unit_frontend","contract_backend","integration_tests"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  --field restrictions=null \
  --field required_linear_history=true \
  --field allow_force_pushes=false \
  --field allow_deletions=false
```

### Method 3: GitHub API (Automation)

Use the API calls generated by `./scripts/setup-branch-protection.sh` for automation or CI/CD integration.

## ✅ Verification Steps

### 1. Test Main Branch Protection

Create a test branch and attempt to merge without CI:

```bash
git checkout -b test/branch-protection
echo "test" >> README.md
git add README.md
git commit -m "test: verify branch protection"
git push origin test/branch-protection

# Create PR targeting main - should require status checks
gh pr create --title "Test: Branch Protection" --body "Testing branch protection rules" --base main
```

Expected result: PR should show "Merging is blocked" until all required checks pass.

### 2. Test Integration Branch Protection

```bash
git checkout -b integration/test-protection
echo "test" >> README.md
git add README.md
git commit -m "test: verify integration protection"
git push origin integration/test-protection

# Create PR targeting integration branch
gh pr create --title "Test: Integration Protection" --body "Testing integration branch protection" --base integration/test-protection
```

Expected result: Only `sanity` and `unit_backend` checks required.

## 🚨 Important Notes

### Signed Commits Decision

**Current Status:** ❌ **Not Required Initially**

**Rationale:**

- Requires team training on GPG key setup and commit signing workflow
- May disrupt current development workflow during transition period
- Team productivity prioritized over security enhancement in Phase 1
- Can be enabled later after proper team onboarding and training session

**Future Implementation:**

1. Conduct team training session on commit signing
2. Update documentation with signing setup guide
3. Enable requirement in branch protection settings

### Impact on Development Workflow

**Before Protection:**

- Direct pushes to `main` allowed
- Merges possible without CI validation
- Risk of broken `main` branch

**After Protection:**

- All changes must go through PR process
- CI must pass before merge
- Enhanced code quality and stability
- Slight increase in development overhead (justified by stability gains)

## 📞 Support

**Issues with Branch Protection:**

- Contact: DevOps team
- Escalation: Tech Lead
- Documentation: This guide + `scripts/setup-branch-protection.sh`

**CI/CD Issues:**

- Check: `.github/workflows/integration-ci.yml`
- Logs: GitHub Actions tab
- Debug: `scripts/validate-workspace.sh`

## 📝 Change Log

| Date       | Author        | Changes                         |
| ---------- | ------------- | ------------------------------- |
| 2025-07-07 | Platform Team | Initial branch protection setup |

---

> 🎯 **Success Criteria:** Branch protection rules implemented, `main` branch secure, CI enforcement active, team workflow documented.
