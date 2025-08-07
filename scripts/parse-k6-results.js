#!/usr/bin/env node

/**
 * k6 Results Parser for NightBFF CI
 *
 * This script parses k6 JSON output and extracts key performance metrics
 * for CI monitoring and threshold enforcement.
 *
 * Usage:
 *   node scripts/parse-k6-results.js k6-results.json
 */

const fs = require("fs");
const path = require("path");

// Performance thresholds
const THRESHOLDS = {
  // Response time thresholds (95th percentile)
  http_req_duration_p95: 250, // ms
  http_req_duration_p95_authenticated: 300, // ms

  // Error rate thresholds
  http_req_failed_rate: 0.1, // 10%

  // Check pass rate thresholds
  checks_rate: 0.9, // 90%

  // Request rate thresholds
  http_reqs_rate: 1, // minimum 1 req/sec
};

class K6ResultsParser {
  constructor() {
    this.metrics = {};
    this.summary = {};
    this.thresholds = THRESHOLDS;
  }

  /**
   * Parse k6 JSON output file
   */
  parseFile(filePath) {
    console.log(`📊 Parsing k6 results from: ${filePath}`);

    if (!fs.existsSync(filePath)) {
      throw new Error(`k6 results file not found: ${filePath}`);
    }

    const content = fs.readFileSync(filePath, "utf-8");
    const lines = content.trim().split("\n");

    // Parse each JSON line
    lines.forEach((line) => {
      try {
        const data = JSON.parse(line);
        this.processMetric(data);
      } catch (error) {
        console.warn(`⚠️  Skipping invalid JSON line: ${error.message}`);
      }
    });

    this.generateSummary();
    return this.summary;
  }

  /**
   * Process a single metric from k6 output
   */
  processMetric(data) {
    if (data.type === "Metric") {
      // Store metric definition
      this.metrics[data.metric] = {
        name: data.metric,
        type: data.data.type,
        thresholds: data.data.thresholds || [],
        submetrics: data.data.submetrics || [],
      };
    } else if (data.type === "Point") {
      // Store metric data point
      if (!this.metrics[data.metric]) {
        this.metrics[data.metric] = { values: [] };
      }

      if (!this.metrics[data.metric].values) {
        this.metrics[data.metric].values = [];
      }

      this.metrics[data.metric].values.push({
        time: data.data.time,
        value: data.data.value,
        tags: data.data.tags || {},
      });
    }
  }

  /**
   * Generate summary from parsed metrics
   */
  generateSummary() {
    console.log("📈 Generating performance summary...");

    this.summary = {
      timestamp: new Date().toISOString(),
      thresholds: this.thresholds,
      metrics: {},
      performance: {},
      checks: {},
      errors: [],
      recommendations: [],
    };

    // Process each metric type
    Object.keys(this.metrics).forEach((metricName) => {
      const metric = this.metrics[metricName];

      if (metric.values && metric.values.length > 0) {
        this.processMetricValues(metricName, metric);
      }
    });

    this.evaluateThresholds();
    this.generateRecommendations();
  }

  /**
   * Process metric values and calculate statistics
   */
  processMetricValues(metricName, metric) {
    const values = metric.values
      .map((v) => v.value)
      .filter((v) => v !== null && v !== undefined);

    if (values.length === 0) return;

    // Calculate statistics
    const sorted = values.sort((a, b) => a - b);
    const count = values.length;
    const sum = values.reduce((a, b) => a + b, 0);
    const avg = sum / count;
    const min = sorted[0];
    const max = sorted[sorted.length - 1];
    const p50 = this.percentile(sorted, 50);
    const p90 = this.percentile(sorted, 90);
    const p95 = this.percentile(sorted, 95);
    const p99 = this.percentile(sorted, 99);

    this.summary.metrics[metricName] = {
      count,
      sum,
      avg: Math.round(avg * 1000) / 1000,
      min: Math.round(min * 1000) / 1000,
      max: Math.round(max * 1000) / 1000,
      p50: Math.round(p50 * 1000) / 1000,
      p90: Math.round(p90 * 1000) / 1000,
      p95: Math.round(p95 * 1000) / 1000,
      p99: Math.round(p99 * 1000) / 1000,
    };

    // Special handling for specific metrics
    if (metricName === "http_req_duration") {
      this.summary.performance.responseTime = {
        avg: this.summary.metrics[metricName].avg,
        p95: this.summary.metrics[metricName].p95,
        p99: this.summary.metrics[metricName].p99,
      };
    } else if (metricName === "http_req_failed") {
      this.summary.performance.errorRate = {
        total: this.summary.metrics[metricName].sum,
        rate: this.summary.metrics[metricName].avg,
      };
    } else if (metricName === "checks") {
      this.summary.checks = {
        total: this.summary.metrics[metricName].sum,
        rate: this.summary.metrics[metricName].avg,
      };
    } else if (metricName === "http_reqs") {
      this.summary.performance.requestRate = {
        total: this.summary.metrics[metricName].sum,
        rate: this.summary.metrics[metricName].avg,
      };
    }
  }

  /**
   * Calculate percentile from sorted array
   */
  percentile(sorted, p) {
    const index = Math.ceil((p / 100) * sorted.length) - 1;
    return sorted[Math.max(0, index)];
  }

