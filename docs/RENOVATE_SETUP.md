# Renovate Bot Setup Guide

This document explains how to configure and manage automated dependency updates using Renovate Bot.

## Overview

Renovate Bot is configured to automatically update npm dependencies in this repository with the following strategy:

- **Schedule**: Weekly updates (Saturdays)
- **Auto-merge**: Enabled for patch/minor updates of safe packages
- **Security updates**: High priority with immediate processing
- **Major updates**: Manual review required

## Configuration

The Renovate configuration is defined in `.renovaterc.json` with the following key features:

### Update Strategy

| Update Type                     | Auto-merge | Schedule                | Review Required         |
| ------------------------------- | ---------- | ----------------------- | ----------------------- |
| **Patch/Minor** (safe packages) | ✅ Yes     | Weekly                  | ❌ No                   |
| **Major updates**               | ❌ No      | Weekly                  | ✅ Yes                  |
| **Security updates**            | ✅ Yes     | Immediate               | ⚠️ Notify security team |
| **Lock file maintenance**       | ✅ Yes     | Weekly (early Saturday) | ❌ No                   |

### Package Grouping

Dependencies are grouped for better management:

- **React Native ecosystem**: All React Native, Expo, and related packages
- **NestJS ecosystem**: All NestJS and related backend packages
- **TypeScript tooling**: ESLint, Prettier, TypeScript, and @types packages
- **Docker images**: Node.js base image updates

### Rate Limiting

To prevent overwhelming the team:

- Maximum 3 PRs per hour
- Maximum 5 concurrent PRs
- Maximum 10 concurrent branches

## Setup Instructions

### 1. GitHub App Installation (Repository Admin Required)

1. **Install Renovate GitHub App**:
   - Go to https://github.com/apps/renovate
   - Click "Install" and select the repository
   - Grant necessary permissions:
     - Read access to metadata and code
     - Write access to issues, PRs, and contents

2. **Configure Repository Settings**:
   - Ensure branch protection rules allow Renovate to create PRs
   - Add Renovate bot to the list of allowed force-push users (if needed)

### 2. Team Access Configuration

Update the team mentions in `.renovaterc.json`:

```json
{
  "assignees": ["@YourOrg/platform-team"],
  "reviewers": ["@YourOrg/platform-team"],
  "packageRules": [
    {
      "matchUpdateTypes": ["major"],
      "reviewers": ["@YourOrg/tech-leads"]
    },
    {
      "labels": ["security", "urgent"],
      "reviewers": ["@YourOrg/security-team"]
    }
  ]
}
```

### 3. Validation

The repository includes a GitHub Actions workflow that validates the Renovate configuration:

```bash
# Trigger validation manually
git add .renovaterc.json
git commit -m "feat(deps): update renovate configuration"
git push
```

The workflow will:

- Validate JSON syntax
- Check configuration against Renovate schema
- Verify required fields are present
- Generate a configuration summary

## Daily Operations

### Dependency Dashboard

Renovate creates a "Dependency Updates Dashboard" issue that tracks:

- All pending updates
- Failed update attempts
- Configuration errors

**Location**: Check repository issues for "🤖 Dependency Updates Dashboard"

### Handling Update PRs

#### Auto-merged Updates

- Patch/minor updates for safe packages are automatically merged when CI passes
- Lock file maintenance happens automatically
- Security updates are processed immediately

#### Manual Review Required

- **Major updates**: Review for breaking changes, update documentation
- **React Native/NestJS**: Test thoroughly due to ecosystem complexity
- **Docker updates**: Verify compatibility with CI/production environments

### Monitoring

#### CI Integration

All Renovate PRs must pass:

- `sanity` check
- `unit_backend` tests
- `unit_frontend` tests
- `contract_backend` tests

If any check fails, the PR will not auto-merge and requires manual intervention.

#### Labels for Organization

- `dependencies`: All Renovate PRs
- `automated`: Auto-mergeable updates
- `major-update`: Requires manual review
- `security`: Security-related updates
- `react-native`, `nestjs`: Ecosystem-specific updates

## Troubleshooting

### Common Issues

#### 1. Renovate Not Creating PRs

- Check if GitHub App is properly installed
- Verify repository permissions in Renovate dashboard
- Check for configuration errors in Dependency Dashboard issue

#### 2. Auto-merge Not Working

- Ensure branch protection rules allow auto-merge
- Check if all required status checks are passing
- Verify `platformAutomerge` is not disabled

#### 3. Too Many PRs

- Adjust rate limits in `.renovaterc.json`:
  ```json
  {
    "prHourlyLimit": 2,
    "prConcurrentLimit": 3
  }
  ```

#### 4. Security Updates Not Processing

- Check vulnerability database is up to date
- Verify `osvVulnerabilityAlerts` is enabled
- Review security team notification settings

### Configuration Updates

To modify Renovate behavior:

1. **Update `.renovaterc.json`**
2. **Test configuration**:
   ```bash
   npx renovate-config-validator .renovaterc.json
   ```
3. **Commit changes** - validation workflow will run automatically
4. **Monitor Dependency Dashboard** for changes to take effect

### Emergency Procedures

#### Pause All Updates

Add to `.renovaterc.json`:

```json
{
  "enabled": false
}
```

#### Skip Specific Packages

```json
{
  "ignoreDeps": ["package-name", "@scope/package-name"]
}
```

#### Force Immediate Run

Comment on Dependency Dashboard issue:

```
@renovate[bot] run
```

## Best Practices

### Review Guidelines

1. **Major updates**: Always test locally before merging
2. **Framework updates**: Coordinate with team, plan for potential breaking changes
3. **Security updates**: Prioritize and merge quickly after CI validation
4. **Group updates**: Review related packages together

### Monitoring Health

- Weekly review of Dependency Dashboard
- Monthly review of ignored/failed updates
- Quarterly review of Renovate configuration effectiveness

### Team Coordination

- Assign team members to specific update types
- Use PR discussions for complex updates
- Document any manual interventions in PR comments

## Additional Resources

- [Renovate Documentation](https://docs.renovatebot.com/)
- [Configuration Options](https://docs.renovatebot.com/configuration-options/)
- [GitHub App Setup](https://github.com/apps/renovate)
- [Vulnerability Alerts](https://docs.renovatebot.com/vulnerability-alerts/)
