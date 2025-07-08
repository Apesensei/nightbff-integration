/**
 * commitlint.config.js - NightBFF Integration Repository
 *
 * Enforces Conventional Commits specification for consistent commit messages
 * See: https://www.conventionalcommits.org/
 */

module.exports = {
  extends: ["@commitlint/config-conventional"],

  rules: {
    // Type enforcement
    "type-enum": [
      2,
      "always",
      [
        "feat", // New features
        "fix", // Bug fixes
        "docs", // Documentation only changes
        "style", // Changes that do not affect the meaning of the code
        "refactor", // Code change that neither fixes a bug nor adds a feature
        "perf", // Performance improvements
        "test", // Adding missing tests or correcting existing tests
        "chore", // Changes to the build process or auxiliary tools
        "ci", // Changes to CI configuration files and scripts
        "build", // Changes that affect the build system or dependencies
        "revert", // Reverts a previous commit
        "wip", // Work in progress (for integration branches only)
      ],
    ],

    // Scope rules (optional but recommended)
    "scope-enum": [
      1,
      "always",
      [
        // Infrastructure
        "ci",
        "docker",
        "deps",
        "config",

        // Backend microservices
        "auth",
        "chat",
        "event",
        "plan",
        "user",
        "venue",
        "interest",
        "notification",
        "premium",

        // Frontend areas
        "frontend",
        "ui",
        "navigation",
        "components",

        // Cross-cutting concerns
        "database",
        "migration",
        "redis",
        "testing",
        "monitoring",
        "security",
        "performance",

        // Integration specific
        "submodules",
        "integration",
        "e2e",
        "k6",
        "cypress",

        // Documentation
        "docs",
        "readme",
        "changelog",
      ],
    ],

    // Length limits
    "header-max-length": [2, "always", 72],
    "subject-max-length": [2, "always", 50],
    "body-max-line-length": [2, "always", 100],

    // Format rules
    "subject-case": [2, "always", "lower-case"],
    "subject-empty": [2, "never"],
    "subject-full-stop": [2, "never", "."],
    "type-case": [2, "always", "lower-case"],
    "type-empty": [2, "never"],

    // Body rules
    "body-leading-blank": [2, "always"],
    "footer-leading-blank": [2, "always"],
  },

  // Custom configuration for different scenarios
  ignores: [
    // Allow merge commits
    (message) => message.includes("Merge"),
    // Allow revert commits with default format
    (message) => message.includes("Revert"),
    // Allow initial commits
    (message) => message.includes("Initial commit"),
  ],

  // Help URL for developers
  helpUrl:
    "https://github.com/conventional-changelog/commitlint/#what-is-commitlint",
};
