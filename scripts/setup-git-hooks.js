#!/usr/bin/env node
/**
 * setup-git-hooks.js - NightBFF Integration Git Hooks Installation
 *
 * Automatically installs git hooks from .githooks/ directory to .git/hooks/
 * Called by npm postinstall script to ensure hooks are always set up correctly.
 */

const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

// Colors for console output
const colors = {
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  reset: "\x1b[0m",
};

function log(color, message) {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function checkGitRepository() {
  try {
    execSync("git rev-parse --git-dir", { stdio: "ignore" });
    return true;
  } catch (error) {
    return false;
  }
}

function ensureDirectoryExists(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
    log("blue", `📁 Created directory: ${dirPath}`);
  }
}

function installHook(hookName) {
  const sourceHook = path.join(".githooks", hookName);
  const targetHook = path.join(".git", "hooks", hookName);

  if (!fs.existsSync(sourceHook)) {
    log("yellow", `⚠️  Source hook not found: ${sourceHook}`);
    return false;
  }

  try {
    // Remove existing hook if it exists
    if (fs.existsSync(targetHook)) {
      fs.unlinkSync(targetHook);
      log("blue", `🗑️  Removed existing hook: ${targetHook}`);
    }

    // Create symlink to source hook
    const relativePath = path.relative(path.dirname(targetHook), sourceHook);
    fs.symlinkSync(relativePath, targetHook);

    // Make sure the hook is executable
    fs.chmodSync(targetHook, 0o755);

    log("green", `✅ Installed hook: ${hookName} -> ${relativePath}`);
    return true;
  } catch (error) {
    log("red", `❌ Failed to install hook ${hookName}: ${error.message}`);
    return false;
  }
}

function validateHookInstallation(hookName) {
  const targetHook = path.join(".git", "hooks", hookName);

  if (!fs.existsSync(targetHook)) {
    log("red", `❌ Hook not found: ${targetHook}`);
    return false;
  }

  try {
    const stats = fs.lstatSync(targetHook);
    if (!stats.isSymbolicLink()) {
      log("yellow", `⚠️  Hook exists but is not a symlink: ${targetHook}`);
      return true; // Still functional, just not managed by us
    }

    const linkTarget = fs.readlinkSync(targetHook);
    log("blue", `🔗 Hook ${hookName} links to: ${linkTarget}`);
    return true;
  } catch (error) {
    log("red", `❌ Failed to validate hook ${hookName}: ${error.message}`);
    return false;
  }
}

function scanAvailableHooks() {
  const githooksDir = ".githooks";

  if (!fs.existsSync(githooksDir)) {
    log("yellow", `⚠️  No .githooks directory found`);
    return [];
  }

  try {
    const files = fs.readdirSync(githooksDir);
    const hooks = files.filter((file) => {
      const filePath = path.join(githooksDir, file);
      const stats = fs.statSync(filePath);
      return stats.isFile() && stats.mode & parseInt("111", 8); // Executable
    });

    return hooks;
  } catch (error) {
    log("red", `❌ Failed to scan .githooks directory: ${error.message}`);
    return [];
  }
}

function main() {
  log("blue", "🚀 NightBFF Integration - Git Hooks Setup");
  log("blue", "==========================================");

  // Check if we're in a git repository
  if (!checkGitRepository()) {
    log("yellow", "⚠️  Not in a git repository - skipping hook installation");
    log("blue", "ℹ️  This is normal during npm install in CI/CD environments");
    return 0;
  }

  // If `.git` is *not* a directory (e.g. we are executing inside a Git submodule
  // where `.git` is a *file* pointing to the actual gitdir), attempting to
  // create `.git/hooks` will throw ENOTDIR. The parent repository is already
  // responsible for installing hooks, so we can safely exit early.

  try {
    const gitStat = fs.lstatSync(".git");
    if (!gitStat.isDirectory()) {
      log(
        "yellow",
        "⚠️  Detected submodule context (.git is a file). Skipping hook installation to avoid ENOTDIR.",
      );
      return 0;
    }
  } catch (e) {
    // If .git doesn't exist for some reason, skip as well.
    log("yellow", "⚠️  .git directory not found. Skipping hook installation.");
    return 0;
  }

  // Ensure .git/hooks directory exists
  ensureDirectoryExists(".git/hooks");

  // Scan for available hooks
  const availableHooks = scanAvailableHooks();

  if (availableHooks.length === 0) {
    log("yellow", "⚠️  No executable hooks found in .githooks/");
    return 0;
  }

  log(
    "blue",
    `📋 Found ${availableHooks.length} hook(s): ${availableHooks.join(", ")}`,
  );

  // Install each hook
  let successCount = 0;
  let failureCount = 0;

  for (const hook of availableHooks) {
    if (installHook(hook)) {
      successCount++;
    } else {
      failureCount++;
    }
  }

  log("blue", "\n🔍 Validating installations...");

  // Validate installations
  for (const hook of availableHooks) {
    validateHookInstallation(hook);
  }

  // Summary
  log("blue", "\n📊 Installation Summary:");
  log("green", `✅ Successful: ${successCount}`);
  if (failureCount > 0) {
    log("red", `❌ Failed: ${failureCount}`);
  }

  if (successCount > 0) {
    log("green", "\n🎉 Git hooks installation completed successfully!");
    log("blue", "ℹ️  Hooks will now run automatically on git operations");
  }

  return failureCount > 0 ? 1 : 0;
}

// Run the script if executed directly
if (require.main === module) {
  const exitCode = main();
  process.exit(exitCode);
}

module.exports = { installHook, validateHookInstallation, scanAvailableHooks };
