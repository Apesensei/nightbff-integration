// NightBFF Integration Load Test
// Basic performance validation for the integration stack

import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Trend, Rate } from 'k6/metrics';
import { SharedArray } from 'k6/data';

// Test configuration from environment or defaults
const VUS = __ENV.VUS || 5;
const DURATION = __ENV.DURATION || '30s';
const RAMP_UP = __ENV.RAMP_UP || '10s';
const RAMP_DOWN = __ENV.RAMP_DOWN || '10s';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

// Load test tokens (optional - used for authenticated endpoints)
const testTokens = new SharedArray('testTokens', function () {
  try {
    // Load tokens from file generated during CI token generation step
    const tokensData = open('./loadtest_tokens.json');
    return JSON.parse(tokensData);
  } catch (e) {
    // Tokens file may not exist or be empty - tests will run without auth
    console.warn('Could not load tokens file (./loadtest_tokens.json). Some authenticated tests may fail.');
    return [];
  }
});

// Helper to get a random token for authenticated requests
function getRandomToken() {
  if (testTokens.length === 0) return null;
  return testTokens[Math.floor(Math.random() * testTokens.length)];
}

// Custom metrics
const healthCheckTrend = new Trend('health_check_duration');
const authEndpointTrend = new Trend('auth_endpoint_duration');
const planEndpointTrend = new Trend('plan_endpoint_duration');
const errorRate = new Rate('integration_errors');

export const options = {
  stages: [
    { duration: RAMP_UP, target: VUS },
    { duration: DURATION, target: VUS },
    { duration: RAMP_DOWN, target: 0 },
  ],
  thresholds: {
    // Integration-specific thresholds (less strict than production)
    'http_req_failed': ['rate<0.1'], // 10% error rate max for integration
    'http_req_duration': ['p(95)<250'], // 95% under 250ms
    'health_check_duration': ['p(95)<100'], // Health checks should be fast
    'auth_endpoint_duration': ['p(95)<500'], // Auth can be slower
    'plan_endpoint_duration': ['p(95)<300'], // Plan endpoints
    'integration_errors': ['rate<0.05'], // 5% custom error rate
  },
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
};