  /**
   * Evaluate performance against thresholds
   */
  evaluateThresholds() {
    console.log("🎯 Evaluating performance thresholds...");

    // Response time evaluation
    if (this.summary.performance.responseTime) {
      const p95 = this.summary.performance.responseTime.p95;

      if (p95 > this.thresholds.http_req_duration_p95) {
        this.summary.errors.push({
          type: "PERFORMANCE",
          metric: "http_req_duration_p95",
          actual: p95,
          threshold: this.thresholds.http_req_duration_p95,
          message: `Response time p95 (${p95}ms) exceeds threshold (${this.thresholds.http_req_duration_p95}ms)`,
        });
      }
    }

    // Error rate evaluation
    if (this.summary.performance.errorRate) {
      const errorRate = this.summary.performance.errorRate.rate;

      if (errorRate > this.thresholds.http_req_failed_rate) {
        this.summary.errors.push({
          type: "RELIABILITY",
          metric: "http_req_failed_rate",
          actual: errorRate,
          threshold: this.thresholds.http_req_failed_rate,
          message: `Error rate (${(errorRate * 100).toFixed(2)}%) exceeds threshold (${(this.thresholds.http_req_failed_rate * 100).toFixed(2)}%)`,
        });
      }
    }

    // Check pass rate evaluation
    if (this.summary.checks) {
      const checkRate = this.summary.checks.rate;

      if (checkRate < this.thresholds.checks_rate) {
        this.summary.errors.push({
          type: "FUNCTIONALITY",
          metric: "checks_rate",
          actual: checkRate,
          threshold: this.thresholds.checks_rate,
          message: `Check pass rate (${(checkRate * 100).toFixed(2)}%) below threshold (${(this.thresholds.checks_rate * 100).toFixed(2)}%)`,
        });
      }
    }
  }

  /**
   * Generate recommendations based on results
   */
  generateRecommendations() {
    console.log("💡 Generating recommendations...");

    if (this.summary.errors.length === 0) {
      this.summary.recommendations.push({
        type: "SUCCESS",
        message: "All performance thresholds met! 🎉",
      });
    } else {
      this.summary.errors.forEach((error) => {
        let recommendation = "";

        switch (error.type) {
          case "PERFORMANCE":
            recommendation = `Consider optimizing API endpoints or increasing server resources to improve response times.`;
            break;
          case "RELIABILITY":
            recommendation = `Investigate API errors and improve error handling to reduce failure rates.`;
            break;
          case "FUNCTIONALITY":
            recommendation = `Review test assertions and ensure API endpoints are working correctly.`;
            break;
        }

        this.summary.recommendations.push({
          type: error.type,
          message: recommendation,
        });
      });
    }
  }

  /**
   * Print formatted summary
   */
  printSummary() {
    console.log("\n" + "=".repeat(60));
    console.log("📊 K6 PERFORMANCE TEST SUMMARY");
    console.log("=".repeat(60));

    // Performance metrics
    if (this.summary.performance.responseTime) {
      console.log(`\n⏱️  Response Time:`);
      console.log(`   Average: ${this.summary.performance.responseTime.avg}ms`);
      console.log(`   P95: ${this.summary.performance.responseTime.p95}ms`);
      console.log(`   P99: ${this.summary.performance.responseTime.p99}ms`);
    }

    if (this.summary.performance.errorRate) {
      console.log(`\n❌ Error Rate:`);
      console.log(
        `   Rate: ${(this.summary.performance.errorRate.rate * 100).toFixed(2)}%`,
      );
      console.log(
        `   Total Errors: ${this.summary.performance.errorRate.total}`,
      );
    }

    if (this.summary.checks) {
      console.log(`\n✅ Check Pass Rate:`);
      console.log(`   Rate: ${(this.summary.checks.rate * 100).toFixed(2)}%`);
      console.log(`   Total Checks: ${this.summary.checks.total}`);
    }

    // Threshold evaluation
    console.log(`\n🎯 Threshold Evaluation:`);
    if (this.summary.errors.length === 0) {
      console.log(`   ✅ All thresholds passed!`);
    } else {
      this.summary.errors.forEach((error) => {
        console.log(`   ❌ ${error.message}`);
      });
    }

    // Recommendations
    console.log(`\n💡 Recommendations:`);
    this.summary.recommendations.forEach((rec) => {
      console.log(`   ${rec.type === "SUCCESS" ? "✅" : "⚠️"} ${rec.message}`);
    });

    console.log("\n" + "=".repeat(60));
  }

  /**
   * Export summary to JSON file
   */
  exportSummary(outputPath) {
    const summaryJson = JSON.stringify(this.summary, null, 2);
    fs.writeFileSync(outputPath, summaryJson);
    console.log(`📄 Summary exported to: ${outputPath}`);
  }
}

// Main execution
function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.error(
      "❌ Usage: node scripts/parse-k6-results.js <k6-results.json>",
    );
    process.exit(1);
  }

  const inputFile = args[0];
  const outputFile = args[1] || "k6-summary.json";

  try {
    const parser = new K6ResultsParser();
    const summary = parser.parseFile(inputFile);

    parser.printSummary();
    parser.exportSummary(outputFile);

    // Exit with error code if thresholds failed
    if (summary.errors.length > 0) {
      console.log(
        `\n❌ ${summary.errors.length} threshold(s) failed. Exiting with error code.`,
      );
      process.exit(1);
    } else {
      console.log(`\n✅ All thresholds passed!`);
      process.exit(0);
    }
  } catch (error) {
    console.error(`❌ Error parsing k6 results: ${error.message}`);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = K6ResultsParser;
