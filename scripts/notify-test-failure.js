#!/usr/bin/env node

/**
 * Test Failure Notification Script for NightBFF CI
 *
 * This script sends notifications when k6 tests fail or performance
 * thresholds are not met. It can be extended to support Slack, Discord,
 * or other notification channels.
 *
 * Usage:
 *   node scripts/notify-test-failure.js k6-summary.json
 */

const fs = require("fs");
const path = require("path");

class TestFailureNotifier {
  constructor() {
    this.summary = null;
    this.notificationChannels = {
      console: true,
      // slack: process.env.SLACK_WEBHOOK_URL,
      // discord: process.env.DISCORD_WEBHOOK_URL,
      // email: process.env.EMAIL_SMTP_CONFIG
    };
  }

  /**
   * Load and parse k6 summary
   */
  loadSummary(summaryPath) {
    console.log(`📋 Loading test summary from: ${summaryPath}`);

    if (!fs.existsSync(summaryPath)) {
      throw new Error(`Summary file not found: ${summaryPath}`);
    }

    const content = fs.readFileSync(summaryPath, "utf-8");
    this.summary = JSON.parse(content);

    console.log(`✅ Loaded summary with ${this.summary.errors.length} errors`);
  }

  /**
   * Check if tests failed
   */
  hasFailures() {
    return this.summary && this.summary.errors.length > 0;
  }

  /**
   * Generate notification message
   */
  generateMessage() {
    if (!this.summary) {
      throw new Error("No summary loaded");
    }

    const timestamp = new Date().toISOString();
    const hasFailures = this.hasFailures();

    let message = "";

    if (hasFailures) {
      message = `🚨 **K6 Load Test Failures Detected**\n\n`;
      message += `**Timestamp:** ${timestamp}\n`;
      message += `**Environment:** ${process.env.NODE_ENV || "CI"}\n`;
      message += `**Branch:** ${process.env.GITHUB_REF || "unknown"}\n`;
      message += `**Commit:** ${process.env.GITHUB_SHA || "unknown"}\n\n`;

      message += `**Performance Metrics:**\n`;
      if (this.summary.performance.responseTime) {
        const rt = this.summary.performance.responseTime;
        message += `• Response Time - Avg: ${rt.avg}ms, P95: ${rt.p95}ms, P99: ${rt.p99}ms\n`;
      }
      if (this.summary.performance.errorRate) {
        const er = this.summary.performance.errorRate;
        message += `• Error Rate: ${(er.rate * 100).toFixed(2)}% (${er.total} errors)\n`;
      }
      if (this.summary.checks) {
        const checks = this.summary.checks;
        message += `• Check Pass Rate: ${(checks.rate * 100).toFixed(2)}% (${checks.total} checks)\n`;
      }

      message += `\n**Failed Thresholds:**\n`;
      this.summary.errors.forEach((error, index) => {
        message += `${index + 1}. **${error.type}**: ${error.message}\n`;
        message += `   - Actual: ${error.actual}\n`;
        message += `   - Threshold: ${error.threshold}\n`;
      });

      message += `\n**Recommendations:**\n`;
      this.summary.recommendations.forEach((rec) => {
        message += `• ${rec.message}\n`;
      });

      message += `\n**Next Steps:**\n`;
      message += `• Review the failing metrics above\n`;
      message += `• Check recent code changes that might affect performance\n`;
      message += `• Investigate server resources and API endpoint health\n`;
      message += `• Consider rolling back if performance degradation is significant\n`;
    } else {
      message = `✅ **K6 Load Tests Passed Successfully**\n\n`;
      message += `**Timestamp:** ${timestamp}\n`;
      message += `**Environment:** ${process.env.NODE_ENV || "CI"}\n`;
      message += `**Branch:** ${process.env.GITHUB_REF || "unknown"}\n`;
      message += `**Commit:** ${process.env.GITHUB_SHA || "unknown"}\n\n`;

      message += `**Performance Metrics:**\n`;
      if (this.summary.performance.responseTime) {
        const rt = this.summary.performance.responseTime;
        message += `• Response Time - Avg: ${rt.avg}ms, P95: ${rt.p95}ms, P99: ${rt.p99}ms\n`;
      }
      if (this.summary.performance.errorRate) {
        const er = this.summary.performance.errorRate;
        message += `• Error Rate: ${(er.rate * 100).toFixed(2)}% (${er.total} errors)\n`;
      }
      if (this.summary.checks) {
        const checks = this.summary.checks;
        message += `• Check Pass Rate: ${(checks.rate * 100).toFixed(2)}% (${checks.total} checks)\n`;
      }

      message += `\n🎉 All performance thresholds met! The system is performing well.`;
    }

    return message;
  }