export default function () {
  // Health Check Group
  group('Health and Status Checks', () => {
    const healthRes = http.get(`${BASE_URL}/health`);
    healthCheckTrend.add(healthRes.timings.duration);
    
    const healthOk = check(healthRes, {
      'health check status is 200': (r) => r.status === 200,
      'health check has status field': (r) => {
        try {
          return r.json() && r.json().status;
        } catch (e) {
          return false;
        }
      },
    });
    
    if (!healthOk) {
      errorRate.add(1);
    } else {
      errorRate.add(0);
    }

    // Swagger docs check
    const docsRes = http.get(`${BASE_URL}/api/docs`);
    check(docsRes, {
      'docs status is 200': (r) => r.status === 200,
      'docs returns HTML': (r) => r.headers['Content-Type'] && r.headers['Content-Type'].includes('text/html'),
    });

    sleep(0.5);
  });

  // Authentication Endpoints Group
  group('Authentication Endpoints', () => {
    // Test frontend signin endpoint (expect validation error)
    const signinPayload = JSON.stringify({
      email: 'loadtest@example.com',
      password: 'testpassword'
    });

    const signinRes = http.post(`${BASE_URL}/api/auth/frontend/signin`, signinPayload, {
      headers: { 'Content-Type': 'application/json' },
    });
    
    authEndpointTrend.add(signinRes.timings.duration);

    const signinOk = check(signinRes, {
      'signin endpoint exists (not 404)': (r) => r.status !== 404,
      'signin returns valid response': (r) => r.status >= 200 && r.status < 500,
      'signin response time acceptable': (r) => r.timings.duration < 1000,
    });

    if (!signinOk) {
      errorRate.add(1);
    } else {
      errorRate.add(0);
    }

    // Test frontend signup endpoint
    const signupPayload = JSON.stringify({
      email: `loadtest-${__VU}-${__ITER}@example.com`,
      password: 'testpassword123',
      name: `LoadTest User ${__VU}`
    });

    const signupRes = http.post(`${BASE_URL}/api/auth/frontend/signup`, signupPayload, {
      headers: { 'Content-Type': 'application/json' },
    });

    check(signupRes, {
      'signup endpoint exists (not 404)': (r) => r.status !== 404,
      'signup returns valid response': (r) => r.status >= 200 && r.status < 500,
    });

    sleep(0.5);
  });

  // Plan Endpoints Group  
  group('Plan Endpoints', () => {
    // Test plan cache health check
    const cacheHealthRes = http.get(`${BASE_URL}/api/plans/cache-health-check`);
    planEndpointTrend.add(cacheHealthRes.timings.duration);

    const cacheOk = check(cacheHealthRes, {
      'cache health check status is 200': (r) => r.status === 200,
      'cache health check has status': (r) => {
        try {
          return r.json() && r.json().status;
        } catch (e) {
          return false;
        }
      },
    });

    if (!cacheOk) {
      errorRate.add(1);
    } else {
      errorRate.add(0);
    }

    // Test plan creation endpoint with authentication (if tokens available)
    const planPayload = JSON.stringify({
      destination: `Load Test City ${__VU}-${__ITER}`,
      startDate: '2025-12-01',
      endDate: '2025-12-05'
    });

    const token = getRandomToken();
    const planHeaders = { 'Content-Type': 'application/json' };
    if (token) {
      planHeaders['Authorization'] = `Bearer ${token}`;
    }

    const createPlanRes = http.post(`${BASE_URL}/api/plans`, planPayload, {
      headers: planHeaders,
    });

    check(createPlanRes, {
      'plan creation endpoint exists': (r) => r.status !== 404,
      // If token available, expect success (200/201), otherwise expect auth error (401/403)
      'plan creation with token succeeds or without token requires auth': (r) => {
        if (token) {
          return r.status === 200 || r.status === 201 || r.status === 400; // 400 for validation errors is acceptable
        }
        return r.status === 401 || r.status === 403;
      },
    });

    sleep(0.5);
  });

  // Database Connectivity Test
  group('Database and Cache Connectivity', () => {
    // Multiple cache health checks to test connection pool
    for (let i = 0; i < 3; i++) {
      const cacheRes = http.get(`${BASE_URL}/api/plans/cache-health-check`);
      check(cacheRes, {
        [`cache check ${i + 1} successful`]: (r) => r.status === 200,
      });
      
      if (i < 2) sleep(0.1); // Small delay between checks
    }

    sleep(0.3);
  });

  // Error Handling Test
  group('Error Handling', () => {
    // Test invalid endpoint
    const invalidRes = http.get(`${BASE_URL}/api/nonexistent-endpoint`);
    check(invalidRes, {
      'invalid endpoint returns 404': (r) => r.status === 404,
    });

    // Test malformed JSON
    const malformedRes = http.post(`${BASE_URL}/api/auth/frontend/signin`, 'invalid-json', {
      headers: { 'Content-Type': 'application/json' },
    });
    check(malformedRes, {
      'malformed JSON handled properly': (r) => r.status >= 400 && r.status < 500,
    });

    sleep(0.2);
  });

  // Final sleep to simulate user think time
  sleep(1);
}

export function handleSummary(data) {
  // Custom summary for integration testing
  const summary = {
    'integration-test-summary.json': JSON.stringify({
      timestamp: new Date().toISOString(),
      test_type: 'integration_load_test',
      vus: VUS,
      duration: DURATION,
      metrics: {
        http_req_duration_p95: data.metrics.http_req_duration.values['p(95)'],
        http_req_failed_rate: data.metrics.http_req_failed.values.rate,
        health_check_p95: data.metrics.health_check_duration?.values['p(95)'] || 0,
        auth_endpoint_p95: data.metrics.auth_endpoint_duration?.values['p(95)'] || 0,
        plan_endpoint_p95: data.metrics.plan_endpoint_duration?.values['p(95)'] || 0,
        integration_error_rate: data.metrics.integration_errors?.values.rate || 0,
      },
      thresholds_passed: Object.keys(data.metrics).every(metric => {
        const m = data.metrics[metric];
        return !m.thresholds || Object.keys(m.thresholds).every(t => !m.thresholds[t].ok === false);
      }),
    }, null, 2),
  };

  return summary;
} 