  /**
   * Send console notification
   */
  sendConsoleNotification(message) {
    console.log("\n" + "=".repeat(80));
    console.log("🔔 TEST NOTIFICATION");
    console.log("=".repeat(80));
    console.log(message);
    console.log("=".repeat(80));
  }

  /**
   * Send Slack notification (placeholder)
   */
  async sendSlackNotification(message) {
    const webhookUrl = process.env.SLACK_WEBHOOK_URL;

    if (!webhookUrl) {
      console.log(
        "⚠️  Slack webhook URL not configured, skipping Slack notification",
      );
      return;
    }

    try {
      const payload = {
        text: message,
        username: "NightBFF CI Bot",
        icon_emoji: this.hasFailures() ? ":x:" : ":white_check_mark:",
      };

      // Note: In a real implementation, you would use a proper HTTP client
      // like axios or node-fetch to send the webhook
      console.log(
        "📤 Slack notification payload:",
        JSON.stringify(payload, null, 2),
      );
      console.log(
        "💡 To implement Slack notifications, add axios and send webhook to:",
        webhookUrl,
      );
    } catch (error) {
      console.error("❌ Failed to send Slack notification:", error.message);
    }
  }

  /**
   * Send Discord notification (placeholder)
   */
  async sendDiscordNotification(message) {
    const webhookUrl = process.env.DISCORD_WEBHOOK_URL;

    if (!webhookUrl) {
      console.log(
        "⚠️  Discord webhook URL not configured, skipping Discord notification",
      );
      return;
    }

    try {
      const payload = {
        content: message,
        username: "NightBFF CI Bot",
        avatar_url:
          "https://github.com/Apesensei/nightbff-integration/raw/main/.github/ci-bot-avatar.png",
      };

      // Note: In a real implementation, you would use a proper HTTP client
      console.log(
        "📤 Discord notification payload:",
        JSON.stringify(payload, null, 2),
      );
      console.log(
        "💡 To implement Discord notifications, add axios and send webhook to:",
        webhookUrl,
      );
    } catch (error) {
      console.error("❌ Failed to send Discord notification:", error.message);
    }
  }

  /**
   * Send all notifications
   */
  async sendNotifications() {
    const message = this.generateMessage();

    // Console notification (always enabled)
    if (this.notificationChannels.console) {
      this.sendConsoleNotification(message);
    }

    // Slack notification
    if (this.notificationChannels.slack) {
      await this.sendSlackNotification(message);
    }

    // Discord notification
    if (this.notificationChannels.discord) {
      await this.sendDiscordNotification(message);
    }

    console.log("✅ Notifications sent successfully");
  }

  /**
   * Generate detailed report for debugging
   */
  generateDebugReport() {
    if (!this.summary) {
      throw new Error("No summary loaded");
    }

    const report = {
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV || "CI",
      branch: process.env.GITHUB_REF || "unknown",
      commit: process.env.GITHUB_SHA || "unknown",
      summary: this.summary,
      hasFailures: this.hasFailures(),
      errorCount: this.summary.errors.length,
    };

    const reportPath = `k6-debug-report-${Date.now()}.json`;
    fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
    console.log(`📄 Debug report saved to: ${reportPath}`);

    return reportPath;
  }
}

// Main execution
async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.error(
      "❌ Usage: node scripts/notify-test-failure.js <k6-summary.json>",
    );
    process.exit(1);
  }

  const summaryFile = args[0];

  try {
    const notifier = new TestFailureNotifier();
    notifier.loadSummary(summaryFile);

    await notifier.sendNotifications();

    // Generate debug report if there are failures
    if (notifier.hasFailures()) {
      notifier.generateDebugReport();
      console.log("❌ Test failures detected. Exiting with error code.");
      process.exit(1);
    } else {
      console.log("✅ All tests passed. No failures to report.");
      process.exit(0);
    }
  } catch (error) {
    console.error(`❌ Error in notification script: ${error.message}`);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = TestFailureNotifier;
